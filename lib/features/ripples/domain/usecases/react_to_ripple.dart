import 'package:oasis/features/ripples/domain/models/ripple_entity.dart';
import 'package:oasis/features/ripples/domain/repositories/ripple_repository.dart';

/// Use case for liking a ripple.
class LikeRipple {
  final RippleRepository _repository;

  LikeRipple(this._repository);

  Future<void> call(String rippleId) async {
    return _repository.likeRipple(rippleId);
  }
}

/// Use case for unliking a ripple.
class UnlikeRipple {
  final RippleRepository _repository;

  UnlikeRipple(this._repository);

  Future<void> call(String rippleId) async {
    return _repository.unlikeRipple(rippleId);
  }
}

/// Use case for saving a ripple.
class SaveRipple {
  final RippleRepository _repository;

  SaveRipple(this._repository);

  Future<void> call(String rippleId) async {
    return _repository.saveRipple(rippleId);
  }
}

/// Use case for unsaving a ripple.
class UnsaveRipple {
  final RippleRepository _repository;

  UnsaveRipple(this._repository);

  Future<void> call(String rippleId) async {
    return _repository.unsaveRipple(rippleId);
  }
}

/// Use case for commenting on a ripple.
class CommentOnRipple {
  final RippleRepository _repository;

  CommentOnRipple(this._repository);

  Future<RippleCommentEntity> call({
    required String rippleId,
    required String content,
  }) async {
    return _repository.commentOnRipple(rippleId: rippleId, content: content);
  }
}

/// Use case for getting comments on a ripple.
class GetRippleComments {
  final RippleRepository _repository;

  GetRippleComments(this._repository);

  Future<List<RippleCommentEntity>> call(String rippleId) async {
    return _repository.getComments(rippleId);
  }
}
