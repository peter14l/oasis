import 'package:oasis/features/canvas/domain/repositories/canvas_repository.dart';

/// Use case to delete a canvas.
class DeleteCanvas {
  final CanvasRepository _repository;

  DeleteCanvas(this._repository);

  Future<void> call(String canvasId) {
    return _repository.deleteCanvas(canvasId);
  }
}
