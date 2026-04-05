import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis/features/canvas/domain/models/canvas_models.dart';
import 'package:oasis/widgets/canvas/journal_entry_widget.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

/// Draggable and long-press-deletable item on the canvas.
class CanvasItemWidget extends StatefulWidget {
  final CanvasItemEntity item;
  final void Function(double x, double y, double rotation) onMoved;
  final VoidCallback onDelete;
  final void Function(String emoji)? onReact;
  final void Function(bool lock)? onLock;

  const CanvasItemWidget({
    super.key,
    required this.item,
    required this.onMoved,
    required this.onDelete,
    this.onReact,
    this.onLock,
  });

  @override
  State<CanvasItemWidget> createState() => _CanvasItemWidgetState();
}

class _CanvasItemWidgetState extends State<CanvasItemWidget> {
  late double _x;
  late double _y;
  late double _rotation;
  bool _selected = false;
  bool _isDraggingLocally = false;

  @override
  void initState() {
    super.initState();
    _x = widget.item.xPos;
    _y = widget.item.yPos;
    _rotation = widget.item.rotation;
  }

  @override
  void didUpdateWidget(CanvasItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDraggingLocally) {
      _x = widget.item.xPos;
      _y = widget.item.yPos;
      _rotation = widget.item.rotation;
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.item.isLocked) return;
    setState(() => _isDraggingLocally = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.item.isLocked) return;
    setState(() {
      _x += details.delta.dx;
      _y += details.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.item.isLocked) return;
    setState(() => _isDraggingLocally = false);
    widget.onMoved(_x, _y, _rotation);
  }

  void _onLongPress() {
    setState(() => _selected = true);
    _showItemOptions();
  }

  void _showItemOptions() {
    final currentUserId = context.read<ProfileProvider>().currentProfile?.id;
    final isAuthor = widget.item.authorId == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      ['❤️', '😂', '🔥', '✨', '😢']
                          .map(
                            (emoji) => IconButton(
                              onPressed: () {
                                widget.onReact?.call(emoji);
                                Navigator.pop(context);
                              },
                              icon: Text(
                                emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const Divider(height: 32),
                if (isAuthor)
                  ListTile(
                    leading: Icon(
                      widget.item.isLocked
                          ? FluentIcons.lock_open_24_regular
                          : FluentIcons.lock_closed_24_regular,
                    ),
                    title: Text(
                      widget.item.isLocked ? 'Unlock Item' : 'Lock Item',
                    ),
                    onTap: () {
                      widget.onLock?.call(!widget.item.isLocked);
                      Navigator.pop(context);
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    FluentIcons.delete_24_regular,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Remove from Canvas',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDelete();
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<ProfileProvider>().currentProfile?.id;
    final isBeingModifiedByOther =
        widget.item.lastModifiedBy != null &&
        widget.item.lastModifiedBy != currentUserId;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onLongPress: _onLongPress,
      onTap: () => setState(() => _selected = !_selected),
      child: Transform.rotate(
        angle: _rotation * 3.14159 / 180,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Interaction Halo
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isBeingModifiedByOther
                          ? Colors.blue.withValues(alpha: 0.5)
                          : (_selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent),
                  width: 2,
                ),
                boxShadow:
                    isBeingModifiedByOther
                        ? [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                        : [],
              ),
              child: _buildContent(),
            ),

            // Lock Indicator
            if (widget.item.isLocked)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FluentIcons.lock_closed_12_filled,
                    size: 12,
                    color: Colors.black,
                  ),
                ),
              ),

            // Reactions
            if (widget.item.reactions.isNotEmpty)
              Positioned(
                bottom: -12,
                left: 0,
                right: 0,
                child: Wrap(
                  spacing: 4,
                  alignment: WrapAlignment.center,
                  children:
                      widget.item.reactions.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${entry.value.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
          ],
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
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        );

      case CanvasItemType.sticker:
        return Text(widget.item.content, style: const TextStyle(fontSize: 48));

      case CanvasItemType.photo:
        return Container(
          constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: widget.item.content,
              fit: BoxFit.contain,
              placeholder:
                  (context, url) => Container(
                    width: 150,
                    height: 150,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    width: 150,
                    height: 150,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
            ),
          ),
        );

      case CanvasItemType.voice:
        return Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(FluentIcons.play_24_filled, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
        );

      case CanvasItemType.milestone:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FluentIcons.star_16_filled,
                size: 14,
                color: Colors.black,
              ),
              const SizedBox(width: 6),
              Text(
                widget.item.content,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

      case CanvasItemType.journal:
        return JournalEntryWidget(
          content: widget.item.content,
          createdAt: widget.item.createdAt,
        );
    }
  }
}
