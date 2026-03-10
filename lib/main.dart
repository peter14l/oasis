import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:morrow_v2/routes/app_router.dart';
import 'package:morrow_v2/themes/app_theme.dart';
import 'package:morrow_v2/services/auth_service.dart';
import 'package:morrow_v2/services/supabase_service.dart';
import 'package:morrow_v2/services/encryption_service.dart';
import 'package:morrow_v2/providers/feed_provider.dart';
import 'package:morrow_v2/providers/user_settings_provider.dart';
import 'package:morrow_v2/providers/typing_indicator_provider.dart';
import 'package:morrow_v2/providers/notification_provider.dart';
import 'package:morrow_v2/providers/capsule_provider.dart';
import 'package:morrow_v2/services/vault_service.dart';
import 'package:morrow_v2/services/screen_time_service.dart';
import 'package:morrow_v2/services/energy_meter_service.dart';
import 'package:morrow_v2/services/subscription_service.dart';
import 'package:morrow_v2/widgets/mesh_gradient_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Theme Provider to manage theme mode
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _highContrast = false;
  static const String _themeKey = 'theme_mode';
  static const String _highContrastKey = 'high_contrast';

  ThemeMode get themeMode => _themeMode;
  bool get highContrast => _highContrast;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    _highContrast = prefs.getBool(_highContrastKey) ?? false;
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

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setTheme(_themeMode);
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  try {
    // Initialize Supabase
    await SupabaseService.initialize();
    debugPrint('Supabase initialized successfully');

    // Initialize AuthService and restore session
    final authService = AuthService();
    await authService.restoreSession();

    // If user is already logged in, silently provision/restore encryption keys
    // so they are ready before any chat is opened (WhatsApp-style seamless restore)
    if (authService.currentUser != null) {
      EncryptionService()
          .init()
          .then((status) {
            debugPrint('[Startup] Encryption init status: $status');
          })
          .catchError((e) {
            debugPrint('[Startup] Encryption init error: $e');
          });
    }

    // Initialize theme provider
    final themeProvider = ThemeProvider();
    await themeProvider.loadTheme();

    // Initialize UserSettingsProvider
    final userSettingsProvider = UserSettingsProvider();
    await userSettingsProvider.loadSettings();

    // Initialize ScreenTimeService
    final screenTimeService = await ScreenTimeService.init();

    // Initialize EnergyMeterService
    final energyMeterService = await EnergyMeterService.init();

    // Initialize SubscriptionService
    final subscriptionService = SubscriptionService();
    await subscriptionService.init();

    // Debug log current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        'Current user on startup: ${authService.currentUser?.id ?? 'null'}',
      );
    });

    await SentryFlutter.init(
      (options) {
        options.dsn = dotenv.get('SENTRY_DSN');
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0;
        // The sampling rate for profiling is relative to tracesSampleRate
        // Setting to 1.0 will profile 100% of sampled transactions:
        options.profilesSampleRate = 1.0;
      },
      appRunner:
          () => runApp(
            SentryWidget(
              child: MultiProvider(
                providers: [
                  ChangeNotifierProvider<ThemeProvider>.value(
                    value: themeProvider,
                  ),
                  ChangeNotifierProvider<AuthService>.value(value: authService),
                  ChangeNotifierProvider<UserSettingsProvider>.value(
                    value: userSettingsProvider,
                  ),
                  ChangeNotifierProvider<ScreenTimeService>.value(
                    value: screenTimeService,
                  ),
                  ChangeNotifierProvider<EnergyMeterService>.value(
                    value: energyMeterService,
                  ),
                  ChangeNotifierProvider<SubscriptionService>.value(
                    value: subscriptionService,
                  ),
                  ChangeNotifierProvider(create: (_) => FeedProvider()),
                  ChangeNotifierProvider(create: (_) => ProfileProvider()),
                  ChangeNotifierProvider(create: (_) => CommunityProvider()),
                  ChangeNotifierProvider(
                    create: (_) => TypingIndicatorProvider(),
                  ),
                  ChangeNotifierProvider(create: (_) => NotificationProvider()),
                  ChangeNotifierProvider(create: (_) => CapsuleProvider()),
                  Provider<VaultService>(create: (_) => VaultService()),
                ],
                child: const LifecycleManager(child: MyApp()),
              ),
            ),
          ),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
    // Show error UI if needed
    await SentryFlutter.init(
      (options) {
        options.dsn = dotenv.get('SENTRY_DSN');
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0;
        // The sampling rate for profiling is relative to tracesSampleRate
        // Setting to 1.0 will profile 100% of sampled transactions:
        options.profilesSampleRate = 1.0;
      },
      appRunner:
          () => runApp(
            SentryWidget(
              child: MaterialApp(
                home: Scaffold(
                  body: Center(child: Text('Failed to initialize app: $e')),
                ),
              ),
            ),
          ),
    );
  }
}

class LifecycleManager extends StatefulWidget {
  final Widget child;
  const LifecycleManager({super.key, required this.child});

  @override
  State<LifecycleManager> createState() => _LifecycleManagerState();
}

class _LifecycleManagerState extends State<LifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start tracking when app starts
    if (mounted) {
      context.read<ScreenTimeService>().startTracking();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final service = context.read<ScreenTimeService>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      service.stopTracking();
    } else if (state == AppLifecycleState.resumed) {
      service.startTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // supabase_flutter v2 already handles the token extraction from the deep
  // link internally via its own app_links listener.  We only need to react
  // to the passwordRecovery auth event it fires after processing the link.
  StreamSubscription<AuthState>? _authSub;
  bool _navigatingToReset = false; // one-shot guard

  @override
  void initState() {
    super.initState();
    _listenForPasswordRecovery();
  }

  void _listenForPasswordRecovery() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery &&
          !_navigatingToReset) {
        _navigatingToReset = true;
        debugPrint(
          'passwordRecovery event received — navigating to /reset-password',
        );
        // Defer until after the current frame so the router is mounted.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              AppRouter.router.go('/reset-password');
            }
            _navigatingToReset = false;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // passwordRecovery navigation is handled by _listenForPasswordRecovery
        // above (via initState), not here, to avoid the race with the router.

        return MaterialApp.router(
          title: 'Morrow',
          debugShowCheckedModeBanner: false,
          theme:
              themeProvider.highContrast
                  ? AppTheme.highContrastLight
                  : AppTheme.light,
          darkTheme:
              themeProvider.highContrast
                  ? AppTheme.highContrastDark
                  : AppTheme.dark,
          themeMode: themeProvider.themeMode,
          routerConfig: router,
          builder: (context, child) {
            // Apply text scaling factor
            final mediaQuery = MediaQuery.of(context);
            final settingsProvider = Provider.of<UserSettingsProvider>(context);
            final scale = settingsProvider.fontSizeFactor;

            // Initialize notifications with current user
            if (snapshot.hasData && snapshot.data?.session != null) {
              final userId = snapshot.data!.session!.user.id;
              // Defer to next frame to avoid build-time state updates
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<NotificationProvider>().init(userId);
              });
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<NotificationProvider>().init(null);
              });
            }

            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(scale),
                boldText: false,
              ),
              child: MeshGradientBackground(child: child!),
            );
          },
        );
      },
    );
  }
}
