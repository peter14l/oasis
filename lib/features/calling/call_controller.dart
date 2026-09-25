import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:oasis/core/config/app_config.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/core/providers/safe_change_notifier.dart';
import 'package:oasis/services/notification_manager.dart';
import 'package:uuid/uuid.dart';
import 'call.dart';
import 'call_media.dart';
import 'call_native_bridge.dart';
import 'call_repository.dart';
import 'call_repository_impl.dart';
import 'call_ringtone.dart';
import 'desktop_call_notifier.dart';
import 'livekit_call_media.dart';

/// Immutable view of the calling feature.
class CallState {
  final Call? activeCall;
  final Call? incomingCall;
  final Room? room;
  final bool isLoading;
  final String? error;
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final AudioRoute audioRoute;
  final bool isMinimized;
  final bool isUnanswered;

  const CallState({
    this.activeCall,
    this.incomingCall,
    this.room,
    this.isLoading = false,
    this.error,
    this.isMuted = false,
    this.isVideoOn = true,
    this.isScreenSharing = false,
    this.audioRoute = AudioRoute.earpiece,
    this.isMinimized = false,
    this.isUnanswered = false,
  });

  factory CallState.initial() => const CallState();

  bool get hasCall => activeCall != null || incomingCall != null;

  CallState copyWith({
    Call? activeCall,
    Call? incomingCall,
    Room? room,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearActiveCall = false,
    bool clearIncomingCall = false,
    bool clearRoom = false,
    bool clearUnanswered = false,
    bool? isMuted,
    bool? isVideoOn,
    bool? isScreenSharing,
    AudioRoute? audioRoute,
    bool? isMinimized,
    bool? isUnanswered,
  }) {
    return CallState(
      activeCall: clearActiveCall ? null : (activeCall ?? this.activeCall),
      incomingCall: clearIncomingCall ? null : (incomingCall ?? this.incomingCall),
      room: clearRoom ? null : (room ?? this.room),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isMuted: isMuted ?? this.isMuted,
      isVideoOn: isVideoOn ?? this.isVideoOn,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      audioRoute: audioRoute ?? this.audioRoute,
      isMinimized: isMinimized ?? this.isMinimized,
      isUnanswered: clearUnanswered ? false : (isUnanswered ?? this.isUnanswered),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallState &&
          runtimeType == other.runtimeType &&
          activeCall == other.activeCall &&
          incomingCall == other.incomingCall &&
          room == other.room &&
          isLoading == other.isLoading &&
          error == other.error &&
          isMuted == other.isMuted &&
          isVideoOn == other.isVideoOn &&
          isScreenSharing == other.isScreenSharing &&
          audioRoute == other.audioRoute &&
          isMinimized == other.isMinimized &&
          isUnanswered == other.isUnanswered;

  @override
  int get hashCode =>
      activeCall.hashCode ^
      incomingCall.hashCode ^
      room.hashCode ^
      isLoading.hashCode ^
      error.hashCode ^
      isMuted.hashCode ^
      isVideoOn.hashCode ^
      isScreenSharing.hashCode ^
      audioRoute.hashCode ^
      isMinimized.hashCode ^
      isUnanswered.hashCode;
}

/// Single owner of all call state: signaling (call_sessions rows), media
/// transport (LiveKit), ringtone, and notifications.
///
/// Design rules (from the v2 post-mortem):
///  * Every status transition is a *conditional* update — races resolve via
///    the DB, never via local timers guessing.
///  * One navigation driver (CallRouter) — this controller only mutates
///    state; it never navigates.
///  * No broadcast channels — postgres_changes streams only.
class CallController extends ChangeNotifier with SafeChangeNotifier {
  /// Caller-side ring timeout: unanswered after 20s (conditional markMissed).
  static const Duration ringTimeoutDefault = Duration(seconds: 20);

  /// Receiver-side backstop: a ringing row older than this is marked missed
  /// (covers callers that vanished without hitting their own timeout).
  static const Duration staleIncomingAge = Duration(seconds: 45);

  final CallRepository _repo;
  final CallMedia Function() _mediaFactory;
  final CallRingtone _ringtone;
  final bool _enabled;
  final String? Function()? _userIdOverride;
  final Duration _ringTimeout;

  CallState _state = CallState.initial();
  CallMedia? _media;
  StreamSubscription<List<Call>>? _incomingSub;
  StreamSubscription<Call>? _rowSub;
  StreamSubscription? _authSub;
  Timer? _ringTimeoutTimer;
  Timer? _retryTimer;
  Timer? _mediaNotifyTimer;
  bool _ending = false;
  bool _appVisible = true;

  String? _lastConversationId;
  String? _lastReceiverId;
  CallType? _lastType;

  CallController({
    CallRepository? repository,
    CallMedia Function()? mediaFactory,
    CallRingtone? ringtone,
    bool? enabled,
    String? Function()? userId,
    Duration ringTimeout = ringTimeoutDefault,
  })  : _repo = repository ?? SupabaseCallRepository(),
        _mediaFactory = mediaFactory ?? (() => LiveKitCallMedia()),
        _ringtone = ringtone ?? AssetRingtone(),
        _enabled = enabled ?? AppConfig.enableCalls,
        _userIdOverride = userId,
        _ringTimeout = ringTimeout {
    CallNativeBridge.register(
      onAccept: acceptFromNative,
      onDecline: declineFromNative,
      onEnd: hangUp,
    );
    _consumePendingNative();
    if (_enabled) {
      _startIncomingWatch();
      _listenAuth();
    }
  }

  CallState get state => _state;
  Call? get activeCall => _state.activeCall;
  Call? get incomingCall => _state.incomingCall;
  bool get hasActiveCall => _state.activeCall != null;
  bool get hasIncomingCall => _state.incomingCall != null;
  Room? get room => _state.room;

  String? get _me => _userIdOverride?.call() ?? _repo.currentUserId;

  // ---------------------------------------------------------------------------
  // Incoming calls (receiver side)
  // ---------------------------------------------------------------------------

  void _startIncomingWatch() {
    final me = _me;
    if (me == null) return;
    _incomingSub?.cancel();
    _incomingSub = _repo.watchCallsFor(me).listen(
      _onIncomingRows,
      onError: (Object error) {
        debugPrint('[CallController] incoming watch error: $error');
        if (isDisposed) return;
        _retryTimer?.cancel();
        _retryTimer = Timer(const Duration(seconds: 3), () {
          if (!isDisposed) _startIncomingWatch();
        });
      },
    );
  }

  void _listenAuth() {
    try {
      if (!SupabaseService.isInitialized) return;
      _authSub = SupabaseService().client.auth.onAuthStateChange.listen((data) {
        if (isDisposed || !_enabled) return;
        if (data.session != null) _startIncomingWatch();
      });
    } catch (_) {}
  }

  void _onIncomingRows(List<Call> rows) {
    if (isDisposed || _ending) return;

    final ringing = rows.where((c) => c.status == CallStatus.ringing).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (ringing.isEmpty) {
      if (_state.incomingCall != null) {
        _state = _state.copyWith(clearIncomingCall: true);
        unawaited(_ringtone.stop());
        unawaited(DesktopCallNotifier.instance.dismissIncomingCall());
        notifyListeners();
      }
      return;
    }

    final call = ringing.first;

    // Already in a call — politely decline the newcomer (busy).
    if (_state.activeCall != null) {
      if (_state.activeCall!.id != call.id) {
        unawaited(_repo.declineCall(call.id).catchError((_) => null));
      }
      return;
    }

    if (_state.incomingCall?.id == call.id) return;

    // Stale backstop: mark missed instead of ringing.
    if (call.isStale(maxAge: staleIncomingAge)) {
      unawaited(_repo.markMissed(call.id).catchError((_) => null));
      return;
    }

    _state = _state.copyWith(incomingCall: call, clearError: true);
    notifyListeners();
    if (_appVisible) {
      unawaited(_ringtone.play());
    }
    DesktopCallNotifier.instance.showIncomingCall(
      callId: call.id,
      callerName: 'Incoming Call',
      senderId: call.callerId,
    );
  }

  // ---------------------------------------------------------------------------
  // Outgoing call (caller side)
  // ---------------------------------------------------------------------------

  Future<Call?> startCall({
    required String conversationId,
    required String receiverId,
    required CallType type,
  }) async {
    if (!_enabled || isDisposed) return null;
    if (_state.activeCall != null || _state.isLoading) return null;

    final me = _me;
    if (me == null) {
      _state = _state.copyWith(error: 'Not signed in');
      notifyListeners();
      return null;
    }

    _lastConversationId = conversationId;
    _lastReceiverId = receiverId;
    _lastType = type;

    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearUnanswered: true,
      clearActiveCall: true,
      clearIncomingCall: true,
      isMinimized: false,
    );
    notifyListeners();

    final Call call;
    try {
      call = await _repo.createCall(
        conversationId: conversationId,
        callerId: me,
        receiverId: receiverId,
        type: type,
        roomName: 'room_${const Uuid().v4()}',
      );
    } catch (e) {
      if (!isDisposed) {
        _state = _state.copyWith(isLoading: false, error: 'Failed to start call: $e');
        notifyListeners();
      }
      return null;
    }
    if (isDisposed) return null;

    _ending = false;
    _state = _state.copyWith(activeCall: call, isLoading: false);
    notifyListeners();

    _watchRow(call.id);
    _armRingTimeout(call.id);
    unawaited(_ringtone.play()); // ringback for the caller

    try {
      await _connectMedia(call.roomName, type, me);
    } catch (e) {
      debugPrint('[CallController] media connect failed: $e');
      try {
        await _repo.endCall(call.id);
      } catch (_) {}
      if (!isDisposed) {
        await _teardown();
        _state = _state.copyWith(error: 'Failed to connect call: $e');
        notifyListeners();
      }
      return null;
    }
    return call;
  }

  void _armRingTimeout(String callId) {
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = Timer(_ringTimeout, () async {
      if (isDisposed) return;
      final active = _state.activeCall;
      if (active?.id != callId || active?.status != CallStatus.ringing) return;
      try {
        final missed = await _repo.markMissed(callId);
        // null => answered concurrently; the row watch flips state instead.
        if (missed == null || isDisposed) return;
        await _teardown(unanswered: true);
      } catch (e) {
        debugPrint('[CallController] ring timeout failed: $e');
      }
    });
  }

  Future<void> retryLastCall() async {
    if (_lastConversationId == null || _lastReceiverId == null || _lastType == null) {
      return;
    }
    await startCall(
      conversationId: _lastConversationId!,
      receiverId: _lastReceiverId!,
      type: _lastType!,
    );
  }

  // ---------------------------------------------------------------------------
  // Row watch (both sides observe status changes — no more blind timers)
  // ---------------------------------------------------------------------------

  void _watchRow(String callId) {
    _rowSub?.cancel();
    _rowSub = _repo.watchCall(callId).listen(
      _onRowUpdate,
      onError: (Object error) {
        // The ring timeout still guards the caller if this dies.
        debugPrint('[CallController] row watch error: $error');
      },
    );
  }

  void _onRowUpdate(Call call) {
    if (isDisposed || _ending) return;
    if (_state.activeCall?.id != call.id) return;

    switch (call.status) {
      case CallStatus.active:
        _ringTimeoutTimer?.cancel();
        unawaited(_ringtone.stop());
        _state = _state.copyWith(activeCall: call, clearError: true);
        notifyListeners();
      case CallStatus.missed:
        // Our own timeout won the race (or receiver's stale backstop):
        // surface the unanswered screen.
        unawaited(_teardown(unanswered: true));
      case CallStatus.ended:
      case CallStatus.declined:
        unawaited(_teardown());
      case CallStatus.ringing:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Accept / decline / hang up
  // ---------------------------------------------------------------------------

  Future<void> acceptCall() async {
    if (!_enabled || isDisposed) return;
    final incoming = _state.incomingCall;
    if (incoming == null || _state.isLoading || _state.activeCall != null) return;

    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();
    await _ringtone.stop();

    Call? accepted;
    try {
      accepted = await _repo.acceptCall(incoming.id);
    } catch (e) {
      if (!isDisposed) {
        // Row untouched — user can retry from the incoming screen.
        _state = _state.copyWith(isLoading: false, error: 'Failed to accept call: $e');
        notifyListeners();
      }
      return;
    }

    // null => conditional update lost (answered elsewhere / declined / ended).
    if (accepted == null || isDisposed) {
      unawaited(DesktopCallNotifier.instance.dismissIncomingCall());
      _state = _state.copyWith(isLoading: false, clearIncomingCall: true);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      activeCall: accepted,
      clearIncomingCall: true,
      isLoading: false,
    );
    notifyListeners();
    _watchRow(accepted.id);

    try {
      await _connectMedia(accepted.roomName, accepted.type, _me ?? '');
    } catch (e) {
      debugPrint('[CallController] media connect failed: $e');
      if (!isDisposed) {
        await hangUp();
        _state = _state.copyWith(error: 'Failed to connect call: $e');
        notifyListeners();
      }
    }
  }

  Future<void> declineCall() async {
    if (isDisposed) return;
    final call = _state.incomingCall;
    if (call == null) return;

    unawaited(_ringtone.stop());
    try {
      await _repo.declineCall(call.id);
    } catch (e) {
      debugPrint('[CallController] decline failed: $e');
    }
    if (isDisposed) return;
    _state = _state.copyWith(clearIncomingCall: true);
    unawaited(DesktopCallNotifier.instance.dismissIncomingCall());
    notifyListeners();
  }

  Future<void> hangUp() async {
    if (_ending || isDisposed) return;
    final call = _state.activeCall ?? _state.incomingCall;
    if (call == null && _media == null) return;

    _ending = true;
    try {
      if (call != null) await _repo.endCall(call.id);
    } catch (e) {
      debugPrint('[CallController] endCall failed: $e');
    }
    await _teardown();
    _ending = false;
  }

  /// Local cleanup: no DB writes (caller already did conditionals).
  Future<void> _teardown({bool unanswered = false}) async {
    _ringTimeoutTimer?.cancel();
    _rowSub?.cancel();
    _rowSub = null;
    _state = CallState(
      isUnanswered: unanswered,
      isVideoOn: _media?.isVideoOn ?? true,
    );
    notifyListeners();

    await _ringtone.stop();
    unawaited(NotificationManager.instance.dismissActiveCallNotification());
    unawaited(DesktopCallNotifier.instance.dismissIncomingCall());
    await _media?.disconnect();
  }

  void clearUnanswered() {
    if (isDisposed) return;
    _state = _state.copyWith(clearUnanswered: true);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Native / OS entry points
  // ---------------------------------------------------------------------------

  Future<void> acceptFromNative(String callId) async {
    if (!_enabled || isDisposed) return;
    if (_state.activeCall?.id == callId || _state.isLoading) return;
    try {
      final call = await _repo.getCall(callId);
      if (call == null ||
          call.status != CallStatus.ringing ||
          call.receiverId != _me ||
          _state.activeCall != null ||
          isDisposed) {
        return;
      }
      _state = _state.copyWith(incomingCall: call, clearError: true);
      notifyListeners();
      await acceptCall();
    } catch (e) {
      debugPrint('[CallController] acceptFromNative failed: $e');
    }
  }

  Future<void> declineFromNative(String callId) async {
    if (!_enabled) return;
    if (_state.incomingCall?.id == callId) {
      await declineCall();
      return;
    }
    try {
      await _repo.declineCall(callId);
    } catch (_) {}
  }

  void _consumePendingNative() {
    final acceptId = CallNativeBridge.pendingAcceptCallId;
    CallNativeBridge.pendingAcceptCallId = null;
    if (acceptId != null) {
      unawaited(acceptFromNative(acceptId));
    }
    final declineId = CallNativeBridge.pendingDeclineCallId;
    CallNativeBridge.pendingDeclineCallId = null;
    if (declineId != null) {
      unawaited(declineFromNative(declineId));
    }
  }

  // ---------------------------------------------------------------------------
  // Media + controls
  // ---------------------------------------------------------------------------

  Future<void> _connectMedia(String roomName, CallType type, String userId) async {
    final media = _media ??= _mediaFactory();
    media.onChanged = _onMediaChanged;
    media.onRemoteLeft = _onRemoteLeft;
    await media.connect(
      roomName: roomName,
      userId: userId,
      videoEnabled: type == CallType.video,
    );
    if (isDisposed) return;
    _syncFromMedia();
    final id = _state.activeCall?.id;
    if (id != null) {
      NotificationManager.instance.showActiveCallNotification(
        callId: id,
        participantName: 'Call in Progress',
      );
    }
  }

  void _onRemoteLeft() {
    if (isDisposed || _ending) return;
    // Last remote participant gone — end locally (row conditional no-ops
    // if the peer already ended it server-side).
    unawaited(hangUp());
  }

  void _onMediaChanged() {
    if (isDisposed) return;
    // Coalesce LiveKit event bursts (old CallService used a 16ms debounce).
    _mediaNotifyTimer?.cancel();
    _mediaNotifyTimer = Timer(const Duration(milliseconds: 16), () {
      if (!isDisposed) _syncFromMedia();
    });
  }

  void _syncFromMedia() {
    final media = _media;
    _state = _state.copyWith(
      room: media?.room,
      clearRoom: media?.room == null,
      isMuted: media?.isMuted ?? false,
      isVideoOn: media?.isVideoOn ?? true,
      isScreenSharing: media?.isScreenSharing ?? false,
      audioRoute: media?.audioRoute ?? AudioRoute.earpiece,
    );
    notifyListeners();
  }

  void toggleMute() {
    final media = _media;
    if (media == null) return;
    unawaited(media.setMuted(!media.isMuted));
  }

  void toggleVideo() {
    final media = _media;
    if (media == null) return;
    unawaited(media.setVideoEnabled(!media.isVideoOn));
  }

  void toggleScreenShare() {
    final media = _media;
    if (media == null) return;
    unawaited(media.setScreenShareEnabled(!media.isScreenSharing));
  }

  void cycleAudioRoute() {
    final media = _media;
    if (media == null) return;
    unawaited(media.cycleAudioRoute());
  }

  Future<void> inviteUser(String userId) async {
    final call = _state.activeCall;
    if (call == null || !_enabled) return;
    final me = _me;
    if (me == null) return;
    await _repo.createCall(
      conversationId: call.conversationId,
      callerId: me,
      receiverId: userId,
      type: call.type,
      roomName: call.roomName, // same LiveKit room
    );
  }

  void toggleMinimize({bool? value}) {
    if (isDisposed) return;
    _state = _state.copyWith(isMinimized: value ?? !_state.isMinimized);
    notifyListeners();
  }

  void clearError() {
    if (isDisposed || _state.error == null) return;
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // App lifecycle — in-app ringtone only while visible (native CallKit rings
  // in the background; avoids double ringtones).
  // ---------------------------------------------------------------------------

  void setAppVisible(bool visible) {
    if (_appVisible == visible || isDisposed) return;
    _appVisible = visible;
    if (!visible) {
      unawaited(_ringtone.stop());
    } else if (_state.incomingCall != null && _state.activeCall == null) {
      unawaited(_ringtone.play());
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-out / dispose
  // ---------------------------------------------------------------------------

  /// Full reset on sign-out / account switch: cancels subscriptions and
  /// tears down media without writing to the DB.
  void reset() {
    if (isDisposed) return;
    _ringTimeoutTimer?.cancel();
    _retryTimer?.cancel();
    _mediaNotifyTimer?.cancel();
    _incomingSub?.cancel();
    _incomingSub = null;
    _rowSub?.cancel();
    _rowSub = null;
    _ending = false;
    _state = CallState.initial();
    unawaited(_ringtone.stop());
    unawaited(NotificationManager.instance.dismissActiveCallNotification());
    unawaited(DesktopCallNotifier.instance.dismissIncomingCall());
    unawaited(_media?.disconnect() ?? Future<void>.value());
    _lastConversationId = null;
    _lastReceiverId = null;
    _lastType = null;
    notifyListeners();
    // Re-arm incoming watch if a session still exists (account switch).
    if (_enabled) _startIncomingWatch();
  }

  @override
  void dispose() {
    CallNativeBridge.unregister();
    _ringTimeoutTimer?.cancel();
    _retryTimer?.cancel();
    _mediaNotifyTimer?.cancel();
    _incomingSub?.cancel();
    _rowSub?.cancel();
    _authSub?.cancel();
    _ringtone.dispose();
    _media?.dispose();
    super.dispose();
  }
}
