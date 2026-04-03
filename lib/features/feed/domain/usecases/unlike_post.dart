import 'package:oasis_v2/features/feed/domain/repositories/post_repository.dart';

/// Unlike a post.
class UnlikePost {
  final PostRepository _repository;

  UnlikePost(this._repository);

  Future<void> call({required String userId, required String postId}) {
    return _repository.unlikePost(userId: userId, postId: postId);
  }
}
