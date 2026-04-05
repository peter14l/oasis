import 'package:oasis/features/canvas/domain/repositories/canvas_repository.dart';
import 'package:oasis/features/canvas/domain/models/canvas_models.dart';

/// Use case to add an item to a canvas.
class AddCanvasItem {
  final CanvasRepository _repository;

  AddCanvasItem(this._repository);

  Future<CanvasItemEntity> call({
    required String canvasId,
    required String authorId,
    required CanvasItemType type,
    required String content,
    required double xPos,
    required double yPos,
    double rotation = 0.0,
    double scale = 1.0,
    String color = '#252930',
    DateTime? unlockAt,
  }) {
    return _repository.addCanvasItem(
      canvasId: canvasId,
      authorId: authorId,
      type: type,
      content: content,
      xPos: xPos,
      yPos: yPos,
      rotation: rotation,
      scale: scale,
      color: color,
      unlockAt: unlockAt,
    );
  }
}
