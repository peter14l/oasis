import 'package:oasis_v2/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis_v2/features/profile/domain/repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository _repository;

  GetProfile(this._repository);

  Future<UserProfileEntity> call(String userId) {
    return _repository.getProfile(userId);
  }
}
