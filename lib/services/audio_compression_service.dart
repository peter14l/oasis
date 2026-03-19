import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/session_state.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AudioCompressionService {
  static final AudioCompressionService _instance = AudioCompressionService._internal();
  factory AudioCompressionService() => _instance;
  AudioCompressionService._internal();

  /// Compresses an audio file to be under 50MB if possible.
  /// Returns the path to the compressed file.
  Future<String?> compressAudio(String inputPath) async {
    try {
      final file = File(inputPath);
      final originalSize = await file.length();
      
      // If already under 45MB, no need to compress (safety margin)
      if (originalSize < 45 * 1024 * 1024) {
        debugPrint('File size ${(originalSize / (1024 * 1024)).toStringAsFixed(2)}MB is below threshold. Skipping compression.');
        return inputPath;
      }

      final directory = await getTemporaryDirectory();
      final outputPath = '${directory.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp3';

      debugPrint('STARTING async compression: $inputPath (${(originalSize / (1024 * 1024)).toStringAsFixed(2)} MB)');
      
      // -i: input
      // -codec:a libmp3lame: Use MP3 for reliability
      // -b:a 32k: 32kbps bitrate
      // -ac 1: mono
      // -preset superfast: faster processing
      // -y: overwrite output
      final command = '-i "$inputPath" -codec:a libmp3lame -b:a 32k -ac 1 -preset superfast -y "$outputPath"';

      final session = await FFmpegKit.executeAsync(command, (session) async {
        final state = await session.getState();
        final returnCode = await session.getReturnCode();
        debugPrint('FFmpeg session finished with state $state and return code $returnCode');
      }, (log) {
        // Full logs for debugging
        debugPrint('FFmpeg: ${log.getMessage()}');
      }, (stats) {
        debugPrint('Compression Progress: ${stats.getTime()}ms processed');
      });

      // Wait for completion
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final compressedFile = File(outputPath);
        final compressedSize = await compressedFile.length();
        debugPrint('COMPRESSION SUCCESS. New size: ${(compressedSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        return outputPath;
      } else {
        final logs = await session.getLogs();
        debugPrint('COMPRESSION FAILED. Last 5 logs: ${logs.take(5).join('\n')}');
        return null;
      }
    } catch (e) {
      debugPrint('Error during audio compression: $e');
      return null;
    }
  }

  /// Checks if a file needs compression (> 50MB)
  Future<bool> needsCompression(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final size = await file.length();
    return size > 48 * 1024 * 1024; // Use 48MB as threshold for safety
  }
}
