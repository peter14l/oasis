import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis/features/messages/presentation/screens/image_preview_screen.dart';
import 'package:oasis/features/messages/presentation/widgets/bubbles/text_bubble.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/messages/presentation/providers/chat_provider.dart';

/// Image message bubble with view-once/allow-replay support.
/// Extracted from the image branch of _buildMessageBubble() in chat_screen.dart.
class ImageBubble extends StatelessWidget {
  const ImageBubble({
    super.key,
    required this.imageUrl,
    required this.caption,
    required this.isMe,
    this.mediaViewMode = 'unlimited',
    this.currentUserViewCount = 0,
    this.messageId,
    this.textColor,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  final String imageUrl;
  final String caption;
  final bool isMe;
  final String mediaViewMode;
  final int currentUserViewCount;
  final String? messageId;
  final Color? textColor;
  final bool isUploading;
  final double uploadProgress;

  bool get _isRestricted => mediaViewMode == 'once' || mediaViewMode == 'twice';
  int get _viewLimit => mediaViewMode == 'once' ? 1 : 2;
  bool get _isViewed => _isRestricted && currentUserViewCount >= _viewLimit;
  bool get _isLocalFile => !imageUrl.startsWith('http') && !imageUrl.startsWith('https');

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
                            imageUrl: imageUrl,
                            caption:
                                MessageTextUtils.isDisplayableCaption(caption)
                                    ? caption
                                    : null,
                            messageId: messageId,
                            mediaViewMode: mediaViewMode,
                          ),
                    ),
                  );
                  if (messageId != null && context.mounted) {
                    context.read<ChatProvider>().incrementLocalMediaViewCount(messageId!);
                  }
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
                Icons.camera_alt_rounded,
                size: 20,
                color:
                    _isViewed
                        ? (isMe ? Colors.white54 : Colors.grey)
                        : (isMe ? Colors.white : theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _isViewed ? 'Opened' : 'Photo',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isUploading ? null : () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => ImagePreviewScreen(
                      imageUrl: imageUrl,
                      caption:
                          MessageTextUtils.isDisplayableCaption(caption)
                              ? caption
                              : null,
                    ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300, maxWidth: 300),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _isLocalFile 
                    ? Image.file(
                        File(imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        placeholder:
                            (context, url) => const SizedBox(
                              height: 150,
                              width: 150,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                        fit: BoxFit.cover,
                      ),
                  if (isUploading) ...[
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
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
                ],
              ),
            ),
          ),
        ),
        if (MessageTextUtils.isDisplayableCaption(caption))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              caption.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
      ],
    );
  }
}
