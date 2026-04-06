import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis/features/messages/domain/models/message.dart';
import 'package:oasis/features/messages/data/encryption_service.dart';
import 'package:oasis/features/messages/data/signal/signal_service.dart';
import 'package:oasis/features/messages/presentation/screens/encryption_setup_screen.dart';

/// Provider handling all encryption-related chat logic.
/// Extracted from _ChatScreenState encryption methods in chat_screen.dart.
class ChatEncryptionProvider with ChangeNotifier {
  final EncryptionService _encryptionService = EncryptionService();
  bool _encryptionReady = false;
  bool get encryptionReady => _encryptionReady;

  /// Initialize encryption, prompting setup/restore if needed.
  /// Original: _initializeEncryption() in chat_screen.dart
  Future<bool> initializeEncryption(BuildContext context) async {
    if (!_encryptionService.isInitialized) return false;

    if (!SignalService().isInitialized) {
      final success = await SignalService().init();
      if (!success) {
        debugPrint('Failed to initialize SignalService');
      }
    }

    final status = await _encryptionService.init();

    if (status == EncryptionStatus.needsSetup) {
      if (context.mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => const EncryptionSetupScreen(isRestore: false),
          ),
        );
        final ready = result == true;
        _encryptionReady = ready;
        notifyListeners();
        return ready;
      }
    } else if (status == EncryptionStatus.needsRestore) {
      if (context.mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => const EncryptionSetupScreen(isRestore: true),
          ),
        );
        final ready = result == true;
        _encryptionReady = ready;
        notifyListeners();
        return ready;
      }
    } else if (status == EncryptionStatus.ready) {
      _encryptionReady = true;
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Decrypt a single message (content + reply context).
  /// Original: _decryptSingleMessage() in chat_screen.dart
  Future<Message> decryptSingleMessage(
    Message message,
    String? currentUserId,
  ) async {
    Message decryptedMessage = message;

    // 1. Decrypt main content
    if (message.signalMessageType != null) {
      try {
        final isSender =
            currentUserId != null &&
            message.senderId.toLowerCase() == currentUserId.toLowerCase();

        if (isSender &&
            message.signalSenderContent != null &&
            message.encryptedKeys != null &&
            message.iv != null) {
          final decrypted = await _encryptionService.decryptMessage(
            message.signalSenderContent!,
            message.encryptedKeys!,
            message.iv!,
          );
          decryptedMessage = decryptedMessage.copyWith(
            content: decrypted ?? '🔒 Message encrypted',
          );
        } else if (!isSender) {
          String decrypted = await SignalService().decryptMessage(
            message.senderId,
            message.content,
            message.signalMessageType!,
          );

          if ((decrypted.contains('🔒') ||
                  decrypted.contains('Optimizing secure connection')) &&
              message.signalSenderContent != null &&
              message.encryptedKeys != null &&
              message.iv != null) {
            final rsaDecrypted = await _encryptionService.decryptMessage(
              message.signalSenderContent!,
              message.encryptedKeys!,
              message.iv!,
            );
            if (rsaDecrypted != null) decrypted = rsaDecrypted;
          }
          decryptedMessage = decryptedMessage.copyWith(content: decrypted);
        }
      } catch (e) {
        debugPrint('Decryption failed: $e');
        decryptedMessage = decryptedMessage.copyWith(
          content: '🔒 Message encrypted',
        );
      }
    } else if (message.encryptedKeys != null && message.iv != null) {
      final decrypted = await _encryptionService.decryptMessage(
        message.content,
        message.encryptedKeys!,
        message.iv!,
      );
      decryptedMessage = decryptedMessage.copyWith(
        content: decrypted ?? '🔒 Message encrypted',
      );
    }

    // 2. Decrypt reply content if available
    if (decryptedMessage.replyToId != null &&
        decryptedMessage.replyToData != null) {
      final replyData = decryptedMessage.replyToData!;
      final replySenderId = replyData['sender_id'] as String?;
      final replyEncryptedKeys =
          replyData['encrypted_keys'] as Map<String, dynamic>?;
      final replyIv = replyData['iv'] as String?;
      final replySignalType = replyData['signal_message_type'] as int?;
      final replyContent = replyData['content'] as String?;
      final replySenderContent = replyData['signal_sender_content'] as String?;

      if (replySenderId != null && replyContent != null) {
        String? decryptedReply;
        try {
          if (replySignalType != null) {
            final isSender =
                currentUserId != null &&
                replySenderId.toLowerCase() == currentUserId.toLowerCase();

            if (isSender &&
                replySenderContent != null &&
                replyEncryptedKeys != null &&
                replyIv != null) {
              decryptedReply = await _encryptionService.decryptMessage(
                replySenderContent,
                Map<String, String>.from(replyEncryptedKeys),
                replyIv,
              );
            } else if (!isSender) {
              decryptedReply = await SignalService().decryptMessage(
                replySenderId,
                replyContent,
                replySignalType,
              );

              if (decryptedReply.contains('🔒') &&
                  replySenderContent != null &&
                  replyEncryptedKeys != null &&
                  replyIv != null) {
                decryptedReply = await _encryptionService.decryptMessage(
                  replySenderContent,
                  Map<String, String>.from(replyEncryptedKeys),
                  replyIv,
                );
              }
            }
          } else if (replyEncryptedKeys != null && replyIv != null) {
            decryptedReply = await _encryptionService.decryptMessage(
              replyContent,
              Map<String, String>.from(replyEncryptedKeys),
              replyIv,
            );
          }

          if (decryptedReply != null && !decryptedReply.contains('🔒')) {
            decryptedMessage = decryptedMessage.copyWith(
              replyToContent: decryptedReply,
            );
          } else {
            debugPrint(
              'Reply decryption resulted in placeholder or null for msg ${message.id}',
            );
          }
        } catch (e) {
          debugPrint(
            'Failed to decrypt reply context for msg ${message.id}: $e',
          );
        }
      } else {
        debugPrint(
          'Missing sender_id or content in replyToData for msg ${message.id}',
        );
      }
    }

    return decryptedMessage;
  }

  /// Enable screenshot/recording prevention.
  /// Original: _enableScreenProtection() in chat_screen.dart
  Future<void> enableScreenProtection() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await ScreenProtector.preventScreenshotOn();
      }
    } catch (e) {
      debugPrint('Error enabling screen protection: $e');
    }
  }

  /// Disable screenshot/recording prevention.
  /// Original: _disableScreenProtection() in chat_screen.dart
  Future<void> disableScreenProtection() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await ScreenProtector.preventScreenshotOff();
      }
    } catch (e) {
      debugPrint('Error disabling screen protection: $e');
    }
  }

  /// Extract dominant colors from a background image for bubble theming.
  /// Original: _extractColorsFromBackground() in chat_screen.dart
  Future<void> extractColorsFromBackground(
    String? backgroundUrl,
    void Function(Color?, Color?, Color?, Color?) onColorsExtracted,
  ) async {
    if (backgroundUrl == null) return;

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final imageProvider = CachedNetworkImageProvider(backgroundUrl);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 20,
      );

      final sentColor = paletteGenerator.dominantColor?.color ?? Colors.blue;
      final receivedColor =
          paletteGenerator.lightVibrantColor?.color ?? Colors.grey;

      final bubbleColorSent = sentColor.withValues(alpha: 0.9);
      final bubbleColorReceived = receivedColor.withValues(alpha: 0.85);

      final textColorSent =
          sentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
      final textColorReceived =
          receivedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

      onColorsExtracted(
        bubbleColorSent,
        bubbleColorReceived,
        textColorSent,
        textColorReceived,
      );
    } catch (e) {
      debugPrint('Error extracting colors: $e');
    }
  }
}
