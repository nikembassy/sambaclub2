import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Thin, **failure-safe** wrappers around the media plugins used by Sambaclub
/// (image_picker, file_picker, record, just_audio, path_provider).
///
/// Every plugin call is wrapped in try/catch: on any failure (missing plugin,
/// denied permission, unsupported platform, cancelled picker) the method logs
/// via [debugPrint] and returns `null` (or does nothing) instead of throwing.
/// Callers can therefore drive the UI without guarding each call themselves —
/// a `null` result simply means "nothing to add".
///
/// ## Permissions
/// Runtime permissions are requested through **permission_handler**:
/// * microphone (`Permission.microphone` → `RECORD_AUDIO` on Android,
///   `NSMicrophoneUsageDescription` on iOS) before voice recording;
/// * gallery/photo pickers rely on the OS picker and, on older Android targets,
///   need `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` plus the iOS
///   `NSPhotoLibraryUsageDescription` key.
/// See the README "Media" section for the full manifest / Info.plist list.
class MediaService {
  MediaService._();

  static final ImagePicker _imagePicker = ImagePicker();
  static final AudioRecorder _recorder = AudioRecorder();
  static final AudioPlayer _player = AudioPlayer();

  /// Path of the recording currently in progress, if any.
  static String? _recordingPath;

  /// True while [startVoiceRecording] has been called and not yet stopped.
  static bool get isRecording => _recordingPath != null;

  // ------------------------------------------------------------- Photos

  /// Opens the gallery and returns the picked image's file path, or `null` if
  /// the user cancelled or the picker failed.
  static Future<String?> pickProfilePhoto() async {
    try {
      final XFile? file =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      return file?.path;
    } catch (error) {
      debugPrint('MediaService.pickProfilePhoto failed: $error');
      return null;
    }
  }

  // -------------------------------------------------------------- Audio

  /// Opens the system file browser filtered to audio files and returns the
  /// selected file path, or `null` when cancelled / on failure.
  static Future<String?> pickAudioFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return null;
      return result.files.single.path;
    } catch (error) {
      debugPrint('MediaService.pickAudioFile failed: $error');
      return null;
    }
  }

  /// Requests the microphone permission via permission_handler.
  ///
  /// Returns `true` when granted; `false` when denied/restricted or when the
  /// permission API itself is unavailable.
  static Future<bool> requestMicrophonePermission() async {
    try {
      final PermissionStatus status = await Permission.microphone.request();
      return status.isGranted;
    } catch (error) {
      debugPrint('MediaService.requestMicrophonePermission failed: $error');
      return false;
    }
  }

  /// Starts recording a voice note into the app documents directory and returns
  /// the destination path, or `null` when the permission was denied or the
  /// recorder could not start.
  static Future<String?> startVoiceRecording() async {
    try {
      if (isRecording) return _recordingPath;
      if (!await requestMicrophonePermission()) return null;

      final Directory dir = await getApplicationDocumentsDirectory();
      final String path =
          '${dir.path}/samba_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _recordingPath = path;
      return path;
    } catch (error) {
      debugPrint('MediaService.startVoiceRecording failed: $error');
      _recordingPath = null;
      return null;
    }
  }

  /// Stops the active recording and returns the saved file path, or `null` when
  /// nothing was recording / on failure.
  static Future<String?> stopVoiceRecording() async {
    try {
      if (!isRecording) return null;
      final String? path = await _recorder.stop();
      _recordingPath = null;
      if (path == null || path.isEmpty) return null;
      return path;
    } catch (error) {
      debugPrint('MediaService.stopVoiceRecording failed: $error');
      _recordingPath = null;
      return null;
    }
  }

  /// Cancels the active recording without keeping the file (best effort).
  static Future<void> cancelVoiceRecording() async {
    try {
      await _recorder.stop();
    } catch (error) {
      debugPrint('MediaService.cancelVoiceRecording failed: $error');
    } finally {
      _recordingPath = null;
    }
  }

  /// Plays the audio file at [path] from the start, replacing any current clip.
  /// Does nothing when [path] is empty or playback fails.
  static Future<void> playAudio(String path) async {
    if (path.isEmpty) return;
    try {
      await _player.stop();
      await _player.setFilePath(path);
      await _player.play();
    } catch (error) {
      debugPrint('MediaService.playAudio failed: $error');
    }
  }

  /// Stops whatever audio is currently playing (best effort).
  static Future<void> stopAudio() async {
    try {
      await _player.stop();
    } catch (error) {
      debugPrint('MediaService.stopAudio failed: $error');
    }
  }
}
