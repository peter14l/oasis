import 'package:oasis/features/feed/domain/repositories/post_repository.dart';

/// Like a post.
class LikePost {
  final PostRepository _repository;

  LikePost(this._repository);

  Future<void> call({required String userId, required String postId}) {
    return _repository.likePost(userId: userId, postId: postId);
  }
}
