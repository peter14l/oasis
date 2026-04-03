import 'package:flutter/material.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/previews/media_view_mode_selector.dart';

/// Video preview bar shown above the input area when a video is selected.
/// Extracted from _buildVideoPreview() in chat_screen.dart.
class VideoPreview extends StatelessWidget {
  const VideoPreview({
    super.key,
    required this.mediaViewMode,
    required this.onDismiss,
    required this.onViewModeChanged,
  });

  final String mediaViewMode;
  final VoidCallback onDismiss;
  final Function(String) onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.videocam_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text('Video selected'),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: onDismiss),
            ],
          ),
          const SizedBox(height: 8),
          MediaViewModeSelector(
            currentMode: mediaViewMode,
            onModeChanged: onViewModeChanged,
          ),
        ],
      ),
    );
  }
}
