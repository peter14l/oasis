import 'package:flutter/foundation.dart';
import 'package:oasis_v2/config/supabase_config.dart';
import 'package:oasis_v2/models/notification.dart';
import 'package:oasis_v2/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final _supabase = SupabaseService().client;

  /// Get user's notifications
  Future<List<AppNotification>> getNotifications({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.notificationsTable)
          .select('''
            *,
            ${SupabaseConfig.profilesTable}:actor_id (
              username,
              avatar_url
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response.isEmpty) return [];

      final List<AppNotification> notifications = [];
      for (final item in response) {
        final notificationMap = Map<String, dynamic>.from(item);
        final profile = notificationMap[SupabaseConfig.profilesTable];
        if (profile != null) {
          notificationMap['actor_name'] = profile['username'];
          notificationMap['actor_avatar'] = profile['avatar_url'];
        }
        notifications.add(AppNotification.fromJson(notificationMap));
      }

      return notifications;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from(SupabaseConfig.notificationsTable)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from(SupabaseConfig.notificationsTable)
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.notificationsTable)
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from(SupabaseConfig.notificationsTable)
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Subscribe to new notifications
  RealtimeChannel subscribeToNotifications({
    required String userId,
    required Function(AppNotification) onNewNotification,
  }) {
    final channel = _supabase.channel('notifications:$userId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.notificationsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            try {
              final notificationData = payload.newRecord;

              // Fetch actor details
              if (notificationData['actor_id'] != null) {
                final profile =
                    await _supabase
                        .from(SupabaseConfig.profilesTable)
                        .select('username, avatar_url')
                        .eq('id', notificationData['actor_id'])
                        .single();

                notificationData['actor_name'] = profile['username'];
                notificationData['actor_avatar'] = profile['avatar_url'];
              }

              final notification = AppNotification.fromJson(notificationData);
              onNewNotification(notification);
            } catch (e) {
              debugPrint('Error processing new notification: $e');
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from notifications
  Future<void> unsubscribeFromNotifications(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  /// Create a notification (for testing or manual creation)
  Future<void> createNotification({
    required String userId,
    required String type,
    required String actorId,
    String? postId,
    String? commentId,
    String? message,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.notificationsTable).insert({
        'user_id': userId,
        'type': type,
        'actor_id': actorId,
        'post_id': postId,
        'comment_id': commentId,
        'content': message,
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  /// Update FCM token for the user
  Future<void> updateFcmToken(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _supabase
            .from(SupabaseConfig.profilesTable)
            .update({'fcm_token': fcmToken})
            .eq('id', userId);
        debugPrint('FCM Token updated for user: $userId');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }
}
