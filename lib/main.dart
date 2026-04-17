import 'dart:async';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:oasis/core/config/app_config.dart';
import 'package:oasis/routes/app_router.dart';
import 'package:oasis/services/app_initializer.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/core/storage/prefs_storage.dart';
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
import 'package:oasis/themes/fluent_theme.dart';
import 'package:oasis/widgets/mesh_gradient_background.dart';
import 'package:oasis/widgets/splash_screen.dart';
import 'package:oasis/services/update_service.dart';
import 'package:dynamic_color/dynamic_color.dart';

// ---------------------------------------------------------------------------
// LifecycleManager
// ---------------------------------------------------------------------------

class LifecycleManager extends StatefulWidget {
  final Widget child;
  const LifecycleManager({super.key, required this.child});

  @override
  State<LifecycleManager> createState() => _LifecycleManagerState();
}

class _LifecycleManagerState extends State<LifecycleManager>
    with material.WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    material.WidgetsBinding.instance.addObserver(this);
    if (mounted) {
      context.read<ScreenTimeService>().startTracking();
    }
  }

  @override
  void dispose() {
    material.WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(material.AppLifecycleState state) {
    if (!mounted) return;

    final screenTime = context.read<ScreenTimeService>();
    final energyMeter = context.read<EnergyMeterService>();
    final wellness = context.read<WellnessService>();
    final wellbeing = context.read<DigitalWellbeingService>();
    final ripples = context.read<RipplesProvider>();
    final presence = context.read<PresenceProvider>();
    final auth = context.read<AuthService>();

    if (state == material.AppLifecycleState.paused ||
        state == material.AppLifecycleState.detached) {
      screenTime.stopTracking();
      energyMeter.onPaused();
      wellness.onPaused();
      wellbeing.resetSession();
      ripples.onPaused();

      context.read<VaultService>().lockItemsWithInterval('app_close');

      final userId = auth.currentUser?.id;
      if (userId != null) {
        presence.updateUserPresence(userId, 'offline');
      }
    } else if (state == material.AppLifecycleState.resumed) {
      screenTime.startTracking();
      energyMeter.onResumed();
      wellness.onResumed();
      ripples.onResumed();

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthState>? _authSub;
  bool _navigatingToReset = false;
  String? _lastInitializedUserId;

  material.ThemeData? _cachedLightTheme;
  material.ThemeData? _cachedDarkTheme;
  material.ColorScheme? _cachedLightScheme;
  material.ColorScheme? _cachedDarkScheme;
  String _cachedSettingsKey = '';
  bool _themeSettingsChanged = true;

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
        material.WidgetsBinding.instance.addPostFrameCallback((_) {
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
      context.read<NotificationProvider>().init(userId);
      context.read<PresenceProvider>().updateUserPresence(userId, 'online');

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          context.read<ConversationProvider>().initialize(userId);
        }
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.read<ProfileProvider>().loadCurrentProfile(userId);
        }
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          context.read<CircleProvider>().loadCircles(userId);
        }
      });

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          context.read<CanvasProvider>().loadCanvases(userId);
        }
      });

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
      builder: (material.ColorScheme? lightDynamic, material.ColorScheme? darkDynamic) {
        material.ColorScheme? lightScheme;
        material.ColorScheme? darkScheme;

        final userSettings = Provider.of<UserSettingsProvider>(context);

        if (themeProvider.useMaterialYou && themeProvider.isM3EEnabled) {
          lightScheme = lightDynamic;
          darkScheme = darkDynamic;
        } else if (themeProvider.colorPalette != ColorPalette.none &&
            themeProvider.isM3EEnabled) {
          lightScheme = themeProvider.getPaletteColorScheme(material.Brightness.light);
          darkScheme = themeProvider.getPaletteColorScheme(material.Brightness.dark);
        }

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
          _cachedLightTheme = AppTheme.getTheme(
            material.Brightness.light,
            isM3E: themeProvider.isM3EEnabled,
            highContrast: themeProvider.highContrast,
            fontFamily: userSettings.fontFamily,
            dynamicColorScheme: lightScheme,
          );
          _cachedDarkTheme = AppTheme.getTheme(
            material.Brightness.dark,
            isM3E: themeProvider.isM3EEnabled,
            highContrast: themeProvider.highContrast,
            fontFamily: userSettings.fontFamily,
            dynamicColorScheme: darkScheme,
          );
        } else {
          lightScheme = _cachedLightScheme;
          darkScheme = _cachedDarkScheme;
        }

        final theme = _cachedLightTheme ?? material.ThemeData.light();
        final darkTheme = _cachedDarkTheme ?? material.ThemeData.dark();

        return StreamBuilder<AuthState>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            final userId = snapshot.hasData && snapshot.data?.session != null
                ? snapshot.data!.session!.user.id
                : null;

            material.WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _handleInitialization(userId);
            });

            if (themeProvider.useFluentUI) {
              return fluent.FluentApp.router(
                title: 'Oasis',
                debugShowCheckedModeBanner: false,
                theme: AppFluentTheme.getTheme(
                  material.Brightness.light,
                  materialColorScheme: lightScheme,
                  fontFamily: userSettings.fontFamily,
                ),
                darkTheme: AppFluentTheme.getTheme(
                  material.Brightness.dark,
                  materialColorScheme: darkScheme,
                  fontFamily: userSettings.fontFamily,
                ),
                themeMode: themeProvider.themeMode == material.ThemeMode.system
                    ? fluent.ThemeMode.system
                    : themeProvider.themeMode == material.ThemeMode.dark
                        ? fluent.ThemeMode.dark
                        : fluent.ThemeMode.light,
                routerConfig: router,
                builder: (context, child) {
                  return material.MediaQuery(
                    data: material.MediaQuery.of(context).copyWith(
                      textScaler: material.TextScaler.linear(userSettings.fontSizeFactor),
                    ),
                    child: CallNavigator(child: child!),
                  );
                },
              );
            }

            return material.MaterialApp.router(
              title: 'Oasis',
              debugShowCheckedModeBanner: false,
              theme: theme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: router,
              builder: (context, child) {
                return material.MediaQuery(
                  data: material.MediaQuery.of(context).copyWith(
                    textScaler: material.TextScaler.linear(userSettings.fontSizeFactor),
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
        material.WidgetsBinding.instance.addPostFrameCallback((_) {
          final activeCallId = callProvider.activeCall?.id;
          final incomingCallId = callProvider.incomingCall?.id;
          final callId = activeCallId ?? incomingCallId;

          if (callId != null) {
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
      final theme = material.Theme.of(context);
      childWidget = material.Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            surface: material.Colors.black.withValues(alpha: 0.05),
            surfaceContainer: material.Colors.black.withValues(alpha: 0.02),
            onSurface: material.Colors.white,
          ),
          scaffoldBackgroundColor: material.Colors.transparent,
          canvasColor: material.Colors.transparent,
          cardColor: material.Colors.white.withValues(alpha: 0.02),
        ),
        child: childWidget,
      );

      childWidget = Container(color: material.Colors.transparent, child: childWidget);
    }

    if (userSettings.meshEnabled) {
      return MeshGradientBackground(child: childWidget);
    } else {
      final isDark = material.Theme.of(context).brightness == material.Brightness.dark;

      return Container(
        color: isDark ? const material.Color(0xFF080A0E) : const material.Color(0xFFF8F9FA),
        child: childWidget,
      );
    }
  }
}

void main() async {
  material.debugPrint('--- APP STARTING ---');
  material.WidgetsFlutterBinding.ensureInitialized();

  runApp(
    material.MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(
        onInitComplete: () {
          _runAppInitialization();
        },
      ),
    ),
  );
}

