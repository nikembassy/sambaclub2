import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 1:1 video-match stub.
///
/// UI only: a pulsing avatar and an "Avvia ricerca" button that simulates a
/// ~2 second search and then shows "Match con <nome>!". No real video/network
/// call happens — real matching needs the backend.
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _names = <String>[
    'Luna',
    'MarcoBeat',
    'Sofia',
    'Dario',
    'Aisha',
    'Nina',
    'Yusuf',
    'Elena',
  ];

  late final AnimationController _pulse;
  final Random _random = Random();
  Timer? _searchTimer;
  bool _searching = false;
  String? _matched;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _startSearch() {
    if (_searching) return;
    setState(() {
      _searching = true;
      _matched = null;
    });
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _matched = _names[_random.nextInt(_names.length)];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sambaBlack,
      appBar: AppBar(title: const Text('Match 1:1')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            const Text(
              'Video match casuale',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.sambaText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Trova una persona con cui chattare in video',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.sambaMuted),
            ),
            const Spacer(),
            _avatar(),
            const SizedBox(height: 28),
            Text(
              _statusText(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _matched != null
                    ? AppColors.sambaGold
                    : AppColors.sambaText,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _searching ? null : _startSearch,
                icon: Icon(_searching ? Icons.hourglass_top : Icons.search),
                label: Text(_searching ? 'Ricerca in corso…' : 'Avvia ricerca'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Stub di UI: il matchmaking reale verrà collegato al backend.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.sambaMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText() {
    if (_searching) return 'Cerco un partner…';
    if (_matched != null) return 'Match con $_matched!';
    return 'Premi “Avvia ricerca” per iniziare';
  }

  Widget _avatar() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (BuildContext context, Widget? child) {
        final double t = _pulse.value;
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Transform.scale(
                scale: 1.0 + 0.35 * t,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.sambaGold.withOpacity(0.35 * (1 - t)),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 1.0 + 0.12 * t,
                child: Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
      child: Text(
        _matched == null ? '😀' : '💛',
        style: const TextStyle(fontSize: 52),
      ),
    );
  }
}
