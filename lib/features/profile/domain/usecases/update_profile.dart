import 'package:oasis_v2/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis_v2/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository _repository;

  UpdateProfile(this._repository);

  Future<UserProfileEntity> call({
    required String userId,
    String? username,
    String? fullName,
    String? bio,
    String? location,
    String? website,
    String? bannerColor,
    String? avatarFilePath,
    String? bannerFilePath,
  }) {
    return _repository.updateProfile(
      userId: userId,
      username: username,
      fullName: fullName,
      bio: bio,
      location: location,
      website: website,
      bannerColor: bannerColor,
      avatarFilePath: avatarFilePath,
      bannerFilePath: bannerFilePath,
    );
  }
}