Future<void> _runAppInitialization() async {
  runZonedGuarded(() async {
    try {
      await AppInitializer.loadEnv();

      await AppInitializer.runWithSentry(() async {
        final packageInfo = await PackageInfo.fromPlatform();
        AppConfig.appVersion = packageInfo.version;

        _checkForUpdates();

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
        } catch (e, stackTrace) {
          _showErrorScreen(e, stackTrace);
        }
      });
    } catch (e, st) {
      material.debugPrint('Root initialization failed: $e');
      _showErrorScreen(e, st);
    }
  }, (error, stack) {
    material.debugPrint('--- UNCAUGHT ERROR ---');
    material.debugPrint('Error: $error');
    
    // If it is a FormatException during startup, it is likely disk corruption
    if (error is FormatException) {
       _showErrorScreen(
         'Data Corruption Detected\n\nYour local session data was corrupted (likely due to a system crash). Please click "Repair App" to reset and log in again.',
         stack,
         isCorruption: true,
       );
    } else {
      _showErrorScreen(error, stack);
    }
  });
}

void _showErrorScreen(Object error, StackTrace stack, {bool isCorruption = false}) {
  runApp(
    material.MaterialApp(
      home: material.Scaffold(
        backgroundColor: const material.Color(0xFF080A0E),
        body: material.Center(
          child: material.Padding(
            padding: const material.EdgeInsets.all(32.0),
            child: material.Column(
              mainAxisAlignment: material.MainAxisAlignment.center,
              children: [
                const material.Icon(material.Icons.warning_amber_rounded, color: material.Colors.amber, size: 64),
                const material.SizedBox(height: 24),
                material.Text(
                  isCorruption ? 'App Needs Repair' : 'Failed to Initialize',
                  style: const material.TextStyle(color: material.Colors.white, fontSize: 24, fontWeight: material.FontWeight.bold),
                ),
                const material.SizedBox(height: 16),
                material.Text(
                  error.toString(),
                  style: material.TextStyle(color: material.Colors.white.withValues(alpha: 0.7)),
                  textAlign: material.TextAlign.center,
                ),
                const material.SizedBox(height: 32),
                material.ElevatedButton(
                  onPressed: () async {
                    // Logic to wipe cache would go here in a real production app
                    // For now, simple restart instruction
                    material.debugPrint('User requested app repair/reset');
                  },
                  child: material.Text(isCorruption ? 'Repair & Reset App' : 'Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _checkForUpdates() async {
  if (!UpdateService.isEnabled) return;

  final updateInfo = await UpdateService.instance.checkForUpdates();

  if (updateInfo != null && updateInfo.isUpdateAvailable) {
    Future.delayed(const Duration(seconds: 3), () {
      if (updateInfo.isRequired) {
        _pendingUpdateInfo = updateInfo;
      } else {
        UpdateService.instance.showUpdateNotification(updateInfo);
      }
    });
  }
}

UpdateInfo? _pendingUpdateInfo;
