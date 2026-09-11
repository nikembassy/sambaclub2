import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/gift.dart';
import '../models/room.dart';

/// A participant announced by the signaling server.
class LivePeer {
  const LivePeer({
    required this.id,
    required this.name,
    required this.emoji,
    this.photo,
  });

  final String id;
  final String name;
  final String emoji;
  final String? photo;

  factory LivePeer.fromJson(Map<String, dynamic> json) {
    return LivePeer(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Ospite').toString(),
      emoji: (json['emoji'] ?? '🎤').toString(),
      photo: json['photo']?.toString(),
    );
  }
}

/// An incoming chat line (`{"type":"chat"}`).
class LiveChatEvent {
  const LiveChatEvent({required this.from, required this.text, required this.ts});

  final String from;
  final String text;
  final double ts;
}

/// An incoming audio payload (`{"type":"audio"}`, base64 data URL).
class LiveAudioEvent {
  const LiveAudioEvent({required this.from, required this.data});

  final String from;
  final String data;
}

/// An incoming gift (`{"type":"gift"}`) with the updated PK scores.
class LiveGiftEvent {
  const LiveGiftEvent({
    required this.from,
    required this.emoji,
    required this.name,
    required this.qty,
    required this.total,
    required this.pkLeft,
    required this.pkRight,
  });

  final String from;
  final String emoji;
  final String name;
  final int qty;
  final int total;
  final int pkLeft;
  final int pkRight;
}

/// A WebRTC signaling message relayed by the server (`{"type":"signal"}`).
class LiveSignalEvent {
  const LiveSignalEvent({required this.from, required this.data});

  final String from;
  final Map<String, dynamic> data;
}

/// The payload of a successful `join` (`{"type":"joined"}`).
class JoinedEvent {
  const JoinedEvent({required this.room, required this.host});

  final LiveRoom room;
  final LivePeer host;
}

/// Gradients used to build a room cover for server rooms (no network images).
const List<List<Color>> _coverPalettes = <List<Color>>[
  <Color>[Color(0xFF3A2C6B), Color(0xFF0A0A0C)],
  <Color>[Color(0xFF6B2C4A), Color(0xFF0A0A0C)],
  <Color>[Color(0xFF7A1F3D), Color(0xFF2A2A34)],
  <Color>[Color(0xFF274B6B), Color(0xFF17171D)],
  <Color>[Color(0xFF2E4A3A), Color(0xFF0A0A0C)],
  <Color>[Color(0xFF5C4A1E), Color(0xFF17171D)],
  <Color>[Color(0xFF1F4E6B), Color(0xFF0A0A0C)],
  <Color>[Color(0xFF6B3A1F), Color(0xFF17171D)],
  <Color>[Color(0xFF232A44), Color(0xFF0A0A0C)],
  <Color>[Color(0xFF3D2C4A), Color(0xFF17171D)],
];

