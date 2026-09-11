import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

/// Wraps `flutter_webrtc` for the Sambaclub live flow.
///
/// * The **host** calls [startLocalMedia] once and then [offerTo] for every peer
///   announced by the server.
/// * A **viewer** never publishes; it just answers the host offer through
///   [handleSignal] and renders the remote stream in [remoteRenderer].
///
/// Every native call is guarded with `try/catch`; failures are reported through
/// the [onError] callback instead of crashing the UI.
class WebRtcService {
  WebRtcService({this.onSignal, this.onError, this.onRemoteStream});

  /// Called to relay a signaling payload (`offer` / `answer` / `ice`) to a peer.
  final void Function(String toPeerId, Map<String, dynamic> data)? onSignal;

  /// Called with a human-readable message whenever a native call fails.
  final void Function(String message)? onError;

  /// Called when the remote MediaStream is attached (viewer side).
  final void Function(MediaStream stream)? onRemoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  static const Map<String, dynamic> _iceServers = <String, dynamic>{
    'iceServers': <Map<String, dynamic>>[
      <String, dynamic>{'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _peers =
      <String, RTCPeerConnection>{};
  final Map<String, List<RTCIceCandidate>> _pendingCandidates =
      <String, List<RTCIceCandidate>>{};

  bool _renderersReady = false;
  bool _localMediaStarted = false;
  bool _disposed = false;

  /// True once the camera/mic stream is attached to [localRenderer].
  bool get hasLocalMedia => _localMediaStarted;

  /// True once a remote stream is attached to [remoteRenderer].
  bool get hasRemoteStream => remoteRenderer.srcObject != null;

  // ------------------------------------------------------------- Lifecycle

  /// Initializes both video renderers (safe to call more than once).
  Future<void> initialize() => _ensureRenderers();

  Future<void> _ensureRenderers() async {
    if (_renderersReady || _disposed) return;
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      _renderersReady = true;
    } catch (error) {
      _fail('Inizializzazione dei renderer video', error);
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      final Map<Permission, PermissionStatus> statuses =
          await <Permission>[Permission.camera, Permission.microphone].request();
      return statuses.values.every(
        (PermissionStatus status) => status.isGranted,
      );
    } catch (error) {
      _fail('Richiesta permessi fotocamera/microfono', error);
      return false;
    }
  }

  /// Requests the camera/mic permissions and starts the local capture,
  /// attaching the stream to [localRenderer].
  Future<void> startLocalMedia() async {
    if (_localMediaStarted) return;
    try {
      final bool granted = await _requestPermissions();
      if (!granted) {
        _error('Permessi fotocamera/microfono negati');
        return;
      }
      await _ensureRenderers();
      final MediaStream stream =
          await navigator.mediaDevices.getUserMedia(<String, dynamic>{
        'audio': true,
        'video': <String, dynamic>{
          'facingMode': 'user',
          'width': <String, dynamic>{'ideal': 720},
          'height': <String, dynamic>{'ideal': 1280},
        },
      });
      _localStream = stream;
      localRenderer.srcObject = stream;
      _localMediaStarted = true;
    } catch (error) {
      _fail('Avvio camera/microfono', error);
    }
  }

  /// Adds the local audio/video tracks to [pc] (host side).
  void addLocalTracks(RTCPeerConnection pc) {
    final MediaStream? stream = _localStream;
    if (stream == null) {
      _error('Nessun media locale: chiama startLocalMedia() prima.');
      return;
    }
    try {
      for (final MediaStreamTrack track in stream.getTracks()) {
        pc.addTrack(track, stream);
      }
    } catch (error) {
      _fail('Aggiunta delle tracce locali', error);
    }
  }

  // ----------------------------------------------------------------- Peers

  Future<RTCPeerConnection> _ensurePeer(String peerId) async {
    final RTCPeerConnection? existing = _peers[peerId];
    if (existing != null) return existing;

    final RTCPeerConnection pc = await createPeerConnection(_iceServers);
    _peers[peerId] = pc;

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate == null) return;
      onSignal?.call(peerId, <String, dynamic>{
        'kind': 'ice',
        'candidate': candidate.toMap(),
      });
    };

    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _attachRemote(event.streams.first);
      }
    };
    pc.onAddStream = (MediaStream stream) {
      _attachRemote(stream);
    };
    return pc;
  }

  /// Host side: builds a peer connection for [peerId], adds the local tracks and
  /// sends the `offer` through [onSignal].
  Future<void> offerTo(String peerId) async {
    if (peerId.isEmpty) return;
    try {
      await _ensureRenderers();
      final RTCPeerConnection pc = await _ensurePeer(peerId);
      addLocalTracks(pc);
      final RTCSessionDescription offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      onSignal?.call(peerId, <String, dynamic>{
        'kind': 'offer',
        'sdp': offer.toMap(),
      });
    } catch (error) {
      _fail('Creazione dell\'offerta per $peerId', error);
    }
  }

  /// Viewer + host side: applies an incoming `offer`, `answer` or `ice`.
  Future<void> handleSignal(String from, Map data) async {
    try {
      final Map<String, dynamic> payload = Map<String, dynamic>.from(data);
      final String kind = (payload['kind'] ?? '').toString();
      switch (kind) {
        case 'offer':
          await _handleOffer(from, payload);
          break;
        case 'answer':
          await _handleAnswer(from, payload);
          break;
        case 'ice':
          await _handleIce(from, payload);
          break;
        default:
          break;
      }
    } catch (error) {
      _fail('Gestione del segnale da $from', error);
    }
  }

  Future<void> _handleOffer(
    String from,
    Map<String, dynamic> payload,
  ) async {
    await _ensureRenderers();
    final RTCPeerConnection pc = await _ensurePeer(from);
    await pc.setRemoteDescription(_descriptionFrom(payload['sdp'], 'offer'));
    await _flushCandidates(from, pc);
    final RTCSessionDescription answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    onSignal?.call(from, <String, dynamic>{
      'kind': 'answer',
      'sdp': answer.toMap(),
    });
  }

  Future<void> _handleAnswer(
    String from,
    Map<String, dynamic> payload,
  ) async {
    final RTCPeerConnection? pc = _peers[from];
    if (pc == null) return;
    await pc.setRemoteDescription(_descriptionFrom(payload['sdp'], 'answer'));
    await _flushCandidates(from, pc);
  }

  Future<void> _handleIce(String from, Map<String, dynamic> payload) async {
    final dynamic raw = payload['candidate'];
    if (raw is! Map) return;
    final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
    final RTCIceCandidate candidate = RTCIceCandidate(
      map['candidate']?.toString(),
      map['sdpMid']?.toString(),
      map['sdpMLineIndex'] is int
          ? map['sdpMLineIndex'] as int
          : int.tryParse(map['sdpMLineIndex']?.toString() ?? ''),
    );
    final RTCPeerConnection? pc = _peers[from];
    final RTCSessionDescription? remote =
        pc == null ? null : await pc.getRemoteDescription();
    if (pc != null && remote != null) {
      await pc.addCandidate(candidate);
    } else {
      _pendingCandidates
          .putIfAbsent(from, () => <RTCIceCandidate>[])
          .add(candidate);
    }
  }

  Future<void> _flushCandidates(String peerId, RTCPeerConnection pc) async {
    final List<RTCIceCandidate>? pending = _pendingCandidates.remove(peerId);
    if (pending == null) return;
    for (final RTCIceCandidate candidate in pending) {
      try {
        await pc.addCandidate(candidate);
      } catch (error) {
        _fail('Aggiunta di un candidato ICE', error);
      }
    }
  }

  RTCSessionDescription _descriptionFrom(dynamic raw, String fallbackType) {
    final Map<String, dynamic> map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final String? sdp = map['sdp']?.toString();
    final String type = (map['type'] ?? fallbackType).toString();
    return RTCSessionDescription(sdp, type);
  }

  Future<void> _attachRemote(MediaStream stream) async {
    try {
      await _ensureRenderers();
      if (_disposed) return;
      remoteRenderer.srcObject = stream;
      onRemoteStream?.call(stream);
    } catch (error) {
      _fail('Ricezione dello stream remoto', error);
    }
  }

  /// Closes the peer connection for [peerId] (called on `peer_left`).
  Future<void> closePeer(String peerId) async {
    final RTCPeerConnection? pc = _peers.remove(peerId);
    _pendingCandidates.remove(peerId);
    if (pc == null) return;
    try {
      await pc.close();
    } catch (error) {
      _fail('Chiusura del peer $peerId', error);
    }
  }

  // --------------------------------------------------------------- Teardown

  /// Closes every peer connection, stops the local tracks and disposes both
  /// renderers. Safe to call more than once.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    for (final RTCPeerConnection pc in _peers.values) {
      try {
        await pc.close();
      } catch (_) {}
    }
    _peers.clear();
    _pendingCandidates.clear();

    final MediaStream? stream = _localStream;
    if (stream != null) {
      try {
        for (final MediaStreamTrack track in stream.getTracks()) {
          try {
            await track.stop();
          } catch (_) {}
        }
        await stream.dispose();
      } catch (_) {}
    }
    _localStream = null;
    _localMediaStarted = false;

    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (_) {}
    try {
      await localRenderer.dispose();
    } catch (_) {}
    try {
      await remoteRenderer.dispose();
    } catch (_) {}
    _renderersReady = false;
  }

  // ----------------------------------------------------------------- Errors

  void _fail(String context, Object error) => _error('$context: $error');

  void _error(String message) {
    final void Function(String message)? callback = onError;
    if (callback != null) {
      callback(message);
    } else {
      debugPrint('[WebRtcService] $message');
    }
  }
}
