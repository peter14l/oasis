import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:oasis/features/messages/presentation/screens/image_preview_screen.dart';

import 'package:oasis/widgets/spoiler_widget.dart';

/// Video message bubble with view-once/allow-replay support.
/// Extracted from the video branch of _buildMessageBubble() in chat_screen.dart.
class VideoBubble extends StatelessWidget {
  const VideoBubble({
    super.key,
    required this.mediaUrl,
    required this.mediaFileName,
    required this.isMe,
    this.mediaViewMode = 'unlimited',
    this.currentUserViewCount = 0,
    this.messageId,
    this.textColor,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.isSpoiler = false,
  });

  final String mediaUrl;
  final String? mediaFileName;
  final bool isMe;
  final String mediaViewMode;
  final int currentUserViewCount;
  final String? messageId;
  final Color? textColor;
  final bool isUploading;
  final double uploadProgress;
  final bool isSpoiler;

  bool get _isRestricted => mediaViewMode == 'once' || mediaViewMode == 'twice';
  int get _viewLimit => mediaViewMode == 'once' ? 1 : 2;
  bool get _isViewed => _isRestricted && currentUserViewCount >= _viewLimit;
  bool get _isLocalFile => !mediaUrl.startsWith('http') && !mediaUrl.startsWith('https');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        textColor ??
        (isMe
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface);

    if (_isRestricted && !isUploading) {
      return GestureDetector(
        onTap:
            _isViewed
                ? null
                : () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => ImagePreviewScreen(
                            imageUrl: mediaUrl,
                            caption: null,
                            messageId: messageId,
                            mediaViewMode: mediaViewMode,
                          ),
                    ),
                  );
                  // Caller should refresh messages to update view counts
                },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isMe
                        ? Colors.white.withValues(alpha: 0.2)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam_rounded,
                size: 20,
                color:
                    _isViewed
                        ? (isMe ? Colors.white54 : Colors.grey)
                        : (isMe ? Colors.white : theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _isViewed ? 'Opened' : 'Video',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    _isViewed
                        ? (isMe ? Colors.white54 : Colors.grey)
                        : (isMe ? Colors.white : theme.colorScheme.onSurface),
                fontWeight: _isViewed ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      );
    }

    Widget content;
    if (isUploading) {
      content = Container(
        width: 200,
        height: 120,
        decoration: BoxDecoration(
          color: isMe ? Colors.black.withValues(alpha: 0.1) : theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_rounded, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  mediaFileName ?? 'Video',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: Center(
                    child: Text(
                      '${(uploadProgress * 100).toInt()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: uploadProgress,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 4,
              ),
            ),
          ],
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_rounded, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              mediaFileName ?? 'Video',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      );
    }

    if (isSpoiler) {
      return SpoilerWidget(child: content);
    }
    return content;
  }
}
