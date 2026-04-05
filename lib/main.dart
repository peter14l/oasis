import 'dart:async';
import 'package:flutter/material.dart';
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
import 'package:oasis/services/vault_service.dart';
import 'package:oasis/services/wellness_service.dart';
import 'package:oasis/services/digital_wellbeing_service.dart';
import 'package:oasis/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:oasis/features/circles/presentation/providers/circle_provider.dart';
import 'package:oasis/providers/conversation_provider.dart';
import 'package:oasis/providers/notification_provider.dart';
import 'package:oasis/providers/presence_provider.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/providers/user_settings_provider.dart';
import 'package:oasis/themes/app_theme.dart';
import 'package:oasis/widgets/mesh_gradient_background.dart';
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

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme? lightScheme;
        ColorScheme? darkScheme;

        if (themeProvider.useMaterialYou && themeProvider.isM3EEnabled) {
          lightScheme = lightDynamic;
          darkScheme = darkDynamic;
        }

        final ThemeData theme =
            themeProvider.highContrast
                ? AppTheme.highContrastLight
                : (themeProvider.isM3EEnabled
                    ? (lightScheme != null
                        ? AppTheme.createM3ETheme(lightScheme, Brightness.light)
                        : AppTheme.m3eLight)
                    : AppTheme.light);

        final ThemeData darkTheme =
            themeProvider.highContrast
                ? AppTheme.highContrastDark
                : (themeProvider.isM3EEnabled
                    ? (darkScheme != null
                        ? AppTheme.createM3ETheme(darkScheme, Brightness.dark)
                        : AppTheme.m3eDark)
                    : AppTheme.dark);

        return StreamBuilder<AuthState>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            return MaterialApp.router(
              title: 'Oasis',
              debugShowCheckedModeBanner: false,
              theme: theme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: router,
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                final settingsProvider = Provider.of<UserSettingsProvider>(
                  context,
                );
                final scale = settingsProvider.fontSizeFactor;

                if (snapshot.hasData && snapshot.data?.session != null) {
                  final userId = snapshot.data!.session!.user.id;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<NotificationProvider>().init(userId);
                    context.read<PresenceProvider>().updateUserPresence(
                      userId,
                      'online',
                    );
                    context.read<ConversationProvider>().initialize(userId);
                    context.read<ProfileProvider>().loadCurrentProfile(userId);
                    context.read<CircleProvider>().loadCircles(userId);
                    context.read<CanvasProvider>().loadCanvases(userId);
                    SharingService().init(context);
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
                  child: Consumer<UserSettingsProvider>(
                    builder: (context, userSettings, _) {
                      Widget childWidget = child!;

                      if (Platform.isWindows && userSettings.micaEnabled) {
                        final theme = Theme.of(context);
                        childWidget = Theme(
                          data: theme.copyWith(
                            colorScheme: theme.colorScheme.copyWith(
                              surface: Colors.black.withValues(alpha: 0.05),
                              surfaceContainer: Colors.black.withValues(
                                alpha: 0.02,
                              ),
                              onSurface: Colors.white,
                            ),
                            scaffoldBackgroundColor: Colors.transparent,
                            canvasColor: Colors.transparent,
                            cardColor: Colors.white.withValues(alpha: 0.02),
                          ),
                          child: childWidget,
                        );

                        return Container(
                          color: Colors.transparent,
                          child: childWidget,
                        );
                      }

                      if (userSettings.meshEnabled) {
                        return MeshGradientBackground(child: childWidget);
                      } else {
                        final isDark =
                            themeProvider.themeMode == ThemeMode.dark ||
                            (themeProvider.themeMode == ThemeMode.system &&
                                MediaQuery.platformBrightnessOf(context) ==
                                    Brightness.dark);

                        return Container(
                          color:
                              isDark
                                  ? const Color(0xFF080A0E)
                                  : const Color(0xFFF8F9FA),
                          child: childWidget,
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// main — thin entry point, delegates to AppInitializer
// ---------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppInitializer.loadEnv();

  await AppInitializer.runWithSentry(() async {
    await AppInitializer.initFirebase();

    try {
      final services = await AppInitializer.initCore();

      runApp(
        SentryWidget(
          child: AppInitializer.buildProviderTree(
            services: services,
            child: const LifecycleManager(child: MyApp()),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error initializing app: $e');
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Failed to initialize app: $e')),
          ),
        ),
      );
    }
  });
}
