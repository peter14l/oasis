import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart';

import 'package:oasis/features/calling/call_controller.dart';
import 'package:oasis/features/settings/presentation/providers/user_settings_provider.dart';
import 'package:oasis/routes/app_router.dart';

/// Single navigation driver for calls (v2 had three competing drivers that
/// auto-accepted incoming calls). Pushes `/call/:callId` exactly once per
/// call id, never while minimized, and never navigates itself away.
class CallRouter extends StatefulWidget {
  final Widget child;

  /// Router to push on. Defaults to the app-global [AppRouter.router];
  /// tests inject their own to observe pushes.
  final GoRouter? router;

  const CallRouter({super.key, required this.child, this.router});

  @override
  State<CallRouter> createState() => _CallRouterState();
}

class _CallRouterState extends State<CallRouter>
    with WidgetsBindingObserver {
  String? _lastPushedCallId;

  GoRouter get _router => widget.router ?? AppRouter.router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(material.AppLifecycleState state) {
    // In-app ringtone only while visible; native CallKit rings in background.
    context.read<CallController>().setAppVisible(
          state == material.AppLifecycleState.resumed,
        );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveCall =
        context.select<CallController, bool>((c) => c.hasActiveCall);
    final hasIncomingCall =
        context.select<CallController, bool>((c) => c.hasIncomingCall);
    final isMinimized =
        context.select<CallController, bool>((c) => c.state.isMinimized);
    final activeCallId =
        context.select<CallController, String?>((c) => c.activeCall?.id);
    final incomingCallId =
        context.select<CallController, String?>((c) => c.incomingCall?.id);
    final userSettings = context.watch<UserSettingsProvider>();

    final hasCall = hasActiveCall || hasIncomingCall;
    final callId = activeCallId ?? incomingCallId;

    if (!hasCall) {
      _lastPushedCallId = null;
    }

    if (hasCall && callId != null && _lastPushedCallId != callId) {
      String location = '';
      try {
        location =
            GoRouter.of(context).routeInformationProvider.value.uri.path;
      } catch (e) {
        location = _router.routerDelegate.currentConfiguration.uri.path;
      }

      final onCallScreen = location.startsWith('/call');
      final onAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/splash' ||
          location == '/onboarding';

      if (!onCallScreen && !isMinimized && !onAuthRoute) {
        _lastPushedCallId = callId;
        material.WidgetsBinding.instance.addPostFrameCallback((_) {
          final navContext = _router.configuration.navigatorKey.currentContext;
          if (navContext != null) {
            GoRouter.of(navContext).pushNamed(
              'active_call',
              pathParameters: {'callId': callId},
            );
          } else {
            _router.pushNamed(
              'active_call',
              pathParameters: {'callId': callId},
            );
          }
        });
      }
    }

    final bool canUseTransparency =
        !kIsWeb && (Platform.isWindows || Platform.isMacOS);
    final bool useTransparency = userSettings.micaEnabled && canUseTransparency;

    final theme = material.Theme.of(context);
    final isDark = theme.brightness == material.Brightness.dark;

    return Container(
      color: useTransparency
          ? (isDark
                ? material.Colors.black.withValues(alpha: 0.0)
                : material.Colors.white.withValues(alpha: 0.0))
          : theme.scaffoldBackgroundColor,
      child: widget.child,
    );
  }
}
