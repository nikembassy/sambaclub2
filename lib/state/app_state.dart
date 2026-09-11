import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/chat_message.dart';
import '../models/gift.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/free_coin_service.dart';

/// A recorded gift send (used by the profile gift history).
class GiftEvent {
  const GiftEvent({
    required this.gift,
    required this.roomName,
    required this.at,
    this.qty = 1,
  });

  final Gift gift;
  final String roomName;
  final DateTime at;

  /// How many copies were sent at once (1 for a normal send).
  final int qty;

  /// Total coins spent on this event.
  int get totalCoins => gift.price * qty;
}

/// A ranked gift sender inside a single room (top contributor).
class RoomContributor {
  const RoomContributor({
    required this.name,
    required this.avatarEmoji,
    required this.coins,
  });

  final String name;
  final String avatarEmoji;
  final int coins;
}

/// Seed contributors used to pre-populate an empty room ranking (mock data).
const List<RoomContributor> kMockContributors = <RoomContributor>[
  RoomContributor(name: 'Marta', avatarEmoji: '🦊', coins: 4200),
  RoomContributor(name: 'Leo', avatarEmoji: '🐯', coins: 3100),
  RoomContributor(name: 'Sofia', avatarEmoji: '🐼', coins: 2450),
  RoomContributor(name: 'Dario', avatarEmoji: '🐸', coins: 1200),
  RoomContributor(name: 'Giulia', avatarEmoji: '🦄', coins: 900),
];

/// Global application state exposed through Provider / [ChangeNotifier].
class AppState extends ChangeNotifier {
  AppState({
    AuthService authService = const AuthService(),
    FreeCoinService freeCoinService = const FreeCoinService(),
  })  : _authService = authService,
        _freeCoinService = freeCoinService;

  final AuthService _authService;
  final FreeCoinService _freeCoinService;

  AppUser? _currentUser;
  int _coins = 0;
  final List<LiveRoom> _rooms = List<LiveRoom>.of(kMockRooms);
  final List<ChatMessage> _chatLog = <ChatMessage>[];
  final List<GiftEvent> _giftHistory = <GiftEvent>[];
  final Set<String> _following = <String>{};
  DateTime? _lastFreeClaim;

  /// Local file path of the user's chosen profile photo (null = emoji avatar).
  String? _profilePhotoPath;

  /// Per-room top gift senders: roomId -> (nickname -> contributor).
  final Map<String, Map<String, RoomContributor>> _contributors =
      <String, Map<String, RoomContributor>>{};

  /// Per-room PK battle scores ("Team Oro" vs "Team Rival").
  final Map<String, int> _pkLeft = <String, int>{};
  final Map<String, int> _pkRight = <String, int>{};

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  int get coins => _coins;
  String? get profilePhotoPath => _profilePhotoPath;
  List<LiveRoom> get rooms => List<LiveRoom>.unmodifiable(_rooms);
  List<LiveRoom> get partyRooms => List<LiveRoom>.unmodifiable(
        _rooms.where((LiveRoom room) => room.isParty),
      );
  List<LiveRoom> get liveRooms => List<LiveRoom>.unmodifiable(
        _rooms.where((LiveRoom room) => !room.isParty),
      );
  List<ChatMessage> get chatLog => List<ChatMessage>.unmodifiable(_chatLog);
  List<GiftEvent> get giftHistory => List<GiftEvent>.unmodifiable(_giftHistory);
  Set<String> get following => Set<String>.unmodifiable(_following);

  bool isFollowing(String roomId) => _following.contains(roomId);

  // ---------------------------------------------------------------- Auth

