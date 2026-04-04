import 'dart:async' show unawaited;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_io/io.dart';

import 'package:oasis_v2/firebase_options.dart';
import 'package:oasis_v2/features/auth/presentation/providers/auth_provider.dart';
import 'package:oasis_v2/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:oasis_v2/services/call_service.dart';
import 'package:oasis_v2/services/desktop_window_service.dart';
import 'package:oasis_v2/services/energy_meter_service.dart';
import 'package:oasis_v2/services/encryption_service.dart';
import 'package:oasis_v2/services/notification_manager.dart';
import 'package:oasis_v2/services/ripples_service.dart';
import 'package:oasis_v2/services/screen_time_service.dart';
import 'package:oasis_v2/services/signal/signal_service.dart';
import 'package:oasis_v2/services/subscription_service.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/core/network/supabase_client.dart';
import 'package:oasis_v2/services/vault_service.dart';
import 'package:oasis_v2/services/wellness_service.dart';
import 'package:oasis_v2/providers/canvas_provider.dart';
import 'package:oasis_v2/providers/capsule_provider.dart';
import 'package:oasis_v2/features/circles/presentation/providers/circle_provider.dart';
import 'package:oasis_v2/features/circles/data/repositories/circle_repository_impl.dart';
import 'package:oasis_v2/providers/community_provider.dart';
import 'package:oasis_v2/providers/conversation_provider.dart';
import 'package:oasis_v2/features/feed/presentation/providers/feed_provider.dart';
import 'package:oasis_v2/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:oasis_v2/features/feed/data/repositories/post_repository_impl.dart';
import 'package:oasis_v2/features/feed/data/repositories/comment_repository_impl.dart';
import 'package:oasis_v2/providers/notification_provider.dart';
import 'package:oasis_v2/providers/presence_provider.dart';
import 'package:oasis_v2/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis_v2/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:oasis_v2/providers/typing_indicator_provider.dart';
import 'package:oasis_v2/providers/user_settings_provider.dart';
import 'package:oasis_v2/themes/app_theme.dart';
import 'package:oasis_v2/core/storage/prefs_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// ThemeProvider (kept here — it's UI-level state, not a service)
// ---------------------------------------------------------------------------

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _highContrast = false;
  bool _isM3EEnabled = false;
  bool _isM3ETransparencyDisabled = false;
  bool _useMaterialYou = false;
  static const String _themeKey = 'theme_mode';
  static const String _highContrastKey = 'high_contrast';
  static const String _m3eKey = 'm3e_enabled';
  static const String _m3eTransparencyKey = 'm3e_transparency_disabled';
  static const String _materialYouKey = 'use_material_you';

  ThemeMode get themeMode => _themeMode;
  bool get highContrast => _highContrast;
  bool get isM3EEnabled => _isM3EEnabled;
  bool get isM3ETransparencyDisabled => _isM3ETransparencyDisabled;
  bool get useMaterialYou => _useMaterialYou;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    _highContrast = prefs.getBool(_highContrastKey) ?? false;
    _isM3EEnabled = prefs.getBool(_m3eKey) ?? false;
    _isM3ETransparencyDisabled = prefs.getBool(_m3eTransparencyKey) ?? false;
    _useMaterialYou = prefs.getBool(_materialYouKey) ?? false;
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
    notifyListeners();
  }

  Future<void> setM3EEnabled(bool value) async {
    _isM3EEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_m3eKey, value);
    notifyListeners();
  }

  Future<void> setM3ETransparencyDisabled(bool value) async {
    _isM3ETransparencyDisabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_m3eTransparencyKey, value);
    notifyListeners();
  }

  Future<void> setMaterialYou(bool value) async {
    _useMaterialYou = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_materialYouKey, value);
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setTheme(_themeMode);
  }
}

// ---------------------------------------------------------------------------
// AppInitializer — encapsulates all startup logic
// ---------------------------------------------------------------------------

/// Holds every service/provider instance needed by the widget tree.
class InitializedServices {
  final ThemeProvider themeProvider;
  final AuthProvider authProvider;
  final UserSettingsProvider userSettingsProvider;
  final ScreenTimeService screenTimeService;
  final WellnessService wellnessService;
  final EnergyMeterService energyMeterService;
  final SubscriptionService subscriptionService;

  const InitializedServices({
    required this.themeProvider,
    required this.authProvider,
    required this.userSettingsProvider,
    required this.screenTimeService,
    required this.wellnessService,
    required this.energyMeterService,
    required this.subscriptionService,
  });
}

class AppInitializer {
  /// Background FCM message handler (must be top-level / static).
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    // Ensure Firebase is initialized for the background isolate
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('Handling a background message: ${message.messageId}');

