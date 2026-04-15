import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oasis/services/presence_service.dart';
import 'package:oasis/core/network/supabase_client.dart';

class UserPresence {
  final String status;
  final DateTime? lastSeen;
  UserPresence({required this.status, this.lastSeen});
}

class PresenceProvider with ChangeNotifier {
  final PresenceService _presenceService = PresenceService();
  final Map<String, UserPresence> _userPresence = {};

  // Polling fallback for user presence (when realtime presence sync fails)
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 10);
  final Set<String> _trackedUserIds = {};

  UserPresence? getUserPresence(String userId) => _userPresence[userId];

  bool isUserOnline(String userId) => _userPresence[userId]?.status == 'online';

  void subscribeToUserPresence(String userId) {
    // Track user ID for polling fallback
    _trackedUserIds.add(userId);

    _presenceService.subscribeToUserPresence(
      userId: userId,
      onUpdate: (status, lastSeen) {
        _userPresence[userId] = UserPresence(
          status: status,
          lastSeen: lastSeen,
        );
        notifyListeners();
      },
    );

    // Start polling fallback if not started
    _startPollingFallback();
  }

  void updateUserPresence(String userId, String status) {
    _presenceService.updateUserPresence(userId, status);
  }

  void unsubscribeFromUserPresence(String userId) {
    _presenceService.unsubscribeFromPresence(userId);
    _userPresence.remove(userId);
    _trackedUserIds.remove(userId);
    notifyListeners();

    // Stop polling if no more users to track
    if (_trackedUserIds.isEmpty) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    super.dispose();
  }

  /// Start polling fallback to sync presence when realtime fails.
  void _startPollingFallback() {
    if (_pollingTimer != null) return; // Already running

    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _pollUserPresence();
    });
  }

  /// Poll user presence directly from database.
  Future<void> _pollUserPresence() async {
    for (final userId in _trackedUserIds) {
      try {
        final result = await _presenceService.getUserStatus(userId);

        if (result != null) {
          final status = result['status'] as String? ?? 'offline';
          final lastSeenStr = result['last_seen'] as String?;
          final lastSeen =
              lastSeenStr != null ? DateTime.parse(lastSeenStr) : null;

          _userPresence[userId] = UserPresence(
            status: status,
            lastSeen: lastSeen,
          );
        } else {
          _userPresence[userId] = UserPresence(
            status: 'offline',
            lastSeen: null,
          );
        }
        notifyListeners();
      } catch (e) {
        debugPrint('[PresenceProvider] Polling error for $userId: $e');
      }
    }
  }
}
