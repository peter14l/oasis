import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/features/calling/call.dart';

void main() {
  Map<String, dynamic> row({
    String id = 'c1',
    String status = 'ringing',
    String type = 'voice',
    String? roomName,
    String? startedAt,
    String? endedAt,
    String createdAt = '2026-09-25T10:00:00Z',
  }) {
    return {
      'id': id,
      'conversation_id': 'conv1',
      'caller_id': 'u1',
      'receiver_id': 'u2',
      'status': status,
      'type': type,
      if (roomName != null) 'room_name': roomName,
      'started_at': startedAt,
      'ended_at': endedAt,
      'created_at': createdAt,
    };
  }

  group('Call.fromRow', () {
    test('parses all columns', () {
      final call = Call.fromRow(row(
        status: 'active',
        type: 'video',
        roomName: 'room_abc',
        startedAt: '2026-09-25T10:00:05Z',
        endedAt: '2026-09-25T10:05:00Z',
      ));
      expect(call.id, 'c1');
      expect(call.conversationId, 'conv1');
      expect(call.callerId, 'u1');
      expect(call.receiverId, 'u2');
      expect(call.status, CallStatus.active);
      expect(call.type, CallType.video);
      expect(call.roomName, 'room_abc');
      expect(call.startedAt, isNotNull);
      expect(call.endedAt, isNotNull);
    });

    test('falls back to id for missing room_name', () {
      expect(Call.fromRow(row()).roomName, 'c1');
    });

    test('falls back to ringing/voice for unknown enums', () {
      final call = Call.fromRow(row(status: 'weird', type: 'weird'));
      expect(call.status, CallStatus.ringing);
      expect(call.type, CallType.voice);
    });
  });

  group('Call.toInsert', () {
    test('serializes the insert columns', () {
      final call = Call(
        id: 'x',
        conversationId: 'conv1',
        callerId: 'u1',
        receiverId: 'u2',
        status: CallStatus.ringing,
        type: CallType.video,
        roomName: 'room1',
        createdAt: DateTime.utc(2026),
      );
      expect(call.toInsert(), {
        'conversation_id': 'conv1',
        'caller_id': 'u1',
        'receiver_id': 'u2',
        'status': 'ringing',
        'type': 'video',
        'room_name': 'room1',
      });
    });
  });

  group('copyWith / equality', () {
    test('copyWith changes only requested fields', () {
      final a = Call.fromRow(row());
      final b = a.copyWith(status: CallStatus.active);
      expect(a.status, CallStatus.ringing);
      expect(b.status, CallStatus.active);
      expect(b.id, a.id);
      expect(b.roomName, a.roomName);
    });

    test('value equality and hashCode', () {
      final a = Call.fromRow(row());
      final b = Call.fromRow(row());
      final c = Call.fromRow(row(id: 'c2'));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a.copyWith(status: CallStatus.ended) == a, isFalse);
    });
  });

  group('isStale', () {
    test('young rows are not stale', () {
      final call = Call.fromRow(row(
        createdAt: DateTime.now().toUtc().subtract(const Duration(seconds: 10)).toIso8601String(),
      ));
      expect(call.isStale(), isFalse);
    });

    test('rows older than maxAge are stale', () {
      final call = Call.fromRow(row(
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)).toIso8601String(),
      ));
      expect(call.isStale(), isTrue);
    });
  });
}
