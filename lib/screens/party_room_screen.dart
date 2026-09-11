import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/gift.dart';
import '../models/room.dart';
import '../services/media_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gift_tray.dart';
import '../widgets/live_chat.dart';

/// A "party" room: a 3x3 grid of seats (1 host + members + free seats) on top
/// of a live chat, an input bar and the gift button.
///
/// Reads a party [LiveRoom] (`room.type == RoomType.party`).
class PartyRoomScreen extends StatefulWidget {
  const PartyRoomScreen({super.key, required this.room});

  final LiveRoom room;

  @override
  State<PartyRoomScreen> createState() => _PartyRoomScreenState();
}

class _PartyRoomScreenState extends State<PartyRoomScreen> {
  final TextEditingController _input = TextEditingController();
  late final List<_Seat> _seats;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _seats = <_Seat>[
      _Seat(
        emoji: widget.room.hostEmoji,
        label: widget.room.hostName,
        isHost: true,
      ),
      const _Seat(emoji: '🦊', label: 'Marta'),
      const _Seat(emoji: '🐯', label: 'Leo'),
      const _Seat(emoji: '🐼', label: 'Sofia'),
      const _Seat(emoji: '🐸', label: 'Dario'),
      const _Seat(emoji: '🦄', label: 'Giulia'),
      const _Seat(emoji: '➕', label: 'Libero', isFree: true),
      const _Seat(emoji: '➕', label: 'Libero', isFree: true),
      const _Seat(emoji: '➕', label: 'Libero', isFree: true),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final AppState state = context.read<AppState>();
      if (state.chatLog.length < 3) {
        state.seedChat(kMockChatLines);
      }
      state.seedContributors(widget.room.id);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _tapSeat(_Seat seat) {
    final String message;
    if (seat.isFree) {
      message = 'Posto libero 🎙️ — tocca per salire sul palco!';
    } else if (seat.isHost) {
      message = '👑 ${seat.label} è l\'host di questa stanza';
    } else {
      message = '🎙️ ${seat.label} è sul palco';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _send(AppState state) {
    state.sendChat(_input.text);
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
      const SnackBar(content: Text('🎵 Messaggio audio inviato')),
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
      const SnackBar(content: Text('🎤 Messaggio vocale inviato')),
    );
  }

  Future<void> _openGiftTray(AppState state) async {
    final GiftOrder? order = await GiftTray.show(context);
    if (!mounted || order == null) return;
    final bool sent =
        state.sendGiftBundle(order.gift, order.qty, roomId: widget.room.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? '${order.gift.emoji} ${order.gift.name} x${order.qty} inviato!'
              : 'Monete insufficienti — riscatta monete gratis dal profilo',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.sambaBlack,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _seats.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final _Seat seat = _seats[index];
                    return _SeatTile(
                      seat: seat,
                      gradient: widget.room.coverGradient,
                      onTap: () => _tapSeat(seat),
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.sambaLines),
            Expanded(child: LiveChat(messages: state.chatLog)),
            _inputBar(state),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.sambaText,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.sambaSurface2,
            child: Text(
              widget.room.hostEmoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.room.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.sambaText,
                  ),
                ),
                Text(
                  '👥 ${widget.room.viewersLabel} · Party a 9 posti',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.sambaMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.sambaGold,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'PARTY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.sambaBlack,
              ),
            ),
          ),
        ],
      ),
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
                hintText: 'Scrivi al party…',
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

/// One of the 9 party seats.
class _Seat {
  const _Seat({
    required this.emoji,
    required this.label,
    this.isHost = false,
    this.isFree = false,
  });

  final String emoji;
  final String label;
  final bool isHost;
  final bool isFree;
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.seat,
    required this.gradient,
    required this.onTap,
  });

  final _Seat seat;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.sambaSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seat.isHost
                ? AppColors.sambaGold
                : seat.isFree
                    ? AppColors.sambaLines
                    : AppColors.sambaGold.withOpacity(0.35),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: seat.isFree ? null : gradient,
                color: seat.isFree ? AppColors.sambaSurface2 : null,
                shape: BoxShape.circle,
              ),
              child: Text(seat.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 6),
            Text(
              seat.isHost ? '👑 ${seat.label}' : seat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: seat.isHost ? FontWeight.w700 : FontWeight.w500,
                color: seat.isFree ? AppColors.sambaMuted : AppColors.sambaText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
