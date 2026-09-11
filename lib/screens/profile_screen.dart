import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/media_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'recharge_screen.dart';

/// Profile tab: user header, stats, gift history, settings and logout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context) {
    context.read<AppState>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  /// Opens the gallery, then stores the picked photo in [AppState].
  Future<void> _changePhoto(BuildContext context, AppState state) async {
    final String? path = await MediaService.pickProfilePhoto();
    if (!context.mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna foto selezionata')),
      );
      return;
    }
    await state.setProfilePhoto(path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📸 Foto profilo aggiornata!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AppUser? user = state.currentUser;

    return Scaffold(
      backgroundColor: AppColors.sambaBlack,
      appBar: AppBar(title: const Text('Profilo')),
      body: user == null
          ? const Center(
              child: Text(
                'Nessun accesso attivo',
                style: TextStyle(color: AppColors.sambaMuted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _header(context, state, user),
                const SizedBox(height: 14),
                _changePhotoTile(context, state),
                const SizedBox(height: 18),
                _stats(user),
                const SizedBox(height: 22),
                _sectionTitle('Monete'),
                _rechargeTile(context, state),
                const SizedBox(height: 22),
                _sectionTitle('Storico regali'),
                _giftHistory(state),
                const SizedBox(height: 22),
                _sectionTitle('Impostazioni'),
                _settings(),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Esci'),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _header(BuildContext context, AppState state, AppUser user) {
    final String? photo = state.profilePhotoPath;
    final bool hasPhoto = photo != null && photo.isNotEmpty;
    return Row(
      children: <Widget>[
        GestureDetector(
          onTap: () => _changePhoto(context, state),
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.sambaSurface2,
            backgroundImage: hasPhoto ? FileImage(File(photo)) : null,
            onBackgroundImageError: hasPhoto
                ? (Object error, StackTrace? stackTrace) {
                    debugPrint('Profile photo failed to load: $error');
                  }
                : null,
            child: hasPhoto
                ? null
                : Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      user.avatarEmoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                user.nickname,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.sambaText,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Livello ${user.level}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.sambaBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _changePhotoTile(BuildContext context, AppState state) {
    return Card(
      color: AppColors.sambaSurface,
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Text('📸', style: TextStyle(fontSize: 22)),
        title: const Text(
          'Cambia foto profilo',
          style: TextStyle(color: AppColors.sambaText),
        ),
        subtitle: const Text(
          'Scegli un\'immagine dalla galleria',
          style: TextStyle(color: AppColors.sambaMuted),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.sambaGold),
        onTap: () => _changePhoto(context, state),
      ),
    );
  }

  Widget _stats(AppUser user) {
    return Row(
      children: <Widget>[
        Expanded(child: _statTile('Follower', user.followers)),
        const SizedBox(width: 10),
        Expanded(child: _statTile('Following', user.following)),
        const SizedBox(width: 10),
        Expanded(child: _statTile('Regali', user.level * 3)),
      ],
    );
  }

  Widget _statTile(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.sambaSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sambaLines),
      ),
      child: Column(
        children: <Widget>[
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.sambaGold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.sambaMuted),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.sambaText,
        ),
      ),
    );
  }

  Widget _rechargeTile(BuildContext context, AppState state) {
    return Card(
      color: AppColors.sambaSurface,
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Text('🪙', style: TextStyle(fontSize: 22)),
        title: Text(
          'Saldo: ${state.coins} monete',
          style: const TextStyle(color: AppColors.sambaText),
        ),
        subtitle: const Text(
          'Tutte le monete sono gratuite in questa fase',
          style: TextStyle(color: AppColors.sambaMuted),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.sambaGold),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const RechargeScreen()),
        ),
      ),
    );
  }

  Widget _giftHistory(AppState state) {
    if (state.giftHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.sambaSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.sambaLines),
        ),
        child: const Text(
          'Non hai ancora inviato regali. Entra in una live e mandane uno! 🎁',
          style: TextStyle(color: AppColors.sambaMuted),
        ),
      );
    }
    return Column(
      children: state.giftHistory.map((GiftEvent event) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.sambaSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sambaLines),
          ),
          child: Row(
            children: <Widget>[
              Text(event.gift.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      event.gift.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.sambaText,
                      ),
                    ),
                    Text(
                      'a ${event.roomName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.sambaMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '-${event.gift.price} 🪙',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.sambaGold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _settings() {
    return Card(
      color: AppColors.sambaSurface,
      margin: EdgeInsets.zero,
      child: Column(
        children: const <Widget>[
          ListTile(
            leading: Icon(Icons.notifications_none),
            title: Text('Notifiche'),
            trailing: Icon(Icons.chevron_right, color: AppColors.sambaMuted),
          ),
          Divider(height: 1, color: AppColors.sambaLines),
          ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Privacy'),
            trailing: Icon(Icons.chevron_right, color: AppColors.sambaMuted),
          ),
          Divider(height: 1, color: AppColors.sambaLines),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Lingua'),
            subtitle: Text('Italiano'),
            trailing: Icon(Icons.chevron_right, color: AppColors.sambaMuted),
          ),
          Divider(height: 1, color: AppColors.sambaLines),
          ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('Tema'),
            subtitle: Text('Nero & Oro'),
            trailing: Icon(Icons.chevron_right, color: AppColors.sambaMuted),
          ),
          Divider(height: 1, color: AppColors.sambaLines),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Informazioni'),
            trailing: Icon(Icons.chevron_right, color: AppColors.sambaMuted),
          ),
        ],
      ),
    );
  }
}
