import 'package:oasis_v2/features/canvas/domain/repositories/canvas_repository.dart';
import 'package:oasis_v2/features/canvas/domain/models/canvas_models.dart';

/// Use case to get all canvases for a user.
class GetCanvases {
  final CanvasRepository _repository;

  GetCanvases(this._repository);

  Future<List<OasisCanvasEntity>> call(String userId) {
    return _repository.getCanvases(userId);
  }
}
