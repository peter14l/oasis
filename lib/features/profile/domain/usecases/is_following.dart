import 'package:oasis/features/profile/domain/repositories/profile_repository.dart';

class IsFollowing {
  final ProfileRepository _repository;

  IsFollowing(this._repository);

  Future<bool> call({required String followerId, required String followingId}) {
    return _repository.isFollowing(
      followerId: followerId,
      followingId: followingId,
    );
  }
}
