/// Call status state machine.
enum CallStatus { ringing, active, ended, declined, missed }

/// Call kind.
enum CallType { voice, video }

/// One ringing attempt: a caller invited one receiver into a LiveKit room.
///
/// Multi-party calls are additional [Call] rows sharing the same [roomName].
/// There is no E2EE offer column — media is protected by LiveKit DTLS-SRTP
/// plus per-call access tokens.
class Call {
  final String id;
  final String conversationId;
  final String callerId;
  final String receiverId;
  final CallStatus status;
  final CallType type;
  final String roomName;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  const Call({
    required this.id,
    required this.conversationId,
    required this.callerId,
    required this.receiverId,
    this.status = CallStatus.ringing,
    this.type = CallType.voice,
    required this.roomName,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
  });

  factory Call.fromRow(Map<String, dynamic> row) {
    return Call(
      id: row['id'] as String,
      conversationId: row['conversation_id'] as String,
      callerId: row['caller_id'] as String,
      receiverId: row['receiver_id'] as String,
      status: CallStatus.values.firstWhere(
        (e) => e.name == row['status'],
        orElse: () => CallStatus.ringing,
      ),
      type: CallType.values.firstWhere(
        (e) => e.name == row['type'],
        orElse: () => CallType.voice,
      ),
      roomName: row['room_name'] as String? ?? row['id'] as String,
      startedAt: row['started_at'] != null
          ? DateTime.tryParse(row['started_at'] as String)
          : null,
      endedAt: row['ended_at'] != null
          ? DateTime.tryParse(row['ended_at'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'conversation_id': conversationId,
      'caller_id': callerId,
      'receiver_id': receiverId,
      'status': status.name,
      'type': type.name,
      'room_name': roomName,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
    };
  }

  Call copyWith({
    CallStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return Call(
      id: id,
      conversationId: conversationId,
      callerId: callerId,
      receiverId: receiverId,
      status: status ?? this.status,
      type: type,
      roomName: roomName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt,
    );
  }

  bool isStale({Duration maxAge = const Duration(seconds: 45)}) {
    return DateTime.now().toUtc().difference(createdAt.toUtc()) > maxAge;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Call &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conversationId == other.conversationId &&
          callerId == other.callerId &&
          receiverId == other.receiverId &&
          status == other.status &&
          type == other.type &&
          roomName == other.roomName &&
          startedAt == other.startedAt &&
          endedAt == other.endedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      conversationId.hashCode ^
      callerId.hashCode ^
      receiverId.hashCode ^
      status.hashCode ^
      type.hashCode ^
      roomName.hashCode ^
      startedAt.hashCode ^
      endedAt.hashCode ^
      createdAt.hashCode;
}
