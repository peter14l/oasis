import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScreenTimeService extends ChangeNotifier {
  static const String _storageKeyPrefix = 'screen_time_';

  DateTime? _sessionStartTime;
  Timer? _autoSaveTimer;

  // --- Digital Well-being state ---
  /// Seconds elapsed in the current continuous app session.
  int _currentSessionElapsedSeconds = 0;
  Timer? _wellbeingTicker;

  final SharedPreferences _prefs;

  int _scrollLimitMinutes = 30;

  // Real category tracking
  String? _currentCategory;
  Map<String, int> _categoryMinutes = {};
  static const String _categoryStorageKeyPrefix = 'screen_time_categories_';

  ScreenTimeService(this._prefs) {
    _loadSettings();
    _loadCategoryData();
    _startAutoSave();
  }

  /// Update the current active screen category
  void setCurrentCategory(String? category) {
    if (_currentCategory == category) return;
    _currentCategory = category;
    // No notifyListeners here as this is often called during build
  }

  void _loadCategoryData() {
    final dateKey = _getDateKey(DateTime.now());
    final catKey = '${_categoryStorageKeyPrefix}$dateKey';
    final data = _prefs.getString(catKey);
    if (data != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(data);
        _categoryMinutes = decoded.map((k, v) => MapEntry(k, v as int));
      } catch (e) {
        _categoryMinutes = {};
      }
    }
  }

  /// Record time spent on a specific screen category
  void recordScreenTime(String category, int minutes) {
    if (minutes <= 0) return;
    _categoryMinutes[category] = (_categoryMinutes[category] ?? 0) + minutes;
    _saveCategoryData();
    notifyListeners();
  }

  Future<void> _saveCategoryData() async {
    final dateKey = _getDateKey(DateTime.now());
    final catKey = '${_categoryStorageKeyPrefix}$dateKey';
    await _prefs.setString(catKey, jsonEncode(_categoryMinutes));
  }

  static Future<ScreenTimeService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return ScreenTimeService(prefs);
  }

  // ---- Digital Well-being computed state ----

  /// The current scroll limit in minutes.
  int get scrollLimitMinutes => _scrollLimitMinutes;

  /// Set the scroll limit (used by Pro users).
  void setScrollLimit(int minutes) {
    _scrollLimitMinutes = minutes;
    notifyListeners();
  }

  /// Minutes elapsed in the current continuous session (live, updates every second).
  int get sessionElapsedMinutes => _currentSessionElapsedSeconds ~/ 60;

  /// Saturation level for greyscale effect based on continuous scroll time.
  /// Logic:
  /// - Full color until [limit - 5] minutes.
  /// - Fade to B/W over 5 minutes.
  /// - B/W for 10 minutes.
  /// - Fade back to color over 1 minute.
  double get saturationLevel {
    final t = sessionElapsedMinutes;
    final limit = _scrollLimitMinutes;
    final bwEnd = limit + 10;
    final fadeBackEnd = bwEnd + 1;

    if (t < limit - 5) return 1.0;
    if (t < limit) {
      // Ramp down 1.0 -> 0.0 over 5 mins
      return 1.0 - ((t - (limit - 5)) / 5.0);
    }
    if (t < bwEnd) return 0.0;
    if (t < fadeBackEnd) {
      // Fade back 0.0 -> 1.0 over 1 min
      // Using seconds for a smoother fade-back transition
      final secondsInFade = _currentSessionElapsedSeconds - (bwEnd * 60);
      return (secondsInFade / 60.0).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  /// True when the session has reached the scroll limit and the break period is active.
  /// Aligns with [saturationLevel] logic: active during the ramp-down and B/W period.
  bool get isKillSwitchActive {
    final t = sessionElapsedMinutes;
    final limit = _scrollLimitMinutes;
    // The kill switch is active from the moment we hit the limit
    // until the end of the B/W period (limit + 10 mins).
    return t >= limit && t < (limit + 10);
  }

  /// Reset the session counter, giving the user a fresh window.
  void resetKillSwitch() {
    _currentSessionElapsedSeconds = 0;
    _sessionStartTime = DateTime.now();
    notifyListeners();
    debugPrint('ScreenTime: Scroll health reset. New session started.');
  }

  /// Debug-only helper to jump forward by [minutes] minutes.
  void debugAddMinutes(int minutes) {
    assert(() {
      _currentSessionElapsedSeconds += minutes * 60;
      notifyListeners();
      return true;
    }());
  }

  // ---- Tracking lifecycle ----

  void startTracking() {
    _sessionStartTime = DateTime.now();
    _startWellbeingTicker();
    debugPrint('ScreenTime: Session started at $_sessionStartTime');
  }

  Future<void> stopTracking() async {
    _stopWellbeingTicker();
    if (_sessionStartTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_sessionStartTime!);
    _sessionStartTime = null;

    if (duration.inSeconds < 1) return;

    // Safety: don't call async record if we're technically disposed
    // though shared_prefs is usually okay
    try {
      await _recordUsage(endTime, duration);
    } catch (e) {
      debugPrint('ScreenTime: Error recording usage during stop: $e');
    }
    debugPrint('ScreenTime: Session ended. Duration: ${duration.inMinutes}m');
  }

  void _startWellbeingTicker() {
    _wellbeingTicker?.cancel();
    _wellbeingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _currentSessionElapsedSeconds++;
      notifyListeners();
    });
  }

  void _stopWellbeingTicker() {
    _wellbeingTicker?.cancel();
    _wellbeingTicker = null;
  }

  void _startAutoSave() {
    // Auto-save every minute to prevent data loss on crash/kill
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_sessionStartTime != null) {
        final now = DateTime.now();
        final duration = now.difference(_sessionStartTime!);
        if (duration.inSeconds >= 60) {
          await _recordUsage(now, duration);
          // Reset start time to now to avoid double counting
          _sessionStartTime = now;
        }
      }
    });
  }

  Future<void> _recordUsage(DateTime timestamp, Duration duration) async {
    final dateKey = _getDateKey(timestamp);
    final hour = timestamp.hour;

    // Get current daily data
    List<int> hourlyUsage = _getHourlyUsage(dateKey);

    // Add minutes to current hour
    // Note: This is a simplification. If a session spans across hours,
    // strictly speaking we should split it. For now, attributing to the end hour is acceptable
    // for general usage tracking, or we can split it if precision is critical.
    // Let's do a simple split if it's a long duration, but for 1-minute auto-saves,
    // it will mostly fall in the correct hour.

    hourlyUsage[hour] += duration.inMinutes;

    await _prefs.setString(dateKey, jsonEncode(hourlyUsage));

    // Also record for current category
    if (_currentCategory != null && duration.inMinutes > 0) {
      _categoryMinutes[_currentCategory!] = (_categoryMinutes[_currentCategory!] ?? 0) + duration.inMinutes;
      await _saveCategoryData();
    }

    notifyListeners();
  }

  List<int> _getHourlyUsage(String dateKey) {
    final data = _prefs.getString(dateKey);
    if (data == null) {
      return List.filled(24, 0);
    }
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => e as int).toList();
    } catch (e) {
      return List.filled(24, 0);
    }
  }

  String _getDateKey(DateTime date) {
    return '${_storageKeyPrefix}${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get usage for a specific date
  /// Returns a map with 'totalMinutes' and 'hourlyBreakdown'
  Map<String, dynamic> getDailyUsage(DateTime date) {
    final dateKey = _getDateKey(date);
    final hourlyUsage = _getHourlyUsage(dateKey);
    final totalMinutes = hourlyUsage.reduce((a, b) => a + b);

    return {'totalMinutes': totalMinutes, 'hourlyBreakdown': hourlyUsage};
  }

  /// Get average daily usage over the last 7 days (excluding today)
  int getWeeklyAverage() {
    int totalMinutes = 0;
    int daysWithData = 0;

    for (int i = 1; i <= 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final usage = getDailyUsage(date);
      final minutes = usage['totalMinutes'] as int;

      if (minutes > 0) {
        totalMinutes += minutes;
        daysWithData++;
      }
    }

    if (daysWithData == 0) return 0;
    return (totalMinutes / 7)
        .round(); // Average over 7 days regardless of usage to show true average
  }

  /// Get daily totals for the last 7 days including today
  List<Map<String, dynamic>> getWeeklyData() {
    List<Map<String, dynamic>> data = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final usage = getDailyUsage(date);
      data.add({
        'day': _getDayName(date.weekday),
        'minutes': usage['totalMinutes'],
        'date': date,
      });
    }
    return data;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  /// Get usage breakdown by category (Real tracked data)
  List<Map<String, dynamic>> getCategoryUsage(int totalMinutes) {
    if (_categoryMinutes.isEmpty) {
      // If no data yet, show 0 for all standard categories instead of mock percentages
      return [
        {'name': 'Feed', 'minutes': 0, 'icon': Icons.feed, 'color': 0xFF2196F3},
        {'name': 'Messages', 'minutes': 0, 'icon': Icons.chat, 'color': 0xFF4CAF50},
        {'name': 'Communities', 'minutes': 0, 'icon': Icons.people, 'color': 0xFFFF9800},
        {'name': 'Profile', 'minutes': 0, 'icon': Icons.person, 'color': 0xFF9C27B0},
      ];
    }

    final List<Map<String, dynamic>> categories = [];
    
    // Define standard categories and their styling
    final categoryStyles = {
      'Feed': {'icon': Icons.feed, 'color': 0xFF2196F3},
      'Messages': {'icon': Icons.chat, 'color': 0xFF4CAF50},
      'Communities': {'icon': Icons.people, 'color': 0xFFFF9800},
      'Profile': {'icon': Icons.person, 'color': 0xFF9C27B0},
    };

    _categoryMinutes.forEach((name, minutes) {
      final style = categoryStyles[name] ?? {'icon': Icons.more_horiz, 'color': 0xFF9E9E9E};
      categories.add({
        'name': name,
        'minutes': minutes,
        'icon': style['icon'],
        'color': style['color'],
      });
    });

    // Sort by most used
    categories.sort((a, b) => (b['minutes'] as int).compareTo(a['minutes'] as int));
    
    return categories;
  }

  // Quiet Mode
  bool _quietModeEnabled = false;
  TimeOfDay? _quietModeStart;
  TimeOfDay? _quietModeEnd;
  static const String _quietModeKey = 'quiet_mode_enabled';
  static const String _quietModeStartKey = 'quiet_mode_start';
  static const String _quietModeEndKey = 'quiet_mode_end';

  // Break Reminder
  static const int _breakReminderThresholdMinutes = 30; // Remind every 30 mins
  DateTime? _lastBreakReminderTime;

  bool get isQuietModeEnabled => _quietModeEnabled;
  TimeOfDay? get quietModeStart => _quietModeStart;
  TimeOfDay? get quietModeEnd => _quietModeEnd;

  Future<void> _loadSettings() async {
    _quietModeEnabled = _prefs.getBool(_quietModeKey) ?? false;

    final startStr = _prefs.getString(_quietModeStartKey);
    if (startStr != null) {
      final parts = startStr.split(':');
      _quietModeStart = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final endStr = _prefs.getString(_quietModeEndKey);
    if (endStr != null) {
      final parts = endStr.split(':');
      _quietModeEnd = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    notifyListeners();
  }

  Future<void> setQuietMode(bool enabled) async {
    _quietModeEnabled = enabled;
    await _prefs.setBool(_quietModeKey, enabled);
    notifyListeners();
  }

  Future<void> setQuietModeHours(TimeOfDay start, TimeOfDay end) async {
    _quietModeStart = start;
    _quietModeEnd = end;

    await _prefs.setString(_quietModeStartKey, '${start.hour}:${start.minute}');
    await _prefs.setString(_quietModeEndKey, '${end.hour}:${end.minute}');
    notifyListeners();
  }

  bool get isQuietModeActive {
    if (!_quietModeEnabled ||
        _quietModeStart == null ||
        _quietModeEnd == null) {
      return false;
    }

    final now = TimeOfDay.now();
    final start = _quietModeStart!;
    final end = _quietModeEnd!;

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      // Crosses midnight
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  /// Check for break reminder
  /// Returns true if user should take a break
  bool checkBreakReminder() {
    if (_sessionStartTime == null) return false;

    final now = DateTime.now();
    final sessionDuration = now.difference(_sessionStartTime!);

    if (sessionDuration.inMinutes >= _breakReminderThresholdMinutes) {
      // Check if we already reminded recently (e.g., within last 5 mins) to avoid spam
      if (_lastBreakReminderTime == null ||
          now.difference(_lastBreakReminderTime!).inMinutes >=
              _breakReminderThresholdMinutes) {
        _lastBreakReminderTime = now;
        return true;
      }
    }
    return false;
  }

  // Wellness Gamification
  static const int _defaultDailyLimitMinutes = 120; // 2 hours

  /// Calculate current streak (consecutive days under limit)
  int getWellnessStreak() {
    int streak = 0;
    final now = DateTime.now();

    // Check yesterday, day before, etc.
    for (int i = 1; i <= 365; i++) {
      final date = now.subtract(Duration(days: i));
      final usage = getDailyUsage(date);
      final minutes = usage['totalMinutes'] as int;

      // If we have no data for a day, we assume 0 minutes (Success)
      // UNLESS it's older than when the app was installed?
      // For simplicity, let's assume 0 minutes is valid success.

      if (minutes <= _defaultDailyLimitMinutes) {
        streak++;
      } else {
        break; // Streak broken
      }
    }
    return streak;
  }

  /// Get current status for today
  bool isUnderLimit() {
    final usage = getDailyUsage(DateTime.now());
    return (usage['totalMinutes'] as int) <= _defaultDailyLimitMinutes;
  }

  @override
  void dispose() {
    _stopWellbeingTicker();
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    super.dispose();
  }
}
