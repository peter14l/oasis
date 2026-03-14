enum CallStatus { pinging, active, ended, missed, rejected }

enum CallType { voice, video }

class Call {
  final String id;
  final String conversationId;
  final String hostId;
  final String channelName;
  final CallStatus status;
  final CallType type;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? agoraToken;
  final DateTime createdAt;

  Call({
    required this.id,
    required this.conversationId,
    required this.hostId,
    required this.channelName,
    this.status = CallStatus.pinging,
    this.type = CallType.voice,
    required this.startedAt,
    this.endedAt,
    this.agoraToken,
    required this.createdAt,
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      hostId: json['host_id'] as String,
      channelName: json['channel_name'] as String,
      status: CallStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CallStatus.pinging,
      ),
      type: CallType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CallType.voice,
      ),
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
      agoraToken: json['agora_token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'host_id': hostId,
      'channel_name': channelName,
      'status': status.name,
      'type': type.name,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'agora_token': agoraToken,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Call copyWith({
    CallStatus? status,
    DateTime? endedAt,
    String? agoraToken,
  }) {
    return Call(
      id: id,
      conversationId: conversationId,
      hostId: hostId,
      channelName: channelName,
      status: status ?? this.status,
      type: type,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      agoraToken: agoraToken ?? this.agoraToken,
      createdAt: createdAt,
    );
  }
}
