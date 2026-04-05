import 'package:oasis/features/circles/domain/models/circles_models.dart';
import 'package:oasis/features/circles/domain/repositories/circle_repository.dart';

class CreateCircle {
  final CircleRepository _repository;
  CreateCircle(this._repository);
  Future<CircleEntity> call({
    required String createdBy,
    required String name,
    required String emoji,
    required List<String> memberIds,
  }) {
    return _repository.createCircle(
      createdBy: createdBy,
      name: name,
      emoji: emoji,
      memberIds: memberIds,
    );
  }
}
