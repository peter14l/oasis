import 'package:flutter/material.dart';
import 'package:oasis_v2/models/canvas_item.dart';

/// Draggable and long-press-deletable item on the canvas.
class CanvasItemWidget extends StatefulWidget {
  final CanvasItem item;
  final void Function(double x, double y, double rotation) onMoved;
  final VoidCallback onDelete;

  const CanvasItemWidget({
    super.key,
    required this.item,
    required this.onMoved,
    required this.onDelete,
  });

  @override
  State<CanvasItemWidget> createState() => _CanvasItemWidgetState();
}

class _CanvasItemWidgetState extends State<CanvasItemWidget>
    with SingleTickerProviderStateMixin {
  late double _x;
  late double _y;
  late double _rotation;
  bool _selected = false;

  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _x = widget.item.xPos;
    _y = widget.item.yPos;
    _rotation = widget.item.rotation;

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _x += details.delta.dx;
      _y += details.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    widget.onMoved(_x, _y, _rotation);
  }

  void _onLongPress() {
    _scaleController.forward(from: 0);
    setState(() => _selected = true);
    _showDeleteOption();
  }

  void _showDeleteOption() {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove item?'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selected = false);
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              widget.onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onLongPress: _onLongPress,
        onTap: () => setState(() => _selected = !_selected),
        child: Transform.rotate(
          angle: _rotation * 3.14159 / 180,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    switch (widget.item.type) {
      case CanvasItemType.text:
        final bgHex = widget.item.color.replaceAll('#', '');
        final bgColor = Color(int.parse('FF$bgHex', radix: 16));
        return Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.item.content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
          ),
        );

      case CanvasItemType.sticker:
        return Container(
          padding: const EdgeInsets.all(4),
          child: Text(
            widget.item.content,
            style: const TextStyle(fontSize: 40),
          ),
        );

      case CanvasItemType.photo:
      case CanvasItemType.voice:
        // Placeholders for future implementation
        return Container(
          width: 120,
          height: 90,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.item.type == CanvasItemType.photo
                ? Icons.image_outlined
                : Icons.mic_none_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        );
    }
  }
}
