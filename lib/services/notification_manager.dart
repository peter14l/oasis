import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:oasis_v2/routes/app_router.dart';

/// Cross-platform notification manager
class NotificationManager {
  static NotificationManager? _instance;
  bool _isInitialized = false;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  int _notificationId = 0;

  /// Singleton instance
  static NotificationManager get instance {
    _instance ??= NotificationManager._();
    return _instance!;
  }

  NotificationManager._();

  /// Initialize the notification manager
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (_isDesktop) {
        debugPrint(
          'NotificationManager: Initialized for desktop (${Platform.operatingSystem})',
        );
        _isInitialized = true;
        return true;
      } else if (_isMobile) {
        _isInitialized = true;
        await _initLocalNotifications();
        await _initFCM();
        return true;
      } else if (kIsWeb) {
        debugPrint('NotificationManager: Web notifications not supported');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('NotificationManager: Initialization failed: $e');
      return false;
    }
  }

  /// Check if platform supports notifications
  bool get isSupported => _isDesktop || _isMobile;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Show a simple notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationManager: Not initialized');
      return;
    }

    try {
      if (_isDesktop) {
        await _showDesktopNotification(title: title, body: body);
      } else if (_isMobile) {
        await _showMobileNotification(
          title: title,
          body: body,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('NotificationManager: Failed to show notification: $e');
    }
  }

  /// Show a desktop notification
  Future<void> _showDesktopNotification({
    required String title,
    required String body,
  }) async {
    if (Platform.isWindows) {
      try {
        final script = '''
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
\$template = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$title</text>
      <text>$body</text>
    </binding>
  </visual>
</toast>
"@
\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\$xml.LoadXml(\$template)
\$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Morrow").Show(\$toast)
''';

        await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          script,
        ], runInShell: true);
      } catch (e) {
        debugPrint('NotificationManager: [$title] $body');
      }
    } else if (Platform.isMacOS) {
      try {
        await Process.run('osascript', [
          '-e',
          'display notification "$body" with title "$title"',
        ]);
      } catch (e) {
        debugPrint('NotificationManager: [$title] $body');
      }
    } else if (Platform.isLinux) {
      try {
        await Process.run('notify-send', [title, body]);
      } catch (e) {
        debugPrint('NotificationManager: [$title] $body');
      }
    }
  }

  /// Show a mobile notification
  Future<void> _showMobileNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotificationsPlugin.show(
      _notificationId++,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'morrow_channel',
          'Morrow Notifications',
          channelDescription: 'Main notification channel for Morrow',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Initialize local notifications for mobile
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationTap(response.payload);
      },
    );
  }

  /// Initialize FCM integration
  Future<void> _initFCM() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          payload: jsonEncode(message.data),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(jsonEncode(message.data));
    });
    
    // Check if app was opened from terminated state
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(jsonEncode(initialMessage.data));
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;
      
      if (type == 'dm' || type == 'message') {
        final conversationId = data['conversation_id'] as String?;
        if (conversationId != null) {
          AppRouter.router.pushNamed(
            'chat_nested',
            pathParameters: {'conversationId': conversationId},
            extra: {
              'otherUserName': data['sender_name'] ?? 'User',
              'otherUserAvatar': data['sender_avatar'] ?? '',
              'otherUserId': data['sender_id'] ?? '',
            },
          );
        }
      } else if (data.containsKey('post_id')) {
         AppRouter.router.pushNamed(
            'post_details',
            pathParameters: {'postId': data['post_id']},
          );
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return;

    Future.delayed(delay, () {
      showNotification(title: title, body: body, payload: payload);
    });
  }

  Future<void> cancelAll() async {
    await _localNotificationsPlugin.cancelAll();
  }

  Future<bool> requestPermission() async {
    if (_isDesktop) return true;
    if (_isMobile) {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }
    return false;
  }
}

/// Notification types for categorization
enum NotificationType {
  message,
  like,
  comment,
  follow,
  mention,
  community,
  reminder,
  system,
}
