import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:morrow_v2/models/conversation.dart';
import 'package:morrow_v2/services/messaging_service.dart';
import 'package:morrow_v2/services/auth_service.dart';
import 'package:morrow_v2/providers/typing_indicator_provider.dart';
import 'package:morrow_v2/widgets/messages/unread_badge_widget.dart';
import 'package:morrow_v2/widgets/messages/typing_indicator_widget.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:morrow_v2/screens/messages/chat_screen.dart';
import 'package:morrow_v2/services/vault_service.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();

  List<Conversation> _conversations = [];
  Set<String> _lockedConversationIds = {};
  Conversation? _selectedConversation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    // Clean up typing subscriptions
    final typingProvider = context.read<TypingIndicatorProvider>();
    typingProvider.clearAll();
    super.dispose();
  }

  void _subscribeToTypingIndicators() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final typingProvider = context.read<TypingIndicatorProvider>();

    // Subscribe to typing status for all conversations
    for (final conversation in _conversations) {
      typingProvider.subscribeToTypingStatus(conversation.id, userId);
    }
  }

  Future<void> _loadConversations() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final conversations = await _messagingService.getConversations(
        userId: userId,
      );
      if (mounted) {
        // Check for locked conversations
        final vaultService = context.read<VaultService>();
        final lockedIds = <String>{};

        for (final conversation in conversations) {
          if (await vaultService.isInVault(conversation.id)) {
            lockedIds.add(conversation.id);
          }
        }

        setState(() {
          _conversations = conversations;
          _lockedConversationIds = lockedIds;
          _isLoading = false;
        });
      }

      // Subscribe to typing indicators after loading
      _subscribeToTypingIndicators();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
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

    return Consumer<TypingIndicatorProvider>(
      builder: (context, typingProvider, child) {
        final isTyping = typingProvider.isUserTyping(conversation.id);
        final isLocked = _lockedConversationIds.contains(conversation.id);
        final vaultService =
            context
                .read<
                  VaultService
                >(); // This won't rebuild on unlock automatically, handled by local state or re-check
        // We rely on local state updates or checking service.isUnlocked directly during build?
        // Provider<VaultService> is not a notifier. We check the property directly.
        final canShow = !isLocked || vaultService.isUnlocked;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? colorScheme.primaryContainer.withOpacity(0.15)
                    : colorScheme.surface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected
                      ? colorScheme.primary.withOpacity(0.3)
                      : colorScheme.outlineVariant.withOpacity(0.2),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                    if (isLocked && !vaultService.isUnlocked)
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
                            ? FontWeight.bold
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
                        'Protected by Vault',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (conversation.lastMessage != null)
                      Row(
                        children: [
                          // Show icon for media messages
                          if (conversation.lastMessageType != null &&
                              conversation.lastMessageType != 'text') ...[
                            _getMessageTypeIcon(conversation.lastMessageType!),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              conversation.getLastMessageDisplay(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight:
                                    conversation.unreadCount > 0
                                        ? FontWeight.w500
                                        : FontWeight.normal,
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
                                        ? FontWeight.bold
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
                  if (isLocked && !vaultService.isUnlocked) {
                    final authorized = await vaultService.authenticate(
                      context: context,
                    );
                    if (!authorized) {
                      return; // Only return if authentication failed
                    }
                    // If authorized, continue to open the chat below
                    if (mounted) {
                      setState(() {}); // Rebuild to show unlocked content
                    }
                  }

                  // Mark as read when opening
                  await _messagingService.markConversationAsRead(
                    conversation.id,
                    _authService.currentUser!.id,
                  );

                  if (isDesktop) {
                    setState(() {
                      _selectedConversation = conversation;
                    });
                  } else {
                    if (mounted) {
                      context
                          .push(
                            '/chat/${conversation.id}',
                            extra: {
                              'otherUserName': conversation.otherUserName,
                              'otherUserAvatar': conversation.otherUserAvatar,
                              'otherUserId': conversation.otherUserId,
                            },
                          )
                          .then((_) {
                            // Reload conversations when returning to check for updated lock status
                            _loadConversations();
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
