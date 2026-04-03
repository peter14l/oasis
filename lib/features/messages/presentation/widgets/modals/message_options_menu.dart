import 'package:flutter/material.dart';
import 'package:oasis_v2/models/message.dart';
import 'package:oasis_v2/widgets/messages/forward_message_modal.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

/// Desktop context menu for message options.
/// Extracted from the desktop branch of _showMessageOptions() in chat_screen.dart.
class MessageOptionsMenu extends StatelessWidget {
  const MessageOptionsMenu({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.position,
    required this.onReply,
    required this.onForward,
    required this.onCopy,
    required this.onUnsend,
  });

  final Message message;
  final bool isOwnMessage;
  final Offset position;
  final VoidCallback onReply;
  final VoidCallback onForward;
  final VoidCallback onCopy;
  final VoidCallback onUnsend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      elevation: 8,
      items: <PopupMenuEntry>[
        PopupMenuItem(
          onTap: onReply,
          child: const Row(
            children: [
              Icon(FluentIcons.arrow_reply_24_regular, size: 20),
              SizedBox(width: 12),
              Text('Reply'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              useRootNavigator: true,
              builder:
                  (context) =>
                      SafeArea(child: ForwardMessageModal(message: message)),
            );
          },
          child: const Row(
            children: [
              Icon(FluentIcons.share_24_regular, size: 20),
              SizedBox(width: 12),
              Text('Forward'),
            ],
          ),
        ),
        if (message.messageType == MessageType.text &&
            message.content != '🔒 Message encrypted')
          PopupMenuItem(
            onTap: () {
              onCopy();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Row(
              children: [
                Icon(FluentIcons.copy_24_regular, size: 20),
                SizedBox(width: 12),
                Text('Copy Text'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        if (isOwnMessage)
          PopupMenuItem(
            onTap: onUnsend,
            child: Row(
              children: [
                Icon(
                  FluentIcons.delete_24_regular,
                  size: 20,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 12),
                Text('Unsend', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );

    return const SizedBox.shrink();
  }
}
