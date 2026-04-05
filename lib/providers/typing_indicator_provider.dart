import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oasis/services/messaging_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TypingIndicatorProvider with ChangeNotifier {
  final MessagingService _messagingService = MessagingService();

  // Map of conversationId -> isTyping status
  final Map<String, bool> _typingStatus = {};

  // Map of conversationId -> RealtimeChannel
  final Map<String, RealtimeChannel> _subscriptions = {};

  // Debounce timers for stopping typing indicator
  final Map<String, Timer> _debounceTimers = {};

  // Local throttle to avoid spamming the database while typing
  final Map<String, DateTime> _lastDatabaseUpdate = {};

  // Getters
  bool isUserTyping(String conversationId) {
    return _typingStatus[conversationId] ?? false;
  }

  /// Set typing status for current user in a conversation
  Future<void> setTyping(
    String conversationId,
    String userId,
    bool isTyping,
  ) async {
    try {
      // Throttle database updates to once every 2 seconds when typing
      final lastUpdate = _lastDatabaseUpdate[conversationId];
      if (isTyping && lastUpdate != null && 
          DateTime.now().difference(lastUpdate).inSeconds < 2) {
        // Reset the auto-stop timer but don't hit the DB yet
        _debounceTimers[conversationId]?.cancel();
        _debounceTimers[conversationId] = Timer(const Duration(seconds: 4), () {
          setTyping(conversationId, userId, false);
        });
        return;
      }

      // Cancel existing debounce timer
      _debounceTimers[conversationId]?.cancel();

      // Update typing status in database
      await _messagingService.updateTypingStatus(
        conversationId,
        userId,
        isTyping,
      );
      
      _lastDatabaseUpdate[conversationId] = DateTime.now();

      // If typing, set a timer to auto-stop after 4 seconds of inactivity
      if (isTyping) {
        _debounceTimers[conversationId] = Timer(const Duration(seconds: 4), () {
          setTyping(conversationId, userId, false);
        });
      } else {
        _lastDatabaseUpdate.remove(conversationId);
      }
    } catch (e) {
      debugPrint('Error setting typing status: $e');
    }
  }

  /// Subscribe to typing status updates for a conversation
  void subscribeToTypingStatus(String conversationId, String currentUserId) {
    // Don't subscribe if already subscribed
    if (_subscriptions.containsKey(conversationId)) {
      return;
    }

    try {
      final channel = _messagingService.subscribeToTypingStatus(
        conversationId: conversationId,
        onTypingUpdate: (userId, isTyping) {
          // Only update if it's the other user typing (not current user)
          if (userId != currentUserId) {
            _typingStatus[conversationId] = isTyping;
            notifyListeners();

            // Auto-clear typing status after 5 seconds if still showing
            if (isTyping) {
              Future.delayed(const Duration(seconds: 5), () {
                if (_typingStatus[conversationId] == true) {
                  _typingStatus[conversationId] = false;
                  notifyListeners();
                }
              });
            }
          }
        },
      );

      _subscriptions[conversationId] = channel;
    } catch (e) {
      debugPrint('Error subscribing to typing status: $e');
    }
  }

  /// Unsubscribe from typing status updates
  Future<void> unsubscribeFromTypingStatus(String conversationId) async {
    final channel = _subscriptions[conversationId];
    if (channel != null) {
      await _messagingService.unsubscribeFromTypingStatus(channel);
      _subscriptions.remove(conversationId);
      _typingStatus.remove(conversationId);
      _debounceTimers[conversationId]?.cancel();
      _debounceTimers.remove(conversationId);
      notifyListeners();
    }
  }

  /// Clear all subscriptions
  Future<void> clearAll() async {
    for (final conversationId in _subscriptions.keys.toList()) {
      await unsubscribeFromTypingStatus(conversationId);
    }
    _typingStatus.clear();
    _debounceTimers.values.forEach((timer) => timer.cancel());
    _debounceTimers.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}
