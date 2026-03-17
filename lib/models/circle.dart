class Circle {
  final String id;
  final String name;
  final String emoji;
  final String createdBy;
  final DateTime createdAt;
  final int streakCount;
  final List<String> memberIds;

  Circle({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdBy,
    required this.createdAt,
    this.streakCount = 0,
    required this.memberIds,
  });

  factory Circle.fromJson(Map<String, dynamic> json) {
    return Circle(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'My Circle',
      emoji: json['emoji'] as String? ?? '🌊',
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      streakCount: json['streak_count'] as int? ?? 0,
      memberIds: (json['member_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'streak_count': streakCount,
      'member_ids': memberIds,
    };
  }

  Circle copyWith({
    String? id,
    String? name,
    String? emoji,
    String? createdBy,
    DateTime? createdAt,
    int? streakCount,
    List<String>? memberIds,
  }) {
    return Circle(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      streakCount: streakCount ?? this.streakCount,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  bool get hasActiveStreak => streakCount > 0;
}
