import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/models/conversation.dart';
import 'package:oasis_v2/services/messaging_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationProvider with ChangeNotifier {
  final MessagingService _messagingService = MessagingService();
  
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _currentUserId;
  
  // Realtime subscriptions
  RealtimeChannel? _conversationsSubscription;
  final Map<String, RealtimeChannel> _readReceiptSubscriptions = {};
  final Map<String, RealtimeChannel> _typingSubscriptions = {};
  
  // Getters
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  int get totalUnreadCount => _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);

  /// Initialize and load conversations
  Future<void> initialize(String? userId) async {
    if (userId == null) {
      _currentUserId = null;
      _conversations = [];
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    if (_currentUserId == userId && _conversations.isNotEmpty) return;
    
    _currentUserId = userId;
    _conversations = [];
    _isLoading = true;
    notifyListeners();
    
    await loadConversations();
    _setupRealtimeSubscriptions();
  }

  /// Load conversations from service
  Future<void> loadConversations() async {
    if (_currentUserId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _conversations = await _messagingService.getConversations(userId: _currentUserId!);
      
      // Setup individual subscriptions for each conversation (read receipts, typing)
      for (final conversation in _conversations) {
        _listenToConversationDetails(conversation.id);
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Setup global and conversation-specific subscriptions
  void _setupRealtimeSubscriptions() {
    if (_currentUserId == null) return;
    
    // Stop existing global subscription
    _conversationsSubscription?.unsubscribe();
    
    // Subscribe to unread count changes and participant changes
    _conversationsSubscription = _messagingService.subscribeToConversations(
      userId: _currentUserId!,
      onUpdate: () {
        // Refresh the whole list for now to ensure consistency
        loadConversations();
      },
    );
  }

  /// Listen for read receipts and typing status for a specific conversation
  void _listenToConversationDetails(String conversationId) {
    if (_readReceiptSubscriptions.containsKey(conversationId)) return;
    
    // Subscribe to read receipts (for "Seen" status)
    final readReceiptChannel = _messagingService.subscribeToReadReceipts(
      conversationId: conversationId,
      onUpdate: (messageId, userId, readAt) {
        _handleReadReceiptUpdate(conversationId);
      },
    );
    _readReceiptSubscriptions[conversationId] = readReceiptChannel;
    
    // Subscribe to typing status
    final typingChannel = _messagingService.subscribeToTypingStatus(
      conversationId: conversationId,
      onTypingUpdate: (userId, isTyping) {
        if (userId != _currentUserId) {
          _handleTypingUpdate(conversationId, isTyping);
        }
      },
    );
    _typingSubscriptions[conversationId] = typingChannel;
  }

  /// Handle read receipt updates for a specific conversation
  Future<void> _handleReadReceiptUpdate(String conversationId) async {
    // Optimization: Instead of reloading everyone, just reload this conversation's seen status
    // or reload the whole list to maintain sort order if last message changed.
    loadConversations();
  }

  /// Reload a single conversation's state
  Future<void> refreshConversation(String conversationId) async {
    if (_currentUserId == null) return;
    
    try {
      final updatedConversation = await _messagingService.getConversationDetails(conversationId);
      
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = updatedConversation;
        // Move to top of list if it's the newest message
        _conversations.sort((a, b) {
          final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA);
        });
        notifyListeners();
      } else {
        // If it's a new conversation, just reload everything
        loadConversations();
      }
    } catch (e) {
      debugPrint('Error refreshing conversation: $e');
    }
  }

  /// Handle typing status updates
  void _handleTypingUpdate(String conversationId, bool isTyping) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        isOtherUserTyping: isTyping,
      );
      notifyListeners();
    }
  }

  /// Mark a conversation as read locally and on server
  Future<void> markAsRead(String conversationId) async {
    if (_currentUserId == null) return;
    
    try {
      await _messagingService.markConversationAsRead(conversationId, _currentUserId!);
      
      // Update local state immediately for responsiveness
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
    }
  }

  @override
  void dispose() {
    _conversationsSubscription?.unsubscribe();
    for (final channel in _readReceiptSubscriptions.values) {
      channel.unsubscribe();
    }
    for (final channel in _typingSubscriptions.values) {
      channel.unsubscribe();
    }
    super.dispose();
  }
}
