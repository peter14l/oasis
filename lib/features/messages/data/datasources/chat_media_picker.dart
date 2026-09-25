import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oasis/core/utils/permission_utils.dart';

/// Service for picking media files in the chat.
/// Extracted from _pickImage, _pickFile, _pickVideo, _pickAudio in chat_screen.dart.
class ChatMediaPicker {
  final ImagePicker _imagePicker = ImagePicker();

  /// Get the default initial directory for file picking.
  Future<String?> getInitialDirectory() async {
    try {
      final dir = await getDownloadsDirectory();
      if (dir != null) return dir.path;
      final docsDir = await getApplicationDocumentsDirectory();
      return docsDir.path;
    } catch (e) {
      return null;
    }
  }

  /// Pick multiple images from gallery.
  Future<List<XFile>> pickMultiImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final permissionGranted = await PermissionUtils.requestGalleryPermission();
        if (!permissionGranted) {
          // On Android 13+, PhotoPicker doesn't need permissions; try picking anyway before giving up
          try {
            final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
            if (picked.isNotEmpty) return picked;
          } catch (_) {}
          throw Exception('Gallery permission denied');
        }
      }

      if (Platform.isWindows) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          initialDirectory: await getInitialDirectory(),
        );
        if (result != null && result.paths.isNotEmpty) {
          return result.paths
              .where((path) => path != null)
              .map((path) => XFile(path!))
              .toList();
        }
        return [];
      } else {
        return await _imagePicker.pickMultiImage(imageQuality: 85);
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      rethrow;
    }
  }

  /// Pick a file.
  Future<PlatformFile?> pickFile() async {
    try {
      // Note: FilePicker uses Storage Access Framework (SAF) on Android and UIDocumentPicker on iOS.
      // Neither requires runtime READ_EXTERNAL_STORAGE permission on Android 10+ or iOS.
      final result = await FilePicker.platform.pickFiles(
        initialDirectory: await getInitialDirectory(),
      );
      if (result != null && result.files.single.path != null) {
        return result.files.single;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      rethrow;
    }
  }

  /// Pick a video.
  Future<XFile?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final permissionGranted = await PermissionUtils.requestGalleryPermission();
        if (!permissionGranted) {
          try {
            final picked = await _imagePicker.pickVideo(
              source: source,
              maxDuration: const Duration(minutes: 5),
            );
            if (picked != null) return picked;
          } catch (_) {}
          throw Exception('Gallery permission denied');
        }
      }

      if (Platform.isWindows) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          initialDirectory: await getInitialDirectory(),
        );
        if (result != null && result.files.single.path != null) {
          return XFile(result.files.single.path!);
        }
        return null;
      } else {
        return await _imagePicker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 5),
        );
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      rethrow;
    }
  }

  /// Pick an audio file.
  Future<File?> pickAudio() async {
    try {
      // Audio selection uses system SAF picker without requiring obsolete storage permission
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        initialDirectory: await getInitialDirectory(),
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final sizeInBytes = await file.length();
        final sizeInMb = sizeInBytes / (1024 * 1024);
        if (sizeInMb > 50) {
          throw Exception('File too large (Max 50MB).');
        }
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking audio: $e');
      rethrow;
    }
  }
}
