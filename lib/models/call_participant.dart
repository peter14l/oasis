class CallParticipant {
  final String id;
  final String callId;
  final String userId;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final bool isMmuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final String status; // invited, joined, left, declined
  final DateTime createdAt;

  CallParticipant({
    required this.id,
    required this.callId,
    required this.userId,
    this.joinedAt,
    this.leftAt,
    this.isMmuted = false,
    this.isVideoOn = true,
    this.isScreenSharing = false,
    this.status = 'invited',
    required this.createdAt,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      id: json['id'] as String,
      callId: json['call_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at'] as String) : null,
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at'] as String) : null,
      isMmuted: json['is_muted'] as bool? ?? false,
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
      'is_muted': isMmuted,
      'is_video_on': isVideoOn,
      'is_screen_sharing': isScreenSharing,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
