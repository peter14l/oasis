import 'package:oasis/features/canvas/domain/repositories/canvas_repository.dart';
import 'package:oasis/features/canvas/domain/models/canvas_models.dart';

/// Use case to get canvas items (timeline view).
class GetCanvasTimeline {
  final CanvasRepository _repository;

  GetCanvasTimeline(this._repository);

  Future<List<CanvasItemEntity>> call(String canvasId) {
    return _repository.getCanvasItems(canvasId);
  }
}
