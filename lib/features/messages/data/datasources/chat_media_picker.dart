import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Service for picking media files in the chat.
/// Extracted from _pickImage, _pickFile, _pickVideo, _pickAudio in chat_screen.dart.
class ChatMediaPicker {
  final ImagePicker _imagePicker = ImagePicker();

  /// Get the default initial directory for file picking.
  Future<String?> getInitialDirectory() async {
    try {
      if (Platform.isWindows) {
        return 'C:\\Users\\${Platform.environment['USERNAME']}\\Downloads';
      }
      return (await getDownloadsDirectory())?.path;
    } catch (e) {
      return null;
    }
  }

  /// Pick an image from gallery or camera.
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _imagePicker.pickImage(source: source, imageQuality: 85);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick a file.
  Future<PlatformFile?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        initialDirectory: await getInitialDirectory(),
      );
      if (result != null && result.files.single.path != null) {
        return result.files.single;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  /// Pick a video.
  Future<XFile?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  /// Pick an audio file.
  Future<File?> pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        initialDirectory: await getInitialDirectory(),
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final sizeInBytes = await file.length();
        final sizeInMb = sizeInBytes / (1024 * 1024);
        if (sizeInMb > 50) {
          debugPrint('File too large (Max 50MB).');
          return null;
        }
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking audio: $e');
      return null;
    }
  }
}
