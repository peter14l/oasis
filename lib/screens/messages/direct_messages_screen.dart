import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis_v2/models/conversation.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/providers/typing_indicator_provider.dart';
import 'package:oasis_v2/widgets/messages/unread_badge_widget.dart';
import 'package:oasis_v2/widgets/messages/typing_indicator_widget.dart';
import 'package:oasis_v2/screens/messages/chat_screen.dart';
import 'package:oasis_v2/services/vault_service.dart';
import 'package:oasis_v2/providers/conversation_provider.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  Conversation? _selectedConversation;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final conversationProvider = Provider.of<ConversationProvider>(context);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Left Pane: Conversation List
            SizedBox(
              width: 350,
              child: Scaffold(
                backgroundColor: const Color(0xFF0C0F14),
                appBar: AppBar(
                  title: const Text(
                    'Messages',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  centerTitle: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push('/new-message'),
                    ),
                  ],
                ),
                body: _buildConversationList(isDesktop: true),
              ),
            ),
            // Divider
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
            // Right Pane: Chat Detail
            Expanded(
              child:
                  _selectedConversation == null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select a conversation',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                      : ChatScreen(
                        key: ValueKey(_selectedConversation!.id),
                        conversationId: _selectedConversation!.id,
                        otherUserName: _selectedConversation!.otherUserName,
                        otherUserAvatar: _selectedConversation!.otherUserAvatar,
                        otherUserId: _selectedConversation!.otherUserId,
                      ),
            ),
          ],
        ),
      );
    }

    // Mobile Layout
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/new-message'),
          ),
        ],
      ),
      body: _buildConversationList(isDesktop: false),
    );
  }

  Widget _buildConversationList({required bool isDesktop}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = Provider.of<ConversationProvider>(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text('No messages yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Start a conversation!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.conversations.length,
        itemBuilder: (context, index) {
          final conversation = provider.conversations[index];
          return _buildConversationItem(conversation, isDesktop);
        },
      ),
    );
  }

  Widget _buildConversationItem(Conversation conversation, bool isDesktop) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected =
        isDesktop && _selectedConversation?.id == conversation.id;

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;

    return Consumer2<TypingIndicatorProvider, VaultService>(
      builder: (context, typingProvider, vaultService, child) {
        final isTyping = typingProvider.isUserTyping(conversation.id);
        final isLocked = vaultService.isInVaultSync(conversation.id);
        final isUnlocked = vaultService.isItemUnlocked(conversation.id);
        final canShow = !isLocked || isUnlocked;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                    : colorScheme.surface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected
                      ? colorScheme.primary.withValues(alpha: 0.3)
                      : colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ListTile(
                selected: isSelected,
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          conversation.otherUserAvatar.isNotEmpty
                              ? CachedNetworkImageProvider(
                                conversation.otherUserAvatar,
                              )
                              : null,
                      child:
                          conversation.otherUserAvatar.isEmpty
                              ? Text(
                                conversation.otherUserName[0].toUpperCase(),
                              )
                              : null,
                    ),
                    if (isLocked && !isUnlocked)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  conversation.otherUserName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight:
                        conversation.unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isTyping)
                      TypingIndicatorWidget(
                        username: conversation.otherUserName,
                      )
                    else if (!canShow)
                      Text(
                        'Locked by Vault',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (conversation.lastMessage != null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.getLastMessageDisplay(userId),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: conversation.unreadCount > 0 
                                  ? colorScheme.onSurface 
                                  : colorScheme.onSurfaceVariant,
                                fontWeight: conversation.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (conversation.lastMessageReadAt != null &&
                              conversation.lastMessageSenderId == userId)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '• Seen',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary.withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                trailing:
                    canShow && conversation.lastMessageTime != null
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTimestamp(conversation.lastMessageTime!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    conversation.unreadCount > 0
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                fontWeight:
                                    conversation.unreadCount > 0
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                              ),
                            ),
                            if (conversation.unreadCount > 0) ...[
                              const SizedBox(height: 4),
                              UnreadBadgeWidget(
                                count: conversation.unreadCount,
                              ),
                            ],
                          ],
                        )
                        : null,
                onTap: () async {
                  if (isLocked && !isUnlocked) {
                    final authorized = await vaultService.authenticate(
                      itemId: conversation.id,
                      context: context,
                    );
                    if (!authorized) {
                      return; // Only return if authentication failed
                    }
                  }

                  // Mark as read locally and on server using the provider
                  if (context.mounted) {
                    context.read<ConversationProvider>().markAsRead(conversation.id);
                  }

                  if (isDesktop) {
                    setState(() {
                      _selectedConversation = conversation;
                    });
                  } else {
                    if (mounted) {
                      context
                          .push(
                            '/messages/${conversation.id}',
                            extra: {
                              'otherUserName': conversation.otherUserName,
                              'otherUserAvatar': conversation.otherUserAvatar,
                              'otherUserId': conversation.otherUserId,
                            },
                          )
                          .then((_) {
                            // The provider will handle real-time sync when returning
                          });
                    }
                  }
                },
              ),
            ),
          ),
        );
      },
    );

  }

  Widget _getMessageTypeIcon(String type) {
    IconData icon;
    switch (type) {
      case 'image':
        icon = Icons.image;
        break;
      case 'document':
        icon = Icons.description;
        break;
      case 'voice':
        icon = Icons.mic;
        break;
      case 'poll':
        icon = Icons.poll;
        break;
      case 'location':
        icon = Icons.location_on;
        break;
      default:
        icon = Icons.message;
    }

    return Icon(
      icon,
      size: 16,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year % 100}';
    }
  }
}
