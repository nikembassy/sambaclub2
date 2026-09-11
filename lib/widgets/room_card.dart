import 'package:flutter/material.dart';

import '../models/room.dart';
import '../theme/app_theme.dart';

/// Grid tile representing a single [LiveRoom].
///
/// The "cover" is a CSS-like gradient placeholder ([LiveRoom.coverGradient])
/// with an emoji — no network image is ever loaded.
class RoomCard extends StatelessWidget {
  const RoomCard({super.key, required this.room, this.onTap});

  final LiveRoom room;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.sambaSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sambaLines),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(gradient: room.coverGradient),
                      child: Center(
                        child: Text(
                          room.hostEmoji,
                          style: const TextStyle(fontSize: 46),
                        ),
                      ),
                    ),
                    const Positioned(top: 8, left: 8, child: _LiveBadge()),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _Pill(text: '👁 ${room.viewersLabel}'),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: _Pill(text: room.category, gold: true),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      room.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.sambaText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Text(
                          room.flagEmoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            room.hostName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.sambaMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.gold = false});

  final String text;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final Color fg = gold ? AppColors.sambaBlack : AppColors.sambaText;
    final Color bg =
        gold ? AppColors.sambaGold : AppColors.sambaBlack.withOpacity(0.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.sambaLive,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}