/// Deterministic cover palette so the same room always looks the same.
List<Color> _coverFor(String id) {
  int h = 7;
  for (final int c in id.codeUnits) {
    h = (h * 31 + c) & 0x7FFFFFFF;
  }
  return _coverPalettes[h % _coverPalettes.length];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

int _asInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Maps a server room object to the app's [LiveRoom] model.
LiveRoom _roomFromJson(Map<String, dynamic> json) {
  final String id = (json['id'] ?? '').toString();
  final String type = (json['type'] ?? 'live').toString();
  return LiveRoom(
    id: id,
    hostName: (json['host'] ?? 'Ospite').toString(),
    hostEmoji: (json['hostEmoji'] ?? '🎤').toString(),
    flagEmoji: '🌐',
    title: (json['title'] ?? 'Live').toString(),
    category: (json['cat'] ?? 'Talk').toString(),
    viewers: _asInt(json['viewers'], 0),
    type: type == 'party' ? RoomType.party : RoomType.live,
    coverColors: _coverFor(id),
  );
}

/// Real-time client for the Sambaclub signaling server (JSON text frames over
/// `ws://HOST:8000/ws`).
///
/// It owns a single [WebSocketChannel] and exposes broadcast streams for every
/// server event. WebRTC negotiation itself lives in `WebRtcService`; this class
/// only relays the `signal` messages (and every other message) verbatim.
class LiveService {
  /// Default URL for the Android emulator (host machine seen as 10.0.2.2).
  static const String defaultServerUrl = 'ws://10.0.2.2:8000/ws';

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  final StreamController<List<LiveRoom>> _rooms =
      StreamController<List<LiveRoom>>.broadcast();
  final StreamController<LiveChatEvent> _chat =
      StreamController<LiveChatEvent>.broadcast();
  final StreamController<LiveAudioEvent> _audio =
      StreamController<LiveAudioEvent>.broadcast();
  final StreamController<LiveGiftEvent> _gifts =
      StreamController<LiveGiftEvent>.broadcast();
  final StreamController<int> _viewers = StreamController<int>.broadcast();
  final StreamController<LivePeer> _peerJoined =
      StreamController<LivePeer>.broadcast();
  final StreamController<String> _peerLeft = StreamController<String>.broadcast();
  final StreamController<LiveSignalEvent> _signals =
      StreamController<LiveSignalEvent>.broadcast();
  final StreamController<String> _roomClosed =
      StreamController<String>.broadcast();
  final StreamController<JoinedEvent> _joined =
      StreamController<JoinedEvent>.broadcast();
  final StreamController<LiveRoom> _liveStarted =
      StreamController<LiveRoom>.broadcast();
  final StreamController<String> _errors = StreamController<String>.broadcast();

  Stream<List<LiveRoom>> get rooms => _rooms.stream;
  Stream<LiveChatEvent> get chat => _chat.stream;
  Stream<LiveAudioEvent> get audio => _audio.stream;
  Stream<LiveGiftEvent> get gifts => _gifts.stream;
  Stream<int> get viewers => _viewers.stream;
  Stream<LivePeer> get peerJoined => _peerJoined.stream;
  Stream<String> get peerLeft => _peerLeft.stream;
  Stream<LiveSignalEvent> get signals => _signals.stream;
  Stream<String> get roomClosed => _roomClosed.stream;
  Stream<JoinedEvent> get joined => _joined.stream;
  Stream<LiveRoom> get liveStarted => _liveStarted.stream;
  Stream<String> get errors => _errors.stream;

  /// Server id assigned to this client (`welcome` / `ready`).
  String? myId;

  /// Room this client is currently inside, if any.
  String? currentRoomId;

  String? _name;
  String? _photo;
  String _emoji = '🎤';
  bool _isHost = false;
  bool _connected = false;

  /// Last room list received from the server (used to tell real rooms apart
  /// from the local mock rooms).
  List<LiveRoom> _cachedRooms = <LiveRoom>[];

  /// True when this client created the current room via [goLive].
  bool get isHost => _isHost;

  /// True while the websocket is open.
  bool get isConnected => _connected;

  /// Nickname sent in the `hello` frame.
  String? get displayName => _name;

  /// Photo URL sent in the `hello` frame (may be null).
  String? get photoUrl => _photo;

  /// Emoji sent in the `hello` frame.
  String get emoji => _emoji;

  /// Last known server rooms.
  List<LiveRoom> get knownRooms => List<LiveRoom>.unmodifiable(_cachedRooms);

  /// True when [roomId] exists on the server (vs. a local mock room).
  bool knowsRoom(String roomId) =>
      _cachedRooms.any((LiveRoom room) => room.id == roomId);

  // ------------------------------------------------------------- Connection

  /// Opens the websocket at [url], sends `hello` + `list` and resolves once the
  /// connection is established.
  ///
  /// Throws when the socket cannot be opened so the caller (login screen) can
  /// surface a clear error.
  Future<void> connect(
    String url, {
    required String name,
    String? photo,
    String emoji = '🎤',
  }) async {
    await _close(silent: true);
    _name = name;
    _photo = photo;
    _emoji = emoji;
    try {
      final Uri uri = Uri.parse(url.trim());
      final WebSocketChannel channel = WebSocketChannel.connect(uri);
      await channel.ready;
      _channel = channel;
      _connected = true;
      _sub = channel.stream.listen(
        _onData,
        onError: _onSocketError,
        onDone: _onSocketDone,
        cancelOnError: false,
      );
      _send(<String, dynamic>{
        'type': 'hello',
        'name': name,
        'emoji': emoji,
        'photo': photo,
      });
      _send(<String, dynamic>{'type': 'list'});
    } catch (error) {
      _connected = false;
      _errors.add('Connessione al server non riuscita: $error');
      rethrow;
    }
  }

  void _onSocketError(Object error) {
    _connected = false;
    _errors.add('Errore di rete: $error');
  }

  void _onSocketDone() {
    _connected = false;
  }

  void _send(Map<String, dynamic> message) {
    final WebSocketChannel? channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode(message));
    } catch (error) {
      _errors.add('Invio non riuscito: $error');
    }
  }

  // ----------------------------------------------------------- Outgoing API

  /// Creates a room on the server and (on `live_started`) joins it as host.
  void goLive(String title, String cat) {
    _isHost = true;
    _send(<String, dynamic>{
      'type': 'golive',
      'title': title,
      'cat': cat,
      'kind': 'live',
    });
  }

  /// [goLive] + waits for the `live_started` room (throws [TimeoutException]).
  Future<LiveRoom> goLiveAndWait(
    String title,
    String cat, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    goLive(title, cat);
    return _liveStarted.stream.first.timeout(timeout);
  }

  /// Joins [roomId] as a viewer (or re-joins as host).
  void join(String roomId) {
    currentRoomId = roomId;
    _send(<String, dynamic>{'type': 'join', 'room': roomId});
  }

  /// Leaves the current room and clears the host flag.
  void leave() {
    final String? roomId = currentRoomId;
    if (roomId != null) {
      _send(<String, dynamic>{'type': 'leave', 'room': roomId});
    }
    currentRoomId = null;
    _isHost = false;
  }

  /// Requests the current room list.
  void refreshList() => _send(<String, dynamic>{'type': 'list'});

  /// Sends a chat line to the current room.
  void sendChat(String text) {
    final String? roomId = currentRoomId;
    final String clean = text.trim();
    if (roomId == null || clean.isEmpty) return;
    _send(<String, dynamic>{'type': 'chat', 'room': roomId, 'text': clean});
  }

  /// Sends an audio message (base64 data URL) to the current room.
  void sendAudio(String dataUrl) {
    final String? roomId = currentRoomId;
    if (roomId == null || dataUrl.isEmpty) return;
    _send(<String, dynamic>{'type': 'audio', 'room': roomId, 'data': dataUrl});
  }

  /// Sends a gift (and its total) to the current room.
  void sendGift(Gift gift, int qty, int total) {
    final String? roomId = currentRoomId;
    if (roomId == null) return;
    _send(<String, dynamic>{
      'type': 'gift',
      'room': roomId,
      'emoji': gift.emoji,
      'name': gift.name,
      'qty': qty,
      'total': total,
      'side': 'left',
    });
  }

  /// Relays a WebRTC signal to a single peer.
  void sendSignal(String toPeerId, Map<String, dynamic> data) {
    if (toPeerId.isEmpty) return;
    _send(<String, dynamic>{'type': 'signal', 'to': toPeerId, 'data': data});
  }

  // ---------------------------------------------------------- Incoming loop

  void _onData(dynamic raw) {
    try {
      final String text = raw is String
          ? raw
          : raw is List<int>
              ? utf8.decode(raw)
              : raw.toString();
      final dynamic decoded = jsonDecode(text);
      if (decoded is! Map) return;
      _handle(Map<String, dynamic>.from(decoded));
    } catch (error) {
      _errors.add('Messaggio non valido: $error');
    }
  }

  void _handle(Map<String, dynamic> msg) {
    final String type = (msg['type'] ?? '').toString();
    switch (type) {
      case 'welcome':
        myId = msg['id']?.toString();
        _emitRooms(msg['rooms']);
        break;
      case 'ready':
        if (msg['id'] != null) myId = msg['id'].toString();
        break;
      case 'rooms':
        _emitRooms(msg['rooms']);
        break;
      case 'live_started':
        final LiveRoom room = _roomFromJson(_asMap(msg['room']));
        _isHost = true;
        currentRoomId = room.id;
        _liveStarted.add(room);
        // The host must also enter the room to receive peer_joined / viewers.
        _send(<String, dynamic>{'type': 'join', 'room': room.id});
        break;
      case 'joined':
        final LiveRoom room = _roomFromJson(_asMap(msg['room']));
        currentRoomId = room.id;
        _joined.add(
          JoinedEvent(room: room, host: LivePeer.fromJson(_asMap(msg['host']))),
        );
        break;
      case 'peer_joined':
        _peerJoined.add(LivePeer.fromJson(_asMap(msg['peer'])));
        break;
      case 'peer_left':
        _peerLeft.add((msg['peerId'] ?? '').toString());
        break;
      case 'viewers':
        _viewers.add(_asInt(msg['n'], 0));
        break;
      case 'chat':
        _chat.add(LiveChatEvent(
          from: (msg['from'] ?? 'Ospite').toString(),
          text: (msg['text'] ?? '').toString(),
          ts: msg['ts'] is num
              ? (msg['ts'] as num).toDouble()
              : DateTime.now().millisecondsSinceEpoch.toDouble(),
        ));
        break;
      case 'audio':
        _audio.add(LiveAudioEvent(
          from: (msg['from'] ?? 'Ospite').toString(),
          data: (msg['data'] ?? '').toString(),
        ));
        break;
      case 'gift':
        final Map<String, dynamic> pk = _asMap(msg['pk']);
        _gifts.add(LiveGiftEvent(
          from: (msg['from'] ?? 'Ospite').toString(),
          emoji: (msg['emoji'] ?? '🎁').toString(),
          name: (msg['name'] ?? 'Regalo').toString(),
          qty: _asInt(msg['qty'], 1),
          total: _asInt(msg['total'], 0),
          pkLeft: _asInt(pk['left'], 0),
          pkRight: _asInt(pk['right'], 0),
        ));
        break;
      case 'signal':
        final String from = (msg['from'] ?? '').toString();
        if (from.isNotEmpty) {
          _signals.add(
            LiveSignalEvent(from: from, data: _asMap(msg['data'])),
          );
        }
        break;
      case 'room_closed':
        final String roomId = (msg['room'] ?? '').toString();
        if (roomId == currentRoomId) currentRoomId = null;
        _roomClosed.add(roomId);
        break;
      case 'error':
        _errors.add((msg['msg'] ?? 'Errore dal server').toString());
        break;
      default:
        break;
    }
  }

  void _emitRooms(dynamic raw) {
    if (raw is! List) return;
    final List<LiveRoom> parsed = <LiveRoom>[];
    for (final dynamic item in raw) {
      if (item is Map) parsed.add(_roomFromJson(Map<String, dynamic>.from(item)));
    }
    _cachedRooms = parsed;
    _rooms.add(parsed);
  }

  // ---------------------------------------------------------------- Teardown

  Future<void> _close({required bool silent}) async {
    _connected = false;
    try {
      await _sub?.cancel();
    } catch (_) {}
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    myId = null;
    if (!silent) {
      currentRoomId = null;
      _isHost = false;
    }
  }

  /// Closes the socket and all broadcast streams.
  Future<void> dispose() async {
    await _close(silent: false);
    _cachedRooms = <LiveRoom>[];
    await _rooms.close();
    await _chat.close();
    await _audio.close();
    await _gifts.close();
    await _viewers.close();
    await _peerJoined.close();
    await _peerLeft.close();
    await _signals.close();
    await _roomClosed.close();
    await _joined.close();
    await _liveStarted.close();
    await _errors.close();
  }
}