  /// Logs in as [nickname] (mock auth) and grants the starting free coins.
  void login(String nickname) {
    _currentUser = _authService.createUser(nickname);
    _coins = _freeCoinService.startingCoins;
    _chatLog.clear();
    _chatLog.add(
      ChatMessage(
        user: 'Sambaclub',
        text: 'Benvenuto/a, ${_currentUser!.nickname}! 🎉',
      ),
    );
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _coins = 0;
    _following.clear();
    _chatLog.clear();
    _giftHistory.clear();
    _contributors.clear();
    _pkLeft.clear();
    _pkRight.clear();
    _lastFreeClaim = null;
    _profilePhotoPath = null;
    notifyListeners();
  }

  // -------------------------------------------------------------- Media

  /// Stores the local path of the user's profile photo and notifies listeners.
  ///
  /// No upload happens in this offline scaffold: the path points at a file on
  /// the device (e.g. produced by `MediaService.pickProfilePhoto`).
  Future<void> setProfilePhoto(String path) async {
    if (path.isEmpty) return;
    _profilePhotoPath = path;
    notifyListeners();
  }

  /// Clears the custom profile photo, falling back to the emoji avatar.
  void clearProfilePhoto() {
    if (_profilePhotoPath == null) return;
    _profilePhotoPath = null;
    notifyListeners();
  }

  // --------------------------------------------------------------- Gifts

  /// Sends a single [gift] on behalf of the current user.
  bool sendGift(Gift gift, {String? roomId}) =>
      sendGiftBundle(gift, 1, roomId: roomId);

  /// Sends [qty] copies of [gift], deducting `gift.price * qty`.
  ///
  /// Returns false when the user is not logged in, [qty] is not positive or
  /// there are not enough coins. On success it deducts the total, records the
  /// event (with quantity), updates the room contributors + PK score and posts
  /// a gift message to the chat.
  bool sendGiftBundle(Gift gift, int qty, {String? roomId}) {
    final AppUser? user = _currentUser;
    if (user == null || qty <= 0) return false;

    final int total = gift.price * qty;
    if (_coins < total) return false;

    _coins -= total;
    final String rid = roomId ?? '';
    _giftHistory.insert(
      0,
      GiftEvent(
        gift: gift,
        roomName: _roomName(roomId),
        at: DateTime.now(),
        qty: qty,
      ),
    );
    _recordContribution(rid, user.nickname, user.avatarEmoji, total);
    _pkLeft[rid] = pkLeftScore(rid) + total;
    _chatLog.add(
      ChatMessage(
        user: user.nickname,
        text: qty > 1
            ? 'ha inviato ${gift.name} x$qty'
            : 'ha inviato ${gift.name}',
        isGift: true,
        giftEmoji: gift.emoji,
      ),
    );
    notifyListeners();
    return true;
  }

  // -------------------------------------------------------- Contributors

  /// Top gift senders in [roomId], highest spend first.
  List<RoomContributor> topContributors(String roomId, {int limit = 3}) {
    final Map<String, RoomContributor> room =
        _contributors[roomId] ?? const <String, RoomContributor>{};
    final List<RoomContributor> ranked = room.values.toList()
      ..sort(
        (RoomContributor a, RoomContributor b) => b.coins.compareTo(a.coins),
      );
    return ranked.take(limit).toList();
  }

  /// Pre-populates [roomId] with mock contributors when it has none yet.
  void seedContributors(String roomId) {
    _contributors.putIfAbsent(roomId, _contributorSeed);
  }

  void _recordContribution(String roomId, String name, String emoji, int coins) {
    final Map<String, RoomContributor> room =
        _contributors.putIfAbsent(roomId, _contributorSeed);
    final RoomContributor? prev = room[name];
    room[name] = RoomContributor(
      name: name,
      avatarEmoji: emoji,
      coins: (prev?.coins ?? 0) + coins,
    );
  }

  static Map<String, RoomContributor> _contributorSeed() {
    return <String, RoomContributor>{
      for (final RoomContributor c in kMockContributors) c.name: c,
    };
  }

  // ---------------------------------------------------------- PK battles

  /// Score of the left team ("Team Oro") in [roomId].
  int pkLeftScore(String roomId) => _pkLeft[roomId] ?? _seedScore(roomId, 1);

