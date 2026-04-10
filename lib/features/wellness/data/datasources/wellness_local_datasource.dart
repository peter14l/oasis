import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/services/subscription_service.dart';
import '../../domain/models/energy_meter_entity.dart';
import '../../domain/models/wellness_entity.dart';

/// Local datasource for wellness data using SharedPreferences
class WellnessLocalDatasource {
  static const String _energyMeterKey = 'energy_meter_state';
  static const String _focusModeKey = 'focus_mode_enabled';
  static const String _focusModeScheduleKey = 'focus_mode_schedule';
  static const String _windDownEnabledKey = 'wind_down_enabled';
  static const String _windDownTimeKey = 'wind_down_time';
  static const String _blockedFeaturesKey = 'focus_blocked_features';
  static const String _dailyGoalKey = 'daily_usage_goal';
  static const String _achievementsKey = 'wellness_achievements';
  static const String _quietModeKey = 'quiet_mode_enabled';
  static const String _quietModeStartKey = 'quiet_mode_start';
  static const String _quietModeEndKey = 'quiet_mode_end';
  static const String _storageKeyPrefix = 'screen_time_';
  static const String _categoryStorageKeyPrefix = 'screen_time_categories_';

  final SharedPreferences _prefs;

  WellnessLocalDatasource(this._prefs);

  // Energy Meter methods
  Future<EnergyMeterEntity> getEnergyMeterState() async {
    final stateJson = _prefs.getString(_energyMeterKey);
    if (stateJson != null) {
      final json = jsonDecode(stateJson) as Map<String, dynamic>;
      return EnergyMeterEntity.fromJson(json);
    }
    return EnergyMeterEntity.initial();
  }

  Future<void> saveEnergyMeterState(EnergyMeterEntity state) async {
    await _prefs.setString(_energyMeterKey, jsonEncode(state.toJson()));
  }

  // Focus Mode methods
  bool get focusModeEnabled => _prefs.getBool(_focusModeKey) ?? false;
  Future<void> setFocusModeEnabled(bool enabled) async {
    await _prefs.setBool(_focusModeKey, enabled);
  }

  Map<String, bool> get focusSchedule {
    final scheduleJson = _prefs.getString(_focusModeScheduleKey);
    if (scheduleJson != null) {
      final decoded = jsonDecode(scheduleJson) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as bool));
    }
    return {};
  }

  Set<String> get blockedFeatures {
    final blockedJson = _prefs.getStringList(_blockedFeaturesKey);
    return blockedJson?.toSet() ?? {};
  }

  Future<void> setBlockedFeatures(Set<String> features) async {
    await _prefs.setStringList(_blockedFeaturesKey, features.toList());
  }

  // Wind Down methods
  bool get windDownEnabled => _prefs.getBool(_windDownEnabledKey) ?? false;
  Future<void> setWindDownEnabled(bool enabled) async {
    await _prefs.setBool(_windDownEnabledKey, enabled);
  }

  TimeOfDay? get windDownTime {
    final windDownStr = _prefs.getString(_windDownTimeKey);
    if (windDownStr != null) {
      final parts = windDownStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return null;
  }

  Future<void> setWindDownTime(TimeOfDay time) async {
    await _prefs.setString(_windDownTimeKey, '${time.hour}:${time.minute}');
  }

  // Daily Goal
  int get dailyGoalMinutes => _prefs.getInt(_dailyGoalKey) ?? 60;
  Future<void> setDailyGoal(int minutes) async {
    await _prefs.setInt(_dailyGoalKey, minutes);
  }

  // Achievements
  List<WellnessAchievementEntity> get achievements {
    final achievementsJson = _prefs.getString(_achievementsKey);
    if (achievementsJson != null) {
      final List decoded = jsonDecode(achievementsJson);
      return decoded.map((a) => WellnessAchievementEntity.fromJson(a)).toList();
    }
    return [];
  }

  Future<void> saveAchievements(
    List<WellnessAchievementEntity> achievements,
  ) async {
    final json = jsonEncode(achievements.map((a) => a.toJson()).toList());
    await _prefs.setString(_achievementsKey, json);
  }

  // Quiet Mode
  bool get quietModeEnabled => _prefs.getBool(_quietModeKey) ?? false;
  Future<void> setQuietMode(bool enabled) async {
    await _prefs.setBool(_quietModeKey, enabled);
  }

  TimeOfDay? get quietModeStart {
    final startStr = _prefs.getString(_quietModeStartKey);
    if (startStr != null) {
      final parts = startStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return null;
  }

  TimeOfDay? get quietModeEnd {
    final endStr = _prefs.getString(_quietModeEndKey);
    if (endStr != null) {
      final parts = endStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return null;
  }

  Future<void> setQuietModeHours(TimeOfDay start, TimeOfDay end) async {
    await _prefs.setString(_quietModeStartKey, '${start.hour}:${start.minute}');
    await _prefs.setString(_quietModeEndKey, '${end.hour}:${end.minute}');
  }

  // Screen Time methods
  String _getDateKey(DateTime date) {
    return '$_storageKeyPrefix${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<int> getHourlyUsage(String dateKey) {
    final data = _prefs.getString(dateKey);
    if (data == null) return List.filled(24, 0);
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => e as int).toList();
    } catch (e) {
      return List.filled(24, 0);
    }
  }

  Future<void> saveHourlyUsage(String dateKey, List<int> hourlyUsage) async {
    await _prefs.setString(dateKey, jsonEncode(hourlyUsage));
  }

  Map<String, int> getCategoryMinutes(DateTime date) {
    final dateKey = _getDateKey(date);
    final catKey = '$_categoryStorageKeyPrefix$dateKey';
    final data = _prefs.getString(catKey);
    if (data != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(data);
        return decoded.map((k, v) => MapEntry(k, v as int));
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  Future<void> saveCategoryMinutes(
    DateTime date,
    Map<String, int> minutes,
  ) async {
    final dateKey = _getDateKey(date);
    final catKey = '$_categoryStorageKeyPrefix$dateKey';
    await _prefs.setString(catKey, jsonEncode(minutes));
  }

  // XP methods
  bool _isUserPro() {
    return SubscriptionService().isPro;
  }

  bool get isUserPro => _isUserPro();

  Future<void> updateUserXP(int amount) async {
    final user = SupabaseService().client.auth.currentUser;
    if (user == null) return;

    try {
      await SupabaseService().client.rpc(
        'increment_xp',
        params: {'user_id': user.id, 'xp_amount': amount},
      );
    } catch (e) {
      debugPrint('Error updating XP: $e');
    }
  }

  static Future<WellnessLocalDatasource> init() async {
    final prefs = await SharedPreferences.getInstance();
    return WellnessLocalDatasource(prefs);
  }
}
