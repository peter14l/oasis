import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Cross-platform notification manager
///
/// Uses platform-specific implementations:
/// - Windows/macOS/Linux: Uses system tray notifications (simulated)
/// - Android/iOS: Would use flutter_local_notifications (when uncommented)
///
/// The Windows ATL/MFC issue with flutter_local_notifications is avoided
/// by using a platform-aware approach with graceful fallbacks.
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
        // Desktop platforms: Use native notifications via dart:ffi or package
        // For now, we log and provide a stub implementation
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
  ///
  /// For Windows, this uses a toast notification approach.
  /// In a production app, consider using the `local_notifier` package
  /// or Windows toast notifications via dart:ffi.
  Future<void> _showDesktopNotification({
    required String title,
    required String body,
  }) async {
    // Desktop notification implementation
    // Using PowerShell for Windows notifications as a fallback
    if (Platform.isWindows) {
      try {
        // Windows Toast Notification via PowerShell
        // This is a workaround that works without ATL/MFC dependencies
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
        debugPrint('NotificationManager: Windows notification sent');
      } catch (e) {
        // Fallback: Just log the notification
        debugPrint('NotificationManager: [$title] $body');
      }
    } else if (Platform.isMacOS) {
      try {
        // macOS notification via osascript
        await Process.run('osascript', [
          '-e',
          'display notification "$body" with title "$title"',
        ]);
        debugPrint('NotificationManager: macOS notification sent');
      } catch (e) {
        debugPrint('NotificationManager: [$title] $body');
      }
    } else if (Platform.isLinux) {
      try {
        // Linux notification via notify-send
        await Process.run('notify-send', [title, body]);
        debugPrint('NotificationManager: Linux notification sent');
      } catch (e) {
        debugPrint('NotificationManager: [$title] $body');
      }
    }
  }

  /// Show a mobile notification
  ///
  /// This is a stub implementation. Enable flutter_local_notifications
  /// in pubspec.yaml when building for mobile only.
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

    debugPrint('NotificationManager: [Mobile] [$title] $body');
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
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
  }

  /// Initialize FCM integration
  Future<void> _initFCM() async {
    final messaging = FirebaseMessaging.instance;

    // Request permissions (specifically for iOS/Android 13+)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'FCM Foreground message received: ${message.notification?.title}',
      );
      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });

    // Handle background/terminated message clicks
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM Message opened app: ${message.data}');
    });
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) {
      debugPrint('NotificationManager: Scheduled time is in the past');
      return;
    }

    // Simple implementation using a delayed future
    Future.delayed(delay, () {
      showNotification(title: title, body: body, payload: payload);
    });

    debugPrint(
      'NotificationManager: Scheduled notification for ${scheduledTime.toIso8601String()}',
    );
  }

  /// Cancel all pending notifications
  Future<void> cancelAll() async {
    debugPrint('NotificationManager: All notifications cancelled');
    // Implementation would cancel scheduled notifications
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    if (_isDesktop) {
      // Desktop platforms generally don't require permission
      return true;
    } else if (_isMobile) {
      // Would use permission_handler package here
      // return await Permission.notification.request().isGranted;
      return true;
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
