import 'package:oasis_v2/features/feed/domain/repositories/post_repository.dart';

/// Delete a post (verifies ownership).
class DeletePost {
  final PostRepository _repository;

  DeletePost(this._repository);

  Future<void> call(String postId, String userId) {
    return _repository.deletePost(postId, userId);
  }
}
