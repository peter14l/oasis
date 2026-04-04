import 'package:oasis_v2/features/ripples/domain/models/ripple_entity.dart';

/// Immutable state class for ripples feature.
/// Captures all UI state for ripples including session management.
class RipplesState {
  final List<RippleEntity> ripples;
  final bool isLoading;
  final String? error;
  final RipplesLayoutType currentLayout;
  final bool isRipplesLocked;
  final DateTime? lockoutEndTime;
  final Duration? remainingDuration;
  final String? currentUserId;

  const RipplesState({
    this.ripples = const [],
    this.isLoading = false,
    this.error,
    this.currentLayout = RipplesLayoutType.kineticCardStack,
    this.isRipplesLocked = false,
    this.lockoutEndTime,
    this.remainingDuration,
    this.currentUserId,
  });

  RipplesState copyWith({
    List<RippleEntity>? ripples,
    bool? isLoading,
    String? error,
    RipplesLayoutType? currentLayout,
    bool? isRipplesLocked,
    DateTime? lockoutEndTime,
    Duration? remainingDuration,
    String? currentUserId,
  }) {
    return RipplesState(
      ripples: ripples ?? this.ripples,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentLayout: currentLayout ?? this.currentLayout,
      isRipplesLocked: isRipplesLocked ?? this.isRipplesLocked,
      lockoutEndTime: lockoutEndTime ?? this.lockoutEndTime,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}
