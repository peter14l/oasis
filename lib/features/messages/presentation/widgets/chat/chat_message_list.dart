import 'package:flutter/material.dart';
import 'package:oasis/models/message.dart';
import 'package:oasis/features/messages/presentation/widgets/bubbles/bubbles.dart';
import 'package:oasis/features/messages/presentation/widgets/bubbles/text_bubble.dart';
import 'package:oasis/widgets/skeleton_container.dart';

/// Chat message list with skeleton loading, empty state, and message rendering.
class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.currentUserId,
    required this.onMessageLongPress,
    required this.onMessageDoubleTap,
    this.headerHeight = 72,
    this.bubbleColorSent,
    this.bubbleColorReceived,
    this.textColorSent,
    this.textColorReceived,
    this.scrollController,
  });

  final List<Message> messages;
  final bool isLoading;
  final String? currentUserId;
  final Function(Message, Offset?) onMessageLongPress;
  final Function(Message) onMessageDoubleTap;
  final double headerHeight;
  final Color? bubbleColorSent;
  final Color? bubbleColorReceived;
  final Color? textColorSent;
  final Color? textColorReceived;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (isLoading && messages.isEmpty) {
      return _buildSkeletonLoading(context);
    }

    if (messages.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      reverse: true,
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + headerHeight + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        final isMe = message.senderId == currentUserId;
        return _buildMessageItem(context, message, isMe);
      },
    );
  }

  Widget _buildMessageItem(BuildContext context, Message message, bool isMe) {
    if (message.messageType == MessageType.system) {
      return SystemMessageBubble(content: message.content);
    }

    if (message.messageType == MessageType.text &&
        message.content.startsWith('[INVITE:')) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(message.content),
      );
    }

    return MessageBubble(
      message: message,
      isMe: isMe,
      bubbleColorSent: bubbleColorSent,
      bubbleColorReceived: bubbleColorReceived,
      textColorSent: textColorSent,
      textColorReceived: textColorReceived,
      onLongPress: () => onMessageLongPress(message, null),
      onDoubleTap: () => onMessageDoubleTap(message),
    );
  }

  Widget _buildSkeletonLoading(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + headerHeight + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: SkeletonContainer.rounded(
              width: 150.0 + (index % 3) * 50,
              height: 40.0 + (index % 2) * 20,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isMe ? const Radius.circular(4) : null,
                bottomLeft: !isMe ? const Radius.circular(4) : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text('No messages yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Main message bubble container that wraps specialized bubble types.
/// Handles: decoration, reply preview, read receipts, reactions.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onLongPress,
    required this.onDoubleTap,
    this.bubbleColorSent,
    this.bubbleColorReceived,
    this.textColorSent,
    this.textColorReceived,
  });

  final Message message;
  final bool isMe;
  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;
  final Color? bubbleColorSent;
  final Color? bubbleColorReceived;
  final Color? textColorSent;
  final Color? textColorReceived;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    final bubbleColor =
        isMe
            ? (bubbleColorSent ?? colorScheme.primary)
            : (bubbleColorReceived ?? colorScheme.surfaceContainerHighest);
    final textColor =
        isMe
            ? (textColorSent ?? colorScheme.onPrimaryContainer)
            : (textColorReceived ?? colorScheme.onSurface);

    Widget content = _buildContent(context, textColor);

    final bubbleDecoration = BoxDecoration(
      color: bubbleColor,
      borderRadius: BorderRadius.circular(24).copyWith(
        bottomRight: isMe ? const Radius.circular(8) : null,
        bottomLeft: !isMe ? const Radius.circular(8) : null,
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 0.1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );

    Widget bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: bubbleDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyToId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white70 : colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.replyToSenderName ?? 'Unknown',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isMe ? Colors.white : colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          message.replyToContent ?? 'Original message',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isMe
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          content,
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.done_all,
                  size: 14,
                  color: message.isRead ? Colors.blue : Colors.black,
                ),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth:
                isDesktop ? 400.0 : MediaQuery.of(context).size.width * 0.75,
          ),
          child: IntrinsicWidth(child: bubble),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    final theme = Theme.of(context);

    switch (message.messageType) {
      case MessageType.text:
        return TextBubble(
          content: message.content,
          isMe: isMe,
          textColor: textColor,
        );
      case MessageType.image:
        return ImageBubble(
          imageUrl: message.mediaUrl ?? '',
          caption: message.content,
          isMe: isMe,
          mediaViewMode: message.mediaViewMode,
          currentUserViewCount: message.currentUserViewCount,
          messageId: message.id,
          textColor: textColor,
        );
      case MessageType.document:
        if (message.mediaUrl?.contains('videos') ?? false) {
          return VideoBubble(
            mediaUrl: message.mediaUrl!,
            mediaFileName: message.mediaFileName,
            isMe: isMe,
            mediaViewMode: message.mediaViewMode,
            currentUserViewCount: message.currentUserViewCount,
            messageId: message.id,
            textColor: textColor,
          );
        }
        return DocumentBubble(
          fileName: message.mediaFileName ?? 'Document',
          mediaUrl: message.mediaUrl,
          isMe: isMe,
          textColor: textColor,
        );
      case MessageType.voice:
        return VoiceBubble(
          audioUrl: message.mediaUrl ?? '',
          duration: message.voiceDuration,
          isMe: isMe,
          textColor: textColor,
        );
      case MessageType.postShare:
        return PostShareBubble(message: message, isMe: isMe);
      case MessageType.ripple:
        return RippleShareBubble(message: message, isMe: isMe);
      case MessageType.storyReply:
        return StoryReplyBubble(
          message: message,
          isMe: isMe,
          formatTime: _formatTime,
        );
      default:
        return TextBubble(
          content: message.content,
          isMe: isMe,
          textColor: textColor,
        );
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
