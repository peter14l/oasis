import '../repositories/sharing_repository.dart';
import '../models/shared_media_entity.dart';

/// Use case to handle received share intents from external apps
class HandleReceivedIntent {
  final SharingRepository _repository;

  HandleReceivedIntent(this._repository);

  Future<ShareIntentEntity> call() async {
    return _repository.getShareIntent();
  }
}

/// Use case to share content to a specific conversation
class ShareToConversation {
  final SharingRepository _repository;

  ShareToConversation(this._repository);

  Future<ShareResultEntity> call({
    required String conversationId,
    required String senderId,
    required String content,
    List<SharedMediaEntity> media = const [],
    String? rippleId,
    String? storyId,
  }) async {
    return _repository.shareToConversation(
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      media: media,
      rippleId: rippleId,
      storyId: storyId,
    );
  }
}

/// Use case to share content externally using native share sheet
class ShareExternally {
  final SharingRepository _repository;

  ShareExternally(this._repository);

  Future<ShareResultEntity> call({
    required String text,
    String? subject,
  }) async {
    return _repository.shareExternally(text: text, subject: subject);
  }
}
