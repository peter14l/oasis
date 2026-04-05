import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/core/network/supabase_client.dart';

/// Service for managing media attachments in chat.
/// 
/// Handles uploading images, documents, and voice messages to Supabase storage,
/// including support for uploading encrypted byte arrays.
class ChatMediaService {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  ChatMediaService({SupabaseClient? client})
      : _supabase = client ?? SupabaseService().client;

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
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final fileExt = fileExtension ?? filePath.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.$fileExt';
      final storagePath = '$userId/$folder/$fileName';

      if (encryptedBytes != null) {
        await _supabase.storage
            .from(SupabaseConfig.messageAttachmentsBucket)
            .uploadBinary(storagePath, encryptedBytes);
      } else {
        await _supabase.storage
            .from(SupabaseConfig.messageAttachmentsBucket)
            .upload(storagePath, File(filePath));
      }

      return _supabase.storage
          .from(SupabaseConfig.messageAttachmentsBucket)
          .getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('[ChatMediaService] Upload Error: $e');
      rethrow;
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
