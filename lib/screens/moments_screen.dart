import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Social feed ("Moments"): a list of mock posts with avatar, text, a gradient
/// image placeholder and a like/comment row.
class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  late final List<_Post> _posts = <_Post>[
    _Post(
      author: 'Luna',
      avatar: '🌙',
      time: '5 min',
      text: 'Nuova cover registrata stasera 🎙️ chi vuole ascoltarla in live?',
      emoji: '🎶',
      gradient: const <Color>[Color(0xFF3A2C6B), Color(0xFF0A0A0C)],
      likes: 214,
      comments: 18,
    ),
    _Post(
      author: 'MarcoBeat',
      avatar: '🎧',
      time: '22 min',
      text: 'Il nuovo set techno è online. Volume al massimo 🔥',
      emoji: '🎛️',
      gradient: const <Color>[Color(0xFF6B2C4A), Color(0xFF0A0A0C)],
      likes: 512,
      comments: 41,
    ),
    _Post(
      author: 'Party Oro',
      avatar: '🎉',
      time: '1 h',
      text: 'Party a 9 posti sold out in 3 minuti, grazie a tutti! 🥳',
      emoji: '🪩',
      gradient: const <Color>[Color(0xFFD4AF37), Color(0xFF0A0A0C)],
      likes: 903,
      comments: 77,
    ),
    _Post(
      author: 'Sofia',
      avatar: '💃',
      time: '3 h',
      text: 'Coreografia nuova in arrivo: indovinate la canzone 💫',
      emoji: '💃',
      gradient: const <Color>[Color(0xFF7A1F3D), Color(0xFF2A2A34)],
      likes: 341,
      comments: 26,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sambaBlack,
      appBar: AppBar(title: const Text('Moments')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length,
        itemBuilder: (BuildContext context, int index) {
          final _Post post = _posts[index];
          return _PostCard(
            post: post,
            onLike: () => setState(() => post.toggleLike()),
          );
        },
      ),
    );
  }
}

/// A single feed post (mutable like state).
class _Post {
  _Post({
    required this.author,
    required this.avatar,
    required this.time,
    required this.text,
    required this.emoji,
    required this.gradient,
    required this.likes,
    required this.comments,
  });

  final String author;
  final String avatar;
  final String time;
  final String text;
  final String emoji;
  final List<Color> gradient;
  int likes;
  final int comments;
  bool liked = false;

  void toggleLike() {
    liked = !liked;
    likes += liked ? 1 : -1;
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onLike});

  final _Post post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.sambaSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sambaLines),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.sambaSurface2,
                  child: Text(post.avatar, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        post.author,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.sambaText,
                        ),
                      ),
                      Text(
                        post.time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.sambaMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: AppColors.sambaMuted),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Text(
              post.text,
              style: const TextStyle(fontSize: 13, color: AppColors.sambaText),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              height: 160,
              width: double.infinity,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: post.gradient,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(post.emoji, style: const TextStyle(fontSize: 54)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 6),
            child: Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: onLike,
                  icon: Text(
                    post.liked ? '❤️' : '🤍',
                    style: const TextStyle(fontSize: 16),
                  ),
                  label: Text(
                    '${post.likes}',
                    style: TextStyle(
                      color: post.liked
                          ? AppColors.sambaLive
                          : AppColors.sambaMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.mode_comment_outlined,
                  size: 16,
                  color: AppColors.sambaMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  '${post.comments}',
                  style: const TextStyle(color: AppColors.sambaMuted),
                ),
                const Spacer(),
                const Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: AppColors.sambaMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
