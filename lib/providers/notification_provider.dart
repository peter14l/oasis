import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/models/notification.dart';
import 'package:oasis_v2/services/notification_service.dart';
import 'package:oasis_v2/services/notification_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final NotificationManager _notificationManager = NotificationManager.instance;

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
      onNewNotification: (notification) {
        _notifications.insert(0, notification);
        notifyListeners();

        // Show local notification
        _notificationManager.showNotification(
          title: notification.displayTitle,
          body: notification.getNotificationText(),
          payload: notification.postId, // Or route path
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

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}
