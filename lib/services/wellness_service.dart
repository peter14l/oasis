import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morrow_v2/services/supabase_service.dart';

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

/// Model for a wellness achievement/badge
class WellnessAchievement {
  final String id;
  final AchievementType type;
  final String name;
  final String description;
  final String icon;
  final DateTime earnedAt;
  final int? value; // e.g., streak count

  WellnessAchievement({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedAt,
    this.value,
  });

  factory WellnessAchievement.fromJson(Map<String, dynamic> json) {
    return WellnessAchievement(
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
}

/// Enhanced wellness service with focus mode, wind-down, and achievements
class WellnessService extends ChangeNotifier {
  static const String _focusModeKey = 'focus_mode_enabled';
  static const String _focusModeScheduleKey = 'focus_mode_schedule';
  static const String _windDownEnabledKey = 'wind_down_enabled';
  static const String _windDownTimeKey = 'wind_down_time';
  static const String _blockedFeaturesKey = 'focus_blocked_features';
  static const String _dailyGoalKey = 'daily_usage_goal';
  static const String _achievementsKey = 'wellness_achievements';

  final SharedPreferences _prefs;
  Timer? _windDownTimer;

  // Focus Mode
  bool _focusModeEnabled = false;
  Map<String, bool> _focusSchedule = {};
  Set<String> _blockedFeatures = {};

  // Wind Down Mode
  bool _windDownEnabled = false;
  TimeOfDay? _windDownTime;
  bool _isWindDownActive = false;
  double _windDownDimLevel = 0;

  // Goals & Achievements
  int _dailyGoalMinutes = 60;
  List<WellnessAchievement> _achievements = [];

  WellnessService(this._prefs) {
    _loadSettings();
    _startWindDownMonitor();
  }

  bool _isUserPro() {
    final user = SupabaseService().client.auth.currentUser;
    return user?.userMetadata?['is_pro'] == true;
  }

  // Getters
  bool get focusModeEnabled => _focusModeEnabled;
  Map<String, bool> get focusSchedule => _focusSchedule;
  Set<String> get blockedFeatures => _blockedFeatures;
  bool get windDownEnabled => _windDownEnabled;
  TimeOfDay? get windDownTime => _windDownTime;
  bool get isWindDownActive => _isWindDownActive;
  double get windDownDimLevel => _windDownDimLevel;
  int get dailyGoalMinutes => _dailyGoalMinutes;
  List<WellnessAchievement> get achievements => _achievements;

  static Future<WellnessService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return WellnessService(prefs);
  }

  void _loadSettings() {
    _focusModeEnabled = _prefs.getBool(_focusModeKey) ?? false;

    final scheduleJson = _prefs.getString(_focusModeScheduleKey);
    if (scheduleJson != null) {
      final decoded = jsonDecode(scheduleJson) as Map<String, dynamic>;
      _focusSchedule = decoded.map((k, v) => MapEntry(k, v as bool));
    }

    final blockedJson = _prefs.getStringList(_blockedFeaturesKey);
    if (blockedJson != null) {
      _blockedFeatures = blockedJson.toSet();
    }

    _windDownEnabled = _prefs.getBool(_windDownEnabledKey) ?? false;
    final windDownStr = _prefs.getString(_windDownTimeKey);
    if (windDownStr != null) {
      final parts = windDownStr.split(':');
      _windDownTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    _dailyGoalMinutes = _prefs.getInt(_dailyGoalKey) ?? 60;

    final achievementsJson = _prefs.getString(_achievementsKey);
    if (achievementsJson != null) {
      final List decoded = jsonDecode(achievementsJson);
      _achievements =
          decoded.map((a) => WellnessAchievement.fromJson(a)).toList();
    }

    notifyListeners();
  }

  // Focus Mode methods
  Future<void> setFocusModeEnabled(bool enabled) async {
    _focusModeEnabled = enabled;
    await _prefs.setBool(_focusModeKey, enabled);
    notifyListeners();
  }

  Future<void> setBlockedFeatures(Set<String> features) async {
    if (!_isUserPro()) {
      throw Exception('Upgrade to Morrow Pro to customize Focus Mode blocklist.');
    }
    _blockedFeatures = features;
    await _prefs.setStringList(_blockedFeaturesKey, features.toList());
    notifyListeners();
  }

  bool isFeatureBlocked(String feature) {
    if (!_focusModeEnabled) return false;
    return _blockedFeatures.contains(feature);
  }

  // Available features that can be blocked
  static const List<Map<String, String>> blockableFeatures = [
    {'id': 'feed', 'name': 'Feed', 'icon': 'feed'},
    {'id': 'stories', 'name': 'Stories', 'icon': 'amp_stories'},
    {'id': 'messages', 'name': 'Messages', 'icon': 'chat'},
    {'id': 'communities', 'name': 'Communities', 'icon': 'groups'},
    {'id': 'notifications', 'name': 'Notifications', 'icon': 'notifications'},
    {'id': 'search', 'name': 'Search', 'icon': 'search'},
  ];

  // Wind Down methods
  Future<void> setWindDownEnabled(bool enabled) async {
    if (enabled && !_isUserPro()) {
      throw Exception('Upgrade to Morrow Pro to enable Wind-down mode.');
    }
    _windDownEnabled = enabled;
    await _prefs.setBool(_windDownEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setWindDownTime(TimeOfDay time) async {
    _windDownTime = time;
    await _prefs.setString(_windDownTimeKey, '${time.hour}:${time.minute}');
    notifyListeners();
  }

  void _startWindDownMonitor() {
    _windDownTimer?.cancel();
    _windDownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkWindDown();
    });
  }

  void _checkWindDown() {
    if (!_windDownEnabled || _windDownTime == null) {
      if (_isWindDownActive) {
        _isWindDownActive = false;
        _windDownDimLevel = 0;
        notifyListeners();
      }
      return;
    }

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final windDownMinutes = _windDownTime!.hour * 60 + _windDownTime!.minute;

    // Check if we're past wind-down time (until midnight)
    if (nowMinutes >= windDownMinutes) {
      // Calculate dim level based on how far past wind-down time
      // Max dim at 2 hours after wind-down time
      final minutesPast = nowMinutes - windDownMinutes;
      _windDownDimLevel = (minutesPast / 120).clamp(0.0, 0.3);
      _isWindDownActive = true;
    } else {
      _isWindDownActive = false;
      _windDownDimLevel = 0;
    }

    notifyListeners();
  }

  // Daily goal methods
  Future<void> setDailyGoal(int minutes) async {
    _dailyGoalMinutes = minutes;
    await _prefs.setInt(_dailyGoalKey, minutes);
    notifyListeners();
  }

  // Achievement methods
  Future<void> checkAndAwardAchievements(
    int currentStreak,
    int todayMinutes,
  ) async {
    final newAchievements = <WellnessAchievement>[];

    // Streak achievements (Pro feature)
    if (_isUserPro()) {
      final streakMilestones = [3, 7, 14, 30, 60, 100, 365];
      for (final milestone in streakMilestones) {
        if (currentStreak >= milestone) {
          final existingIndex = _achievements.indexWhere(
            (a) => a.type == AchievementType.streak && a.value == milestone,
          );
          if (existingIndex == -1) {
            newAchievements.add(
              WellnessAchievement(
                id: 'streak_$milestone',
                type: AchievementType.streak,
                name: '$milestone Day Streak',
                description:
                    'Maintained healthy screen time for $milestone days!',
                icon: '🔥',
                earnedAt: DateTime.now(),
                value: milestone,
              ),
            );
          }
        }
      }
    }

    // Under-goal achievement for today
    if (todayMinutes <= _dailyGoalMinutes && todayMinutes > 0) {
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final existingIndex = _achievements.indexWhere(
        (a) => a.type == AchievementType.balance && a.id == 'balance_$todayKey',
      );
      if (existingIndex == -1) {
        newAchievements.add(
          WellnessAchievement(
            id: 'balance_$todayKey',
            type: AchievementType.balance,
            name: 'Balanced Day',
            description: 'Stayed under your daily goal! Great job!',
            icon: '⚖️',
            earnedAt: DateTime.now(),
          ),
        );
      }
    }

    if (newAchievements.isNotEmpty) {
      _achievements.addAll(newAchievements);
      await _saveAchievements();
      notifyListeners();
    }
  }

  Future<void> _saveAchievements() async {
    final json = jsonEncode(
      _achievements
          .map(
            (a) => {
              'id': a.id,
              'achievement_type': a.type.value,
              'achievement_name': a.name,
              'description': a.description,
              'icon': a.icon,
              'earned_at': a.earnedAt.toIso8601String(),
              'value': a.value,
            },
          )
          .toList(),
    );
    await _prefs.setString(_achievementsKey, json);
  }

  // Weekly report data
  Map<String, dynamic> generateWeeklyReport(
    List<Map<String, dynamic>> weeklyData,
  ) {
    if (!_isUserPro()) {
      throw Exception('Upgrade to Morrow Pro to generate Wellness Weekly Reports.');
    }
    if (weeklyData.isEmpty) {
      return {
        'totalMinutes': 0,
        'averageMinutes': 0,
        'daysUnderGoal': 0,
        'bestDay': null,
        'trend': 'stable',
      };
    }

    int totalMinutes = 0;
    int daysUnderGoal = 0;
    String? bestDay;
    int lowestMinutes = 9999;

    for (final day in weeklyData) {
      final minutes = day['minutes'] as int;
      totalMinutes += minutes;
      if (minutes <= _dailyGoalMinutes && minutes > 0) {
        daysUnderGoal++;
      }
      if (minutes < lowestMinutes && minutes > 0) {
        lowestMinutes = minutes;
        bestDay = day['day'];
      }
    }

    final averageMinutes = (totalMinutes / weeklyData.length).round();

    // Calculate trend
    String trend = 'stable';
    if (weeklyData.length >= 3) {
      final recentAvg =
          (weeklyData
                      .sublist(0, 3)
                      .fold<int>(0, (sum, d) => sum + (d['minutes'] as int)) /
                  3)
              .round();
      final olderAvg =
          (weeklyData
                      .sublist(3)
                      .fold<int>(0, (sum, d) => sum + (d['minutes'] as int)) /
                  weeklyData.sublist(3).length)
              .round();

      if (recentAvg < olderAvg - 10) {
        trend = 'improving';
      } else if (recentAvg > olderAvg + 10) {
        trend = 'increasing';
      }
    }

    return {
      'totalMinutes': totalMinutes,
      'averageMinutes': averageMinutes,
      'daysUnderGoal': daysUnderGoal,
      'bestDay': bestDay,
      'trend': trend,
    };
  }

  @override
  void dispose() {
    _windDownTimer?.cancel();
    super.dispose();
  }
}
