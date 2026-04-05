import 'package:universal_io/io.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:win_toast/win_toast.dart';
import 'package:oasis/routes/app_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cross-platform notification manager
class NotificationManager {
  static NotificationManager? _instance;
  bool _isInitialized = false;
  bool _isPaused = false;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  int _notificationId = 0;

  /// Singleton instance
  static NotificationManager get instance {
    _instance ??= NotificationManager._();
    return _instance!;
  }

  NotificationManager._();

  /// Set whether notifications should be suppressed (e.g. during Focus Mode)
  void setPaused(bool paused) {
    _isPaused = paused;
    debugPrint('NotificationManager: Notifications ${paused ? 'paused' : 'resumed'}');
  }

  bool get isPaused => _isPaused;

  /// Initialize the notification manager
  Future<bool> initialize() async {
    // If already initialized, we still want to ensure channels are created 
    // especially if called from a background isolate
    try {
      if (_isDesktop) {
        if (Platform.isWindows) {
          // Initialize WinToast for Windows
          await WinToast.instance().initialize(
            appName: "Oasis",
            productName: "Oasis",
            companyName: "Oasis",
          );
        } else if (Platform.isMacOS) {
          await _initLocalNotifications();
        }
        
        _isInitialized = true;
        debugPrint(
          'NotificationManager: Initialized for desktop (${Platform.operatingSystem})',
        );
        return true;
      } else if (_isMobile) {
        await _initLocalNotifications();
        // FCM initialization usually happens in the main isolate, 
        // but the background handler needs local notifications setup.
        if (kDebugMode) debugPrint('NotificationManager: Mobile local notifications initialized');
        
        // Only init FCM if we are in the main isolate (where Firebase.initializeApp was likely called without options)
        // or if we explicitly want to (the background handler initializes Firebase itself)
        await _initFCM();
        
        _isInitialized = true;
        return true;
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
    String? senderAvatar,
    String? messageType,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationManager: Not initialized');
      return;
    }

    if (_isPaused) {
      debugPrint('NotificationManager: Notification suppressed due to Focus Mode: [$title]');
      return;
    }

    String finalBody = body;
    if (messageType == 'image' || messageType == 'Photo') {
      finalBody = '📷 Photo';
    }

    try {
      if (_isDesktop) {
        await _showDesktopNotification(
          title: title,
          body: finalBody,
          senderAvatar: senderAvatar,
        );
      } else if (_isMobile) {
        await _showMobileNotification(
          title: title,
          body: finalBody,
          payload: payload,
          senderAvatar: senderAvatar,
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
    String? senderAvatar,
  }) async {
    if (Platform.isWindows) {
      try {
        String? iconPath;
        if (senderAvatar != null && senderAvatar.isNotEmpty) {
          try {
            iconPath = await _downloadAndSaveImage(senderAvatar, 'noti_icon_${DateTime.now().millisecondsSinceEpoch}.png');
          } catch (e) {
            debugPrint('Error preparing Windows notification icon: $e');
          }
        }

        // Use win_toast for native Windows notifications
        if (iconPath != null && iconPath.isNotEmpty) {
          await WinToast.instance().showToast(
            type: ToastType.imageAndText02,
            title: title,
            subtitle: body,
            imagePath: iconPath,
          );
        } else {
          await WinToast.instance().showToast(
            type: ToastType.text02,
            title: title,
            subtitle: body,
          );
        }
      } catch (e) {
        debugPrint('NotificationManager (Windows - WinToast): Failed: $e');
      }
    } else if (Platform.isMacOS) {
      try {
        // Use flutter_local_notifications for macOS as it supports images better than osascript
        await _showMobileNotification(title: title, body: body, senderAvatar: senderAvatar);
      } catch (e) {
        // Fallback to simple osascript
        await Process.run('osascript', [
          '-e',
          'display notification "$body" with title "$title"',
        ]);
      }
    } else if (Platform.isLinux) {
      try {
        await Process.run('notify-send', [title, body]);
      } catch (e) {
        debugPrint('NotificationManager (Linux): [$title] $body');
      }
    }
  }

  /// Show a mobile notification (restored exactly as it was)
  Future<void> _showMobileNotification({
    required String title,
    required String body,
    String? payload,
    String? senderAvatar,
  }) async {
    AndroidNotificationDetails? androidDetails;
    DarwinNotificationDetails? darwinDetails;

    if (senderAvatar != null && senderAvatar.isNotEmpty) {
      try {
        final String largeIconPath = await _downloadAndSaveImage(senderAvatar, 'notification_icon');
        
        androidDetails = AndroidNotificationDetails(
          'oasis_channel',
          'Oasis Notifications',
          channelDescription: 'Main notification channel for Oasis',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          largeIcon: FilePathAndroidBitmap(largeIconPath),
        );

        darwinDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          attachments: [DarwinNotificationAttachment(largeIconPath)],
        );
      } catch (e) {
        debugPrint('Error downloading notification icon: $e');
      }
    }

    androidDetails ??= const AndroidNotificationDetails(
      'oasis_channel',
      'Oasis Notifications',
      channelDescription: 'Main notification channel for Oasis',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
    );

    darwinDetails ??= const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotificationsPlugin.show(
      _notificationId++,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
      payload: payload,
    );
  }

  Future<String> _downloadAndSaveImage(String url, String fileName) async {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
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

    // Create the default channel for Android
    if (Platform.isAndroid) {
      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'oasis_channel',
          'Oasis Notifications',
          description: 'Main notification channel for Oasis',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
    }
  }

  /// Initialize FCM integration
  Future<void> _initFCM() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    try {
      final token = await messaging.getToken();
      if (token != null) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client.from('profiles').update({'fcm_token': token}).eq('id', userId);
        }
      }
      messaging.onTokenRefresh.listen((newToken) async {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          try {
            await Supabase.instance.client.from('profiles').update({'fcm_token': newToken}).eq('id', userId);
          } catch (e) {
            debugPrint('Error updating refreshed FCM token: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Failed to retrieve or save FCM token: $e');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          payload: jsonEncode(message.data),
          messageType: message.data['message_type'] ?? message.data['type'],
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
