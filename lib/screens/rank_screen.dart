import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Leaderboards: two tabs ("Top Host" / "Top Fans"), top-5 each with medals,
/// avatar and coin totals.
class RankScreen extends StatelessWidget {
  const RankScreen({super.key});

  static const List<_RankEntry> _topHosts = <_RankEntry>[
    _RankEntry(name: 'Luna', avatar: '🌙', coins: 128900),
    _RankEntry(name: 'MarcoBeat', avatar: '🎧', coins: 98250),
    _RankEntry(name: 'Party Gold', avatar: '🥳', coins: 87500),
    _RankEntry(name: 'Sofia', avatar: '💃', coins: 64200),
    _RankEntry(name: 'LeoGames', avatar: '🎮', coins: 52800),
  ];

  static const List<_RankEntry> _topFans = <_RankEntry>[
    _RankEntry(name: 'Marta', avatar: '🦊', coins: 154000),
    _RankEntry(name: 'Leo', avatar: '🐯', coins: 132400),
    _RankEntry(name: 'Sofia', avatar: '🐼', coins: 98500),
    _RankEntry(name: 'Dario', avatar: '🐸', coins: 76200),
    _RankEntry(name: 'Giulia', avatar: '🦄', coins: 61100),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.sambaBlack,
        appBar: AppBar(
          title: const Text('Classifica'),
          bottom: const TabBar(
            labelColor: AppColors.sambaGold,
            unselectedLabelColor: AppColors.sambaMuted,
            indicatorColor: AppColors.sambaGold,
            tabs: <Widget>[
              Tab(text: 'Top Host'),
              Tab(text: 'Top Fans'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            _RankList(entries: _topHosts),
            _RankList(entries: _topFans),
          ],
        ),
      ),
    );
  }
}

class _RankEntry {
  const _RankEntry({
    required this.name,
    required this.avatar,
    required this.coins,
  });

  final String name;
  final String avatar;
  final int coins;
}

class _RankList extends StatelessWidget {
  const _RankList({required this.entries});

  final List<_RankEntry> entries;

  static const List<String> _medals = <String>['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (BuildContext context, int index) {
        final _RankEntry entry = entries[index];
        final bool podium = index < 3;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.sambaSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: podium
                  ? AppColors.sambaGold.withOpacity(0.5)
                  : AppColors.sambaLines,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                alignment: Alignment.center,
                child: Text(
                  podium ? _medals[index] : '${index + 1}',
                  style: TextStyle(
                    fontSize: podium ? 22 : 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sambaMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.sambaSurface2,
                child: Text(entry.avatar, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.sambaText,
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  const Text('🪙', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.coins}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.sambaGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
