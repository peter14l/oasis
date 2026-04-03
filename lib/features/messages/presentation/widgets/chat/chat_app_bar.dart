import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/providers/presence_provider.dart';
import 'package:oasis_v2/providers/typing_indicator_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

/// Chat app bar with avatar, presence indicator, encryption lock, and action buttons.
/// TODO: Fully extract from chat_screen.dart _buildAppBar section.
/// This is a placeholder — the actual implementation is still in the legacy screen.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    super.key,
    required this.otherUserName,
    this.otherUserAvatar,
    this.otherUserId,
    this.isEncryptionReady = false,
    this.isDesktop = false,
    this.isDetailsOpen = false,
    this.onDetailsToggle,
    this.onCallPressed,
    this.onVideoCallPressed,
    this.onSearchPressed,
  });

  final String otherUserName;
  final String? otherUserAvatar;
  final String? otherUserId;
  final bool isEncryptionReady;
  final bool isDesktop;
  final bool isDetailsOpen;
  final VoidCallback? onDetailsToggle;
  final VoidCallback? onCallPressed;
  final VoidCallback? onVideoCallPressed;
  final VoidCallback? onSearchPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage:
                    (otherUserAvatar ?? '').isNotEmpty
                        ? CachedNetworkImageProvider(otherUserAvatar!)
                        : null,
                child:
                    (otherUserAvatar ?? '').isEmpty
                        ? Text(
                          (otherUserName.isNotEmpty ? otherUserName[0] : 'U')
                              .toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 14,
                          ),
                        )
                        : null,
              ),
              Consumer<PresenceProvider>(
                builder: (context, presenceProvider, child) {
                  final isOnline =
                      otherUserId != null &&
                      presenceProvider.isUserOnline(otherUserId!);
                  return Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  otherUserName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: isDesktop ? 15 : 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Consumer<PresenceProvider>(
                  builder: (context, presenceProvider, child) {
                    final presence =
                        otherUserId != null
                            ? presenceProvider.getUserPresence(otherUserId!)
                            : null;
                    final isOnline = presence?.status == 'online';

                    return Row(
                      children: [
                        if (isEncryptionReady) ...[
                          Icon(
                            FluentIcons.lock_closed_12_filled,
                            size: 10,
                            color: colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isOnline
                              ? 'Online'
                              : (presence?.lastSeen != null
                                  ? 'Last seen ${_formatSeenTime(presence!.lastSeen!)}'
                                  : 'Offline'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isOnline
                                    ? Colors.green.withValues(alpha: 0.8)
                                    : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.7,
                                    ),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (isDesktop)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(FluentIcons.call_24_regular, size: 20),
                onPressed: onCallPressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(FluentIcons.video_24_regular, size: 20),
                onPressed: onVideoCallPressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(FluentIcons.search_24_regular, size: 20),
                onPressed: onSearchPressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  isDetailsOpen
                      ? FluentIcons.info_24_filled
                      : FluentIcons.info_24_regular,
                  size: 20,
                ),
                onPressed: onDetailsToggle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          )
        else
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'details') onDetailsToggle?.call();
            },
            icon: const Icon(Icons.more_vert, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 12),
                        Text('Details'),
                      ],
                    ),
                  ),
                ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  String _formatSeenTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
