class StudySessionParticipant {
  final String id;
  final String sessionId;
  final String userId;
  final DateTime joinedAt;
  final String exitStatus; // joined, completed, left_early
  final int xpEarned;

  StudySessionParticipant({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.joinedAt,
    this.exitStatus = 'joined',
    this.xpEarned = 0,
  });

  factory StudySessionParticipant.fromJson(Map<String, dynamic> json) {
    return StudySessionParticipant(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      exitStatus: json['exit_status'] as String? ?? 'joined',
      xpEarned: json['xp_earned'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
      'exit_status': exitStatus,
      'xp_earned': xpEarned,
    };
  }
}
