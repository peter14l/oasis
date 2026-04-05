import 'package:oasis/features/profile/domain/repositories/profile_repository.dart';

class FollowUser {
  final ProfileRepository _repository;

  FollowUser(this._repository);

  Future<void> call({required String followerId, required String followingId}) {
    return _repository.followUser(
      followerId: followerId,
      followingId: followingId,
    );
  }
}
