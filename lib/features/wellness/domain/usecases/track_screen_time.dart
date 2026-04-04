import '../models/wellness_entity.dart';
import '../repositories/wellness_repository.dart';

/// Use case for tracking screen time and usage data
class TrackScreenTime {
  final WellnessRepository _repository;

  TrackScreenTime(this._repository);

  /// Get screen time data for a specific date
  Future<ScreenTimeEntity> getScreenTimeData(DateTime date) {
    return _repository.getScreenTimeData(date);
  }

  /// Get weekly usage data
  Future<List<Map<String, dynamic>>> getWeeklyData() {
    return _repository.getWeeklyData();
  }

  /// Get average daily usage over the last 7 days
  Future<int> getWeeklyAverage() {
    return _repository.getWeeklyAverage();
  }

  /// Get category breakdown for usage
  Future<List<Map<String, dynamic>>> getCategoryUsage(int totalMinutes) {
    return _repository.getCategoryUsage(totalMinutes);
  }

  /// Record time spent on a specific category
  Future<void> recordScreenTime(String category, int minutes) {
    return _repository.recordScreenTime(category, minutes);
  }

  /// Start tracking a new session
  Future<void> startTracking() {
    return _repository.startTracking();
  }

  /// Stop tracking the current session
  Future<void> stopTracking() {
    return _repository.stopTracking();
  }

  /// Set current active screen category
  void setCurrentCategory(String? category) {
    _repository.setCurrentCategory(category);
  }

  /// Get current session elapsed time in seconds
  int get currentSessionSeconds => _repository.currentSessionElapsedSeconds;

  /// Get current wellness streak
  int get wellnessStreak => _repository.wellnessStreak;
}
