import 'package:oasis/features/feed/domain/repositories/post_repository.dart';

/// Share/repost a post (increment share count).
class Repost {
  final PostRepository _repository;

  Repost(this._repository);

  Future<void> call(String postId) {
    return _repository.sharePost(postId);
  }
}
