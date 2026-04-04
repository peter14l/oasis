import '../models/energy_meter_entity.dart';
import '../repositories/wellness_repository.dart';

/// Use case for managing user interaction energy
/// Handles energy deduction, passive recovery, and persistence
class ManageEnergyMeter {
  final WellnessRepository _repository;

  ManageEnergyMeter(this._repository);

  /// Get current energy meter state
  Future<EnergyMeterEntity> getEnergyMeterState() {
    return _repository.getEnergyMeterState();
  }

  /// Deduct energy for an interaction
  /// Returns false if insufficient energy
  Future<bool> deductEnergy(InteractionType type) {
    return _repository.deductEnergy(type);
  }

  /// Manually trigger recovery (for testing or special events)
  Future<void> forceRecovery() {
    return _repository.forceEnergyRecovery();
  }

  /// Reset energy to full (for testing or daily reset)
  Future<void> resetEnergy() {
    return _repository.resetEnergy();
  }

  /// Check if user has enough energy for an interaction
  Future<bool> canInteract(InteractionType type) async {
    final state = await _repository.getEnergyMeterState();
    double cost;
    switch (type) {
      case InteractionType.expand:
        cost = EnergyMeterEntity.expansionCost;
        break;
      case InteractionType.view:
        cost = EnergyMeterEntity.viewCost;
        break;
      case InteractionType.like:
      case InteractionType.comment:
      case InteractionType.share:
      case InteractionType.bookmark:
        cost = EnergyMeterEntity.likeCost;
        break;
    }
    return state.currentEnergy >= cost;
  }

  /// Handle app lifecycle changes
  void onPaused() {
    _repository.onPaused();
  }

  void onResumed() {
    _repository.onResumed();
  }
}
