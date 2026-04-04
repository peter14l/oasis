import 'package:flutter/foundation.dart';
import '../../domain/models/energy_meter_entity.dart';
import '../../domain/models/wellness_entity.dart';
import '../../domain/usecases/track_screen_time.dart';
import '../../domain/usecases/get_wellness_stats.dart';
import '../../domain/usecases/manage_energy_meter.dart';

/// Immutable state for wellness feature
class WellnessState {
  final EnergyMeterEntity? energyMeter;
  final ScreenTimeEntity? screenTime;
  final WellnessStatsEntity? stats;
  final bool isLoading;
  final String? error;
  final bool focusModeEnabled;
  final int focusRemainingSeconds;
  final double focusProgress;
  final bool windDownEnabled;
  final bool isWindDownActive;
  final double windDownDimLevel;

  const WellnessState({
    this.energyMeter,
    this.screenTime,
    this.stats,
    this.isLoading = false,
    this.error,
    this.focusModeEnabled = false,
    this.focusRemainingSeconds = 0,
    this.focusProgress = 0.0,
    this.windDownEnabled = false,
    this.isWindDownActive = false,
    this.windDownDimLevel = 0.0,
  });

  factory WellnessState.initial() {
    return const WellnessState(isLoading: true);
  }

  WellnessState copyWith({
    EnergyMeterEntity? energyMeter,
    ScreenTimeEntity? screenTime,
    WellnessStatsEntity? stats,
    bool? isLoading,
    String? error,
    bool? focusModeEnabled,
    int? focusRemainingSeconds,
    double? focusProgress,
    bool? windDownEnabled,
    bool? isWindDownActive,
    double? windDownDimLevel,
  }) {
    return WellnessState(
      energyMeter: energyMeter ?? this.energyMeter,
      screenTime: screenTime ?? this.screenTime,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
      focusRemainingSeconds:
          focusRemainingSeconds ?? this.focusRemainingSeconds,
      focusProgress: focusProgress ?? this.focusProgress,
      windDownEnabled: windDownEnabled ?? this.windDownEnabled,
      isWindDownActive: isWindDownActive ?? this.isWindDownActive,
      windDownDimLevel: windDownDimLevel ?? this.windDownDimLevel,
    );
  }
}

/// Provider for wellness state management
/// Combines screen time, energy meter, and wellness tracking
class WellnessProvider extends ChangeNotifier {
  late final TrackScreenTime _trackScreenTime;
  late final GetWellnessStats _getWellnessStats;
  late final ManageEnergyMeter _manageEnergyMeter;

  WellnessState _state = WellnessState.initial();

  WellnessState get state => _state;

  // Getters for convenience
  EnergyMeterEntity? get energyMeter => _state.energyMeter;
  ScreenTimeEntity? get screenTime => _state.screenTime;
  WellnessStatsEntity? get stats => _state.stats;
  bool get focusModeEnabled => _state.focusModeEnabled;
  int get focusRemainingSeconds => _state.focusRemainingSeconds;
  double get focusProgress => _state.focusProgress;
  int get dailyGoalMinutes => _state.stats?.dailyGoalMinutes ?? 60;
  List<WellnessAchievementEntity> get achievements =>
      _state.stats?.achievements ?? [];

  Future<void> initialize() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      // Initialize use cases (would be injected in real app)
      // For now, just load initial state
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  // Screen Time methods
  Future<void> loadScreenTimeData(DateTime date) async {
    try {
      final data = await _trackScreenTime.getScreenTimeData(date);
      _state = _state.copyWith(screenTime: data);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyData() {
    return _trackScreenTime.getWeeklyData();
  }

  Future<int> getWeeklyAverage() {
    return _trackScreenTime.getWeeklyAverage();
  }

  Future<List<Map<String, dynamic>>> getCategoryUsage(int totalMinutes) {
    return _trackScreenTime.getCategoryUsage(totalMinutes);
  }

  void setCurrentCategory(String? category) {
    _trackScreenTime.setCurrentCategory(category);
  }

  int get currentSessionSeconds => _trackScreenTime.currentSessionSeconds;

  int get wellnessStreak => _trackScreenTime.wellnessStreak;

  // Energy Meter methods
  Future<void> loadEnergyMeterState() async {
    try {
      final state = await _manageEnergyMeter.getEnergyMeterState();
      _state = _state.copyWith(energyMeter: state);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  Future<bool> deductEnergy(InteractionType type) async {
    try {
      final success = await _manageEnergyMeter.deductEnergy(type);
      if (success) {
        await loadEnergyMeterState();
      }
      return success;
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<void> forceEnergyRecovery() async {
    await _manageEnergyMeter.forceRecovery();
    await loadEnergyMeterState();
  }

  Future<void> resetEnergy() async {
    await _manageEnergyMeter.resetEnergy();
    await loadEnergyMeterState();
  }

  // Focus Mode
  Future<void> setFocusModeEnabled(bool enabled) async {
    try {
      _state = _state.copyWith(focusModeEnabled: enabled);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  // Wind Down
  Future<void> setWindDownEnabled(bool enabled) async {
    try {
      _state = _state.copyWith(windDownEnabled: enabled);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  // Daily Goal
  Future<void> setDailyGoal(int minutes) async {
    try {
      // Would call repository
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  // Wellness Stats
  Future<void> loadWellnessStats() async {
    try {
      final stats = await _getWellnessStats.getWellnessStats();
      _state = _state.copyWith(stats: stats);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  // Lifecycle
  void onPaused() {
    _manageEnergyMeter.onPaused();
  }

  void onResumed() {
    _manageEnergyMeter.onResumed();
    loadEnergyMeterState();
    loadScreenTimeData(DateTime.now());
  }

  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }
}
