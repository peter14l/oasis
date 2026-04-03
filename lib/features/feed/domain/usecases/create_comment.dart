import 'package:oasis_v2/features/feed/domain/models/comment.dart';
import 'package:oasis_v2/features/feed/domain/repositories/comment_repository.dart';

/// Create a comment (top-level or reply).
class CreateComment {
  final CommentRepository _repository;

  CreateComment(this._repository);

  Future<Comment> call({
    required String userId,
    required String postId,
    required String content,
    String? parentCommentId,
  }) {
    return _repository.createComment(
      userId: userId,
      postId: postId,
      content: content,
      parentCommentId: parentCommentId,
    );
  }
}
