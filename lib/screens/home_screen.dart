import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/room.dart';
import '../services/live_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/room_card.dart';
import 'live_room_screen.dart';
import 'match_screen.dart';
import 'messages_screen.dart';
import 'moments_screen.dart';
import 'party_room_screen.dart';
import 'profile_screen.dart';
import 'rank_screen.dart';
import 'recharge_screen.dart';

/// Main shell: Home (with Discovery / Party / Seguiti / Nuovi tabs),
/// Party, a centre "+" Go Live action, Messaggi and Profilo.
///
/// The Home tab now also hosts a **LIVE ORA** carousel fed by the signaling
/// server ([LiveService.rooms]) with a real "Vai in Live" button.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.liveService});

  final LiveService liveService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _segments = <String>[
    'Discovery',
    'Party',
    'Seguiti',
    'Nuovi',
  ];

  int _tab = 0;
  int _segment = 0;
  String _category = 'Tutti';

  final List<StreamSubscription<dynamic>> _subs = <StreamSubscription<dynamic>>[];
  List<LiveRoom> _serverRooms = <LiveRoom>[];
  bool _goingLive = false;

  @override
  void initState() {
    super.initState();
    _subs.add(widget.liveService.rooms.listen((List<LiveRoom> rooms) {
      if (!mounted) return;
      setState(() => _serverRooms = rooms);
    }));
    _subs.add(widget.liveService.liveStarted.listen((LiveRoom room) {
      if (!mounted) return;
      setState(() => _goingLive = false);
      _openRoom(room);
    }));
    _subs.add(widget.liveService.errors.listen((String message) {
      if (!mounted) return;
      setState(() => _goingLive = false);
    }));
    // Ask the server for the current room list.
    widget.liveService.refreshList();
  }

  @override
  void dispose() {
    for (final StreamSubscription<dynamic> sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    super.dispose();
  }

  void _openRoom(LiveRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => room.isParty
            ? PartyRoomScreen(room: room)
            : LiveRoomScreen(room: room, liveService: widget.liveService),
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _onNavTap(int index) {
    if (index == 2) {
      _startGoLiveFlow();
      return;
    }
    setState(() => _tab = index);
  }

  // ------------------------------------------------------------ Go live

  Future<void> _startGoLiveFlow() async {
    if (_goingLive) return;
    final TextEditingController title = TextEditingController();
    String category = kCategories.firstWhere(
      (String c) => c != 'Tutti',
      orElse: () => 'Talk',
    );

    final bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sambaSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      '🔴 Vai in Live',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sambaText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'La stanza viene creata sul server e resta visibile a tutti.',
                      style: TextStyle(fontSize: 12, color: AppColors.sambaMuted),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: title,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        hintText: 'Titolo della live',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Categoria',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sambaText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kCategories
                          .where((String c) => c != 'Tutti')
                          .map((String c) {
                        return ChoiceChip(
                          label: Text(c),
                          selected: c == category,
                          onSelected: (bool selected) {
                            if (selected) setSheetState(() => category = c);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(true),
                      icon: const Icon(Icons.videocam),
                      label: const Text('Avvia live'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    final String cleanTitle = title.text.trim();
    title.dispose();
    if (confirm != true) return;
    if (cleanTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aggiungi un titolo alla tua live')),
      );
      return;
    }
    setState(() => _goingLive = true);
    widget.liveService.goLive(cleanTitle, category);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creazione della live…')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      _buildHomeTab(),
      _buildPartyTab(),
      const SizedBox.shrink(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: tabs),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: _onNavTap,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.celebration_outlined),
            activeIcon: Icon(Icons.celebration),
            label: 'Party',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 40, color: AppColors.sambaGold),
            label: 'Vai live',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messaggi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Home tab

  Widget _buildHomeTab() {
    final AppState state = context.watch<AppState>();
    final List<LiveRoom> rooms = _filteredRooms(state);

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(child: _header(state)),
        SliverToBoxAdapter(child: _liveOraSection()),
        SliverToBoxAdapter(child: _segmentedTabs()),
        SliverToBoxAdapter(child: _quickActions()),
        if (_segment == 0) SliverToBoxAdapter(child: _categoryChips()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          sliver: rooms.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _emptyLabel(),
                      style: const TextStyle(color: AppColors.sambaMuted),
                    ),
                  ),
                )
              : SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final LiveRoom room = rooms[index];
                      return RoomCard(
                        room: room,
                        onTap: () => _openRoom(room),
                      );
                    },
                    childCount: rooms.length,
                  ),
                ),
        ),
      ],
    );
  }

  // -------------------------------------------------------- LIVE ORA (server)

  Widget _liveOraSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                '🔴 LIVE ORA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.sambaText,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _goingLive ? null : _startGoLiveFlow,
                icon: const Icon(Icons.videocam, size: 16),
                label: Text(_goingLive ? 'Avvio…' : 'Vai in Live'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_serverRooms.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.sambaSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sambaLines),
              ),
              child: const Text(
                'Nessuna live sul server: premi "Vai in Live" per aprirne una.',
                style: TextStyle(fontSize: 12, color: AppColors.sambaMuted),
              ),
            )
          else
            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _serverRooms.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 10),
                itemBuilder: (BuildContext context, int index) {
                  return _serverRoomCard(_serverRooms[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _serverRoomCard(LiveRoom room) {
    return GestureDetector(
      onTap: () => _openRoom(room),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          gradient: room.coverGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.sambaGold.withOpacity(0.35)),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sambaLive,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '● LIVE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '👁 ${room.viewersLabel}',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${room.hostEmoji} ${room.hostName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.sambaText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    room.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.85),
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

  List<LiveRoom> _filteredRooms(AppState state) {
    switch (_segment) {
      case 1:
        return state.partyRooms;
      case 2:
        return state.rooms
            .where((LiveRoom room) => state.isFollowing(room.id))
            .toList();
      case 3:
        return state.rooms.reversed.take(6).toList();
      default:
        if (_category == 'Tutti') return state.rooms;
        return state.rooms
            .where((LiveRoom room) => room.category == _category)
            .toList();
    }
  }

  String _emptyLabel() {
    switch (_segment) {
      case 1:
        return 'Nessuna party room disponibile.';
      case 2:
        return 'Non segui ancora nessuna stanza: tocca ❤️ in una live.';
      case 3:
        return 'Nessuna novità per ora.';
      default:
        return 'Nessuna stanza in questa categoria.';
    }
  }

  Widget _header(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: <Widget>[
          const Text(
            'Sambaclub',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.sambaText,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sambaSurface2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.sambaGold.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Text('🪙', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '${state.coins}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.sambaGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentedTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < _segments.length; i++)
            Expanded(child: _segmentButton(i)),
        ],
      ),
    );
  }

  Widget _segmentButton(int index) {
    final bool selected = index == _segment;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: () => setState(() => _segment = index),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.goldGradient : null,
            color: selected ? null : AppColors.sambaSurface2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.sambaLines,
            ),
          ),
          child: Text(
            _segments[index],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.sambaBlack : AppColors.sambaMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _quickAction(
              emoji: '🎥',
              label: 'Match',
              onTap: () => _push(const MatchScreen()),
            ),
          ),
          Expanded(
            child: _quickAction(
              emoji: '✨',
              label: 'Moments',
              onTap: () => _push(const MomentsScreen()),
            ),
          ),
          Expanded(
            child: _quickAction(
              emoji: '🏆',
              label: 'Classifica',
              onTap: () => _push(const RankScreen()),
            ),
          ),
          Expanded(
            child: _quickAction(
              emoji: '🪙',
              label: 'Ricarica',
              onTap: () => _push(const RechargeScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.sambaSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sambaLines),
          ),
          child: Column(
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sambaText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: kCategories.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final String category = kCategories[index];
          return ChoiceChip(
            label: Text(category),
            selected: category == _category,
            onSelected: (bool selected) {
              setState(() => _category = category);
            },
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------- Party tab

  Widget _buildPartyTab() {
    final AppState state = context.watch<AppState>();
    final List<LiveRoom> rooms = state.partyRooms;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Text(
          '🎉 Party a 9 posti',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.sambaText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sali sul palco e chiacchiera con la stanza',
          style: TextStyle(color: AppColors.sambaMuted),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
          children: rooms
              .map(
                (LiveRoom room) => RoomCard(
                  room: room,
                  onTap: () => _openRoom(room),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
