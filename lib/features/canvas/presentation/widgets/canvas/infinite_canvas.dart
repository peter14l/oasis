import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:oasis/features/canvas/domain/models/canvas_models.dart';
import 'package:oasis/features/canvas/presentation/widgets/canvas/canvas_item_widget.dart';
import 'package:oasis/features/canvas/presentation/widgets/canvas/ghost_presence_painter.dart';

class InfiniteCanvas extends StatefulWidget {
  final List<CanvasItemEntity> items;
  final Function(String itemId, double x, double y) onItemMoved;
  final Function(Offset localPosition) onLongPress;
  final Function(Offset offset)? onTransformationChanged;
  final bool isDrawingMode;
  final Widget? drawingLayer;
  
  // Presence support
  final String? currentUserId;
  final Map<String, dynamic> presenceState;
  final Function(double x, double y)? onPresenceUpdate;

  const InfiniteCanvas({
    super.key,
    required this.items,
    required this.onItemMoved,
    required this.onLongPress,
    this.onTransformationChanged,
    this.isDrawingMode = false,
    this.drawingLayer,
    this.currentUserId,
    this.presenceState = const {},
    this.onPresenceUpdate,
    // Background removed to be handled by parent
    @Deprecated('Background is now handled by parent') Widget? background,
  });

  @override
  State<InfiniteCanvas> createState() => _InfiniteCanvasState();
}

class _InfiniteCanvasState extends State<InfiniteCanvas> {
  final TransformationController _transformationController = TransformationController();
  
  static const double _virtualSize = 1000000;
  static const double _initialOffset = _virtualSize / 2;
  static const double _canvasScale = 3000.0;

  DateTime _lastPresenceUpdate = DateTime.now();
  Offset? _currentCanvasPosition;

  @override
  void initState() {
    super.initState();
    
    // Initial centering logic:
    // We want the coordinate (0,0) to be in the middle of the screen.
    // (0,0) in the Stack is at (_initialOffset, _initialOffset).
    // To center that, we need to translate by -_initialOffset + (screenWidth / 2).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      _transformationController.value = Matrix4.translationValues(
        -_initialOffset + (size.width / 2), 
        -_initialOffset + (size.height / 2),
        0,
      );
    });
    
    _transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final matrix = _transformationController.value;
    final offset = Offset(matrix.getTranslation().x, matrix.getTranslation().y);
    widget.onTransformationChanged?.call(offset);
  }

  void _broadcastPresence(Offset globalPosition) {
    if (widget.onPresenceUpdate == null) return;
    
    final now = DateTime.now();
    if (now.difference(_lastPresenceUpdate).inMilliseconds < 50) return;
    _lastPresenceUpdate = now;

    final Matrix4 matrix = _transformationController.value;
    final Matrix4 invertMatrix = Matrix4.inverted(matrix);
    
    final Vector4 transformedOffset = invertMatrix.transform(
      Vector4(globalPosition.dx, globalPosition.dy, 0, 1),
    );
    
    final canvasX = (transformedOffset.x - _initialOffset) / _canvasScale;
    final canvasY = (transformedOffset.y - _initialOffset) / _canvasScale;

    // Track current position for proximity detection
    _currentCanvasPosition = Offset(canvasX, canvasY);

    widget.onPresenceUpdate!(canvasX, canvasY);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: (event) => _broadcastPresence(event.position),
      onPointerMove: (event) => _broadcastPresence(event.position),
      child: GestureDetector(
        onLongPressStart: (details) {
          final Matrix4 matrix = _transformationController.value;
          final Matrix4 invertMatrix = Matrix4.inverted(matrix);
          
          // Transform the global touch point into the Stack's coordinate system
          final Vector4 transformedOffset = invertMatrix.transform(
            Vector4(details.globalPosition.dx, details.globalPosition.dy, 0, 1),
          );
          
          // Convert from Stack pixels to Canvas relative coordinates
          final canvasX = (transformedOffset.x - _initialOffset) / _canvasScale;
          final canvasY = (transformedOffset.y - _initialOffset) / _canvasScale;
          
          debugPrint('InfiniteCanvas: LongPress at Canvas ($canvasX, $canvasY)');
          widget.onLongPress(Offset(canvasX, canvasY));
        },
        child: InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.05,
          maxScale: 5.0,
          panEnabled: !widget.isDrawingMode,
          scaleEnabled: !widget.isDrawingMode,
          constrained: false,
          child: SizedBox(
            width: _virtualSize,
            height: _virtualSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Collaborative Ghost Pointers
                if (widget.currentUserId != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GhostPresencePainter(
                        presenceState: widget.presenceState,
                        currentUserId: widget.currentUserId!,
                        initialOffset: _initialOffset,
                        canvasScale: _canvasScale,
                        showStarFlare: true, // Enable star flare
                        currentUserPosition: _currentCanvasPosition,
                      ),
                    ),
                  ),

                ...widget.items.map((item) {
                  return Positioned(
                    left: _initialOffset + (item.xPos * _canvasScale),
                    top: _initialOffset + (item.yPos * _canvasScale),
                    child: CanvasItemWidget(
                      item: item,
                      onMoved: (x, y, rotation) {
                        widget.onItemMoved(item.id, x, y);
                      },
                      onDelete: () {},
                    ),
                  );
                }),
                
                if (widget.isDrawingMode && widget.drawingLayer != null)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: widget.drawingLayer!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
