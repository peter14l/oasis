import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/models/message.dart';

void main() {
  group('Message Model Mapping Tests', () {
    test('Should correctly map voice_url to MessageType.voice', () {
      final json = {
        'id': 'msg-123',
        'conversation_id': 'conv-123',
        'sender_id': 'user-123',
        'content': 'Sent attachment',
        'voice_url': 'https://example.com/audio.m4a',
        'voice_duration': 60,
        'created_at': DateTime.now().toIso8601String(),
      };

      final message = Message.fromJson(json);

      expect(message.messageType, MessageType.voice);
      expect(message.mediaUrl, 'https://example.com/audio.m4a');
      expect(message.voiceDuration, 60);
    });

    test('Should prioritize voice_url over image_url if both exist', () {
      final json = {
        'id': 'msg-124',
        'conversation_id': 'conv-123',
        'sender_id': 'user-123',
        'content': 'Sent attachment',
        'voice_url': 'https://example.com/audio.m4a',
        'image_url': 'https://example.com/image.jpg',
        'created_at': DateTime.now().toIso8601String(),
      };

      final message = Message.fromJson(json);

      expect(message.messageType, MessageType.voice);
      expect(message.mediaUrl, 'https://example.com/audio.m4a');
    });

    test('Should map document if only file_url is present', () {
      final json = {
        'id': 'msg-125',
        'conversation_id': 'conv-123',
        'sender_id': 'user-123',
        'content': 'Sent attachment',
        'file_url': 'https://example.com/doc.pdf',
        'created_at': DateTime.now().toIso8601String(),
      };

      final message = Message.fromJson(json);

      expect(message.messageType, MessageType.document);
      expect(message.mediaUrl, 'https://example.com/doc.pdf');
    });
  });
}
