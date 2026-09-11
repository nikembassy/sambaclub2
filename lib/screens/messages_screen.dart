import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class _Conversation {
  const _Conversation({
    required this.name,
    required this.emoji,
    required this.last,
    required this.time,
    this.unread = 0,
  });

  final String name;
  final String emoji;
  final String last;
  final String time;
  final int unread;
}

const List<_Conversation> _conversations = <_Conversation>[
  _Conversation(
    name: 'Luna',
    emoji: '🌙',
    last: 'Grazie per il regalo! ❤️',
    time: '19:42',
    unread: 2,
  ),
  _Conversation(
    name: 'MarcoBeat',
    emoji: '🎧',
    last: 'Domani set alle 21, ci sei?',
    time: '18:15',
    unread: 1,
  ),
  _Conversation(
    name: 'Sofia',
    emoji: '💃',
    last: 'Ti mando la coreografia 🎶',
    time: '17:03',
  ),
  _Conversation(
    name: 'LeoGames',
    emoji: '🎮',
    last: 'GG! Rigiocchiamo stasera',
    time: 'Ieri',
  ),
  _Conversation(
    name: 'Chiara',
    emoji: '🕯️',
    last: 'Buonanotte 🌙',
    time: 'Ieri',
  ),
  _Conversation(
    name: 'Sambaclub',
    emoji: '⚙️',
    last: 'Benvenuto/a nella community!',
    time: 'Lun',
  ),
];

/// Mock conversation list (no backend).
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sambaBlack,
      appBar: AppBar(title: const Text('Messaggi')),
      body: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 1, color: AppColors.sambaLines),
        itemBuilder: (BuildContext context, int index) {
          final _Conversation conversation = _conversations[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.sambaSurface2,
              child: Text(conversation.emoji),
            ),
            title: Text(
              conversation.name,
              style: const TextStyle(
                color: AppColors.sambaText,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              conversation.last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.sambaMuted),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  conversation.time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.sambaMuted,
                  ),
                ),
                const SizedBox(height: 4),
                if (conversation.unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sambaGold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${conversation.unread}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sambaBlack,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chat con ${conversation.name} (demo)'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
