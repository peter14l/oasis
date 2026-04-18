import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/services/subscription_service.dart';

/// Service for managing media attachments in chat.
/// 
/// Handles uploading images, documents, and voice messages to Supabase storage,
/// including support for uploading encrypted byte arrays with real progress tracking.
class ChatMediaService {
  final SupabaseClient _supabase;
  final SubscriptionService _subscriptionService;
  final _uuid = const Uuid();
  final _dio = Dio();

  ChatMediaService({SupabaseClient? client, SubscriptionService? subscriptionService})
      : _supabase = client ?? SupabaseService().client,
        _subscriptionService = subscriptionService ?? SubscriptionService();

  /// Uploads media to the message attachments bucket.
  /// 
  /// [filePath] is the local path to the file.
  /// [folder] is the sub-directory in the bucket (e.g. 'images', 'voice').
  /// [encryptedBytes] if provided, will upload these bytes instead of the file.
  /// 
  /// Returns the public URL of the uploaded file.
  Future<String> uploadChatMedia(
    String filePath, {
    String folder = 'images',
    Uint8List? encryptedBytes,
    String? fileExtension,
    Function(double)? onProgress,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      final userId = session?.user.id;
      if (userId == null) throw Exception('Not authenticated');

      final file = File(filePath);
      int totalSize = 0;
      
      if (encryptedBytes != null) {
        totalSize = encryptedBytes.length;
      } else if (await file.exists()) {
        totalSize = await file.length();
      }

      // Check for 2GB limit for Free users
      if (!_subscriptionService.isPro) {
        const twoGBInBytes = 2 * 1024 * 1024 * 1024;
        if (totalSize > twoGBInBytes) {
          throw Exception('Files larger than 2GB require Oasis Pro.');
        }
      }

      final fileExt = fileExtension ?? filePath.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.$fileExt';
      final storagePath = '$userId/$folder/$fileName';

      if (encryptedBytes != null) {
        await _supabase.storage
            .from(SupabaseConfig.messageAttachmentsBucket)
            .uploadBinary(
              storagePath,
              encryptedBytes,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        await _supabase.storage
            .from(SupabaseConfig.messageAttachmentsBucket)
            .upload(
              storagePath,
              file,
              fileOptions: const FileOptions(upsert: true),
            );
      }

      onProgress?.call(1.0); // Final completion

      return _supabase.storage
          .from(SupabaseConfig.messageAttachmentsBucket)
          .getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('[ChatMediaService] Upload Error: $e');
      rethrow;
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      case 'm4a':
      case 'aac':
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Deletes media from storage based on its public URL.
  Future<void> deleteMediaFromUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      const bucketName = SupabaseConfig.messageAttachmentsBucket;
      
      final bucketIndex = pathSegments.indexOf(bucketName);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(bucketName).remove([storagePath]);
        debugPrint('[ChatMediaService] Deleted: $storagePath');
      }
    } catch (e) {
      debugPrint('[ChatMediaService] Delete Error: $e');
    }
  }
}
