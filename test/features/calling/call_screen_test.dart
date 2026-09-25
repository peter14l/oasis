import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/calling/call.dart';
import 'package:oasis/features/calling/call_controller.dart';
import 'package:oasis/features/calling/presentation/call_screen.dart';

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

  CallController build({
    Duration ringTimeout = const Duration(seconds: 20),
  }) {
    final c = CallController(
      repository: repo,
      mediaFactory: () => media,
      ringtone: ringtone,
      enabled: true,
      userId: () => 'user_me',
      ringTimeout: ringTimeout,
    );
    controller = c;
    return c;
  }

  Widget wrap(CallController c) => ChangeNotifierProvider<CallController>.value(
        value: c,
        child: const MaterialApp(home: CallScreen()),
      );

  setUp(() {
    repo = FakeCallRepository();
    media = FakeCallMedia();
    ringtone = FakeRingtone();
  });

  tearDown(() {
    controller?.dispose();
    controller = null;
  });

  testWidgets('incoming call shows explicit accept/decline and NEVER '
      'auto-accepts (v2 root bug regression)', (tester) async {
    repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
    final c = build();
    await flush(tester);
    await tester.pumpWidget(wrap(c));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(ringtone.playing, isTrue);

    // Wait well past every legacy auto-accept/timeout window.
    await tester.pump(const Duration(seconds: 20));
    await flush(tester);

    expect(repo['c1']!.status, CallStatus.ringing,
        reason: 'the screen must not accept the call by itself');
    expect(c.activeCall, isNull);
    expect(ringtone.playing, isTrue,
        reason: 'ringtone must keep playing until the user decides');
  });

  testWidgets('tapping Accept answers and connects', (tester) async {
    repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
    final c = build();
    await flush(tester);
    await tester.pumpWidget(wrap(c));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.call));
    await flush(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await flush(tester);

    expect(repo['c1']!.status, CallStatus.active);
    expect(c.activeCall?.id, 'c1');
    expect(media.connectCount, 1);
    expect(ringtone.playing, isFalse);
    // Active call UI replaces the incoming buttons.
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('tapping Decline declines and stops the ringtone',
      (tester) async {
    repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
    final c = build();
    await flush(tester);
    await tester.pumpWidget(wrap(c));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.call_end));
    await flush(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(repo['c1']!.status, CallStatus.declined);
    expect(c.incomingCall, isNull);
    expect(ringtone.playing, isFalse);
  });

  testWidgets('active call: hang-up button ends the call', (tester) async {
    final c = build();
    final call = await c.startCall(
      conversationId: 'conv_1',
      receiverId: 'other',
      type: CallType.voice,
    );
    await flush(tester);
    await tester.pumpWidget(wrap(c));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.call_end), findsOneWidget);

    await tester.tap(find.byIcon(Icons.call_end));
    await flush(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(repo[call!.id]!.status, CallStatus.ended);
    expect(c.activeCall, isNull);
  });

  testWidgets('unanswered screen offers retry and cancel', (tester) async {
    final c = build(ringTimeout: const Duration(milliseconds: 50));
    final call = await c.startCall(
      conversationId: 'conv_1',
      receiverId: 'other',
      type: CallType.voice,
    );
    await flush(tester);
    await tester.pumpWidget(wrap(c));
    await tester.pump(const Duration(milliseconds: 300));
    await flush(tester);

    expect(find.text('No answer'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(repo[call!.id]!.status, CallStatus.missed);

    await tester.tap(find.byIcon(Icons.refresh));
    // Keep the advance under the 50ms test ring timeout, otherwise the retried
    // call is legitimately missed again mid-assertion.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(c.activeCall, isNotNull);
    expect(c.activeCall!.status, CallStatus.ringing);
    expect(c.state.isUnanswered, isFalse);

    // Leave no ringing call behind: the 20s caller timeout is a real timer.
    await c.hangUp();
    await flush(tester);
  });

  testWidgets('screen pops itself when there is no call to show',
      (tester) async {
    final c = build();
    await tester.pumpWidget(
      ChangeNotifierProvider<CallController>.value(
        value: c,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CallScreen(),
                    ),
                  ),
                  child: const Text('home'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();

    // Empty state -> CallScreen immediately removes itself.
    await tester.pump(const Duration(milliseconds: 100));
    await flush(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('home'), findsOneWidget);
    expect(find.byType(CallScreen), findsNothing);
  });
}
