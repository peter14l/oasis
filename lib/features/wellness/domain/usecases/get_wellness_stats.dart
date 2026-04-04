import '../models/wellness_entity.dart';
import '../repositories/wellness_repository.dart';

/// Use case for retrieving wellness statistics and achievements
class GetWellnessStats {
  final WellnessRepository _repository;

  GetWellnessStats(this._repository);

  /// Get complete wellness stats
  Future<WellnessStatsEntity> getWellnessStats() {
    return _repository.getWellnessStats();
  }

  /// Get all achievements
  List<WellnessAchievementEntity> getAchievements() {
    return _repository.achievements;
  }

  /// Get daily goal in minutes
  int get dailyGoalMinutes => _repository.dailyGoalMinutes;

  /// Check if focus mode is enabled
  bool get focusModeEnabled => _repository.focusModeEnabled;

  /// Get focus mode progress (0.0 - 1.0)
  double get focusProgress => _repository.focusProgress;

  /// Get remaining focus time in seconds
  int get focusRemainingSeconds => _repository.focusRemainingSeconds;

  /// Get current wellness streak
  Future<int> getWellnessStreak() {
    return _repository.getWellnessStreak();
  }

  /// Check if wind down mode is active
  bool get isWindDownActive => _repository.isWindDownActive;

  /// Get wind down dim level (0.0 - 0.3)
  double get windDownDimLevel => _repository.windDownDimLevel;

  /// Get quiet mode status
  bool get isQuietModeActive => _repository.isQuietModeActive;

  /// Get total XP
  Future<int> getTotalXp() async {
    final stats = await _repository.getWellnessStats();
    return stats.totalXp;
  }

  /// Check if a feature is blocked by focus mode
  bool isFeatureBlocked(String feature) {
    return _repository.isFeatureBlocked(feature);
  }

  /// Check and award new achievements based on current usage
  Future<void> checkAndAwardAchievements(int currentStreak, int todayMinutes) {
    return _repository.checkAndAwardAchievements(currentStreak, todayMinutes);
  }
}
