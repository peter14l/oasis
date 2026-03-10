import 'package:flutter/material.dart';

/// Represents the current state of the user's interaction energy
/// Energy depletes with interactions and recovers passively over time
class EnergyMeterState {
  final double currentEnergy; // 0-100
  final DateTime lastInteraction;
  final int interactionsToday;
  final DateTime dayStart;

  // Constants for energy mechanics
  static const double MAX_ENERGY = 100.0;
  static const double EXPANSION_COST = 15.0;
  static const double VIEW_COST = 2.0;
  static const double LIKE_COST = 1.0;
  static const double RECOVERY_RATE = 5.0; // per minute
  static const double LOW_ENERGY_THRESHOLD = 10.0;

  const EnergyMeterState({
    required this.currentEnergy,
    required this.lastInteraction,
    required this.interactionsToday,
    required this.dayStart,
  });

  /// Create initial state with full energy
  factory EnergyMeterState.initial() {
    final now = DateTime.now();
    return EnergyMeterState(
      currentEnergy: MAX_ENERGY,
      lastInteraction: now,
      interactionsToday: 0,
      dayStart: DateTime(now.year, now.month, now.day),
    );
  }

  /// Calculate energy after passive recovery
  EnergyMeterState withRecovery() {
    final now = DateTime.now();
    final minutesElapsed = now.difference(lastInteraction).inMinutes;
    final recoveredEnergy = (currentEnergy + (minutesElapsed * RECOVERY_RATE))
        .clamp(0.0, MAX_ENERGY);

    // Reset daily counter if it's a new day
    final isNewDay =
        now.day != dayStart.day ||
        now.month != dayStart.month ||
        now.year != dayStart.year;

    return EnergyMeterState(
      currentEnergy: recoveredEnergy,
      lastInteraction: lastInteraction,
      interactionsToday: isNewDay ? 0 : interactionsToday,
      dayStart: isNewDay ? DateTime(now.year, now.month, now.day) : dayStart,
    );
  }

  /// Deduct energy for an interaction
  EnergyMeterState deductEnergy(double cost) {
    final now = DateTime.now();
    return EnergyMeterState(
      currentEnergy: (currentEnergy - cost).clamp(0.0, MAX_ENERGY),
      lastInteraction: now,
      interactionsToday: interactionsToday + 1,
      dayStart: dayStart,
    );
  }

  /// Check if energy is critically low
  bool get isLowEnergy => currentEnergy < LOW_ENERGY_THRESHOLD;

  /// Get energy percentage (0.0 - 1.0)
  double get energyPercentage => currentEnergy / MAX_ENERGY;

  /// Get color representing current energy level
  Color get energyColor {
    if (currentEnergy >= 70) {
      return Colors.green;
    } else if (currentEnergy >= 40) {
      return Colors.yellow;
    } else if (currentEnergy >= LOW_ENERGY_THRESHOLD) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'currentEnergy': currentEnergy,
      'lastInteraction': lastInteraction.toIso8601String(),
      'interactionsToday': interactionsToday,
      'dayStart': dayStart.toIso8601String(),
    };
  }

  /// Create from JSON
  factory EnergyMeterState.fromJson(Map<String, dynamic> json) {
    return EnergyMeterState(
      currentEnergy: (json['currentEnergy'] as num?)?.toDouble() ?? MAX_ENERGY,
      lastInteraction:
          json['lastInteraction'] != null
              ? DateTime.parse(json['lastInteraction'] as String)
              : DateTime.now(),
      interactionsToday: json['interactionsToday'] as int? ?? 0,
      dayStart:
          json['dayStart'] != null
              ? DateTime.parse(json['dayStart'] as String)
              : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'EnergyMeterState(energy: ${currentEnergy.toStringAsFixed(1)}, '
        'interactions: $interactionsToday)';
  }
}
