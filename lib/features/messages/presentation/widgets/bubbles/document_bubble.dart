import 'package:flutter/material.dart';
import 'package:oasis_v2/services/media_download_service.dart';

/// Document/file message bubble with download support.
/// Extracted from the document branch of _buildMessageBubble() in chat_screen.dart.
class DocumentBubble extends StatelessWidget {
  const DocumentBubble({
    super.key,
    required this.fileName,
    required this.mediaUrl,
    required this.isMe,
    this.textColor,
  });

  final String fileName;
  final String? mediaUrl;
  final bool isMe;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        textColor ??
        (isMe
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            fileName,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.download, size: 20, color: color),
          onPressed:
              mediaUrl != null
                  ? () async {
                    final mediaDownloadService = MediaDownloadService();
                    try {
                      await mediaDownloadService.downloadDocument(
                        mediaUrl!,
                        fileName,
                        context,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Document downloaded'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Download failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                  : null,
        ),
      ],
    );
  }
}
