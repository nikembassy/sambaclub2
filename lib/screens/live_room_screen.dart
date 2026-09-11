import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../models/gift.dart';
import '../models/room.dart';
import '../services/live_service.dart';
import '../services/media_service.dart';
import '../services/webrtc_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gift_tray.dart';
import '../widgets/live_chat.dart';

/// A REAL live room.
///
/// The host publishes camera + mic through [WebRtcService] (one
/// [RTCPeerConnection] per viewer) and the viewers answer the offers they
/// receive. Chat, gifts, PK, the viewer counter and room lifecycle all travel
/// through the shared [LiveService] websocket.
///
/// The black & gold look is unchanged: the old gradient placeholder is now the
/// fallback shown until the first video frame arrives.
class LiveRoomScreen extends StatefulWidget {
  const LiveRoomScreen({
    super.key,
    required this.room,
    required this.liveService,
  });

  final LiveRoom room;
  final LiveService liveService;

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _input = TextEditingController();
  final List<StreamSubscription<dynamic>> _subs = <StreamSubscription<dynamic>>[];
  final List<ChatMessage> _messages = <ChatMessage>[];

  late final AnimationController _burst;
  late final WebRtcService _rtc;

  String? _burstEmoji;
  String? _comboText;
  bool _showPk = false;
  bool _isRecording = false;
  bool _remoteReady = false;
  int _viewers = 0;
  int _pkLeft = 0;
  int _pkRight = 0;

  bool get _isHost => widget.liveService.isHost;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _viewers = widget.room.viewers;
    _pkLeft = context.read<AppState>().pkLeftScore(widget.room.id);
    _pkRight = context.read<AppState>().pkRightScore(widget.room.id);

