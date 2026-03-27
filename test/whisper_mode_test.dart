import 'package:flutter_test/flutter_test.dart';
import 'package:oasis_v2/models/message.dart';
import 'package:oasis_v2/services/messaging_service.dart';

void main() {
  group('Whisper Mode Vanish on Reopen Logic', () {
    Message createEphemeralMessage({
      required String id,
      required DateTime? anyReadAt,
    }) {
      return Message(
        id: id,
        conversationId: 'conv1',
        senderId: 'other_user',
        senderName: 'Other',
        senderAvatar: '',
        content: 'Whisper message',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isEphemeral: true,
        ephemeralDuration: 0, // Vanish Mode
        isRead: anyReadAt != null,
        readAt: anyReadAt,
        anyReadAt: anyReadAt,
      );
    }

    test('Messages seen BEFORE session start should be filtered out', () {
      final sessionStart = DateTime.now();
      final seenBefore = sessionStart.subtract(const Duration(seconds: 10));
      
      final msg = createEphemeralMessage(id: 'old', anyReadAt: seenBefore);
      
      final filtered = MessagingService.filterExpiredMessages(
        [msg],
        sessionStart: sessionStart,
      );
      
      expect(filtered, isEmpty, reason: 'Message seen in previous session should vanish');
    });

    test('Messages seen AFTER session start should stay visible', () {
      final sessionStart = DateTime.now().subtract(const Duration(seconds: 10));
      final seenAfter = DateTime.now();
      
      final msg = createEphemeralMessage(id: 'new', anyReadAt: seenAfter);
      
      final filtered = MessagingService.filterExpiredMessages(
        [msg],
        sessionStart: sessionStart,
      );
      
      expect(filtered.length, 1, reason: 'Message seen in current session should stay');
      expect(filtered.first.id, 'new');
    });

    test('Unread messages should always stay visible', () {
      final sessionStart = DateTime.now();
      
      final msg = createEphemeralMessage(id: 'unread', anyReadAt: null);
      
      final filtered = MessagingService.filterExpiredMessages(
        [msg],
        sessionStart: sessionStart,
      );
      
      expect(filtered.length, 1, reason: 'Unread messages should never be filtered');
    });
  });
}
