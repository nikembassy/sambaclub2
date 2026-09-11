import 'package:flutter/material.dart';

/// What kind of room this is: a classic 1-to-many live stream or a
/// multi-seat audio/video "party" room.
enum RoomType { live, party }

/// A live-streaming room (or a party room when [type] is [RoomType.party]).
class LiveRoom {
  const LiveRoom({
    required this.id,
    required this.hostName,
    required this.hostEmoji,
    required this.flagEmoji,
    required this.title,
    required this.category,
    required this.viewers,
    required this.coverColors,
    this.type = RoomType.live,
  });

  final String id;
  final String hostName;
  final String hostEmoji;
  final String flagEmoji;
  final String title;
  final String category;
  final int viewers;

  /// Two (or more) colors used to build the gradient "cover" placeholder.
  /// No network images are used anywhere in the app.
  final List<Color> coverColors;

  /// Defaults to [RoomType.live] so existing mock rooms keep working.
  final RoomType type;

  bool get isParty => type == RoomType.party;

  /// Gradient used as the room cover / video placeholder.
  LinearGradient get coverGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: coverColors,
      );

  /// Compact viewer count, e.g. 1243 -> "1.2K".
  String get viewersLabel {
    if (viewers >= 1000000) {
      return '${(viewers / 1000000).toStringAsFixed(1)}M';
    }
    if (viewers >= 1000) {
      return '${(viewers / 1000).toStringAsFixed(1)}K';
    }
    return '$viewers';
  }
}
