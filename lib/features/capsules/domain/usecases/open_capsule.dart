import 'package:oasis_v2/features/capsules/domain/models/time_capsule_entity.dart';
import 'package:oasis_v2/features/capsules/domain/repositories/capsule_repository.dart';

/// Use case to open/unlock a time capsule
class OpenCapsule {
  final CapsuleRepository _repository;

  OpenCapsule(this._repository);

  Future<TimeCapsuleEntity> call(String capsuleId) {
    return _repository.openCapsule(capsuleId);
  }
}
