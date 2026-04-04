import 'dart:io';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oasis_v2/core/config/feature_flags.dart';
import '../../domain/models/shared_media_entity.dart';

/// Data source for handling share intents and external sharing
class SharingRemoteDatasource {
  /// Get share intent from external apps (images, text, etc.)
  Stream<List<SharedMediaEntity>> getShareIntentStream() {
    if (!FeatureFlags.supportSystemIntents) {
      return Stream.value([]);
    }

    return ReceiveSharingIntent.instance.getMediaStream().map((files) {
      return files
          .map(
            (file) => SharedMediaEntity(
              path: file.path,
              mimeType: _getMimeType(file.type),
              createdAt: DateTime.now(),
            ),
          )
          .toList();
    });
  }

  /// Get initial share intent (when app was closed)
  Future<List<SharedMediaEntity>> getInitialShareIntent() async {
    if (!FeatureFlags.supportSystemIntents) {
      return [];
    }

    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    return files
        .map(
          (file) => SharedMediaEntity(
            path: file.path,
            mimeType: _getMimeType(file.type),
            createdAt: DateTime.now(),
          ),
        )
        .toList();
  }

  /// Clear shared files after handling
  Future<void> clearSharedFiles() async {
    ReceiveSharingIntent.instance.reset();
  }

  /// Share content externally using native share sheet
  Future<void> shareExternally({required String text, String? subject}) async {
    await Share.share(text, subject: subject);
  }

  /// Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return file.length();
  }

  String? _getMimeType(SharedMediaType? type) {
    switch (type) {
      case SharedMediaType.image:
        return 'image/jpeg';
      case SharedMediaType.video:
        return 'video/mp4';
      case SharedMediaType.file:
        return 'application/octet-stream';
      case SharedMediaType.text:
        return 'text/plain';
      default:
        return null;
    }
  }
}
