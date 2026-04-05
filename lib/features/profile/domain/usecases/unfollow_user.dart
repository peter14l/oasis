import 'package:oasis/features/profile/domain/repositories/profile_repository.dart';

class UnfollowUser {
  final ProfileRepository _repository;

  UnfollowUser(this._repository);

  Future<void> call({required String followerId, required String followingId}) {
    return _repository.unfollowUser(
      followerId: followerId,
      followingId: followingId,
    );
  }
}
