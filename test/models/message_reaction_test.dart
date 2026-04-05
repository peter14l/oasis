import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/features/messages/domain/models/message_reaction.dart';

void main() {
  group('MessageReactionModel Tests', () {
    test('fromJson should correctly parse message reaction with username', () {
      final json = {
        'id': '1',
        'message_id': 'm1',
        'user_id': 'u1',
        'username': 'testuser',
        'reaction': '❤️',
        'created_at': '2026-03-16T12:00:00Z',
      };

      final model = MessageReactionModel.fromJson(json);

      expect(model.id, '1');
      expect(model.messageId, 'm1');
      expect(model.userId, 'u1');
      expect(model.username, 'testuser');
      expect(model.reaction, '❤️');
    });

    test('fromJson should use default username if missing', () {
      final json = {
        'id': '1',
        'message_id': 'm1',
        'user_id': 'u1',
        'reaction': '❤️',
        'created_at': '2026-03-16T12:00:00Z',
      };

      final model = MessageReactionModel.fromJson(json);

      expect(model.username, 'Unknown');
    });

    test('toJson should correctly serialize message reaction', () {
      final model = MessageReactionModel(
        id: '1',
        messageId: 'm1',
        userId: 'u1',
        username: 'testuser',
        reaction: '❤️',
        createdAt: DateTime.parse('2026-03-16T12:00:00Z'),
      );

      final json = model.toJson();

      expect(json['id'], '1');
      expect(json['message_id'], 'm1');
      expect(json['user_id'], 'u1');
      expect(json['username'], 'testuser');
      expect(json['reaction'], '❤️');
    });
  });
}
