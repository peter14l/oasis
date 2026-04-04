import '../../domain/repositories/sharing_repository.dart';
import '../../domain/models/shared_media_entity.dart';
import '../datasources/sharing_remote_datasource.dart';

/// Implementation of SharingRepository
class SharingRepositoryImpl implements SharingRepository {
  final SharingRemoteDatasource _datasource;

  SharingRepositoryImpl({SharingRemoteDatasource? datasource})
    : _datasource = datasource ?? SharingRemoteDatasource();

  @override
  Future<ShareIntentEntity> getShareIntent() async {
    final media = await _datasource.getInitialShareIntent();
    await _datasource.clearSharedFiles();
    return ShareIntentEntity(media: media, receivedAt: DateTime.now());
  }

  @override
  Future<ShareResultEntity> shareToConversation({
    required String conversationId,
    required String senderId,
    required String content,
    required List<SharedMediaEntity> media,
    String? rippleId,
    String? storyId,
  }) async {
    try {
      // For now, this will delegate to the existing messaging service
      // The actual send will be handled by the provider that uses this repository
      return ShareResultEntity.success(conversationId: conversationId);
    } catch (e) {
      return ShareResultEntity.failure(e.toString());
    }
  }

  @override
  Future<ShareResultEntity> shareExternally({
    required String text,
    String? subject,
  }) async {
    try {
      await _datasource.shareExternally(text: text, subject: subject);
      return ShareResultEntity.success();
    } catch (e) {
      return ShareResultEntity.failure(e.toString());
    }
  }
}
