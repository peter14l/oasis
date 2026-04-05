import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:oasis/features/messages/domain/models/message.dart';
import 'package:oasis/services/messaging_service.dart';
import 'package:oasis/core/utils/haptic_utils.dart';

/// Provider handling all voice recording logic.
/// Extracted from _ChatScreenState recording methods in chat_screen.dart.
class ChatRecordingProvider with ChangeNotifier {
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _recordTimer;
  bool _isRecording = false;
  int _recordDuration = 0;

  bool get isRecording => _isRecording;
  int get recordDuration => _recordDuration;

  /// Called when recording stops and audio is ready to send.
  Function(String audioPath, int duration)? onRecordingComplete;

  /// Called on recording errors.
  Function(String error)? onError;

  /// Toggle recording on/off.
  Future<void> toggleRecording() async {
    if (_isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  /// Start a new voice recording.
  /// Original: _startRecording() in chat_screen.dart
  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 32000, // 32kbps is perfect for voice
            numChannels: 1, // Mono
          ),
          path: filePath,
        );

        _isRecording = true;
        _recordDuration = 0;
        notifyListeners();

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _recordDuration++;
          notifyListeners();
        });
        HapticUtils.lightImpact();
      }
    } catch (e) {
      onError?.call('Error starting recording: $e');
    }
  }

  /// Stop the current recording and trigger send.
  /// Original: _stopRecording() in chat_screen.dart
  Future<void> stopRecording() async {
    try {
      _recordTimer?.cancel();
      _recordTimer = null;
      final recordPath = await _audioRecorder.stop();

      final duration = _recordDuration;
      _isRecording = false;
      _recordDuration = 0;
      notifyListeners();

      if (recordPath != null) {
        onRecordingComplete?.call(recordPath, duration);
      }
      HapticUtils.lightImpact();
    } catch (e) {
      onError?.call('Error stopping recording: $e');
      _isRecording = false;
      notifyListeners();
    }
  }

  /// Send a recorded audio message via the messaging service.
  /// Original: _sendAudioMessage() in chat_screen.dart
  Future<void> sendAudioMessage({
    required String audioPath,
    required String conversationId,
    required String userId,
    required int recordDuration,
  }) async {
    final messagingService = MessagingService();
    try {
      await messagingService.sendMessage(
        conversationId: conversationId,
        senderId: userId,
        content: 'Audio message',
        messageType: MessageType.voice,
        mediaUrl: audioPath,
        mediaFileName: 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
        voiceDuration: recordDuration,
      );
    } catch (e) {
      onError?.call('Error sending audio message: $e');
    }
  }

  /// Format a Duration into mm:ss string.
  /// Original: _formatDuration() in chat_screen.dart
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
