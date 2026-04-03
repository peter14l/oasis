import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oasis_v2/models/energy_meter_state.dart';
import 'package:oasis_v2/models/feed_layout_strategy.dart';

/// Service for managing user interaction energy
/// Handles energy deduction, passive recovery, and persistence
class EnergyMeterService extends ChangeNotifier {
  static const String _storageKey = 'energy_meter_state';

  EnergyMeterState _state = EnergyMeterState.initial();
  Timer? _recoveryTimer;

  EnergyMeterState get state => _state;

  /// Initialize the service and load persisted state
  static Future<EnergyMeterService> init() async {
    final service = EnergyMeterService();
    await service._loadState();
    service._startRecoveryTimer();
    return service;
  }

  /// Load state from SharedPreferences
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_storageKey);

      if (stateJson != null) {
        final json = jsonDecode(stateJson) as Map<String, dynamic>;
        _state = EnergyMeterState.fromJson(json);

        // Apply passive recovery for time elapsed while app was closed
        _state = _state.withRecovery();
        await _saveState();
      }
    } catch (e) {
      debugPrint('Error loading energy meter state: $e');
      _state = EnergyMeterState.initial();
    }
    notifyListeners();
  }

  /// Save state to SharedPreferences
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = jsonEncode(_state.toJson());
      await prefs.setString(_storageKey, stateJson);
    } catch (e) {
      debugPrint('Error saving energy meter state: $e');
    }
  }

  /// Start timer for passive energy recovery
  void _startRecoveryTimer() {
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _applyRecovery(),
    );
  }

  /// App lifecycle handling to save battery
  void onPaused() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
    debugPrint('EnergyMeter: Recovery timer paused (background)');
  }

  void onResumed() {
    // Re-load state to apply catch-up recovery for time spent in background
    _loadState();
    _startRecoveryTimer();
    debugPrint('EnergyMeter: Recovery timer resumed (foreground)');
  }

  /// Apply passive recovery
  void _applyRecovery() {
    _state = _state.withRecovery();
    _saveState();
    notifyListeners();
  }

  /// Deduct energy for an interaction
  Future<bool> deductEnergy(InteractionType type) async {
    double cost;

    switch (type) {
      case InteractionType.expand:
        cost = EnergyMeterState.expansionCost;
        break;
      case InteractionType.view:
        cost = EnergyMeterState.viewCost;
        break;
      case InteractionType.like:
      case InteractionType.comment:
      case InteractionType.share:
      case InteractionType.bookmark:
        cost = EnergyMeterState.likeCost;
        break;
    }

    // Check if user has enough energy
    if (_state.currentEnergy < cost) {
      return false; // Interaction blocked
    }

    _state = _state.deductEnergy(cost);
    await _saveState();
    notifyListeners();
    return true;
  }

  /// Manually trigger recovery (for testing or special events)
  Future<void> forceRecovery() async {
    _state = _state.withRecovery();
    await _saveState();
    notifyListeners();
  }

  /// Reset energy to full (for testing or daily reset)
  Future<void> resetEnergy() async {
    _state = EnergyMeterState.initial();
    await _saveState();
    notifyListeners();
  }

  /// Get energy statistics
  Map<String, dynamic> getStats() {
    return {
      'currentEnergy': _state.currentEnergy,
      'energyPercentage': _state.energyPercentage,
      'interactionsToday': _state.interactionsToday,
      'isLowEnergy': _state.isLowEnergy,
      'lastInteraction': _state.lastInteraction.toIso8601String(),
    };
  }

  @override
  void dispose() {
    _recoveryTimer?.cancel();
    super.dispose();
  }
}
