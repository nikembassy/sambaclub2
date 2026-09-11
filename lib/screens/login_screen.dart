import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/live_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// Entry screen: pick a nickname, point the app at the signaling server and
/// enter. The [LiveService] websocket is opened **before** navigating to the
/// home screen so a bad URL surfaces a clear error instead of an empty feed.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nickname = TextEditingController();
  final TextEditingController _server =
      TextEditingController(text: LiveService.defaultServerUrl);

  bool _connecting = false;
  String? _error;

  @override
  void dispose() {
    _nickname.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _enter(String nickname) async {
    if (_connecting) return;
    final String url = _server.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Inserisci l\'indirizzo del server (es. '
          '${LiveService.defaultServerUrl})');
      return;
    }
    setState(() {
      _connecting = true;
      _error = null;
    });

    final AppState state = context.read<AppState>();
    state.login(nickname);

    final LiveService live = LiveService();
    try {
      await live.connect(
        url,
        name: nickname,
        photo: state.profilePhotoPath,
        emoji: state.currentUser?.avatarEmoji ?? '🎤',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(liveService: live),
        ),
      );
    } catch (_) {
      await live.dispose();
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = 'Impossibile connettersi a $url.\n'
            'Controlla che il server sia attivo e raggiungibile da questo '
            'dispositivo (su emulatore Android usa 10.0.2.2).';
      });
    }
  }

  String _cleanNickname() {
    final String value = _nickname.text.trim();
    return value.isEmpty ? 'Ospite' : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🎤', style: TextStyle(fontSize: 44)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sambaclub',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.sambaText,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Live streaming e social, in oro e nero.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.sambaMuted),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nickname,
                  enabled: !_connecting,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Il tuo nickname',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _server,
                  enabled: !_connecting,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _enter(_cleanNickname()),
                  decoration: const InputDecoration(
                    hintText: 'ws://10.0.2.2:8000/ws',
                    labelText: 'Server di segnalazione',
                    prefixIcon: Icon(Icons.dns_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Default emulatore Android: ws://10.0.2.2:8000/ws. '
                  'Su un telefono reale usa l\'IP del PC nella stessa rete '
                  '(es. ws://192.168.1.10:8000/ws).',
                  style: TextStyle(fontSize: 11, color: AppColors.sambaMuted),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.sambaSurface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.sambaLive.withOpacity(0.6),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.sambaLive,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.sambaText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _connecting
                      ? null
                      : () => _enter(_cleanNickname()),
                  child: _connecting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.sambaBlack,
                          ),
                        )
                      : const Text('Entra'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed:
                      _connecting ? null : () => _enter('Ospite'),
                  child: const Text('Ospite'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'In questa fase tutte le monete sono gratuite 🎁',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.sambaMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
