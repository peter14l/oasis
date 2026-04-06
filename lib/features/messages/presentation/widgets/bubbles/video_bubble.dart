import 'package:flutter/material.dart';
import 'package:oasis/features/messages/presentation/screens/image_preview_screen.dart';

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
  });

  final String mediaUrl;
  final String? mediaFileName;
  final bool isMe;
  final String mediaViewMode;
  final int currentUserViewCount;
  final String? messageId;
  final Color? textColor;

  bool get _isRestricted => mediaViewMode == 'once' || mediaViewMode == 'twice';
  int get _viewLimit => mediaViewMode == 'once' ? 1 : 2;
  bool get _isViewed => _isRestricted && currentUserViewCount >= _viewLimit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        textColor ??
        (isMe
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface);

    if (_isRestricted) {
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

    return Row(
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
}
