import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:oasis/features/calling/call.dart';
import 'package:oasis/features/calling/call_media.dart';
import 'package:oasis/features/calling/call_repository.dart';
import 'package:oasis/features/calling/call_ringtone.dart';
import 'package:oasis/features/settings/domain/repositories/settings_repository.dart';
import 'package:oasis/features/settings/domain/usecases/settings_usecases.dart';
import 'package:oasis/features/settings/presentation/providers/user_settings_provider.dart';

/// In-memory [CallRepository] mirroring the conditional-update semantics of
/// the Supabase implementation: accept/decline/markMissed only succeed while
/// the row is `ringing`; endCall only while `ringing` or `active`.
///
/// Streams emit the current snapshot on listen, then every mutation.
class FakeCallRepository implements CallRepository {
  final Map<String, Call> rows = {};
  final Map<String, List<void Function(Call)>> _rowListeners = {};
  final List<void Function(List<Call>)> _listListeners = [];

  String? userId = 'user_me';
  String? _incomingWatchUser;
  int endCallCount = 0;

  @override
  String? get currentUserId => userId;

  Call seed({
    required String id,
    required String callerId,
    required String receiverId,
    CallStatus status = CallStatus.ringing,
    CallType type = CallType.voice,
    String conversationId = 'conv_1',
    String? roomName,
    DateTime? createdAt,
  }) {
    final call = Call(
      id: id,
      conversationId: conversationId,
      callerId: callerId,
      receiverId: receiverId,
      status: status,
      type: type,
      roomName: roomName ?? 'room_$id',
      createdAt: createdAt ?? DateTime.now().toUtc(),
    );
    _put(call);
    return call;
  }

  /// Latest stored row (null if unknown).
  Call? operator [](String id) => rows[id];

  void _put(Call call) {
    rows[call.id] = call;
    for (final listener in List.of(_rowListeners[call.id] ?? const [])) {
      listener(call);
    }
    _emitList();
  }

  void _emitList() {
    final user = _incomingWatchUser;
    final snapshot =
        rows.values.where((c) => c.receiverId == user).toList();
    for (final listener in List.of(_listListeners)) {
      listener(snapshot);
    }
  }

  @override
  Future<Call> createCall({
    required String conversationId,
    required String callerId,
    required String receiverId,
    required CallType type,
    required String roomName,
  }) async {
    final call = Call(
      id: 'call_${rows.length + 1}',
      conversationId: conversationId,
      callerId: callerId,
      receiverId: receiverId,
      type: type,
      roomName: roomName,
      createdAt: DateTime.now().toUtc(),
    );
    _put(call);
    return call;
  }

  @override
  Future<Call?> getCall(String callId) async => rows[callId];

  @override
  Future<Call?> acceptCall(String callId) async {
    final call = rows[callId];
    if (call == null || call.status != CallStatus.ringing) return null;
    final updated = call.copyWith(
      status: CallStatus.active,
      startedAt: DateTime.now().toUtc(),
    );
    _put(updated);
    return updated;
  }

  @override
  Future<Call?> declineCall(String callId) async {
    final call = rows[callId];
    if (call == null || call.status != CallStatus.ringing) return null;
    final updated = call.copyWith(status: CallStatus.declined);
    _put(updated);
    return updated;
  }

  @override
  Future<Call?> markMissed(String callId) async {
    final call = rows[callId];
    if (call == null || call.status != CallStatus.ringing) return null;
    final updated = call.copyWith(
      status: CallStatus.missed,
      endedAt: DateTime.now().toUtc(),
    );
    _put(updated);
    return updated;
  }

  @override
  Future<Call?> endCall(String callId) async {
    endCallCount++;
    final call = rows[callId];
    if (call == null ||
        (call.status != CallStatus.ringing &&
            call.status != CallStatus.active)) {
      return null;
    }
    final updated = call.copyWith(
      status: CallStatus.ended,
      endedAt: DateTime.now().toUtc(),
    );
    _put(updated);
    return updated;
  }

  @override
  Stream<Call> watchCall(String callId) {
    return Stream<Call>.multi((controller) {
      final current = rows[callId];
      if (current != null) controller.add(current);
      void onData(Call call) => controller.add(call);
      final listeners =
          _rowListeners.putIfAbsent(callId, () => <void Function(Call)>[]);
      listeners.add(onData);
      controller.onCancel = () => listeners.remove(onData);
    });
  }

  @override
  Stream<List<Call>> watchCallsFor(String userId) {
    _incomingWatchUser = userId;
    final user = userId;
    List<Call> snapshot() =>
        rows.values.where((c) => c.receiverId == user).toList();
    return Stream<List<Call>>.multi((controller) {
      controller.add(snapshot());
      void onData(List<Call> _) => controller.add(snapshot());
      _listListeners.add(onData);
      controller.onCancel = () => _listListeners.remove(onData);
    });
  }
}

/// [CallMedia] fake: records calls and can be told to fail connects.
class FakeCallMedia implements CallMedia {
  @override
  Room? room;

  @override
  bool isMuted = false;

  @override
  bool isVideoOn = true;

  @override
  bool isScreenSharing = false;

  @override
  AudioRoute audioRoute = AudioRoute.earpiece;

  @override
  VoidCallback? onChanged;

  @override
  VoidCallback? onRemoteLeft;

  int connectCount = 0;
  int disconnectCount = 0;
  int disposeCount = 0;
  bool failConnect = false;
  String? connectedRoomName;

  @override
  Future<void> connect({
    required String roomName,
    required String userId,
    required bool videoEnabled,
  }) async {
    connectCount++;
    connectedRoomName = roomName;
    isVideoOn = videoEnabled;
    if (failConnect) throw Exception('media connect failed');
  }

  @override
  Future<void> disconnect() async {
    disconnectCount++;
  }

  @override
  Future<void> setMuted(bool muted) async {
    isMuted = muted;
    onChanged?.call();
  }

  @override
  Future<void> setVideoEnabled(bool enabled) async {
    isVideoOn = enabled;
    onChanged?.call();
  }

  @override
  Future<void> setScreenShareEnabled(bool enabled) async {
    isScreenSharing = enabled;
    onChanged?.call();
  }

  @override
  Future<void> setAudioRoute(AudioRoute route) async {
    audioRoute = route;
    onChanged?.call();
  }

  @override
  Future<void> cycleAudioRoute() async {
    audioRoute = audioRoute == AudioRoute.earpiece
        ? AudioRoute.speaker
        : audioRoute == AudioRoute.speaker
            ? AudioRoute.bluetooth
            : AudioRoute.earpiece;
    onChanged?.call();
  }

  @override
  void dispose() {
    disposeCount++;
  }
}

/// [CallRingtone] fake with call accounting.
class FakeRingtone implements CallRingtone {
  int playCount = 0;
  int stopCount = 0;
  int disposeCount = 0;
  bool playing = false;

  @override
  Future<void> play() async {
    playCount++;
    playing = true;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    playing = false;
  }

  @override
  void dispose() {
    disposeCount++;
  }
}

class _UnusedSettingsRepository implements SettingsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// UserSettingsProvider with inert use cases (nothing loads in tests).
UserSettingsProvider buildTestUserSettings() {
  final repo = _UnusedSettingsRepository();
  return UserSettingsProvider(
    getSettingsUseCase: GetSettingsUseCase(repo),
    saveSettingsUseCase: SaveSettingsUseCase(repo),
  );
}
