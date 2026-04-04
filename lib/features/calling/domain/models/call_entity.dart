/// Call status enum
enum CallStatus { pinging, active, ended, missed, rejected }

/// Call type enum
enum CallType { voice, video }

/// Domain entity representing a call
class CallEntity {
  final String id;
  final String conversationId;
  final String hostId;
  final String channelName;
  final CallStatus status;
  final CallType type;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? sdp;
  final String? sdpType;
  final List<Map<String, dynamic>>? iceCandidates;
  final String? agoraToken;
  final DateTime createdAt;

  const CallEntity({
    required this.id,
    required this.conversationId,
    required this.hostId,
    required this.channelName,
    this.status = CallStatus.pinging,
    this.type = CallType.voice,
    required this.startedAt,
    this.endedAt,
    this.agoraToken,
    this.sdp,
    this.sdpType,
    this.iceCandidates,
    required this.createdAt,
  });

  factory CallEntity.fromJson(Map<String, dynamic> json) {
    return CallEntity(
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
      endedAt:
          json['ended_at'] != null
              ? DateTime.parse(json['ended_at'] as String)
              : null,
      agoraToken: json['agora_token'] as String?,
      sdp: json['sdp'] as String?,
      sdpType: json['sdp_type'] as String?,
      iceCandidates:
          json['ice_candidates'] != null
              ? List<Map<String, dynamic>>.from(json['ice_candidates'] as List)
              : null,
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
      'sdp': sdp,
      'sdp_type': sdpType,
      'ice_candidates': iceCandidates,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CallEntity copyWith({
    String? id,
    String? conversationId,
    String? hostId,
    String? channelName,
    CallStatus? status,
    CallType? type,
    DateTime? startedAt,
    DateTime? endedAt,
    String? sdp,
    String? sdpType,
    List<Map<String, dynamic>>? iceCandidates,
    String? agoraToken,
    DateTime? createdAt,
  }) {
    return CallEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      hostId: hostId ?? this.hostId,
      channelName: channelName ?? this.channelName,
      status: status ?? this.status,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      sdp: sdp ?? this.sdp,
      sdpType: sdpType ?? this.sdpType,
      iceCandidates: iceCandidates ?? this.iceCandidates,
      agoraToken: agoraToken ?? this.agoraToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isActive => status == CallStatus.active;
  bool get isVoiceCall => type == CallType.voice;
  bool get isVideoCall => type == CallType.video;
  Duration? get duration =>
      endedAt != null ? endedAt!.difference(startedAt) : null;
}
