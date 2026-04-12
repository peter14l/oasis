import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/core/network/supabase_client.dart';

class PresenceService {
  final SupabaseClient _supabase = SupabaseService().client;
  final Map<String, RealtimeChannel> _presenceChannels = {};

  // Track subscription state to prevent race conditions
  final Map<String, bool> _channelSubscribed = {};

  // Debounce: skip redundant updates with same status
  final Map<String, String> _lastTrackedStatus = {};

  // Track a user's presence in a specific conversation or globally
  RealtimeChannel subscribeToUserPresence({
    required String userId,
    required Function(String status, DateTime? lastSeen) onUpdate,
  }) {
    final channelName = 'user_presence:$userId';

    if (_presenceChannels.containsKey(channelName)) {
      return _presenceChannels[channelName]!;
    }

    final channel = _supabase.channel(channelName);

    channel
        .onPresenceSync((payload) {
          final presenceState = channel.presenceState();
          if (presenceState.isEmpty) {
            onUpdate('offline', null);
            return;
          }

          // Check if any session for this user is online
          bool isOnline = false;
          DateTime? latestSeen;

          for (final singlePresence in presenceState) {
            for (final presence in singlePresence.presences) {
              final status = presence.payload['status'] as String?;
              if (status == 'online') {
                isOnline = true;
              }
              final lastSeenStr = presence.payload['last_seen'] as String?;
              if (lastSeenStr != null) {
                final lastSeen = DateTime.parse(lastSeenStr);
                if (latestSeen == null || lastSeen.isAfter(latestSeen)) {
                  latestSeen = lastSeen;
                }
              }
            }
          }

          onUpdate(isOnline ? 'online' : 'offline', latestSeen);
        })
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError) {
            debugPrint(
              'PresenceService: subscribeToUserPresence error: $error',
            );
          } else if (status == RealtimeSubscribeStatus.subscribed) {
            _channelSubscribed[channelName] = true;
          }
        });

    _presenceChannels[channelName] = channel;
    _channelSubscribed[channelName] = false; // Will be set to true in callback
    return channel;
  }

  // Update current user's presence
  Future<void> updateUserPresence(String userId, String status) async {
    // Debounce: skip if same status already tracked
    final cachedStatus = _lastTrackedStatus[userId];
    if (cachedStatus == status) {
      return; // Skip redundant update
    }

    // Update cached status
    _lastTrackedStatus[userId] = status;

    final channelName = 'user_presence:$userId';
    RealtimeChannel channel;
    bool isNewChannel = false;

    if (_presenceChannels.containsKey(channelName)) {
      channel = _presenceChannels[channelName]!;
    } else {
      channel = _supabase.channel(channelName);
      _presenceChannels[channelName] = channel;
      isNewChannel = true;
      _channelSubscribed[channelName] = false;
    }

    // If new channel, ensure it's subscribed before tracking
    if (isNewChannel) {
      channel.subscribe();
      // Wait briefly for subscription to complete
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      await channel.track({
        'status': status,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('PresenceService: Failed to track presence - ${e.toString()}');
    }
  }

  void unsubscribeFromPresence(String userId) {
    final channelName = 'user_presence:$userId';
    if (_presenceChannels.containsKey(channelName)) {
      _supabase.removeChannel(_presenceChannels[channelName]!);
      _presenceChannels.remove(channelName);
      _channelSubscribed.remove(channelName);
      _lastTrackedStatus.remove(userId);
    }
  }
}
