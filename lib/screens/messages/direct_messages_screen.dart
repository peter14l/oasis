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
import 'package:oasis_v2/screens/messages/chat_details_screen.dart';
import 'package:oasis_v2/services/vault_service.dart';
import 'package:oasis_v2/providers/conversation_provider.dart';

class DirectMessagesScreen extends StatefulWidget {
  final String? initialConversationId;
  final Map<String, dynamic>? initialConversationData;

  const DirectMessagesScreen({
    super.key,
    this.initialConversationId,
    this.initialConversationData,
  });

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  Conversation? _selectedConversation;
  bool _showDetails = false;
  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  double _scrollVelocity = 0;
  double _lastScrollOffset = 0;
  final bool _useMockData = true;
  String _searchQuery = '';

  final Map<String, int> _conversationSizes = {};
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

    if (widget.initialConversationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setInitialConversation());
    }
  }

  @override
  void didUpdateWidget(DirectMessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialConversationId != oldWidget.initialConversationId && 
        widget.initialConversationId != null) {
      _setInitialConversation();
    }
  }

  void _setInitialConversation() {
    if (!mounted) return;
    final provider = Provider.of<ConversationProvider>(context, listen: false);
    final convId = widget.initialConversationId!;
    
    final realConv = provider.conversations.where((c) => c.id == convId).firstOrNull;
    if (realConv != null) {
      setState(() => _selectedConversation = realConv);
      return;
    }

    // Check if we have extra data passed (e.g. from NewMessageScreen)
    if (widget.initialConversationData != null) {
      final data = widget.initialConversationData!;
      setState(() {
        _selectedConversation = Conversation(
          id: convId,
          otherUserId: data['otherUserId'] ?? '',
          otherUserName: data['otherUserName'] ?? 'Unknown',
          otherUserAvatar: data['otherUserAvatar'] ?? '',
          lastMessage: '',
          lastMessageTime: DateTime.now(),
          unreadCount: 0,
        );
      });
      return;
    }

    final mockConv = _generateMockConversations().where((c) => c.id == convId).firstOrNull;
    if (mockConv != null) {
      setState(() => _selectedConversation = mockConv);
    }
  }

  Future<void> _loadConversationSizes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encoded = prefs.getString('conversation_sizes');
      if (encoded != null) {
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _conversationSizes.addAll(decoded.map((k, v) => MapEntry(k, v as int)));
        });
      }
    } catch (e) {
      debugPrint('Error loading sizes: $e');
    }
  }

  Future<void> _saveConversationSizes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('conversation_sizes', jsonEncode(_conversationSizes));
    } catch (e) {
      debugPrint('Error saving sizes: $e');
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
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      final currentSize = _conversationSizes[id] ?? 0;
      _conversationSizes[id] = (currentSize + 1) % 3;
    });
    _saveConversationSizes();
  }

  void _showStealthPreview(Conversation conversation, Offset position) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _previewConversation = conversation;
      _previewPosition = position;
    });
  }

  void _hideStealthPreview() {
    if (_previewConversation != null && mounted) {
      setState(() {
        _previewConversation = null;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content;

    if (isDesktop) {
      content = Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Pane 1: Inbox (Floating)
            Container(
              width: 350,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    children: [
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
                        actions: [
                          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/new-message')),
                        ],
                      ),
                      Expanded(child: _buildConversationList(isDesktop: true)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Pane 2: Chat (Floating)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _selectedConversation == null
                          ? Center(
                              key: const ValueKey('empty'),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white.withValues(alpha: 0.05))
                                      .animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
                                  const SizedBox(height: 16),
                                  Text('SELECT A CONVERSATION', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.2), fontWeight: FontWeight.w900, letterSpacing: 2)),
                                ],
                              ),
                            )
                          : Stack(
                              key: ValueKey(_selectedConversation!.id),
                              children: [
                                ChatScreen(
                                  conversationId: _selectedConversation!.id,
                                  otherUserName: _selectedConversation!.otherUserName,
                                  otherUserAvatar: _selectedConversation!.otherUserAvatar,
                                  otherUserId: _selectedConversation!.otherUserId,
                                ),
                                // Details Toggle Button (Desktop Only)
                                Positioned(
                                  top: 12,
                                  right: 16,
                                  child: IconButton(
                                    icon: Icon(_showDetails ? Icons.info : Icons.info_outline),
                                    onPressed: () => setState(() => _showDetails = !_showDetails),
                                    color: colorScheme.onSurface,
                                    style: IconButton.styleFrom(
                                      backgroundColor: colorScheme.surface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            // Pane 3: Details (Floating)
            if (isDesktop && _selectedConversation != null && _showDetails) ...[
              const SizedBox(width: 12),
              Container(
                width: 350,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: ChatDetailsScreen(
                      conversationId: _selectedConversation!.id,
                      otherUserName: _selectedConversation!.otherUserName,
                      otherUserAvatar: _selectedConversation!.otherUserAvatar,
                      otherUserId: _selectedConversation!.otherUserId,
                      isWhisperMode: false,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      content = Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Messages', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
          centerTitle: true,
          actions: [
            IconButton(icon: Icon(Icons.edit_outlined, color: colorScheme.onSurface), onPressed: () => context.push('/new-message')),
          ],
        ),
        body: _buildConversationList(isDesktop: false),
      );
    }

    return Stack(
      children: [
        content,
        if (_previewConversation != null)
          _StealthPreviewPopup(conversation: _previewConversation!, position: _previewPosition, onDismiss: _hideStealthPreview),
      ],
    );
  }

  Widget _buildConversationList({required bool isDesktop}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = Provider.of<ConversationProvider>(context);

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());

    final List<Conversation> allConversations = [...provider.conversations, if (_useMockData) ..._generateMockConversations()];
    final List<Conversation> filteredConversations = allConversations.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.otherUserName.toLowerCase().contains(query) || (c.lastMessage?.toLowerCase().contains(query) ?? false);
    }).toList();

    final pinnedConversations = filteredConversations.where((c) => c.isPinned).toList();
    final regularConversations = filteredConversations.where((c) => !c.isPinned).toList();

    return RefreshIndicator(
      onRefresh: provider.loadConversations,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                    Text('FAVORITES', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.3), fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    Text('LONG-PRESS TO RESIZE', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary.withValues(alpha: 0.4), fontWeight: FontWeight.w800, fontSize: 8)).animate(onPlay: (c) => c.repeat()).shimmer(delay: 2.seconds),
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
              child: Text('RECENT BUBBLES', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.3), fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Wrap(
                spacing: 20, runSpacing: 24,
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
    final names = ['Alex Rivera', 'Sarah Chen', 'Jordan Smith', 'Mila Kunis', 'David Bowie', 'Elena Gilbert', 'Marcus Aurelius', 'Luna Lovegood', 'Peter Parker', 'Tony Stark', 'Wanda Maximoff', 'Steve Rogers', 'Natasha Romanoff', 'Bruce Banner', 'Diana Prince', 'Arthur Curry', 'Barry Allen', 'Victor Stone', 'Hal Jordan', 'Oliver Queen'];
    return List.generate(names.length, (index) {
      int unread = 0;
      List<String> mockMessages = [];
      if (index == 0) { unread = 3; mockMessages = ["Hey!", "The bubbles look amazing 🫧", "Can't wait to test!"]; }
      else if (index == 12) { unread = 5; mockMessages = ["Wait, stealth preview?", "Cool", "Privacy game changer", "Coffee?", "Bubble tea!"]; }
      return Conversation(id: 'mock_$index', otherUserId: 'user_$index', otherUserName: names[index], otherUserAvatar: '', lastMessage: mockMessages.isNotEmpty ? mockMessages.last : 'Hello!', lastMessageTime: DateTime.now().subtract(Duration(minutes: index * 15)), unreadCount: unread, isPinned: index < 6, recentMessages: mockMessages);
    });
  }

  void _handleConversationTap(Conversation conversation, bool isDesktop) async {
    final vaultService = Provider.of<VaultService>(context, listen: false);
    if (vaultService.isInVaultSync(conversation.id) && !vaultService.isItemUnlocked(conversation.id)) {
      final authorized = await vaultService.authenticate(itemId: conversation.id, context: context);
      if (!authorized) return;
    }

    if (isDesktop) {
      setState(() => _selectedConversation = conversation);
    } else {
      if (mounted) context.push('/messages/${conversation.id}', extra: {'otherUserName': conversation.otherUserName, 'otherUserAvatar': conversation.otherUserAvatar, 'otherUserId': conversation.otherUserId});
    }
  }
}

class _BentoPinnedGrid extends StatelessWidget {
  final List<Conversation> conversations;
  final Function(Conversation) onTap;
  final bool Function(Conversation) isSelected;
  final Map<String, int> conversationSizes;
  final Function(String) onToggleSize;
  const _BentoPinnedGrid({required this.conversations, required this.onTap, required this.isSelected, required this.conversationSizes, required this.onToggleSize});
  @override
  Widget build(BuildContext context) {
    return StaggeredGrid.count(
      crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10,
      children: conversations.map((conversation) {
        final sizeTier = conversationSizes[conversation.id] ?? 0;
        int crossAxis = 2; int mainAxis = 1;
        if (sizeTier == 1) mainAxis = 2; else if (sizeTier == 2) crossAxis = 4;
        return StaggeredGridTile.count(crossAxisCellCount: crossAxis, mainAxisCellCount: mainAxis, child: _BentoItem(conversation: conversation, onTap: () => onTap(conversation), onLongPress: () => onToggleSize(conversation.id), selected: isSelected(conversation), isLarge: mainAxis > 1, isWide: crossAxis > 2));
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
  const _BentoItem({required this.conversation, required this.onTap, required this.onLongPress, required this.selected, required this.isLarge, this.isWide = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vibeColor = _getVibeColor(conversation.otherUserName);
    return GestureDetector(
      onTap: onTap, onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.2), width: selected ? 2 : 1), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [vibeColor.withValues(alpha: 0.12), vibeColor.withValues(alpha: 0.04)])),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Stack(
              children: [
                Positioned(top: -15, right: -15, child: Container(width: isWide ? 150 : 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [vibeColor.withValues(alpha: 0.15), Colors.transparent]))).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 3.seconds)),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: isLarge 
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_PresenceRipple(child: CircleAvatar(radius: 20, backgroundImage: conversation.otherUserAvatar.isNotEmpty ? CachedNetworkImageProvider(conversation.otherUserAvatar) : null, child: conversation.otherUserAvatar.isEmpty ? Text(conversation.otherUserName[0].toUpperCase(), style: const TextStyle(fontSize: 12)) : null)), if (conversation.unreadCount > 0) UnreadBadgeWidget(count: conversation.unreadCount)]), const Spacer(), Text(conversation.otherUserName, style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 14, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis), Text(conversation.lastMessage ?? 'No messages', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)])
                    : Row(children: [_PresenceRipple(child: CircleAvatar(radius: 16, backgroundImage: conversation.otherUserAvatar.isNotEmpty ? CachedNetworkImageProvider(conversation.otherUserAvatar) : null, child: conversation.otherUserAvatar.isEmpty ? Text(conversation.otherUserName[0].toUpperCase(), style: const TextStyle(fontSize: 10)) : null)), const SizedBox(width: 8), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(conversation.otherUserName, style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), if (isWide) Text(conversation.lastMessage ?? '', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis)])), if (conversation.unreadCount > 0) UnreadBadgeWidget(count: conversation.unreadCount)]),
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
  const _FloatingBubble({required this.conversation, required this.onTap, required this.onLongPress});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vibeColor = _getVibeColor(conversation.otherUserName);
    return GestureDetector(
      onTap: onTap, onLongPressStart: (details) => onLongPress(details.globalPosition),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(bottom: -2, right: 18, child: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.black, width: 1))).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2.seconds)),
              Positioned(bottom: -6, right: 10, child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.black, width: 0.5))).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.5.seconds)),
              _PresenceRipple(child: Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.surface, border: Border.all(color: colorScheme.primary, width: 2.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]), child: ClipOval(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: Container(color: vibeColor.withValues(alpha: 0.05), child: conversation.otherUserAvatar.isNotEmpty ? CachedNetworkImage(imageUrl: conversation.otherUserAvatar, fit: BoxFit.cover) : Center(child: Text(conversation.otherUserName[0].toUpperCase(), style: TextStyle(color: vibeColor.withValues(alpha: 0.8), fontWeight: FontWeight.bold, fontSize: 20)))))))),
              if (conversation.unreadCount > 0) Positioned(top: -2, right: -2, child: UnreadBadgeWidget(count: conversation.unreadCount)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(width: 70, child: Text(conversation.otherUserName.split(' ')[0], style: theme.textTheme.labelSmall?.copyWith(fontWeight: conversation.unreadCount > 0 ? FontWeight.w900 : FontWeight.w600, fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.7), letterSpacing: 0.5), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final vibeColor = _getVibeColor(conversation.otherUserName);
    const double popupHeight = 380;
    const double popupWidth = 280;
    final double safeTop = padding.top + kToolbarHeight + 10;
    final double safeBottom = size.height - padding.bottom - 20;

    double left = position.dx - (popupWidth / 2);
    if (left < 20) left = 20;
    if (left + popupWidth > size.width - 20) left = size.width - popupWidth - 20;

    double top = position.dy - popupHeight - 20;
    if (top < safeTop) top = position.dy + 30;
    if (top + popupHeight > safeBottom) top = safeBottom - popupHeight;
    if (top < safeTop) top = safeTop;

    final messages = conversation.recentMessages.isNotEmpty
        ? conversation.recentMessages
        : [conversation.lastMessage ?? 'No preview available'];

    return GestureDetector(
      onTap: onDismiss,
      onVerticalDragStart: (_) => onDismiss(),
      onHorizontalDragStart: (_) => onDismiss(),
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
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
                  border: Border.all(
                    color: vibeColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: vibeColor.withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
                      child: Column(
                        children: [
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
                                      ? Text(
                                          conversation.otherUserName[0],
                                          style: const TextStyle(fontSize: 12),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    conversation.otherUserName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.visibility_off_rounded,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16).copyWith(
                                    bottomLeft: const Radius.circular(4),
                                  ),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  messages[index],
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
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
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .scale(
                    curve: Curves.easeOutBack,
                    begin: const Offset(0.8, 0.8),
                  ),
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
    return Stack(alignment: Alignment.center, children: [if (active) Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 2))).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds).fadeOut(), child]);
  }
}

Color _getVibeColor(String name) {
  final int hash = name.hashCode;
  final colors = [Colors.blue, Colors.purple, const Color(0xFFD946EF), Colors.teal, Colors.indigo, Colors.cyan, const Color(0xFF3B82F6), const Color(0xFFA3E635)];
  return colors[hash.abs() % colors.length];
}

String _formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);
  if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inDays < 1) return '${difference.inHours}h';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays}d';
  return '${timestamp.month}/${timestamp.day}/${timestamp.year % 100}';
}