    _rtc = WebRtcService(
      onSignal: (String to, Map<String, dynamic> data) =>
          widget.liveService.sendSignal(to, data),
      onError: _onRtcError,
      onRemoteStream: (_) {
        if (mounted) setState(() => _remoteReady = true);
      },
    );
    _rtc.initialize();
    _subscribe();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().seedContributors(widget.room.id);
      if (_isHost) {
        _addSystem('🔴 Sei in diretta: in attesa di spettatori…');
        // Rebuild once the local capture is attached to the renderer.
        _rtc.startLocalMedia().then((_) {
          if (mounted) setState(() {});
        });
      } else if (widget.liveService.knowsRoom(widget.room.id)) {
        _addSystem('⏳ Connessione alla live di ${widget.room.hostName}…');
        widget.liveService.join(widget.room.id);
      } else {
        _addSystem('ℹ️ Stanza demo: nessuno streaming reale qui.');
      }
    });
  }

  void _subscribe() {
    final LiveService live = widget.liveService;

    _subs.add(live.chat.listen((LiveChatEvent e) {
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage(
            user: e.from,
            text: e.text,
            time: _timeFrom(e.ts),
          )));
    }));

    _subs.add(live.audio.listen((LiveAudioEvent e) {
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage(
            user: e.from,
            text: '🎵 Messaggio audio',
          )));
    }));

    _subs.add(live.gifts.listen((LiveGiftEvent e) {
      if (!mounted) return;
      setState(() {
        _pkLeft = e.pkLeft;
        _pkRight = e.pkRight;
        _showPk = true;
        _messages.add(ChatMessage(
          user: e.from,
          text: e.qty > 1
              ? 'ha inviato ${e.name} x${e.qty}'
              : 'ha inviato ${e.name}',
          isGift: true,
          giftEmoji: e.emoji,
        ));
      });
      _playBurst(e.emoji);
      if (e.qty > 1) _showCombo(e.qty);
    }));

    _subs.add(live.viewers.listen((int n) {
      if (mounted) setState(() => _viewers = n);
    }));

    _subs.add(live.peerJoined.listen((LivePeer peer) {
      if (!mounted) return;
      _addSystem('👋 ${peer.emoji} ${peer.name} è entrato');
      if (_isHost) _rtc.offerTo(peer.id);
    }));

    _subs.add(live.peerLeft.listen((String peerId) {
      _rtc.closePeer(peerId);
      if (mounted) _addSystem('👋 Un ospite è uscito');
    }));

    _subs.add(live.signals.listen((LiveSignalEvent e) {
      _rtc.handleSignal(e.from, e.data);
    }));

    _subs.add(live.roomClosed.listen((String roomId) {
      if (!mounted) return;
      _addSystem('La live è terminata');
      if (!_isHost) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La live è terminata')),
        );
        Navigator.of(context).maybePop();
      }
    }));

    _subs.add(live.errors.listen((String message) {
      if (!mounted) return;
      _addSystem('⚠️ $message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }));
  }

  @override
  void dispose() {
    for (final StreamSubscription<dynamic> sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    widget.liveService.leave();
    _rtc.dispose();
    _input.dispose();
    _burst.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------- Utils

  DateTime _timeFrom(double ts) {
    if (ts <= 0) return DateTime.now();
    final int ms = ts > 1e12 ? ts.toInt() : (ts * 1000).toInt();
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void _addSystem(String text) {
    if (!mounted) return;
    setState(() => _messages.add(ChatMessage(user: 'Sistema', text: text)));
  }

  void _onRtcError(String message) {
    if (!mounted) return;
    _addSystem('⚠️ $message');
  }

  void _playBurst(String emoji) {
    if (!mounted) return;
    setState(() => _burstEmoji = emoji);
    _burst.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _burstEmoji = null);
    });
  }

  void _showCombo(int qty) {
    if (!mounted) return;
    setState(() => _comboText = 'x$qty COMBO!');
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _comboText == 'x$qty COMBO!') {
        setState(() => _comboText = null);
      }
    });
  }

  // ------------------------------------------------------------- Actions

  void _send(AppState state) {
    final String text = _input.text.trim();
    if (text.isEmpty) return;
    widget.liveService.sendChat(text);
    setState(() => _messages.add(ChatMessage(
          user: state.currentUser?.nickname ?? 'Tu',
          text: text,
        )));
    _input.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickAudio(AppState state) async {
    final String? path = await MediaService.pickAudioFile();
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun file audio selezionato')),
      );
      return;
    }
    state.addAudioMessage(path: path);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎵 Messaggio audio aggiunto alla chat')),
    );
  }

  Future<void> _toggleRecording(AppState state) async {
    if (!_isRecording) {
      final String? path = await MediaService.startVoiceRecording();
      if (!mounted) return;
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microfono non disponibile — controlla i permessi'),
          ),
        );
        return;
      }
      setState(() => _isRecording = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎤 Registrazione… tocca di nuovo per inviare'),
        ),
      );
      return;
    }
    final String? path = await MediaService.stopVoiceRecording();
    if (!mounted) return;
    setState(() => _isRecording = false);
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrazione annullata')),
      );
      return;
    }
    state.addAudioMessage(path: path);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎤 Messaggio vocale aggiunto alla chat')),
    );
  }

  Future<void> _openGiftTray(AppState state) async {
    final GiftOrder? order = await GiftTray.show(context);
    if (!mounted || order == null) return;

    final bool sent =
        state.sendGiftBundle(order.gift, order.qty, roomId: widget.room.id);
    if (!sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Monete insufficienti — riscatta monete gratis dal profilo'),
        ),
      );
      return;
    }
    // Broadcast the gift to everyone in the room.
    widget.liveService.sendGift(order.gift, order.qty, order.total);
    _playBurst(order.gift.emoji);
    if (order.qty > 1) _showCombo(order.qty);
  }

  void _openTreasureBox(AppState state) {
    final int reward = state.openTreasureBox(widget.room.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🎁 Hai trovato $reward monete nel forziere!')),
    );
  }

  Future<void> _leave() async {
    widget.liveService.leave();
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  // --------------------------------------------------------------- Build

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.sambaBlack,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _header(state),
            _contributors(state),
            _stage(),
            if (_showPk) _pkBattle(),
            const Divider(height: 1, color: AppColors.sambaLines),
            Expanded(child: LiveChat(messages: _messages)),
            _inputBar(state),
          ],
        ),
      ),
    );
  }

  Widget _header(AppState state) {
    final bool following = state.isFollowing(widget.room.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.sambaText,
            onPressed: _leave,
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.sambaSurface2,
            child: Text(
              widget.room.hostEmoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        widget.room.hostName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.sambaText,
                        ),
                      ),
                    ),
                    if (_isHost) const SizedBox(width: 6),
                    if (_isHost) _hostBadge(),
                  ],
                ),
                Text(
                  widget.room.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.sambaMuted,
                  ),
                ),
              ],
            ),
          ),
          _coinPill(state.coins),
          IconButton(
            icon: const Icon(Icons.bolt),
            color: _showPk ? AppColors.sambaGold : AppColors.sambaMuted,
            onPressed: () => setState(() => _showPk = !_showPk),
          ),
          IconButton(
            icon: Icon(following ? Icons.favorite : Icons.favorite_border),
            color: following ? AppColors.sambaLive : AppColors.sambaMuted,
            onPressed: () => state.toggleFollow(widget.room.id),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: AppColors.sambaText,
            tooltip: 'Esci',
            onPressed: _leave,
          ),
        ],
      ),
    );
  }

  Widget _hostBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'HOST',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.sambaBlack,
        ),
      ),
    );
  }

  Widget _contributors(AppState state) {
    final List<RoomContributor> top =
        state.topContributors(widget.room.id, limit: 3);
    if (top.isEmpty) return const SizedBox.shrink();
    const List<String> medals = <String>['👑', '🥈', '🥉'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: <Widget>[
          const Text(
            'CONTRIBUTORS',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: AppColors.sambaMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < top.length; i++)
                    _contributorChip(medals[i], top[i]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contributorChip(String medal, RoomContributor contributor) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sambaSurface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sambaLines),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(medal, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(contributor.avatarEmoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            contributor.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.sambaText,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '🪙 ${contributor.coins}',
            style: const TextStyle(fontSize: 10, color: AppColors.sambaGold),
          ),
        ],
      ),
    );
  }

  Widget _coinPill(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sambaSurface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sambaGold.withOpacity(0.5)),
      ),
      child: Row(
        children: <Widget>[
          const Text('🪙', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.sambaGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _videoSurface(),
          const Positioned(top: 10, left: 10, child: _LiveBadge()),
          Positioned(top: 10, right: 10, child: _viewersBadge()),
          if (_comboText != null)
            Positioned(
              top: 46,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _comboText!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.sambaBlack,
                    ),
                  ),
                ),
              ),
            ),
          if (_burstEmoji != null) _burstOverlay(_burstEmoji!),
        ],
      ),
    );
  }

  Widget _videoSurface() {
    if (_isHost && _rtc.hasLocalMedia) {
      return RTCVideoView(
        _rtc.localRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        mirror: true,
      );
    }
    if (!_isHost && _remoteReady) {
      return RTCVideoView(
        _rtc.remoteRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        mirror: false,
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: widget.room.coverGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              widget.room.hostEmoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 8),
            Text(
              _isHost ? 'AVVIO CAMERA…' : 'CONNESSIONE…',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewersBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sambaGold.withOpacity(0.5)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.visibility, size: 13, color: AppColors.sambaGold),
          const SizedBox(width: 4),
          Text(
            _viewersLabel(_viewers),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.sambaText,
            ),
          ),
        ],
      ),
    );
  }

  String _viewersLabel(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _pkBattle() {
    final int left = _pkLeft <= 0 ? 1 : _pkLeft;
    final int right = _pkRight <= 0 ? 1 : _pkRight;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sambaSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sambaGold.withOpacity(0.4)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('⚔️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text(
                'PK BATTLE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.sambaText,
                ),
              ),
              const Spacer(),
              Text(
                '$_pkLeft',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.sambaGold,
                ),
              ),
              const Text(
                '  vs  ',
                style: TextStyle(fontSize: 11, color: AppColors.sambaMuted),
              ),
              Text(
                '$_pkRight',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.sambaLive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                flex: left,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: right,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.sambaLive,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: <Widget>[
              Text(
                'Team Oro',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sambaGold,
                ),
              ),
              Spacer(),
              Text(
                'Team Rival',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sambaLive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _burstOverlay(String emoji) {
    return AnimatedBuilder(
      animation: _burst,
      builder: (BuildContext context, Widget? child) {
        final double t = _burst.value;
        return IgnorePointer(
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.6 + 1.8 * t,
              child: Center(child: child),
            ),
          ),
        );
      },
      child: Text(emoji, style: const TextStyle(fontSize: 72)),
    );
  }

  Widget _inputBar(AppState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      color: AppColors.sambaSurface,
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              onSubmitted: (String value) => _send(state),
              decoration: const InputDecoration(
                hintText: 'Scrivi un messaggio…',
                prefixIcon: Icon(Icons.chat_bubble_outline, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _emojiAction(
            emoji: '📎',
            color: AppColors.sambaGoldLight,
            onTap: () => _pickAudio(state),
          ),
          const SizedBox(width: 8),
          _emojiAction(
            emoji: '🎤',
            color: _isRecording ? AppColors.sambaLive : AppColors.sambaGold,
            onTap: () => _toggleRecording(state),
          ),
          const SizedBox(width: 8),
          _roundAction(
            icon: Icons.send,
            color: AppColors.sambaGold,
            onTap: () => _send(state),
          ),
          const SizedBox(width: 8),
          _roundAction(
            icon: Icons.card_giftcard,
            color: AppColors.sambaLive,
            onTap: () => _openGiftTray(state),
          ),
          const SizedBox(width: 8),
          _roundAction(
            icon: Icons.redeem,
            color: AppColors.sambaGoldLight,
            onTap: () => _openTreasureBox(state),
          ),
        ],
      ),
    );
  }

  Widget _roundAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.sambaSurface2,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }

  Widget _emojiAction({
    required String emoji,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.sambaSurface2,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

/// Small "● LIVE" chip reused over the video surface.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sambaLive,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '● LIVE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
