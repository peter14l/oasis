import 'package:oasis_v2/features/profile/domain/repositories/profile_repository.dart';

class UpdatePrivacy {
  final ProfileRepository _repository;

  UpdatePrivacy(this._repository);

  Future<void> call({required String userId, required bool isPrivate}) {
    return _repository.updatePrivacy(userId: userId, isPrivate: isPrivate);
  }
}
