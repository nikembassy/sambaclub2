/// Kind of payload carried by a [ChatMessage].
///
/// [text] is the classic chat line (the default, so existing call sites keep
/// working unchanged). [audio] is a voice note / picked audio file rendered by
/// the chat as a play-button bubble.
enum ChatMessageType { text, audio }

/// A single message in a live-room chat.
class ChatMessage {
  ChatMessage({
    required this.user,
    required this.text,
    this.type = ChatMessageType.text,
    this.audioPath,
    this.durationSeconds,
    this.localPath,
    this.isGift = false,
    this.giftEmoji,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  final String user;
  final String text;

  /// Whether this message is a plain line ([ChatMessageType.text]) or an audio
  /// clip ([ChatMessageType.audio]).
  final ChatMessageType type;

  /// Path of the audio file to play (local file path in this offline scaffold).
  final String? audioPath;

  /// Length of the audio clip in seconds, when known.
  final int? durationSeconds;

  /// Local file path of the message payload (currently mirrors [audioPath] for
  /// audio messages; kept generic so a cached image path can reuse it later).
  final String? localPath;

  /// True when this message represents a sent gift (rendered in gold).
  final bool isGift;
  final String? giftEmoji;
  final DateTime time;

  /// Convenience flag for the widgets that special-case audio bubbles.
  bool get isAudio => type == ChatMessageType.audio;

  /// File to hand to the audio player, preferring [audioPath] then [localPath].
  String? get audioSource {
    final String? path = audioPath ?? localPath;
    if (path == null || path.isEmpty) return null;
    return path;
  }

  /// "HH:mm" label used by the chat bubbles.
  String get timeLabel {
    final String h = time.hour.toString().padLeft(2, '0');
    final String m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// "m:ss" duration label shown under an audio bubble (0:00 when unknown).
  String get durationLabel {
    final int total = durationSeconds ?? 0;
    final int minutes = total ~/ 60;
    final int seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
