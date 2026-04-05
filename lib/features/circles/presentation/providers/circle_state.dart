import 'package:oasis/features/circles/domain/models/circles_models.dart';

class CircleState {
  final List<CircleEntity> circles;
  final CircleEntity? activeCircle;
  final List<CommitmentEntity> todaysCommitments;
  final bool isLoading;
  final String? error;

  const CircleState({
    this.circles = const [],
    this.activeCircle,
    this.todaysCommitments = const [],
    this.isLoading = false,
    this.error,
  });

  CircleState copyWith({
    List<CircleEntity>? circles,
    CircleEntity? activeCircle,
    List<CommitmentEntity>? todaysCommitments,
    bool? isLoading,
    String? error,
  }) {
    return CircleState(
      circles: circles ?? this.circles,
      activeCircle: activeCircle ?? this.activeCircle,
      todaysCommitments: todaysCommitments ?? this.todaysCommitments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
