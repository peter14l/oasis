/// Wellness achievement types
enum AchievementType {
  streak('streak', '🔥'),
  milestone('milestone', '🏆'),
  challenge('challenge', '💪'),
  balance('balance', '⚖️');

  final String value;
  final String emoji;
  const AchievementType(this.value, this.emoji);
}

/// Domain entity for a wellness achievement/badge
class WellnessAchievementEntity {
  final String id;
  final AchievementType type;
  final String name;
  final String description;
  final String icon;
  final DateTime earnedAt;
  final int? value;

  const WellnessAchievementEntity({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedAt,
    this.value,
  });

  factory WellnessAchievementEntity.fromJson(Map<String, dynamic> json) {
    return WellnessAchievementEntity(
      id: json['id'],
      type: AchievementType.values.firstWhere(
        (t) => t.value == json['achievement_type'],
        orElse: () => AchievementType.milestone,
      ),
      name: json['achievement_name'],
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏅',
      earnedAt: DateTime.parse(json['earned_at']),
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'achievement_type': type.value,
      'achievement_name': name,
      'description': description,
      'icon': icon,
      'earned_at': earnedAt.toIso8601String(),
      'value': value,
    };
  }

  WellnessAchievementEntity copyWith({
    String? id,
    AchievementType? type,
    String? name,
    String? description,
    String? icon,
    DateTime? earnedAt,
    int? value,
  }) {
    return WellnessAchievementEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      earnedAt: earnedAt ?? this.earnedAt,
      value: value ?? this.value,
    );
  }
}

/// Domain entity for wellness statistics
class WellnessStatsEntity {
  final int totalXp;
  final int focusSessionsCompleted;
  final int currentStreak;
  final int dailyGoalMinutes;
  final List<WellnessAchievementEntity> achievements;

  const WellnessStatsEntity({
    required this.totalXp,
    required this.focusSessionsCompleted,
    required this.currentStreak,
    required this.dailyGoalMinutes,
    required this.achievements,
  });

  factory WellnessStatsEntity.empty() {
    return const WellnessStatsEntity(
      totalXp: 0,
      focusSessionsCompleted: 0,
      currentStreak: 0,
      dailyGoalMinutes: 60,
      achievements: [],
    );
  }

  WellnessStatsEntity copyWith({
    int? totalXp,
    int? focusSessionsCompleted,
    int? currentStreak,
    int? dailyGoalMinutes,
    List<WellnessAchievementEntity>? achievements,
  }) {
    return WellnessStatsEntity(
      totalXp: totalXp ?? this.totalXp,
      focusSessionsCompleted:
          focusSessionsCompleted ?? this.focusSessionsCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      achievements: achievements ?? this.achievements,
    );
  }
}

/// Domain entity for screen time data
class ScreenTimeEntity {
  final int totalMinutesToday;
  final int weeklyAverageMinutes;
  final List<Map<String, dynamic>> weeklyData;
  final List<Map<String, dynamic>> categoryUsage;
  final Map<int, int> hourlyBreakdown;
  final int currentSessionSeconds;
  final int wellnessStreak;

  const ScreenTimeEntity({
    required this.totalMinutesToday,
    required this.weeklyAverageMinutes,
    required this.weeklyData,
    required this.categoryUsage,
    required this.hourlyBreakdown,
    required this.currentSessionSeconds,
    required this.wellnessStreak,
  });

  factory ScreenTimeEntity.empty() {
    return ScreenTimeEntity(
      totalMinutesToday: 0,
      weeklyAverageMinutes: 0,
      weeklyData: [],
      categoryUsage: [],
      hourlyBreakdown: {},
      currentSessionSeconds: 0,
      wellnessStreak: 0,
    );
  }

  ScreenTimeEntity copyWith({
    int? totalMinutesToday,
    int? weeklyAverageMinutes,
    List<Map<String, dynamic>>? weeklyData,
    List<Map<String, dynamic>>? categoryUsage,
    Map<int, int>? hourlyBreakdown,
    int? currentSessionSeconds,
    int? wellnessStreak,
  }) {
    return ScreenTimeEntity(
      totalMinutesToday: totalMinutesToday ?? this.totalMinutesToday,
      weeklyAverageMinutes: weeklyAverageMinutes ?? this.weeklyAverageMinutes,
      weeklyData: weeklyData ?? this.weeklyData,
      categoryUsage: categoryUsage ?? this.categoryUsage,
      hourlyBreakdown: hourlyBreakdown ?? this.hourlyBreakdown,
      currentSessionSeconds:
          currentSessionSeconds ?? this.currentSessionSeconds,
      wellnessStreak: wellnessStreak ?? this.wellnessStreak,
    );
  }
}
