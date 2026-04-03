import 'package:oasis_v2/features/circles/domain/models/circles_models.dart';

abstract class CircleRepository {
  Future<List<CircleEntity>> getCircles(String userId);

  Future<CircleEntity> getCircle(String circleId);

  Future<CircleEntity> createCircle({
    required String createdBy,
    required String name,
    required String emoji,
    required List<String> memberIds,
  });

  Future<void> deleteCircle(String circleId);

  Future<void> joinCircle(String circleId, String userId);

  Future<void> leaveCircle(String circleId, String userId);

  Future<List<CommitmentEntity>> getCommitments({
    required String circleId,
    DateTime? date,
  });

  Future<CommitmentEntity> createCommitment({
    required String circleId,
    required String createdBy,
    required String title,
    String? description,
    DateTime? dueDate,
  });

  Future<void> setIntent({
    required String commitmentId,
    required String userId,
    required MemberIntent intent,
  });

  Future<void> markComplete({
    required String commitmentId,
    required String userId,
    String? note,
  });

  Stream<List<CommitmentEntity>> subscribeToCommitments({
    required String circleId,
    DateTime? date,
  });
}
