import 'package:oasis/features/feed/domain/models/comment.dart';
import 'package:oasis/features/feed/domain/repositories/comment_repository.dart';

/// Get comments for a post.
class GetComments {
  final CommentRepository _repository;

  GetComments(this._repository);

  Future<List<Comment>> call({
    required String postId,
    required String currentUserId,
    int limit = 50,
    int offset = 0,
  }) {
    return _repository.getPostComments(
      postId: postId,
      currentUserId: currentUserId,
      limit: limit,
      offset: offset,
    );
  }
}