    // If it's a data-only message or contains data we need to show
    if (message.data.isNotEmpty || message.notification != null) {
      await NotificationManager.instance.initialize();

      final String title =
          message.notification?.title ??
          message.data['title'] ??
          'New Notification';
      final String body =
          message.notification?.body ?? message.data['body'] ?? '';

      // For background, we often want the full data as payload for deep linking
      final String? payload =
          message.data.isNotEmpty ? jsonEncode(message.data) : null;

      await NotificationManager.instance.showNotification(
        title: title,
        body: body,
        payload: payload,
        senderAvatar: message.data['sender_avatar'],
        messageType: message.data['message_type'] ?? message.data['type'],
      );
    }
  }

  /// Step 1 — Load .env (best-effort, never fatal).
  static Future<void> loadEnv() async {
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('.env loaded successfully');
    } catch (e) {
      debugPrint('Could not load .env file: $e');
    }
  }

  /// Step 2 — Initialize Sentry and run the app inside its appRunner.
  static Future<void> runWithSentry(Future<void> Function() appRunner) async {
    SentryWidgetsFlutterBinding.ensureInitialized();
    await SentryFlutter.init((options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = kDebugMode ? 1.0 : 0.05;
      options.sendDefaultPii = false;
    }, appRunner: appRunner);
  }

  /// Step 3 — Initialize Firebase (best-effort).
  static Future<void> initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }

  /// Step 4 — Core initialization: Supabase → auth → settings → services.
  /// Returns all pre-instantiated providers so main.dart can wire them up.
  static Future<InitializedServices> initCore() async {
    // Supabase
    await SupabaseService.initialize();
    debugPrint('Supabase initialized successfully');

    // PrefsStorage (shared preferences wrapper — required by SessionLocalDatasource)
    await PrefsStorage.init();
    debugPrint('PrefsStorage initialized successfully');

    // Auth
    final authProvider = AuthProvider(repository: AuthRepositoryImpl());
    await authProvider.restoreSession();

    // Theme
    final themeProvider = ThemeProvider();
    await themeProvider.loadTheme();

    // User settings
    final userSettingsProvider = UserSettingsProvider();
    await userSettingsProvider.loadSettings();

    // Desktop Windows enhancements
    if (Platform.isWindows) {
      await DesktopWindowService.instance.initialize();
      await DesktopWindowService.instance.enableCloseToTray();
      await DesktopWindowService.instance.setWindowEffect(
        enabled: userSettingsProvider.micaEnabled,
        effect: userSettingsProvider.windowEffect,
      );
    }

    // Wellness & tracking services
    final screenTimeService = await ScreenTimeService.init();
    final wellnessService = await WellnessService.init();
    final energyMeterService = await EnergyMeterService.init();

    // Notifications
    await NotificationManager.instance.initialize();

    // Encryption (fire-and-forget, non-blocking)
    unawaited(
      Future.wait([
        EncryptionService().init(),
        SignalService().init(),
      ]).catchError((e) {
        debugPrint('Encryption/Signal init failed: $e');
        return [EncryptionStatus.error, false];
      }),
    );

    // Subscription
    final subscriptionService = SubscriptionService();
    await subscriptionService.init();

    return InitializedServices(
      themeProvider: themeProvider,
      authProvider: authProvider,
      userSettingsProvider: userSettingsProvider,
      screenTimeService: screenTimeService,
      wellnessService: wellnessService,
      energyMeterService: energyMeterService,
      subscriptionService: subscriptionService,
    );
  }

  /// Step 5 — Build the MultiProvider tree with all initialized services.
  static Widget buildProviderTree({
    required InitializedServices services,
    required Widget child,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(
          value: services.themeProvider,
        ),
        ChangeNotifierProvider<AuthProvider>.value(
          value: services.authProvider,
        ),
        ChangeNotifierProvider<AuthService>.value(value: AuthService()),
        ChangeNotifierProvider<UserSettingsProvider>.value(
          value: services.userSettingsProvider,
        ),
        ChangeNotifierProvider<ScreenTimeService>.value(
          value: services.screenTimeService,
        ),
        ChangeNotifierProvider<WellnessService>.value(
          value: services.wellnessService,
        ),
        ChangeNotifierProvider<EnergyMeterService>.value(
          value: services.energyMeterService,
        ),
        ChangeNotifierProvider<SubscriptionService>.value(
          value: services.subscriptionService,
        ),
        ChangeNotifierProvider(
          create:
              (_) => FeedProvider(
                feedRepository: FeedRepositoryImpl(),
                postRepository: PostRepositoryImpl(),
                commentRepository: CommentRepositoryImpl(),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (_) => ProfileProvider(
                profileRepository: ProfileRepositoryImpl(),
                postRepository: PostRepositoryImpl(),
              ),
        ),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => TypingIndicatorProvider()),
        ChangeNotifierProvider(create: (_) => PresenceProvider()),
        ChangeNotifierProxyProvider<PresenceProvider, ConversationProvider>(
          create: (_) => ConversationProvider(),
          update:
              (context, presenceProvider, conversationProvider) =>
                  conversationProvider!
                    ..updatePresenceProvider(presenceProvider),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CallService()),
        ChangeNotifierProvider(create: (_) => CanvasProvider()),
        ChangeNotifierProvider(
          create: (_) => CircleProvider(repository: CircleRepositoryImpl()),
        ),
        ChangeNotifierProvider(create: (_) => RipplesService()),
        ChangeNotifierProvider(create: (_) => CapsuleProvider()),
        ChangeNotifierProvider<VaultService>(create: (_) => VaultService()),
      ],
      child: child,
    );
  }
}
