/// A Sambaclub user profile.
class AppUser {
  const AppUser({
    required this.id,
    required this.nickname,
    required this.avatarEmoji,
    this.level = 1,
    this.coins = 0,
    this.followers = 0,
    this.following = 0,
  });

  final String id;
  final String nickname;
  final String avatarEmoji;
  final int level;
  final int coins;
  final int followers;
  final int following;

  AppUser copyWith({
    String? id,
    String? nickname,
    String? avatarEmoji,
    int? level,
    int? coins,
    int? followers,
    int? following,
  }) {
    return AppUser(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      followers: followers ?? this.followers,
      following: following ?? this.following,
    );
  }
}
