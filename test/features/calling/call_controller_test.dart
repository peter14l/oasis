import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/features/calling/call.dart';
import 'package:oasis/features/calling/call_controller.dart';
import 'package:oasis/features/calling/call_media.dart';
import 'package:oasis/features/calling/call_native_bridge.dart';

import 'fakes.dart';

Future<void> flush([int times = 4]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  // CallController is a SafeChangeNotifier, which reads WidgetsBinding.instance
  // to avoid notifying during build. Pure `test()` cases have no binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCallRepository repo;
  late FakeCallMedia media;
  late FakeRingtone ringtone;
  CallController? controller;

  CallController build({
    Duration ringTimeout = const Duration(seconds: 20),
    String me = 'user_me',
  }) {
    final c = CallController(
      repository: repo,
      mediaFactory: () => media,
      ringtone: ringtone,
      enabled: true,
      userId: () => me,
      ringTimeout: ringTimeout,
    );
    controller = c;
    return c;
  }

  setUp(() {
    repo = FakeCallRepository();
    media = FakeCallMedia();
    ringtone = FakeRingtone();
    CallNativeBridge.unregister();
    CallNativeBridge.pendingAcceptCallId = null;
    CallNativeBridge.pendingDeclineCallId = null;
  });

  tearDown(() {
    controller?.dispose();
    controller = null;
    CallNativeBridge.unregister();
    CallNativeBridge.pendingAcceptCallId = null;
    CallNativeBridge.pendingDeclineCallId = null;
  });

  group('incoming calls (receiver)', () {
    test('ringing row sets incomingCall and plays ringtone', () async {
      repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
      final c = build();
      await flush();

      expect(c.incomingCall?.id, 'c1');
      expect(ringtone.playing, isTrue);
      expect(ringtone.playCount, 1);
    });

    test('no ringtone while app is backgrounded; plays when visible again',
        () async {
      final c = build();
      c.setAppVisible(false);
      repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
      await flush();

      expect(c.incomingCall?.id, 'c1');
      expect(ringtone.playCount, 0);

      c.setAppVisible(true);
      await flush();
      expect(ringtone.playCount, 1);
    });

    test('stale ringing row is marked missed without ringing', () async {
      repo.seed(
        id: 'c1',
        callerId: 'caller',
        receiverId: 'user_me',
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      );
      final c = build();
      await flush();

      expect(c.incomingCall, isNull);
      expect(repo['c1']!.status, CallStatus.missed);
      expect(ringtone.playCount, 0);
    });

    test('another ringing row while in a call is auto-declined (busy)',
        () async {
      final c = build();
      await c.startCall(
        conversationId: 'conv_a',
        receiverId: 'other',
        type: CallType.voice,
      );
      await flush();
      expect(c.activeCall, isNotNull);

      repo.seed(id: 'c2', callerId: 'caller2', receiverId: 'user_me');
      await flush();

      expect(c.incomingCall, isNull);
      expect(repo['c2']!.status, CallStatus.declined);
      expect(ringtone.playCount, 1); // only the caller ringback, no new ring
    });

    test('incoming row disappearing (peer declined) clears state and stops '
        'ringtone', () async {
      repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
      final c = build();
      await flush();
      expect(c.incomingCall, isNotNull);

      await repo.declineCall('c1');
      await flush();

      expect(c.incomingCall, isNull);
      expect(ringtone.playing, isFalse);
    });

    test('declineCall marks row declined and clears state', () async {
      repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
      final c = build();
      await flush();

      await c.declineCall();
      await flush();

      expect(repo['c1']!.status, CallStatus.declined);
      expect(c.incomingCall, isNull);
      expect(ringtone.playing, isFalse);
    });
  });

  group('accept', () {
    test('successful accept: active call, media connected, ringtone stopped',
        () async {
      repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
      final c = build();
      await flush();

      await c.acceptCall();
      await flush();

      expect(repo['c1']!.status, CallStatus.active);
      expect(c.activeCall?.id, 'c1');
      expect(c.incomingCall, isNull);
      expect(media.connectCount, 1);
      expect(media.connectedRoomName, repo['c1']!.roomName);
      expect(ringtone.playing, isFalse);
    });

    test('conditional-update loss: row answered elsewhere -> no takeover',
        () async {
      repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
      final c = build();
      await flush();

      // Answered on another device — row flips without this client's watch
      // having surfaced it yet (direct map write, no emission).
      repo.rows['c1'] = repo['c1']!.copyWith(status: CallStatus.active);

      await c.acceptCall();
      await flush();

      expect(c.activeCall, isNull);
      expect(c.incomingCall, isNull);
      expect(media.connectCount, 0);
      expect(ringtone.playing, isFalse);
    });

    test('accept flips incoming list watch so state stays consistent',
        () async {
      repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
      final c = build();
      await flush();

      await c.acceptCall();
      await flush();

      // Row is active: the ringing-only incoming list no longer contains it.
      expect(c.state.incomingCall, isNull);
      expect(c.state.activeCall?.status, CallStatus.active);
    });
  });

  group('outgoing call (caller)', () {
    test('startCall: ringing row, ringback, media connected', () async {
      final c = build();
      final call = await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.video,
      );
      await flush();

      expect(call, isNotNull);
      expect(c.activeCall?.status, CallStatus.ringing);
      expect(c.activeCall?.roomName, call!.roomName);
      expect(ringtone.playing, isTrue); // ringback
      expect(media.connectCount, 1);
      expect(media.isVideoOn, isTrue);
      expect(repo[call.id]!.status, CallStatus.ringing);
    });

    test('second startCall while in a call is rejected', () async {
      final c = build();
      await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.voice,
      );
      await flush();
      final second = await c.startCall(
        conversationId: 'conv_2',
        receiverId: 'other2',
        type: CallType.voice,
      );

      expect(second, isNull);
      expect(repo.rows.length, 1);
    });

    test('media connect failure ends the row and surfaces an error', () async {
      media.failConnect = true;
      final c = build();
      final call = await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.voice,
      );
      await flush();

      expect(call, isNull);
      expect(c.state.error, isNotNull);
      expect(c.activeCall, isNull);
      expect(ringtone.playing, isFalse);
      // The created row must not be left ringing forever.
      expect(
        repo.rows.values.every((r) => r.status != CallStatus.ringing),
        isTrue,
      );
    });
  });

  group('ring timeout races (the v2 root bug)', () {
    test('unanswered call is marked missed and surfaces the unanswered state',
        () async {
      final c = build(ringTimeout: const Duration(milliseconds: 60));
      final call = await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.voice,
      );
      await flush();
      expect(c.activeCall, isNotNull);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      await flush();

      expect(repo[call!.id]!.status, CallStatus.missed);
      expect(c.activeCall, isNull);
      expect(c.state.isUnanswered, isTrue);
      expect(ringtone.playing, isFalse);
      expect(media.disconnectCount, greaterThanOrEqualTo(1));
    });

    test('AN ANSWERED CALL IS NEVER FORCE-ENDED BY THE TIMEOUT', () async {
      final c = build(ringTimeout: const Duration(milliseconds: 80));
      final call = await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.voice,
      );
      await flush();

      // Receiver answers just before the timeout fires.
      repo.seed(
        id: call!.id,
        callerId: call.callerId,
        receiverId: call.receiverId,
        conversationId: call.conversationId,
        roomName: call.roomName,
        status: CallStatus.active,
      );
      await flush();
      expect(c.activeCall?.status, CallStatus.active);

      // Let the old force-end window pass.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await flush();

      expect(c.activeCall, isNotNull);
      expect(repo[call.id]!.status, CallStatus.active);
      expect(c.state.isUnanswered, isFalse);
    });

    test('peer ending the call tears down without the unanswered screen',
        () async {
      final c = build();
      final call = await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.voice,
      );
      await flush();
      // Flip to active (answered), then peer hangs up.
      repo.seed(
        id: call!.id,
        callerId: call.callerId,
        receiverId: call.receiverId,
        status: CallStatus.active,
        roomName: call.roomName,
      );
      await flush();

      await repo.endCall(call.id);
      await flush();

      expect(c.activeCall, isNull);
      expect(c.state.isUnanswered, isFalse);
    });
  });

  group('hang up / lifecycle', () {
    test('hangUp ends the row and tears down media', () async {
      final c = build();
      final call = await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.voice,
      );
      await flush();

      await c.hangUp();
      await flush();

      expect(repo[call!.id]!.status, CallStatus.ended);
      expect(c.activeCall, isNull);
      expect(media.disconnectCount, greaterThanOrEqualTo(1));
      expect(ringtone.playing, isFalse);
    });

    test('reset clears state, stops audio, and re-arms the incoming watch',
        () async {
      final c = build();
      await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.voice,
      );
      await flush();
      expect(c.activeCall, isNotNull);
      expect(ringtone.playing, isTrue);

      c.reset();
      await flush();

      expect(c.activeCall, isNull);
      expect(ringtone.playing, isFalse);
      expect(media.disconnectCount, greaterThanOrEqualTo(1));

      // The watch is re-armed: a ringing row still reaches the new session.
      repo.seed(id: 'c2', callerId: 'caller', receiverId: 'user_me');
      await flush();
      expect(c.incomingCall?.id, 'c2');
    });

    test('dispose stops everything and later repo events are harmless',
        () async {
      repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
      final c = build();
      await flush();
      expect(c.incomingCall, isNotNull);

      c.dispose();
      controller = null;
      expect(ringtone.disposeCount, 1);
      // Incoming-only: no media was ever created, so none is disposed.
      expect(media.disposeCount, 0);

      await repo.declineCall('c1');
      await flush(); // must not throw / notify after dispose
    });
  });

  group('native bridge', () {
    test('pending accept set before the controller exists is consumed',
        () async {
      repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
      CallNativeBridge.pendingAcceptCallId = 'c1';

      final c = build();
      await flush();

      expect(repo['c1']!.status, CallStatus.active);
      expect(c.activeCall?.id, 'c1');
      expect(CallNativeBridge.pendingAcceptCallId, isNull);
    });

    test('decline with no controller sets pending; consumed on construction',
        () async {
      repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
      CallNativeBridge.decline('c1');
      expect(CallNativeBridge.pendingDeclineCallId, 'c1');

      final c = build();
      await flush();

      expect(repo['c1']!.status, CallStatus.declined);
      expect(c.incomingCall, isNull);
      expect(CallNativeBridge.pendingDeclineCallId, isNull);
    });

    test('end with no controller is a safe no-op', () {
      expect(() => CallNativeBridge.end(), returnsNormally);
    });

    test('bridge end hangs up the active call', () async {
      final c = build();
      final call = await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.voice,
      );
      await flush();

      CallNativeBridge.end();
      await flush();

      expect(repo[call!.id]!.status, CallStatus.ended);
      expect(c.activeCall, isNull);
    });
  });

  group('controls', () {
    test('toggleMute and audio route sync into state (16ms coalescing)',
        () async {
      final c = build();
      await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.voice,
      );
      await flush();

      c.toggleMute();
      expect(media.isMuted, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(c.state.isMuted, isTrue);

      c.cycleAudioRoute();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(c.state.audioRoute, AudioRoute.speaker);
    });

    test('inviteUser creates a second row sharing the same room', () async {
      final c = build();
      final call = await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.voice,
      );
      await flush();

      await c.inviteUser('friend');
      await flush();

      final extra = repo.rows.values
          .where((r) => r.receiverId == 'friend')
          .toList();
      expect(extra, hasLength(1));
      expect(extra.first.roomName, call!.roomName);
    });

    test('retryLastCall after unanswered starts a fresh ringing call',
        () async {
      final c = build(ringTimeout: const Duration(milliseconds: 50));
      await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.video,
      );
      await flush();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await flush();
      expect(c.state.isUnanswered, isTrue);

      await c.retryLastCall();
      await flush();

      expect(c.state.isUnanswered, isFalse);
      expect(c.activeCall?.status, CallStatus.ringing);
      expect(c.activeCall?.type, CallType.video);
      expect(ringtone.playing, isTrue);
    });
  });

  group('disabled controller', () {
    test('never accepts or starts calls when calls are disabled', () async {
      final c = CallController(
        repository: repo,
        mediaFactory: () => media,
        ringtone: ringtone,
        enabled: false,
        userId: () => 'user_me',
      );
      controller = c;
      repo.seed(id: 'c1', callerId: 'caller', receiverId: 'user_me');
      await flush();

      expect(c.incomingCall, isNull);
      await c.startCall(
        conversationId: 'conv_1',
        receiverId: 'other',
        type: CallType.voice,
      );
      expect(c.activeCall, isNull);
      // The only row is the one the test seeded; a disabled controller never
      // creates rows and never touches an existing one.
      expect(repo.rows.keys, ['c1']);
      expect(repo['c1']!.status, CallStatus.ringing);
      expect(ringtone.playCount, 0);
    });
  });
}
