import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/models/notification.dart';
import 'package:oasis_v2/services/notification_service.dart';
import 'package:oasis_v2/services/notification_manager.dart';
import 'package:oasis_v2/services/encryption_service.dart';
import 'package:oasis_v2/services/signal/signal_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final NotificationManager _notificationManager = NotificationManager.instance;
  final EncryptionService _encryptionService = EncryptionService();
  final SignalService _signalService = SignalService();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  RealtimeChannel? _subscriptionChannel;
  String? _userId;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Initialize with a user ID (called when auth state changes)
  Future<void> init(String? userId) async {
    if (_userId == userId) return; // No change

    _userId = userId;
    _cleanup(); // Clean up old subscription

    if (_userId != null) {
      // Initialize local notification manager
      await _notificationManager.initialize();
      if (_notificationManager.isSupported) {
        await _notificationManager.requestPermission();
      }

      await _loadNotifications();
      _subscribe();
    } else {
      _notifications = [];
      notifyListeners();
    }
  }

  Future<void> _loadNotifications() async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications(
        userId: _userId!,
      );
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribe() {
    if (_userId == null) return;

    _subscriptionChannel = _notificationService.subscribeToNotifications(
      userId: _userId!,
      onNewNotification: (notification) async {
        // Only add to the UI list if it's not a DM
        if (notification.type != 'dm') {
          _notifications.insert(0, notification);
          notifyListeners();
        }

        String body = notification.getNotificationText();

        // If it's a DM, try to decrypt it using the message metadata
        if (notification.type == 'dm' && notification.messageId != null) {
          try {
            // Fetch the actual message record to get encryption metadata
            final supabase = Supabase.instance.client;
            final messageResponse = await supabase
                .from('messages')
                .select('content, sender_id, encrypted_keys, iv, signal_message_type, signal_sender_content')
                .eq('id', notification.messageId!)
                .maybeSingle();

            if (messageResponse != null) {
              final content = messageResponse['content'] as String?;
              final senderId = messageResponse['sender_id'] as String;
              final encryptedKeys = messageResponse['encrypted_keys'] as Map<String, dynamic>?;
              final iv = messageResponse['iv'] as String?;
              final signalType = messageResponse['signal_message_type'] as int?;
              final rsaContent = messageResponse['signal_sender_content'] as String?;

              if (content != null) {
                String? decrypted;
                
                // Try Signal decryption first
                if (signalType != null) {
                   await _signalService.init();
                   decrypted = await _signalService.decryptMessage(senderId, content, signalType);
                   
                   // Fallback to RSA if Signal fails or returns placeholder
                   if ((decrypted.contains('🔒 Message encrypted') || decrypted.contains('Optimizing secure connection')) && 
                       encryptedKeys != null && iv != null && rsaContent != null) {
                     decrypted = await _encryptionService.decryptMessage(
                       rsaContent,
                       Map<String, String>.from(encryptedKeys),
                       iv,
                     );
                   }
                } 
                // Try standard RSA decryption
                else if (encryptedKeys != null && iv != null) {
                  decrypted = await _encryptionService.decryptMessage(
                    content,
                    Map<String, String>.from(encryptedKeys),
                    iv,
                  );
                }

                if (decrypted != null && !decrypted.contains('🔒 Message encrypted')) {
                  body = decrypted;
                }
              }
            }
          } catch (e) {
            debugPrint('Error decrypting notification message: $e');
            // Fallback to the encrypted placeholder already in 'body'
          }
        }

        // ALWAYS show local notification (OS alert)
        _notificationManager.showNotification(
          title: notification.displayTitle,
          body: body,
          payload: notification.postId ?? notification.messageId, // Or route path
          senderAvatar: notification.actorAvatar,
        );
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;
    await _notificationService.markAllAsRead(_userId!);
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  Future<void> clearAll() async {
    if (_userId == null) return;
    await _notificationService.clearAllNotifications(_userId!);
    _notifications = [];
    notifyListeners();
  }

  void _cleanup() {
    if (_subscriptionChannel != null) {
      _notificationService.unsubscribeFromNotifications(_subscriptionChannel!);
      _subscriptionChannel = null;
    }
  }

  void clear() {
    _notifications = [];
    _isLoading = false;
    _cleanup();
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}
