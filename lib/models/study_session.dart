class StudySession {
  final String id;
  final String title;
  final String creatorId;
  final DateTime startTime;
  final int durationMinutes;
  final String status; // active, completed, cancelled
  final bool isLockedIn;
  final DateTime createdAt;

  StudySession({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.startTime,
    required this.durationMinutes,
    this.status = 'active',
    this.isLockedIn = true,
    required this.createdAt,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String,
      title: json['title'] as String,
      creatorId: json['creator_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      durationMinutes: json['duration_minutes'] as int,
      status: json['status'] as String? ?? 'active',
      isLockedIn: json['is_locked_in'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'creator_id': creatorId,
      'start_time': startTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'status': status,
      'is_locked_in': isLockedIn,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
