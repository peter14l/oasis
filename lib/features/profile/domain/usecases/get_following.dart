import 'package:oasis_v2/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis_v2/features/profile/domain/repositories/profile_repository.dart';

class GetFollowing {
  final ProfileRepository _repository;

  GetFollowing(this._repository);

  Future<List<UserProfileEntity>> call({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) {
    return _repository.getFollowing(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }
}
