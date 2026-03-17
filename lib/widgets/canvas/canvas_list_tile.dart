import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis_v2/models/oasis_canvas.dart';

class CanvasListTile extends StatelessWidget {
  final OasisCanvas canvas;
  final VoidCallback onTap;

  const CanvasListTile({
    super.key,
    required this.canvas,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverHex = canvas.coverColor.replaceAll('#', '');
    final coverColor = Color(int.parse('FF$coverHex', radix: 16));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              coverColor.withValues(alpha: 0.5),
              coverColor.withValues(alpha: 0.2),
            ],
          ),
          border: Border.all(
            color: coverColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                FluentIcons.whiteboard_24_regular,
                color: coverColor,
                size: 28,
              ),
              const Spacer(),
              Text(
                canvas.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${canvas.memberIds.length} member${canvas.memberIds.length == 1 ? '' : 's'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
