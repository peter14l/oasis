import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/calling/call.dart';
import 'package:oasis/features/calling/call_controller.dart';
import 'package:oasis/features/calling/presentation/call_router.dart';
import 'package:oasis/features/settings/presentation/providers/user_settings_provider.dart';

import 'fakes.dart';

/// Drains microtasks and zero-duration timers. Must pump: awaiting real
/// `Future.delayed` inside `testWidgets` deadlocks because the clock is fake.
Future<void> flush(WidgetTester tester, [int times = 5]) async {
  for (var i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  late FakeCallRepository repo;
  late FakeCallMedia media;
  late FakeRingtone ringtone;
  CallController? controller;
  GoRouter? router;

  CallController build() {
    final c = CallController(
      repository: repo,
      mediaFactory: () => media,
      ringtone: ringtone,
      enabled: true,
      userId: () => 'user_me',
    );
    controller = c;
    return c;
  }

  GoRouter makeRouter({String initialLocation = '/'}) {
    final r = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, __) => const Scaffold(body: Text('login')),
        ),
        GoRoute(
          path: '/call/:callId',
          name: 'active_call',
          builder: (_, state) =>
              Scaffold(body: Text('call:${state.pathParameters['callId']}')),
        ),
      ],
    );
    router = r;
    return r;
  }

  Widget host(CallController c, GoRouter r, UserSettingsProvider settings) {
    return ChangeNotifierProvider<CallController>.value(
      value: c,
      child: ChangeNotifierProvider<UserSettingsProvider>.value(
        value: settings,
        child: MaterialApp.router(
          routerConfig: r,
          builder: (context, child) =>
              CallRouter(router: r, child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }

  setUp(() {
    repo = FakeCallRepository();
    media = FakeCallMedia();
    ringtone = FakeRingtone();
  });

  tearDown(() {
    controller?.dispose();
    controller = null;
    router?.dispose();
    router = null;
  });

  testWidgets('pushes /call/:id exactly once when a call appears',
      (tester) async {
    final c = build();
    final r = makeRouter();
    await tester.pumpWidget(host(c, r, buildTestUserSettings()));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);

    await c.startCall(
      conversationId: 'conv_1',
      receiverId: 'other',
      type: CallType.voice,
    );
    await flush(tester);
    await tester.pumpAndSettle();

    expect(find.text('call:call_1'), findsOneWidget);
    final pushedMatches =
        r.routerDelegate.currentConfiguration.matches.length;
    expect(pushedMatches, 2, reason: 'base (/) + one pushed call route');

    // State churn (mute toggle via controller notify) must not push again.
    c.toggleMinimize();
    await tester.pumpAndSettle();
    c.toggleMinimize();
    await tester.pumpAndSettle();
    c.clearError();
    await flush(tester);
    await tester.pumpAndSettle();

    expect(r.routerDelegate.currentConfiguration.matches.length,
        pushedMatches,
        reason: 'navigation driver must push exactly once per call');
    expect(find.text('call:call_1'), findsOneWidget);

    // Leave no ringing call behind: the 20s caller timeout is a real timer.
    await c.hangUp();
    await flush(tester);
  });

  testWidgets('does not navigate while minimized; resumes when restored',
      (tester) async {
    final c = build();
    final r = makeRouter();
    await tester.pumpWidget(host(c, r, buildTestUserSettings()));
    await tester.pumpAndSettle();

    c.toggleMinimize(value: true);
    // Incoming, not outgoing: startCall deliberately un-minimizes so a new
    // call the user places opens full screen.
    repo.seed(id: 'c1', callerId: 'other', receiverId: 'user_me');
    await flush(tester);
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget,
        reason: 'minimized calls must not steal navigation');
    expect(find.textContaining('call:'), findsNothing);

    c.toggleMinimize(value: false);
    await tester.pumpAndSettle();

    expect(find.text('call:c1'), findsOneWidget);

    await c.declineCall();
    await flush(tester);
  });

  testWidgets('never navigates on auth routes', (tester) async {
    final c = build();
    final r = makeRouter(initialLocation: '/login');
    await tester.pumpWidget(host(c, r, buildTestUserSettings()));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);

    await c.startCall(
      conversationId: 'conv_1',
      receiverId: 'other',
      type: CallType.voice,
    );
    await flush(tester);
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.textContaining('call:'), findsNothing);

    await c.hangUp();
    await flush(tester);
  });

  testWidgets('a new call after the previous one ended pushes again',
      (tester) async {
    final c = build();
    final r = makeRouter();
    await tester.pumpWidget(host(c, r, buildTestUserSettings()));
    await tester.pumpAndSettle();

    final first = await c.startCall(
      conversationId: 'conv_1',
      receiverId: 'other',
      type: CallType.voice,
    );
    await flush(tester);
    await tester.pumpAndSettle();
    expect(find.text('call:${first!.id}'), findsOneWidget);

    await c.hangUp();
    await flush(tester);
    await tester.pumpAndSettle();

    final second = await c.startCall(
      conversationId: 'conv_1',
      receiverId: 'other',
      type: CallType.voice,
    );
    await flush(tester);
    await tester.pumpAndSettle();

    expect(find.text('call:${second!.id}'), findsOneWidget);

    await c.hangUp();
    await flush(tester);
  });
}
