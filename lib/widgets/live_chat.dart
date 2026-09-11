import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/media_service.dart';
import '../theme/app_theme.dart';

/// Scrollable list of [ChatMessage]s (newest at the bottom).
class LiveChat extends StatelessWidget {
  const LiveChat({super.key, required this.messages});

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'La chat è ancora vuota…',
          style: TextStyle(color: AppColors.sambaMuted),
        ),
      );
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int index) {
        final ChatMessage message = messages[messages.length - 1 - index];
        return _ChatBubble(message: message);
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool gift = message.isGift;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: gift ? AppColors.sambaSurface2 : AppColors.sambaSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: gift
                ? AppColors.sambaGold.withOpacity(0.6)
                : AppColors.sambaLines,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (gift && message.giftEmoji != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  message.giftEmoji!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          message.user,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: gift
                                ? AppColors.sambaGold
                                : AppColors.sambaGoldLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        message.timeLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.sambaMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (message.isAudio)
                    _AudioBubbleContent(message: message)
                  else
                    Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.sambaText,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Play button + duration label shown for [ChatMessageType.audio] messages.
class _AudioBubbleContent extends StatelessWidget {
  const _AudioBubbleContent({required this.message});

  final ChatMessage message;

  void _play() {
    final String? path = message.audioSource;
    if (path == null) return;
    // Fire-and-forget: MediaService guards its own errors and never throws.
    MediaService.playAudio(path);
  }

  @override
  Widget build(BuildContext context) {
    final String? path = message.audioSource;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: path == null ? null : _play,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sambaGold.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.sambaGold.withOpacity(0.6)),
            ),
            child: const Text('▶️', style: TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          message.durationLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.sambaGoldLight,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.graphic_eq, size: 16, color: AppColors.sambaMuted),
      ],
    );
  }
}
