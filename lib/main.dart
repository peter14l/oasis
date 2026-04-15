import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_io/io.dart';

import 'package:oasis/routes/app_router.dart';
import 'package:oasis/services/app_initializer.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:oasis/services/energy_meter_service.dart';
import 'package:oasis/features/ripples/presentation/providers/ripples_provider.dart';
import 'package:oasis/services/screen_time_service.dart';
import 'package:oasis/services/sharing_service.dart';
import 'package:oasis/services/deep_link_service.dart';
import 'package:oasis/services/vault_service.dart';
import 'package:oasis/services/wellness_service.dart';
import 'package:oasis/services/digital_wellbeing_service.dart';
import 'package:oasis/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:oasis/features/circles/presentation/providers/circle_provider.dart';
import 'package:oasis/providers/conversation_provider.dart';
import 'package:oasis/features/notifications/presentation/providers/notification_provider.dart';
import 'package:oasis/providers/presence_provider.dart';
import 'package:oasis/features/calling/presentation/providers/call_provider.dart';
import 'package:oasis/features/settings/presentation/providers/user_settings_provider.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/themes/app_theme.dart';
import 'package:oasis/widgets/mesh_gradient_background.dart';
import 'package:oasis/widgets/splash_screen.dart';
import 'package:dynamic_color/dynamic_color.dart';

// ---------------------------------------------------------------------------
// LifecycleManager — tracks app foreground/background for screen time & vault
// ---------------------------------------------------------------------------

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

    final screenTime = context.read<ScreenTimeService>();
    final energyMeter = context.read<EnergyMeterService>();
    final wellness = context.read<WellnessService>();
    final wellbeing = context.read<DigitalWellbeingService>();
    final ripples = context.read<RipplesProvider>();
    final presence = context.read<PresenceProvider>();
    final auth = context.read<AuthService>();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      screenTime.stopTracking();
      energyMeter.onPaused();
      wellness.onPaused();
      wellbeing.resetSession();
      ripples.onPaused();

      context.read<VaultService>().lockItemsWithInterval('app_close');

      // Update presence to offline when backgrounded
      final userId = auth.currentUser?.id;
      if (userId != null) {
        presence.updateUserPresence(userId, 'offline');
      }
    } else if (state == AppLifecycleState.resumed) {
      screenTime.startTracking();
      energyMeter.onResumed();
      wellness.onResumed();
      ripples.onResumed();

      // Update presence to online when resumed
      final userId = auth.currentUser?.id;
      if (userId != null) {
        presence.updateUserPresence(userId, 'online');
      }
    } else if (state == AppLifecycleState.inactive) {
      // Skip presence update on inactive state - this is intermediate
      // between resumed and paused, often triggered temporarily by system
      // e.g., incoming call, notification, or dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ---------------------------------------------------------------------------
// MyApp — root widget with auth-gated routing and platform-specific chrome
// ---------------------------------------------------------------------------

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthState>? _authSub;
  bool _navigatingToReset = false;
  String? _lastInitializedUserId;

  // Cache for theme data to avoid recomputation on every build
  ThemeData? _cachedLightTheme;
  ThemeData? _cachedDarkTheme;
  ColorScheme? _cachedLightScheme;
  ColorScheme? _cachedDarkScheme;
  String _cachedSettingsKey = '';
  bool _themeSettingsChanged = true; // Track if settings changed

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

  void _handleInitialization(String? userId) {
    if (_lastInitializedUserId == userId) return;
    _lastInitializedUserId = userId;

    if (userId != null) {
      // CRITICAL: Initialize notification first (user-facing)
      context.read<NotificationProvider>().init(userId);

      // CRITICAL: Set presence to online immediately
      context.read<PresenceProvider>().updateUserPresence(userId, 'online');

      // STAGGER: Delay non-critical data loads to prevent frame drops
      // Run conversation initialization after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          context.read<ConversationProvider>().initialize(userId);
        }
      });

      // Run profile loading after 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.read<ProfileProvider>().loadCurrentProfile(userId);
        }
      });

      // Run circle loading after 800ms
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          context.read<CircleProvider>().loadCircles(userId);
        }
      });

      // Run canvas loading after 1200ms (lowest priority, most data)
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          context.read<CanvasProvider>().loadCanvases(userId);
        }
      });

      // Services that don't need user data - run immediately but fire-and-forget style
      SharingService().init(context);
      DeepLinkService().init();
    } else {
      context.read<NotificationProvider>().init(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme? lightScheme;
        ColorScheme? darkScheme;

        final userSettings = Provider.of<UserSettingsProvider>(context);

        // Priority: Material You (system colors) > Palette > None (default M3E)
        if (themeProvider.useMaterialYou && themeProvider.isM3EEnabled) {
          // Use system dynamic colors
          lightScheme = lightDynamic;
          darkScheme = darkDynamic;
        } else if (themeProvider.colorPalette != ColorPalette.none &&
            themeProvider.isM3EEnabled) {
          // Use predefined palette
          lightScheme = themeProvider.getPaletteColorScheme(Brightness.light);
          darkScheme = themeProvider.getPaletteColorScheme(Brightness.dark);
        }

        // Check if theme settings have changed to invalidate cache
        final settingsKey =
            '${themeProvider.isM3EEnabled}_'
            '${themeProvider.useMaterialYou}_'
            '${themeProvider.colorPalette}_'
            '${userSettings.fontFamily}';

        if (_themeSettingsChanged || settingsKey != _cachedSettingsKey) {
          _cachedSettingsKey = settingsKey;
          _themeSettingsChanged = false;
          _cachedLightScheme = lightScheme;
          _cachedDarkScheme = darkScheme;
          // Pre-compute themes
          _cachedLightTheme = AppTheme.getTheme(
            Brightness.light,
            isM3E: themeProvider.isM3EEnabled,
            highContrast: themeProvider.highContrast,
            fontFamily: userSettings.fontFamily,
            dynamicColorScheme: lightScheme,
          );
          _cachedDarkTheme = AppTheme.getTheme(
            Brightness.dark,
            isM3E: themeProvider.isM3EEnabled,
            highContrast: themeProvider.highContrast,
            fontFamily: userSettings.fontFamily,
            dynamicColorScheme: darkScheme,
          );
        } else {
          // Use cached schemes if settings haven't changed
          lightScheme = _cachedLightScheme;
          darkScheme = _cachedDarkScheme;
        }

        final theme =
            _cachedLightTheme ??
            AppTheme.getTheme(
              Brightness.light,
              isM3E: themeProvider.isM3EEnabled,
              highContrast: themeProvider.highContrast,
              fontFamily: userSettings.fontFamily,
              dynamicColorScheme: lightScheme,
            );

        final darkTheme =
            _cachedDarkTheme ??
            AppTheme.getTheme(
              Brightness.dark,
              isM3E: themeProvider.isM3EEnabled,
              highContrast: themeProvider.highContrast,
              fontFamily: userSettings.fontFamily,
              dynamicColorScheme: darkScheme,
            );

        return StreamBuilder<AuthState>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            final userId = snapshot.hasData && snapshot.data?.session != null
                ? snapshot.data!.session!.user.id
                : null;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _handleInitialization(userId);
            });

            return MaterialApp.router(
              title: 'Oasis',
              debugShowCheckedModeBanner: false,
              theme: theme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: router,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(userSettings.fontSizeFactor),
                    boldText: false,
                  ),
                  child: CallNavigator(child: child!),
                );
              },
            );
          },
        );
      },
    );
  }
}

