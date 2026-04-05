import 'package:oasis/features/ripples/domain/models/ripple_entity.dart';
import 'package:oasis/features/ripples/domain/repositories/ripple_repository.dart';

/// Use case for getting all ripples visible to the current user.
class GetRipples {
  final RippleRepository _repository;

  GetRipples(this._repository);

  Future<List<RippleEntity>> call() async {
    return _repository.getRipples();
  }
}

/// Use case for getting a single ripple by ID.
class GetRippleById {
  final RippleRepository _repository;

  GetRippleById(this._repository);

  Future<RippleEntity?> call(String rippleId) async {
    return _repository.getRippleById(rippleId);
  }
}