  /// Score of the right team ("Team Rival") in [roomId].
  int pkRightScore(String roomId) => _pkRight[roomId] ?? _seedScore(roomId, 2);

  /// Adds [points] to one side of the PK battle. Gifts are routed to the left
  /// team by default (see [sendGiftBundle]); [addPkPoints] lets the UI/opponent
  /// also push the right team.
  void addPkPoints(String roomId, {required bool left, required int points}) {
    if (left) {
      _pkLeft[roomId] = pkLeftScore(roomId) + points;
    } else {
      _pkRight[roomId] = pkRightScore(roomId) + points;
    }
    notifyListeners();
  }

  /// Opens the room treasure box and returns the coins found (mock reward).
  int openTreasureBox(String roomId) {
    final int reward = 100 + _seedScore(roomId, 5) % 900;
    _coins += reward;
    notifyListeners();
    return reward;
  }

  /// Deterministic pseudo score so an untouched PK bar still looks alive.
  static int _seedScore(String roomId, int salt) {
    int h = salt * 7 + 13;
    for (final int c in roomId.codeUnits) {
      h = (h * 31 + c) & 0x0FFFFFFF;
    }
    return 1200 + h % 4800;
  }

  // ------------------------------------------------------------- Economy

  /// Grants the free daily coins. Returns the amount granted, or 0 when the
  /// user already claimed today.
  int addFreeCoins() {
    final DateTime now = DateTime.now();
    if (_lastFreeClaim != null && _sameDay(_lastFreeClaim!, now)) {
      return 0;
    }
    _lastFreeClaim = now;
    final int granted = _freeCoinService.dailyFreeCoins;
    _coins += granted;
    notifyListeners();
    return granted;
  }

  /// Follows/unfollows a room's host.
  void toggleFollow(String roomId) {
    if (!_following.remove(roomId)) {
      _following.add(roomId);
    }
    notifyListeners();
  }

  // --------------------------------------------------------------- Chat

  /// Posts a plain chat message from the current user.
  void sendChat(String text) {
    final AppUser? user = _currentUser;
    final String clean = text.trim();
    if (user == null || clean.isEmpty) return;
    _chatLog.add(ChatMessage(user: user.nickname, text: clean));
    notifyListeners();
  }

  /// Posts an audio message from the current user.
  ///
  /// [path] is the local file produced by `MediaService.pickAudioFile` or
  /// `MediaService.stopVoiceRecording`; [durationSeconds] is optional and only
  /// used for the bubble's duration label. No-op when logged out or [path] is
  /// empty.
  void addAudioMessage({required String path, int? durationSeconds}) {
    final AppUser? user = _currentUser;
    if (user == null || path.isEmpty) return;
    _chatLog.add(
      ChatMessage(
        user: user.nickname,
        text: '🎤 Messaggio vocale',
        type: ChatMessageType.audio,
        audioPath: path,
        localPath: path,
        durationSeconds: durationSeconds,
      ),
    );
    notifyListeners();
  }

  /// Posts a system message.
  void addSystemMessage(String text) {
    _chatLog.add(ChatMessage(user: 'Sistema', text: text));
    notifyListeners();
  }

  /// Seeds the live chat with the mock lines (used when entering a room).
  void seedChat(List<String> lines) {
    const List<String> nicks = <String>[
      'Marta',
      'Leo',
      'Sofia',
      'Dario',
      'Giulia',
    ];
    for (int i = 0; i < lines.length; i++) {
      _chatLog.add(ChatMessage(user: nicks[i % nicks.length], text: lines[i]));
    }
    notifyListeners();
  }

  String _roomName(String? roomId) {
    if (roomId == null) return 'Sambaclub';
    for (final LiveRoom room in _rooms) {
      if (room.id == roomId) return room.hostName;
    }
    return 'Sambaclub';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
