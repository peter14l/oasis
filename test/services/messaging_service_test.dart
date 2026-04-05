import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/features/messages/domain/models/message.dart';
import 'package:oasis/services/messaging_service.dart';

void main() {
  group('Whisper Mode Logic', () {
    Message createMessage({
      required String id,
      bool isEphemeral = false,
      DateTime? timestamp,
      DateTime? readAt,
      DateTime? anyReadAt,
      bool isRead = false,
      int ephemeralDuration = 86400,
    }) {
      return Message(
        id: id,
        conversationId: 'conv1',
        senderId: 'user1',
        senderName: 'User 1',
        senderAvatar: '',
        content: 'Test content',
        timestamp: timestamp ?? DateTime.now(),
        isEphemeral: isEphemeral,
        ephemeralDuration: ephemeralDuration,
        isRead: isRead,
        readAt: readAt,
        anyReadAt: anyReadAt ?? readAt, // Default to readAt if not provided
      );
    }

    test('Should identify ephemeral messages', () {
      final msg = createMessage(id: '1', isEphemeral: true);
      expect(msg.isEphemeral, true);
    });

    test('Should filter out expired ephemeral messages (seen > 24h ago)', () {
      final now = DateTime.now();
      final seenLongAgo = now.subtract(const Duration(hours: 25));

      final msg = createMessage(
        id: '1',
        isEphemeral: true,
        isRead: true,
        readAt: seenLongAgo,
      );

      final filtered = MessagingService.filterExpiredMessages([msg]);
      expect(filtered, isEmpty);
    });

    test('Should keep ephemeral messages seen recently (< 24h)', () {
      final now = DateTime.now();
      final seenRecently = now.subtract(const Duration(hours: 23));

      final msg = createMessage(
        id: '1',
        isEphemeral: true,
        isRead: true,
        readAt: seenRecently,
      );

      final filtered = MessagingService.filterExpiredMessages([msg]);
      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('Should keep ephemeral messages NOT seen yet', () {
      final msg = createMessage(
        id: '1',
        isEphemeral: true,
        isRead: false,
        readAt: null,
      );

      final filtered = MessagingService.filterExpiredMessages([msg]);
      expect(filtered.length, 1);
    });

    test('Should keep normal messages seen > 24h ago', () {
      final now = DateTime.now();
      final seenLongAgo = now.subtract(const Duration(hours: 25));

      final msg = createMessage(
        id: '1',
        isEphemeral: false,
        isRead: true,
        readAt: seenLongAgo,
      );

      final filtered = MessagingService.filterExpiredMessages([msg]);
      expect(filtered.length, 1);
    });

    test(
      'Should vanish IMMEDIATE messages (duration=0) right after reading',
      () {
        final msg = createMessage(
          id: '1',
          isEphemeral: true,
          ephemeralDuration: 0,
          isRead: true,
          readAt: DateTime.now(), // Just read
        );

        final filtered = MessagingService.filterExpiredMessages([msg]);
        expect(filtered, isEmpty);
      },
    );

    test('Should keep IMMEDIATE messages (duration=0) if NOT read', () {
      final msg = createMessage(
        id: '1',
        isEphemeral: true,
        ephemeralDuration: 0,
        isRead: false,
        readAt: null,
      );

      final filtered = MessagingService.filterExpiredMessages([msg]);
      expect(filtered.length, 1);
    });
  });
}
