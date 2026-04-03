import 'package:flutter/material.dart';

/// Audio preview bar shown above the input area when audio is selected.
/// Extracted from _buildAudioPreview() in chat_screen.dart.
class AudioPreview extends StatelessWidget {
  const AudioPreview({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.audio_file_rounded, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Audio selected',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onDismiss),
        ],
      ),
    );
  }
}
