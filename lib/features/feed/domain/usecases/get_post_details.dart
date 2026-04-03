import 'package:oasis_v2/features/feed/domain/models/post.dart';
import 'package:oasis_v2/features/feed/domain/repositories/post_repository.dart';

/// Get a single post by ID with like/bookmark status.
class GetPostDetails {
  final PostRepository _repository;

  GetPostDetails(this._repository);

  Future<Post> call(String postId, String userId) {
    return _repository.getPost(postId, userId);
  }
}
