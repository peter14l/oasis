import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/calling/call.dart';
import 'package:oasis/features/calling/call_controller.dart';
import 'package:oasis/features/calling/presentation/floating_call_bar.dart';

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

  setUp(() {
    repo = FakeCallRepository();
    media = FakeCallMedia();
    ringtone = FakeRingtone();
  });

  tearDown(() {
    controller?.dispose();
    controller = null;
  });

  Widget host(CallController c) => ChangeNotifierProvider<CallController>.value(
        value: c,
        child: const MaterialApp(
          home: Scaffold(body: Stack(children: [FloatingCallBar()])),
        ),
      );

  testWidgets('shows only while minimized with an active call',
      (tester) async {
    final c = CallController(
      repository: repo,
      mediaFactory: () => media,
      ringtone: ringtone,
      enabled: true,
      userId: () => 'user_me',
    );
    controller = c;
    await tester.pumpWidget(host(c));
    await tester.pump();
    expect(find.byIcon(Icons.call_end), findsNothing);

    await c.startCall(
      conversationId: 'conv_1',
      receiverId: 'other',
      type: CallType.voice,
    );
    await flush(tester);
    await tester.pump();
    expect(find.byIcon(Icons.call_end), findsNothing,
        reason: 'not minimized -> no floating pill');

    c.toggleMinimize(value: true);
    await tester.pump();
    expect(find.byIcon(Icons.call_end), findsOneWidget);

    c.toggleMinimize(value: false);
    await tester.pump();
    expect(find.byIcon(Icons.call_end), findsNothing);

    // Leave no ringing call behind: the 20s caller timeout is a real timer.
    await c.hangUp();
    await flush(tester);
  });
}
