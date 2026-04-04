import '../models/energy_meter_entity.dart';
import '../models/wellness_entity.dart';

/// Abstract repository interface for wellness operations
/// Defines contracts for screen time, energy meter, and wellness achievements
abstract class WellnessRepository {
  // Energy Meter operations
  Future<EnergyMeterEntity> getEnergyMeterState();
  Future<void> saveEnergyMeterState(EnergyMeterEntity state);
  Future<bool> deductEnergy(InteractionType type);
  Future<void> forceEnergyRecovery();
  Future<void> resetEnergy();

  // Screen Time operations
  Future<ScreenTimeEntity> getScreenTimeData(DateTime date);
  Future<List<Map<String, dynamic>>> getWeeklyData();
  Future<int> getWeeklyAverage();
  Future<List<Map<String, dynamic>>> getCategoryUsage(int totalMinutes);
  Future<void> recordScreenTime(String category, int minutes);
  Future<void> startTracking();
  Future<void> stopTracking();
  void setCurrentCategory(String? category);
  int get currentSessionElapsedSeconds;
  Future<int> getWellnessStreak();

  // Focus Mode operations
  Future<void> setFocusModeEnabled(bool enabled);
  Future<void> setBlockedFeatures(Set<String> features);
  bool isFeatureBlocked(String feature);
  bool get focusModeEnabled;
  int get focusRemainingSeconds;
  double get focusProgress;
  Map<String, bool> get focusSchedule;
  Set<String> get blockedFeatures;

  // Wind Down Mode operations
  Future<void> setWindDownEnabled(bool enabled);
  Future<void> setWindDownTime(int hour, int minute);
  bool get windDownEnabled;
  bool get isWindDownActive;
  double get windDownDimLevel;

  // Daily Goal operations
  Future<void> setDailyGoal(int minutes);
  int get dailyGoalMinutes;

  // Wellness Stats
  Future<WellnessStatsEntity> getWellnessStats();
  Future<void> checkAndAwardAchievements(int currentStreak, int todayMinutes);
  List<WellnessAchievementEntity> get achievements;

  // XP operations
  Future<void> updateUserXP(int amount);

  // Quiet Mode
  Future<void> setQuietMode(bool enabled);
  Future<void> setQuietModeHours(
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  );
  bool get isQuietModeEnabled;
  bool get isQuietModeActive;

  // Lifecycle
  void onPaused();
  void onResumed();
}