class CallNavigator extends StatelessWidget {
  final Widget child;
  const CallNavigator({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final callProvider = context.watch<CallProvider>();
    final userSettings = context.watch<UserSettingsProvider>();

    final hasActiveCall =
        callProvider.hasActiveCall || callProvider.hasIncomingCall;

    if (hasActiveCall) {
      String location = '';
      try {
        location =
            GoRouter.of(context).routeInformationProvider?.value.uri.path ?? '';
      } catch (e) {
        location =
            AppRouter.router.routerDelegate.currentConfiguration.uri.path;
      }

      final onCallScreen = location.startsWith('/call');

      if (!onCallScreen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final activeCallId = callProvider.activeCall?.id;
          final incomingCallId = callProvider.incomingCall?.id;
          final callId = activeCallId ?? incomingCallId;

          if (callId != null) {
            debugPrint(
              '[CallNavigation] Triggering navigation to /call/$callId (Current location: $location)',
            );

            // Use the root navigator context for reliable navigation
            final navContext =
                AppRouter.router.configuration.navigatorKey.currentContext;
            if (navContext != null) {
              GoRouter.of(
                navContext,
              ).pushNamed('active_call', pathParameters: {'callId': callId});
            } else {
              AppRouter.router.pushNamed(
                'active_call',
                pathParameters: {'callId': callId},
              );
            }
          }
        });
      }
    }

    Widget childWidget = child;

    if (Platform.isWindows && userSettings.micaEnabled) {
      final theme = Theme.of(context);
      childWidget = Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            surface: Colors.black.withValues(alpha: 0.05),
            surfaceContainer: Colors.black.withValues(alpha: 0.02),
            onSurface: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: Colors.transparent,
          cardColor: Colors.white.withValues(alpha: 0.02),
        ),
        child: childWidget,
      );

      childWidget = Container(color: Colors.transparent, child: childWidget);
    }

    if (userSettings.meshEnabled) {
      return MeshGradientBackground(child: childWidget);
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Container(
        color: isDark ? const Color(0xFF080A0E) : const Color(0xFFF8F9FA),
        child: childWidget,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// main — thin entry point, delegates to AppInitializer
// ---------------------------------------------------------------------------

void main() async {
  debugPrint('--- APP STARTING ---');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('WidgetsFlutterBinding initialized');

  // Show splash screen immediately for perceived performance
  // The splash will display while heavy initialization happens in background
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(
        onInitComplete: () {
          // This callback fires after splash animation completes
          // Actual app initialization happens after splash is shown
          _runAppInitialization();
        },
      ),
    ),
  );
}

/// Actual app initialization - runs after splash screen is displayed
/// This separates heavy initialization from UI, improving perceived performance
Future<void> _runAppInitialization() async {
  debugPrint('Starting background initialization...');

  try {
    debugPrint('Loading environment variables...');
    await AppInitializer.loadEnv();

    debugPrint('Initializing Sentry...');
    await AppInitializer.runWithSentry(() async {
      debugPrint('Sentry initialized, starting services...');

      await AppInitializer.initFirebase();

      try {
        debugPrint('Initializing core services...');
        final services = await AppInitializer.initCore();
        debugPrint('Core services initialized successfully');

        // Update the running app with the actual app content
        // This replaces the splash screen with the real app
        runApp(
          SentryWidget(
            child: AppInitializer.buildProviderTree(
              services: services,
              child: const LifecycleManager(child: MyApp()),
            ),
          ),
        );
        debugPrint('runApp called');
      } catch (e, stackTrace) {
        debugPrint('CRITICAL ERROR during initialization: $e');
        debugPrint('Stack trace: $stackTrace');
        // Print each frame
        for (final frame in stackTrace.toString().split('\n')) {
          debugPrint(frame);
        }
        runApp(
          MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Failed to initialize app: $e',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    });
  } catch (e, st) {
    debugPrint('Initialization failed: $e');
    debugPrint('Stack trace: $st');
  }
}
