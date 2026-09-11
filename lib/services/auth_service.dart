import '../models/user.dart';

/// Minimal mock auth service.
///
/// This does NOT perform any real authentication or network call — it simply
/// builds an in-memory [AppUser] so the UI can be exercised end to end.
class AuthService {
  const AuthService();

  /// Builds a lightweight local user for [nickname].
  AppUser createUser(String nickname) {
    final String clean = nickname.trim();
    final String name = clean.isEmpty ? 'Ospite' : clean;
    return AppUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      nickname: name,
      avatarEmoji: '🎤',
      level: 1,
      coins: 0,
      followers: 0,
      following: 0,
    );
  }

  /// Convenience helper for the "Ospite" (guest) button.
  AppUser createGuest() => createUser('Ospite');
}
