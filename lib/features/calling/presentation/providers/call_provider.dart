import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:oasis/services/call_service.dart';
import '../../domain/models/call_entity.dart';
import '../../domain/models/call_participant_entity.dart';
import '../../domain/usecases/initiate_call.dart';
import '../../domain/usecases/accept_call.dart';
import '../../domain/usecases/end_call.dart';
import '../../domain/usecases/get_active_calls.dart';

/// Immutable state for calling feature
class CallState {
  final CallEntity? activeCall;
  final CallEntity? incomingCall;
  final List<CallEntity> activeCalls;
  final List<CallParticipantEntity> participants;
  final MediaStream? localStream;
  final Map<String, MediaStream> remoteStreams;
  final bool isLoading;
  final String? error;
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;

  const CallState({
    this.activeCall,
    this.incomingCall,
    this.activeCalls = const [],
    this.participants = const [],
    this.localStream,
    this.remoteStreams = const {},
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
    bool clearActiveCall = false,
    CallEntity? incomingCall,
    bool clearIncomingCall = false,
    List<CallEntity>? activeCalls,
    List<CallParticipantEntity>? participants,
    MediaStream? localStream,
    Map<String, MediaStream>? remoteStreams,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isMuted,
    bool? isVideoOn,
    bool? isScreenSharing,
  }) {
    return CallState(
      activeCall: clearActiveCall ? null : (activeCall ?? this.activeCall),
      incomingCall: clearIncomingCall ? null : (incomingCall ?? this.incomingCall),
      activeCalls: activeCalls ?? this.activeCalls,
      participants: participants ?? this.participants,
      localStream: localStream ?? this.localStream,
      remoteStreams: remoteStreams ?? this.remoteStreams,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isMuted: isMuted ?? this.isMuted,
      isVideoOn: isVideoOn ?? this.isVideoOn,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
    );
  }
}

/// Provider for call state management
class CallProvider extends ChangeNotifier {
  final CallService _callService;
  late InitiateCall _initiateCall;
  late AcceptCall _acceptCall;
  late EndCall _endCall;
  late GetActiveCalls _getActiveCalls;
  bool _isInitialized = false;
  bool _isEnding = false;

  CallState _state = CallState.initial();

  CallProvider(this._callService) {
    _callService.addListener(_onCallServiceUpdate);
  }

  void _onCallServiceUpdate() {
    if (_isEnding) return; // Ignore updates while we are trying to end the call

    _state = _state.copyWith(
      localStream: _callService.localStream,
      remoteStreams: Map.from(_callService.remoteStreams),
      participants: List.from(_callService.participants),
      isMuted: _callService.isMuted,
      isVideoOn: _callService.isVideoOn,
      isScreenSharing: _callService.isScreenSharing,
      incomingCall: _callService.incomingCall,
      clearIncomingCall: _callService.incomingCall == null,
      clearActiveCall: _callService.currentCallId == null,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _callService.removeListener(_onCallServiceUpdate);
    super.dispose();
  }

  CallState get state => _state;
  CallEntity? get activeCall => _state.activeCall;
  CallEntity? get incomingCall => _state.incomingCall;
  bool get hasActiveCall => _state.activeCall != null;
  bool get hasIncomingCall => _state.incomingCall != null;
  MediaStream? get localStream => _state.localStream;
  Map<String, MediaStream> get remoteStreams => _state.remoteStreams;
  bool get isMuted => _state.isMuted;
  bool get isVideoOn => _state.isVideoOn;
  bool get isScreenSharing => _state.isScreenSharing;

  Future<void> initialize({
    required InitiateCall initiateCall,
    required AcceptCall acceptCall,
    required EndCall endCall,
    required GetActiveCalls getActiveCalls,
  }) async {
    if (_isInitialized) return;

    _initiateCall = initiateCall;
    _acceptCall = acceptCall;
    _endCall = endCall;
    _getActiveCalls = getActiveCalls;
    _state = _state.copyWith(isLoading: false);
    _callService.startIncomingCallListener();
    _isInitialized = true;
    _isEnding = false;
    notifyListeners();
  }

  /// Initiate a new multi-participant call
  Future<CallEntity?> initiateCall({
    required String conversationId,
    required String hostId,
    required CallType type,
    required List<String> participantIds,
  }) async {
    try {
      _isEnding = false;
      _state = _state.copyWith(isLoading: true, clearError: true);
      notifyListeners();

      final call = await _initiateCall.call(
        conversationId: conversationId,
        hostId: hostId,
        type: type,
        participantIds: participantIds,
      );

      if (call != null) {
        // Now that the call is created in DB, join it to start WebRTC
        await _callService.joinCall(call);
        await _callService.startRingtone(); // Start ringing for host
        _state = _state.copyWith(activeCall: call, isLoading: false);
      } else {
        _state = _state.copyWith(isLoading: false, error: 'Failed to create call');
      }

      notifyListeners();
      return call;
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Join an existing call
  Future<void> joinCall(CallEntity call) async {
    try {
      _isEnding = false;
      _state = _state.copyWith(isLoading: true, clearError: true);
      notifyListeners();

      // Join via service (which handles WebRTC + DB)
      await _callService.joinCall(call);
      
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
      _isEnding = true;
      _state = _state.copyWith(isLoading: true, clearError: true);
      notifyListeners();

      await _endCall.decline(callId, userId);
      await _callService.endCall(); // Clean up WebRTC if needed

      _state = _state.copyWith(isLoading: false, clearIncomingCall: true, clearActiveCall: true);
      _isEnding = false;
      notifyListeners();
    } catch (e) {
      _isEnding = false;
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  /// End current call
  Future<void> endCall() async {
    try {
      final callId = _state.activeCall?.id ?? _state.incomingCall?.id;
      if (callId == null) return;
      
      // Clear state immediately to avoid navigation loops
      _isEnding = true;
      _state = _state.copyWith(
        isLoading: true, 
        clearError: true,
        clearActiveCall: true,
        clearIncomingCall: true,
      );
      notifyListeners();

      // End in repository
      await _endCall.call(callId);
      
      // End in WebRTC service
      await _callService.endCall();
      
      _state = _state.copyWith(isLoading: false);
      _isEnding = false;
      notifyListeners();
    } catch (e) {
      _isEnding = false;
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  /// Toggle mute
  void toggleMute() {
    _callService.toggleMute();
  }

  /// Toggle video
  void toggleVideo() {
    _callService.toggleVideo();
  }

  /// Toggle screen sharing
  Future<void> toggleScreenShare() async {
    await _callService.toggleScreenShare();
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
