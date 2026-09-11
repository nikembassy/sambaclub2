import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';

/// "Avvia live" setup screen: a title field, category chips and a start button.
///
/// Stub: starting a real stream needs the backend, so the button only shows a
/// SnackBar explaining that.
class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  final TextEditingController _title = TextEditingController();
  String _category = 'Musica';

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _start() {
    final String title = _title.text.trim();
    final String message = title.isEmpty
        ? 'Aggiungi un titolo alla tua live'
        : 'Per andare davvero in diretta serve il backend: questa è solo la '
            'schermata di configurazione.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> categories =
        kCategories.where((String c) => c != 'Tutti').toList();
    return Scaffold(
      backgroundColor: AppColors.sambaBlack,
      appBar: AppBar(title: const Text('Avvia live')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Container(
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('📡', style: TextStyle(fontSize: 46)),
                SizedBox(height: 6),
                Text(
                  'Anteprima live',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.sambaBlack,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Titolo',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.sambaText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            maxLength: 60,
            decoration: const InputDecoration(
              hintText: 'Es. Serata cover a richiesta 🎤',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Categoria',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.sambaText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((String category) {
              return ChoiceChip(
                label: Text(category),
                selected: category == _category,
                onSelected: (bool selected) {
                  if (selected) setState(() => _category = category);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.videocam),
            label: const Text('Avvia live'),
          ),
          const SizedBox(height: 12),
          const Text(
            'La trasmissione reale verrà collegata al backend (RTMP/WebRTC).',
            style: TextStyle(fontSize: 11, color: AppColors.sambaMuted),
          ),
        ],
      ),
    );
  }
}
