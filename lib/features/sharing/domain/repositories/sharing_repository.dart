import '../models/shared_media_entity.dart';

/// Abstract repository interface for sharing operations
abstract class SharingRepository {
  /// Handle incoming share intents from external apps
  Future<ShareIntentEntity> getShareIntent();

  /// Share content to a specific conversation
  Future<ShareResultEntity> shareToConversation({
    required String conversationId,
    required String senderId,
    required String content,
    required List<SharedMediaEntity> media,
    String? rippleId,
    String? storyId,
  });

  /// Share externally using native share sheet
  Future<ShareResultEntity> shareExternally({
    required String text,
    String? subject,
  });
}
