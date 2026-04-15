import 'package:flutter/material.dart';
import 'package:oasis/services/media_download_service.dart';
import 'package:oasis/features/messages/domain/models/message.dart';

/// Document/file message bubble with download support.
class DocumentBubble extends StatelessWidget {
  const DocumentBubble({
    super.key,
    required this.fileName,
    required this.mediaUrl,
    required this.isMe,
    this.fileSize,
    this.textColor,
  });

  final String fileName;
  final String? mediaUrl;
  final bool isMe;
  final int? fileSize;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final extension = fileName.split('.').last.toLowerCase();
    
    // Determine icon and color based on extension
    IconData fileIcon = Icons.insert_drive_file;
    Color iconColor = isMe ? Colors.white : colorScheme.onSurfaceVariant;
    
    if (!isMe) {
        if (extension == 'pdf') {
          fileIcon = Icons.picture_as_pdf;
          iconColor = Colors.red;
        } else if (extension == 'doc' || extension == 'docx') {
          fileIcon = Icons.description;
          iconColor = Colors.blue;
        } else if (extension == 'xls' || extension == 'xlsx' || extension == 'csv') {
          fileIcon = Icons.grid_on;
          iconColor = Colors.green;
        } else if (extension == 'ppt' || extension == 'pptx') {
          fileIcon = Icons.slideshow;
          iconColor = Colors.orange;
        }
    }

    final color =
        textColor ??
        (isMe
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface);

    return Container(
      width: 250,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isMe ? Colors.black.withValues(alpha: 0.1) : colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white.withValues(alpha: 0.2) : iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(fileIcon, color: isMe ? Colors.white : iconColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          extension.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.7)),
                        ),
                        if (fileSize != null) ...[
                          Text(
                            ' • ',
                            style: theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.7)),
                          ),
                          Text(
                            Message.formatBytes(fileSize),
                            style: theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.7)),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: color.withValues(alpha: 0.1)),
          InkWell(
            onTap: mediaUrl != null
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text('Download', style: theme.textTheme.labelLarge?.copyWith(color: color)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
