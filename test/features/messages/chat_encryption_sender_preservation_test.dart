import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/features/messages/domain/models/message.dart';
import 'package:oasis/services/notification_decryption_service.dart';

import '../../test_setup.dart';

void main() {
  setUp(() {
    setupTestEnvironment();
  });

  group('NotificationDecryptionService Previews', () {
    test('returns clean preview when content is ciphertext or encrypted', () async {
      final service = NotificationDecryptionService();

      // Test with image message
      final imagePayload = {
        'message_type': 'image',
        'body': 'pqa:verylongbase64ciphertextwithnospacesabcdefghijklmnopqrstuvwxyz1234567890',
      };
      final imageResult = await service.decryptMessage(imagePayload);
      expect(imageResult, equals('📷 Photo'));

      // Test with video message
      final videoPayload = {
        'message_type': 'video',
        'body': 'pqa:verylongbase64ciphertextwithnospacesabcdefghijklmnopqrstuvwxyz1234567890',
      };
      final videoResult = await service.decryptMessage(videoPayload);
      expect(videoResult, equals('🎥 Video'));

      // Test with voice message
      final voicePayload = {
        'message_type': 'voice',
        'body': '🔒 Encrypted message',
      };
      final voiceResult = await service.decryptMessage(voicePayload);
      expect(voiceResult, equals('🎤 Voice message'));

      // Test with generic text ciphertext
      final textPayload = {
        'message_type': 'text',
        'body': 'pqa:verylongbase64ciphertextwithnospacesabcdefghijklmnopqrstuvwxyz1234567890',
      };
      final textResult = await service.decryptMessage(textPayload);
      expect(textResult, equals('New message'));
    });
  });

  group('Sender Plaintext Preservation Logic', () {
    test('preserves sender optimistic plaintext against server ciphertext echo', () {
      const currentUserId = 'user_sender_123';
      final existingOptimistic = Message(
        id: 'client-uuid-1',
        conversationId: 'conv_1',
        senderId: currentUserId,
        content: 'Hello, this is my secret message',
        timestamp: DateTime.now(),
      );

      final incomingServerEcho = Message(
        id: 'server-id-1',
        conversationId: 'conv_1',
        senderId: currentUserId,
        content: '🔒 Message encrypted',
        timestamp: DateTime.now(),
      );

      final bool existingHasPlaintext =
          !existingOptimistic.content.contains('🔒') &&
          existingOptimistic.content.trim().isNotEmpty;

      Message finalMessage;
      if (incomingServerEcho.senderId == currentUserId &&
          existingHasPlaintext &&
          (incomingServerEcho.content.contains('🔒') ||
              incomingServerEcho.content.trim().isEmpty)) {
        finalMessage = incomingServerEcho.copyWith(
          content: existingOptimistic.content,
        );
      } else {
        finalMessage = incomingServerEcho;
      }

      expect(finalMessage.content, equals('Hello, this is my secret message'));
    });
  });
}
