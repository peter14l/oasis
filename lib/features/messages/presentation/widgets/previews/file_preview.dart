import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// File preview bar shown above the input area when a file is selected.
/// Extracted from _buildFilePreview() in chat_screen.dart.
class FilePreview extends StatelessWidget {
  const FilePreview({super.key, required this.file, required this.onDismiss});

  final PlatformFile file;
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
          Icon(Icons.insert_drive_file, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onDismiss),
        ],
      ),
    );
  }
}
