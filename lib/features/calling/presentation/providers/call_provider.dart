import 'package:flutter/foundation.dart';
import '../../domain/models/call_entity.dart';
import '../../domain/models/call_participant_entity.dart';
import '../../domain/usecases/initiate_call.dart';
import '../../domain/usecases/accept_call.dart';
import '../../domain/usecases/end_call.dart';
import '../../domain/usecases/get_active_calls.dart';

/// Immutable state for calling feature
class CallState {
  final CallEntity? activeCall;
  final List<CallEntity> activeCalls;
  final List<CallParticipantEntity> participants;
  final bool isLoading;
  final String? error;
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;

  const CallState({
    this.activeCall,
    this.activeCalls = const [],
    this.participants = const [],
    this.isLoading = false,
    this.error,
    this.isMuted = false,
    this.isVideoOn = true,
    this.isScreenSharing = false,
  });

  factory CallState.initial() {
    return const CallState(isLoading: true);
  }

  CallState copyWith({
    CallEntity? activeCall,
    List<CallEntity>? activeCalls,
    List<CallParticipantEntity>? participants,
    bool? isLoading,
    String? error,
    bool? isMuted,
    bool? isVideoOn,
    bool? isScreenSharing,
  }) {
    return CallState(
      activeCall: activeCall ?? this.activeCall,
      activeCalls: activeCalls ?? this.activeCalls,
      participants: participants ?? this.participants,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isMuted: isMuted ?? this.isMuted,
      isVideoOn: isVideoOn ?? this.isVideoOn,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
    );
  }
}

/// Provider for call state management
class CallProvider extends ChangeNotifier {
  late final InitiateCall _initiateCall;
  late final AcceptCall _acceptCall;
  late final EndCall _endCall;
  late final GetActiveCalls _getActiveCalls;

  CallState _state = CallState.initial();

  CallState get state => _state;
  CallEntity? get activeCall => _state.activeCall;
  bool get hasActiveCall => _state.activeCall != null;
  bool get isMuted => _state.isMuted;
  bool get isVideoOn => _state.isVideoOn;
  bool get isScreenSharing => _state.isScreenSharing;

  Future<void> initialize() async {
    // Initialize use cases (would be injected in real app)
    _state = _state.copyWith(isLoading: false);
    notifyListeners();
  }

  /// Initiate a new call
  Future<CallEntity?> initiateCall({
    required String conversationId,
    required String hostId,
    required CallType type,
  }) async {
    try {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();

      final call = await _initiateCall.call(
        conversationId: conversationId,
        hostId: hostId,
        type: type,
      );

      _state = _state.copyWith(isLoading: false, activeCall: call);
      notifyListeners();
      return call;
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Accept incoming call
  Future<void> acceptCall(String callId, String userId) async {
    try {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();

      final call = await _acceptCall.call(callId: callId, userId: userId);
      _state = _state.copyWith(isLoading: false, activeCall: call);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  /// Decline incoming call
  Future<void> declineCall(String callId, String userId) async {
    try {
      await _endCall.decline(callId, userId);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  /// End current call
  Future<void> endCall(String callId) async {
    try {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();

      await _endCall.call(callId);
      _state = _state.copyWith(isLoading: false, activeCall: null);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  /// Toggle mute
  void toggleMute() {
    _state = _state.copyWith(isMuted: !_state.isMuted);
    notifyListeners();
  }

  /// Toggle video
  void toggleVideo() {
    _state = _state.copyWith(isVideoOn: !_state.isVideoOn);
    notifyListeners();
  }

  /// Toggle screen sharing
  void toggleScreenShare() {
    _state = _state.copyWith(isScreenSharing: !_state.isScreenSharing);
    notifyListeners();
  }

  /// Load active calls
  Future<void> loadActiveCalls(String userId) async {
    try {
      final calls = await _getActiveCalls.calls(userId);
      _state = _state.copyWith(activeCalls: calls);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }
}
