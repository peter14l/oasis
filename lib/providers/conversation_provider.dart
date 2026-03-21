import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/models/conversation.dart';
import 'package:oasis_v2/services/messaging_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    
    // Load cache first
    await _loadCachedConversations();
    
    if (_conversations.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    
    await loadConversations();
    _setupRealtimeSubscriptions();
  }

  /// Load conversations from cache
  Future<void> _loadCachedConversations() async {
    if (_currentUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString('cached_conversations_${_currentUserId}');
      if (cachedData != null) {
        final List<dynamic> decodedData = jsonDecode(cachedData);
        _conversations = decodedData.map((item) => Conversation.fromJson(item)).toList();
        
        // Sort cached conversations
        _conversations.sort((a, b) {
          final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA);
        });

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached conversations: $e');
    }
  }

  /// Save conversations to cache
  Future<void> _saveConversationsToCache() async {
    if (_currentUserId == null || _conversations.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = jsonEncode(_conversations.map((c) => c.toJson()).toList());
      await prefs.setString('cached_conversations_${_currentUserId}', encodedData);
    } catch (e) {
      debugPrint('Error saving conversations to cache: $e');
    }
  }

  /// Load conversations from service
  Future<void> loadConversations() async {
    if (_currentUserId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _conversations = await _messagingService.getConversations(userId: _currentUserId!);
      
      // Ensure they are sorted by last message time (rearranged based on latest text)
      _conversations.sort((a, b) {
        final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });

      await _saveConversationsToCache();
      
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
      onUpdate: (conversationId) async {
        // Add a small delay to ensure DB triggers have finished updating the 'conversations' table
        await Future.delayed(const Duration(milliseconds: 300));
        refreshConversation(conversationId);
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
      } else {
        _conversations.insert(0, updatedConversation);
      }

      // Always re-sort to move the most recent conversation to the top
      _conversations.sort((a, b) {
        final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });
      
      notifyListeners();
      await _saveConversationsToCache();
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

  /// Manually update a conversation's last message time (useful for sender rearrangement)
  void onMessageSent(String conversationId, String content, String? type) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final now = DateTime.now();
      final conversation = _conversations[index];

      _conversations[index] = conversation.copyWith(
        lastMessage: content,
        lastMessageTime: now,
        lastMessageType: type ?? 'text',
        lastMessageSenderId: _currentUserId,
      );

      // Resort immediately to move this conversation to the top
      _conversations.sort((a, b) {
        final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });

      notifyListeners();
      _saveConversationsToCache();
    } else {
      // If conversation not in list (e.g. new message), refresh the whole list
      refreshConversation(conversationId);
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

  /// Clear all data (used during logout)
  Future<void> clear() async {
    // Stop subscriptions
    _conversationsSubscription?.unsubscribe();
    for (final channel in _readReceiptSubscriptions.values) {
      channel.unsubscribe();
    }
    for (final channel in _typingSubscriptions.values) {
      channel.unsubscribe();
    }
    
    _readReceiptSubscriptions.clear();
    _typingSubscriptions.clear();
    
    // Clear cache if we have a user
    if (_currentUserId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_conversations_${_currentUserId}');
      } catch (e) {
        debugPrint('Error clearing cached conversations: $e');
      }
    }
    
    _conversations = [];
    _currentUserId = null;
    _isLoading = false;
    notifyListeners();
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
