import 'package:oasis/features/ripples/domain/models/ripple_entity.dart';
import 'package:oasis/features/ripples/domain/repositories/ripple_repository.dart';

/// Use case for creating a new ripple.
class CreateRipple {
  final RippleRepository _repository;

  CreateRipple(this._repository);

  Future<RippleEntity> call({
    required String videoUrl,
    String? thumbnailUrl,
    String? caption,
    bool isPrivate = false,
  }) async {
    return _repository.createRipple(
      videoUrl: videoUrl,
      caption: caption,
      isPrivate: isPrivate,
    );
  }
}

/// Use case for deleting a ripple.
class DeleteRipple {
  final RippleRepository _repository;

  DeleteRipple(this._repository);

  Future<void> call(String rippleId) async {
    return _repository.deleteRipple(rippleId);
  }
}
