import 'package:oasis_v2/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis_v2/features/profile/domain/repositories/profile_repository.dart';

class SearchUsers {
  final ProfileRepository _repository;

  SearchUsers(this._repository);

  Future<List<UserProfileEntity>> call({
    required String query,
    int limit = 20,
  }) {
    return _repository.searchUsers(query: query, limit: limit);
  }
}
