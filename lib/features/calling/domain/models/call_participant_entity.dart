/// Domain entity representing a participant in a call
class CallParticipantEntity {
  final String id;
  final String callId;
  final String userId;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final String status;
  final DateTime createdAt;

  const CallParticipantEntity({
    required this.id,
    required this.callId,
    required this.userId,
    this.joinedAt,
    this.leftAt,
    this.isMuted = false,
    this.isVideoOn = true,
    this.isScreenSharing = false,
    this.status = 'invited',
    required this.createdAt,
  });

  factory CallParticipantEntity.fromJson(Map<String, dynamic> json) {
    return CallParticipantEntity(
      id: json['id'] as String,
      callId: json['call_id'] as String,
      userId: json['user_id'] as String,
      joinedAt:
          json['joined_at'] != null
              ? DateTime.parse(json['joined_at'] as String)
              : null,
      leftAt:
          json['left_at'] != null
              ? DateTime.parse(json['left_at'] as String)
              : null,
      isMuted: json['is_muted'] as bool? ?? false,
      isVideoOn: json['is_video_on'] as bool? ?? true,
      isScreenSharing: json['is_screen_sharing'] as bool? ?? false,
      status: json['status'] as String? ?? 'invited',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'call_id': callId,
      'user_id': userId,
      'joined_at': joinedAt?.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'is_muted': isMuted,
      'is_video_on': isVideoOn,
      'is_screen_sharing': isScreenSharing,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CallParticipantEntity copyWith({
    String? id,
    String? callId,
    String? userId,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isMuted,
    bool? isVideoOn,
    bool? isScreenSharing,
    String? status,
    DateTime? createdAt,
  }) {
    return CallParticipantEntity(
      id: id ?? this.id,
      callId: callId ?? this.callId,
      userId: userId ?? this.userId,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      isMuted: isMuted ?? this.isMuted,
      isVideoOn: isVideoOn ?? this.isVideoOn,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isInvited => status == 'invited';
  bool get isJoined => status == 'joined';
  bool get isLeft => status == 'left';
  bool get isDeclined => status == 'declined';
  bool get isActive => joinedAt != null && leftAt == null;
}
