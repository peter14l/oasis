import 'package:oasis/features/wellbeing/domain/models/warm_whisper.dart';

abstract class WarmWhisperRepository {
  /// Send a warm whisper care ping to a user.
  Future<void> sendWhisper({
    required String recipientId,
    String? message,
    bool isAnonymous = false,
  });

  /// Retrieve whispers received by the current user.
  Future<List<WarmWhisper>> getReceivedWhispers();

  /// Retrieve whispers sent by the current user.
  Future<List<WarmWhisper>> getSentWhispers();

  /// Mark a whisper as revealed (opened).
  Future<void> markAsRevealed(String whisperId);

  /// Get today's remaining whisper count (max 3 per day).
  Future<int> getRemainingWhisperCount();
}
