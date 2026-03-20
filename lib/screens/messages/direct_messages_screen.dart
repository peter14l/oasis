import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  double _scrollVelocity = 0;
  double _lastScrollOffset = 0;
  final bool _useMockData = true;
  String _searchQuery = '';

  // Track custom sizes for each conversation: 0 = Compact, 1 = Tall, 2 = Wide
  final Map<String, int> _conversationSizes = {};

  // Stealth Preview State
  Conversation? _previewConversation;
  Offset _previewPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadConversationSizes();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadConversationSizes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encoded = prefs.getString('conversation_sizes');
      if (encoded != null) {
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        setState(() {
          _conversationSizes.addAll(decoded.map((k, v) => MapEntry(k, v as int)));
        });
      }
    } catch (e) {
      debugPrint('Error loading conversation sizes: $e');
    }
  }

  Future<void> _saveConversationSizes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('conversation_sizes', jsonEncode(_conversationSizes));
    } catch (e) {
      debugPrint('Error saving conversation sizes: $e');
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;
    if (mounted) {
      setState(() {
        _scrollVelocity = delta.clamp(-20, 20);
        _lastScrollOffset = currentOffset;
      });
    }
  }

  void _toggleSize(String id) {
    HapticFeedback.mediumImpact();
    setState(() {
      final currentSize = _conversationSizes[id] ?? 0;
      _conversationSizes[id] = (currentSize + 1) % 3;
    });
    _saveConversationSizes();
  }

  void _showStealthPreview(Conversation conversation, Offset position) {
    HapticFeedback.heavyImpact();
    setState(() {
      _previewConversation = conversation;
      _previewPosition = position;
    });
  }

  void _hideStealthPreview() {
    if (_previewConversation != null) {
      setState(() {
        _previewConversation = null;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF080A0E),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Messages',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/new-message'),
              ),
            ],
          ),
          body: _buildConversationList(isDesktop: isDesktop),
        ),
        
        // Stealth Preview Overlay
        if (_previewConversation != null)
          _StealthPreviewPopup(
            conversation: _previewConversation!,
            position: _previewPosition,
            onDismiss: _hideStealthPreview,
          ),
      ],
    );
  }

  Widget _buildConversationList({required bool isDesktop}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = Provider.of<ConversationProvider>(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Conversation> allConversations = [
      ...provider.conversations,
      if (_useMockData) ..._generateMockConversations(),
    ];

    final List<Conversation> filteredConversations = allConversations.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.otherUserName.toLowerCase().contains(query) || 
             (c.lastMessage?.toLowerCase().contains(query) ?? false);
    }).toList();

    final pinnedConversations = filteredConversations.where((c) => c.isPinned).toList();
    final regularConversations = filteredConversations.where((c) => !c.isPinned).toList();

    return RefreshIndicator(
      onRefresh: provider.loadConversations,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 15),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ) 
                      : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
          ),

          if (pinnedConversations.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FAVORITES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'LONG-PRESS TO RESIZE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ).animate(onPlay: (c) => c.repeat())
                     .shimmer(delay: 2.seconds, duration: 1.5.seconds, color: colorScheme.primary.withValues(alpha: 0.8)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _BentoPinnedGrid(
                  conversations: pinnedConversations,
                  onTap: (c) => _handleConversationTap(c, isDesktop),
                  isSelected: (c) => isDesktop && _selectedConversation?.id == c.id,
                  conversationSizes: _conversationSizes,
                  onToggleSize: _toggleSize,
                ),
              ),
            ),
          ],

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Text(
                'RECENT BUBBLES',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // THE BUBBLE STREAM
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Wrap(
                spacing: 20,
                runSpacing: 24,
                children: regularConversations.map((c) => _FloatingBubble(
                  conversation: c,
                  onTap: () => _handleConversationTap(c, isDesktop),
                  onLongPress: (pos) => _showStealthPreview(c, pos),
                )).toList(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  List<Conversation> _generateMockConversations() {
    final names = [
      'Alex Rivera', 'Sarah Chen', 'Jordan Smith', 'Mila Kunis', 'David Bowie',
      'Elena Gilbert', 'Marcus Aurelius', 'Luna Lovegood', 'Peter Parker', 'Tony Stark',
      'Wanda Maximoff', 'Steve Rogers', 'Natasha Romanoff', 'Bruce Banner', 'Diana Prince',
      'Arthur Curry', 'Barry Allen', 'Victor Stone', 'Hal Jordan', 'Oliver Queen'
    ];

    return List.generate(names.length, (index) {
      // Add unread counts and recent messages to some of the mock chats
      int unread = 0;
      List<String> mockMessages = [];
      
      if (index == 0) {
        unread = 3;
        mockMessages = [
          "Hey! Did you see the new UI updates?",
          "The thought bubbles look amazing 🫧",
          "Can't wait to test this with the founding 20!"
        ];
      } else if (index == 7) {
        unread = 1;
        mockMessages = ["Checking in on the beta progress!"];
      } else if (index == 12) {
        unread = 5;
        mockMessages = [
          "Wait, the stealth preview is so cool",
          "I can read all these without marking as read?",
          "That's a privacy game changer",
          "Let's grab coffee later",
          "Actually, let's make it bubble tea 🧋"
        ];
      }

      return Conversation(
        id: 'mock_$index',
        otherUserId: 'user_$index',
        otherUserName: names[index],
        otherUserAvatar: '', 
        lastMessage: mockMessages.isNotEmpty ? mockMessages.last : 'High-fidelity mock message! 🚀',
        lastMessageTime: DateTime.now().subtract(Duration(minutes: index * 15)),
        unreadCount: unread,
        isPinned: index < 6, 
        recentMessages: mockMessages,
      );
    });
  }

  void _handleConversationTap(Conversation conversation, bool isDesktop) async {
    final vaultService = Provider.of<VaultService>(context, listen: false);
    final isLocked = vaultService.isInVaultSync(conversation.id);
    final isUnlocked = vaultService.isItemUnlocked(conversation.id);

    if (isLocked && !isUnlocked) {
      final authorized = await vaultService.authenticate(
        itemId: conversation.id,
        context: context,
      );
      if (!authorized) return;
    }

    if (isDesktop) {
      setState(() {
        _selectedConversation = conversation;
      });
    } else {
      if (mounted) {
        context.push(
          '/messages/${conversation.id}',
          extra: {
            'otherUserName': conversation.otherUserName,
            'otherUserAvatar': conversation.otherUserAvatar,
            'otherUserId': conversation.otherUserId,
          },
        );
      }
    }
  }
}

class _BentoPinnedGrid extends StatelessWidget {
  final List<Conversation> conversations;
  final Function(Conversation) onTap;
  final bool Function(Conversation) isSelected;
  final Map<String, int> conversationSizes;
  final Function(String) onToggleSize;

  const _BentoPinnedGrid({
    required this.conversations,
    required this.onTap,
    required this.isSelected,
    required this.conversationSizes,
    required this.onToggleSize,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: conversations.map((conversation) {
        final sizeTier = conversationSizes[conversation.id] ?? 0;
        
        int crossAxis = 2;
        int mainAxis = 1;

        if (sizeTier == 1) {
          mainAxis = 2;
        } else if (sizeTier == 2) {
          crossAxis = 4;
          mainAxis = 1;
        }

        return StaggeredGridTile.count(
          crossAxisCellCount: crossAxis,
          mainAxisCellCount: mainAxis,
          child: _BentoItem(
            conversation: conversation,
            onTap: () => onTap(conversation),
            onLongPress: () => onToggleSize(conversation.id),
            selected: isSelected(conversation),
            isLarge: mainAxis > 1,
            isWide: crossAxis > 2,
          ),
        );
      }).toList(),
    );
  }
}

class _BentoItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selected;
  final bool isLarge;
  final bool isWide;

  const _BentoItem({
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
    required this.selected,
    required this.isLarge,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vibeColor = _getVibeColor(conversation.otherUserName);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.white.withValues(alpha: 0.05),
            width: selected ? 2 : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              vibeColor.withValues(alpha: 0.12),
              vibeColor.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Stack(
              children: [
                Positioned(
                  top: -15,
                  right: -15,
                  child: Container(
                    width: isWide ? 150 : 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          vibeColor.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 3.seconds),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: isLarge 
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _PresenceRipple(
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundImage: conversation.otherUserAvatar.isNotEmpty
                                      ? CachedNetworkImageProvider(conversation.otherUserAvatar)
                                      : null,
                                  child: conversation.otherUserAvatar.isEmpty
                                      ? Text(conversation.otherUserName[0].toUpperCase(), style: const TextStyle(fontSize: 12))
                                      : null,
                                ),
                              ),
                              if (conversation.unreadCount > 0)
                                UnreadBadgeWidget(count: conversation.unreadCount),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            conversation.otherUserName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900, 
                              fontSize: 14,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            conversation.lastMessage ?? 'No messages',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          _PresenceRipple(
                            child: CircleAvatar(
                              radius: 16,
                              backgroundImage: conversation.otherUserAvatar.isNotEmpty
                                  ? CachedNetworkImageProvider(conversation.otherUserAvatar)
                                  : null,
                              child: conversation.otherUserAvatar.isEmpty
                                  ? Text(conversation.otherUserName[0].toUpperCase(), style: const TextStyle(fontSize: 10))
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conversation.otherUserName,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isWide)
                                  Text(
                                    conversation.lastMessage ?? '',
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: colorScheme.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (conversation.unreadCount > 0)
                            UnreadBadgeWidget(count: conversation.unreadCount),
                        ],
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(delay: 100.ms, duration: 200.ms);
  }
}

class _FloatingBubble extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final Function(Offset) onLongPress;

  const _FloatingBubble({
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vibeColor = _getVibeColor(conversation.otherUserName);

    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (details) => onLongPress(details.globalPosition),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Solid White Attached "Thought Bubble" tails - Symmetrical & Side-by-Side
              Positioned(
                bottom: -2,
                right: 18,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 1), // Sharp definition
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2.seconds),
              ),
              Positioned(
                bottom: -6,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 0.5),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.5.seconds),
              ),

              _PresenceRipple(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A1D24), // Match dark surface
                    border: Border.all(
                      color: Colors.white, // 100% Opacity White Border
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: vibeColor.withValues(alpha: 0.05),
                        child: conversation.otherUserAvatar.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: conversation.otherUserAvatar,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Text(
                                  conversation.otherUserName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: vibeColor.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              if (conversation.unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: UnreadBadgeWidget(count: conversation.unreadCount),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 70,
            child: Text(
              conversation.otherUserName.split(' ')[0],
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: conversation.unreadCount > 0 ? FontWeight.w900 : FontWeight.w600,
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn();
  }
}

class _StealthPreviewPopup extends StatelessWidget {
  final Conversation conversation;
  final Offset position;
  final VoidCallback onDismiss;

  const _StealthPreviewPopup({
    required this.conversation,
    required this.position,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final vibeColor = _getVibeColor(conversation.otherUserName);
    
    const double popupHeight = 380;
    const double popupWidth = 280;
    final double safeTop = padding.top + kToolbarHeight + 10;
    final double safeBottom = size.height - padding.bottom - 20;

    // Center horizontally on tap, with edge padding
    double left = position.dx - (popupWidth / 2);
    if (left < 20) left = 20;
    if (left + popupWidth > size.width - 20) left = size.width - popupWidth - 20;

    // Vertical Logic: Try to place ABOVE the tap point first
    double top = position.dy - popupHeight - 20; 
    
    // If it hits the navbar/top, flip it to BELOW the tap point
    if (top < safeTop) {
      top = position.dy + 30;
    }

    // Final safety check: ensure it doesn't bleed off the bottom
    if (top + popupHeight > safeBottom) {
      top = safeBottom - popupHeight;
    }
    
    // If it's still too high (rare case), nudge it down
    if (top < safeTop) top = safeTop;

    final messages = conversation.recentMessages.isNotEmpty 
        ? conversation.recentMessages 
        : [conversation.lastMessage ?? 'No preview available'];

    return GestureDetector(
      onTap: onDismiss,
      onVerticalDragStart: (_) => onDismiss(),
      onHorizontalDragStart: (_) => onDismiss(),
      child: Container(
        color: Colors.black.withValues(alpha: 0.7), // Deeper dim for better focus
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: popupWidth,
                height: popupHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: vibeColor.withValues(alpha: 0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: vibeColor.withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.75),
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: conversation.otherUserAvatar.isNotEmpty
                                      ? CachedNetworkImageProvider(conversation.otherUserAvatar)
                                      : null,
                                  child: conversation.otherUserAvatar.isEmpty
                                      ? Text(conversation.otherUserName[0], style: const TextStyle(fontSize: 12))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    conversation.otherUserName,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.visibility_off_rounded, size: 16, color: Colors.white54),
                              ],
                            ),
                          ),
                          
                          const Divider(height: 1, color: Colors.white10),

                          // Scrollable Message List
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16).copyWith(
                                      bottomLeft: const Radius.circular(4),
                                    ),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  child: Text(
                                    messages[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Footer Info
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                            child: Text(
                              'PEEKING • ${messages.length} UNREAD',
                              style: TextStyle(
                                color: vibeColor.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms).scale(curve: Curves.easeOutBack, begin: const Offset(0.8, 0.8)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _PresenceRipple extends StatelessWidget {
  final Widget child;
  final bool active;

  const _PresenceRipple({required this.child, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (active)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 2),
            ),
          ).animate(onPlay: (c) => c.repeat())
           .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds)
           .fadeOut(),
        child,
      ],
    );
  }
}

Color _getVibeColor(String name) {
  final int hash = name.hashCode;
  final colors = [
    Colors.blue,
    Colors.purple,
    const Color(0xFFD946EF), 
    Colors.teal,
    Colors.indigo,
    Colors.cyan,
    const Color(0xFF3B82F6), 
    const Color(0xFFA3E635), 
  ];
  return colors[hash.abs() % colors.length];
}

String _formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.isNegative || difference.inMinutes < 1) {
    return 'Just now';
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
