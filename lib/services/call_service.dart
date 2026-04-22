import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/features/calling/domain/models/call_entity.dart';
import 'package:oasis/features/messages/data/signal/signal_service.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/services/desktop_call_notifier.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CallService extends ChangeNotifier {
  final _supabase = SupabaseService().client;
  final _signal = SignalService();
  final _uuid = const Uuid();
  final _audioPlayer = AudioPlayer();
  bool _isPlayingRingtone = false;

  // Multi-peer management
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, List<Map<String, dynamic>>> _candidateQueue = {};
  final Map<String, MediaStream> _remoteStreams = {};
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool _localRendererInitialized = false;

  // Track peer connections currently being initialized
  final Set<String> _pendingPeerConnections = {};

  MediaStream? _localStream;
  String? _currentCallId;
  CallEntity? _currentCall;
  
  StreamSubscription? _callSubscription;
  RealtimeChannel? _signalingChannel;

  MediaStream? get localStream => _localStream;
  Map<String, MediaStream> get remoteStreams => _remoteStreams;
  Map<String, RTCVideoRenderer> get remoteRenderers => _remoteRenderers;
  RTCVideoRenderer get localRenderer => _localRenderer;
  CallEntity? get currentCall => _currentCall;
  String? get currentCallId => _currentCallId;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isScreenSharing = false;

  bool get isMuted => _isMuted;
  bool get isVideoOn => _isVideoOn;
  bool get isScreenSharing => _isScreenSharing;

  Future<void> initLocalStream(bool isVideo) async {
    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': isVideo ? {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
        'frameRate': {'ideal': 30},
      } : false,
    };

    if (!_localRendererInitialized) {
      await _localRenderer.initialize();
      _localRendererInitialized = true;
    }

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    _localRenderer.srcObject = _localStream;
    _isVideoOn = isVideo;
    _isMuted = false;
    notifyListeners();
  }

  Future<RTCPeerConnection> _createPeerConnection(String remoteUserId) async {
    final pc = await createPeerConnection(_configuration);
    
    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    pc.onIceCandidate = (candidate) {
      _sendSignaling(remoteUserId, {
        'type': 'candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    pc.onTrack = (event) async {
      MediaStream stream;
      if (event.streams.isNotEmpty) {
        stream = event.streams[0];
      } else {
        _remoteStreams[remoteUserId] ??= await createLocalMediaStream('remote_$remoteUserId');
        _remoteStreams[remoteUserId]!.addTrack(event.track);
        stream = _remoteStreams[remoteUserId]!;
      }
      _remoteStreams[remoteUserId] = stream;

      if (!_remoteRenderers.containsKey(remoteUserId)) {
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        renderer.srcObject = stream;
        _remoteRenderers[remoteUserId] = renderer;
      } else if (_remoteRenderers[remoteUserId]!.srcObject != stream) {
        _remoteRenderers[remoteUserId]!.srcObject = stream;
      }
      
      notifyListeners();
    };

    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _removePeer(remoteUserId);
      }
    };

    _peerConnections[remoteUserId] = pc;
    return pc;
  }

  Future<void> _applyBitrateConstraints(RTCPeerConnection pc) async {
    final senders = await pc.getSenders();
    for (var sender in senders) {
      if (sender.track?.kind == 'video') {
        var parameters = sender.parameters;
        if (parameters.encodings != null && parameters.encodings!.isNotEmpty) {
          parameters.encodings![0].maxBitrate = 1500000;
          await sender.setParameters(parameters);
        }
      }
    }
  }

  Future<void> _sendSignaling(String recipientId, Map<String, dynamic> data) async {
    if (_currentCallId == null || _signalingChannel == null) return;
    
    final jsonStr = jsonEncode(data);
    final encrypted = await _signal.encryptMessage(recipientId, jsonStr);
    
    int dbType = encrypted.getType();
    if (dbType == 3) dbType = 1;

    await _signalingChannel!.sendBroadcast(
      event: 'signaling',
      payload: {
        'sender_id': _supabase.auth.currentUser!.id,
        'recipient_id': recipientId,
        'candidate': base64Encode(encrypted.serialize()),
        'signal_message_type': dbType,
      },
    );
  }

  Future<Map<String, dynamic>> createOffer(String remoteUserId) async {
    final pc = await _getOrCreatePeerConnection(remoteUserId);
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    
    return {
      'type': 'offer',
      'sdp': offer.sdp,
      'sdp_type': offer.type,
    };
  }

  Future<Map<String, dynamic>> createAnswer(String remoteUserId, Map<String, dynamic> offer) async {
    final pc = await _getOrCreatePeerConnection(remoteUserId);
    
    if (pc.signalingState != RTCSignalingState.RTCSignalingStateStable) {
       // If we already have a local offer, we might have a glare condition.
       // In V2, we follow a strict caller-receiver model, so this shouldn't happen often.
    }

    await pc.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['sdp_type']));
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    await _applyBitrateConstraints(pc);
    
    return {
      'type': 'answer',
      'sdp': answer.sdp,
      'sdp_type': answer.type,
    };
  }

  Future<void> startSignaling(CallEntity call) async {
    _currentCallId = call.id;
    _currentCall = call;
    
    _subscribeToCall(call.id);
    _subscribeToSignaling(call.id);
    
    notifyListeners();
  }

  void _subscribeToCall(String callId) {
    final userId = _supabase.auth.currentUser!.id;
    _callSubscription?.cancel();
    _callSubscription = _supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .listen((data) {
          if (data.isNotEmpty) {
            final updatedCall = CallEntity.fromJson(data.first);
            final oldCall = _currentCall;
            _currentCall = updatedCall;

            if (updatedCall.status == CallStatus.ended || 
                updatedCall.status == CallStatus.declined ||
                updatedCall.status == CallStatus.missed) {
              _cleanup();
              return;
            }

            // Caller receives the answer
            if (updatedCall.callerId == userId && 
                updatedCall.status == CallStatus.active && 
                oldCall?.status == CallStatus.ringing &&
                updatedCall.answer != null) {
              _handleSignalingData(updatedCall.receiverId, updatedCall.answer!);
            }

            notifyListeners();
          }
        });
  }

  void _subscribeToSignaling(String callId) {
    final userId = _supabase.auth.currentUser!.id;
    
    _signalingChannel = _supabase.channel('call_$callId');
    
    _signalingChannel!.onBroadcast(event: 'signaling', callback: (payload) {
      final senderId = payload['sender_id'];
      final recipientId = payload['recipient_id'];

      if (recipientId == userId && senderId != userId) {
        Future(() async {
          try {
            int signalType = payload['signal_message_type'];
            if (signalType == 1) signalType = 3;

            final decryptedJson = await _signal.decryptMessage(
              senderId,
              payload['candidate'],
              signalType,
            );

            if (decryptedJson.startsWith('🔒')) return;

            final signalData = jsonDecode(decryptedJson);
            await _handleSignalingData(senderId, signalData);
          } catch (e) {
            debugPrint('[CallService] Signaling decryption error: $e');
          }
        });
      }
    }).subscribe();
  }

  Future<void> _handleSignalingData(String senderId, Map<String, dynamic> data) async {
    final type = data['type'];
    final pc = _peerConnections[senderId];
    
    if (type == 'offer') {
       // Should be handled via calls table initial handshake in V2, but keeping for robustness
    } else if (type == 'answer') {
      if (pc != null && pc.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        await pc.setRemoteDescription(RTCSessionDescription(data['sdp'], data['sdp_type']));
        await _applyBitrateConstraints(pc);
        await _flushCandidateQueue(senderId, pc);
      }
    } else if (type == 'candidate') {
      if (pc != null) {
        await pc.addCandidate(RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        ));
      } else {
        _candidateQueue[senderId] ??= [];
        _candidateQueue[senderId]!.add(data);
      }
    }
  }

  Future<void> _flushCandidateQueue(String senderId, RTCPeerConnection pc) async {
    final queue = _candidateQueue[senderId];
    if (queue != null && queue.isNotEmpty) {
      for (var candData in queue) {
        await pc.addCandidate(RTCIceCandidate(
          candData['candidate'],
          candData['sdpMid'],
          candData['sdpMLineIndex'],
        ));
      }
      queue.clear();
    }
  }

  Future<RTCPeerConnection> _getOrCreatePeerConnection(String remoteUserId) async {
    if (_peerConnections.containsKey(remoteUserId)) {
      return _peerConnections[remoteUserId]!;
    }

    while (_pendingPeerConnections.contains(remoteUserId)) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_peerConnections.containsKey(remoteUserId)) {
        return _peerConnections[remoteUserId]!;
      }
    }

    _pendingPeerConnections.add(remoteUserId);
    try {
      return await _createPeerConnection(remoteUserId);
    } finally {
      _pendingPeerConnections.remove(remoteUserId);
    }
  }

  void _removePeer(String userId) {
    _peerConnections[userId]?.close();
    _peerConnections.remove(userId);
    _remoteStreams.remove(userId);
    _candidateQueue.remove(userId);
    _remoteRenderers[userId]?.dispose();
    _remoteRenderers.remove(userId);
    notifyListeners();
  }

  // Legacy compatibility / simpler join
  Future<void> joinCall(CallEntity call) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    await initLocalStream(call.type == CallType.video);
    await startSignaling(call);
  }

  Future<void> answerCall(CallEntity call) async {
     // Handled by CallProvider usually, but keeping for logic
  }

  void _cleanup() {
    _callSubscription?.cancel();
    _signalingChannel?.unsubscribe();
    _callSubscription = null;
    _signalingChannel = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    for (var pc in _peerConnections.values) {
      pc.close();
    }
    _peerConnections.clear();
    _remoteStreams.clear();
    _candidateQueue.clear();

    for (var renderer in _remoteRenderers.values) {
      renderer.dispose();
    }
    _remoteRenderers.clear();
    _localRenderer.srcObject = null;

    _participants.clear();
    _currentCallId = null;
    _currentCall = null;
    _incomingCall = null;
    _stopRingtone();
    notifyListeners();
  }

  // Global listener for incoming calls
  StreamSubscription? _incomingCallSubscription;
  CallEntity? _incomingCall;
  CallEntity? get incomingCall => _incomingCall;

  void startIncomingCallListener() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _incomingCallSubscription?.cancel();
    _incomingCallSubscription = _supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', user.id)
        .eq('status', 'ringing')
        .listen((data) async {
      if (data.isNotEmpty) {
        final call = CallEntity.fromJson(data.first);
        _incomingCall = call;
        _playRingtone();
        notifyListeners();

        final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
        if (!isMobile) {
          String callerName = 'Someone';
          try {
            final profile = await _supabase
                .from('profiles')
                .select('display_name')
                .eq('id', call.callerId)
                .maybeSingle();
            callerName = (profile?['display_name'] as String?) ?? 'Someone';
          } catch (_) {}

          DesktopCallNotifier.instance.handleIncomingCall(
            callId: call.id,
            callerName: callerName,
            senderId: call.callerId,
          );
        }
      } else {
        if (_incomingCall != null && _currentCallId == null) {
          _incomingCall = null;
          _stopRingtone();
          notifyListeners();
        }
      }
    });
  }

  Future<void> endCall() async {
    if (_currentCallId == null) return;
    final callId = _currentCallId!;
    _cleanup();
    await _supabase.from('calls').update({
      'status': 'ended',
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', callId);
  }

  void toggleMute() {
    if (_localStream == null) return;
    _isMuted = !_isMuted;
    _localStream!.getAudioTracks().forEach((track) => track.enabled = !_isMuted);
    notifyListeners();
  }

  Future<void> toggleVideo() async {
    if (_localStream == null) return;
    _isVideoOn = !_isVideoOn;
    _localStream!.getVideoTracks().forEach((track) => track.enabled = _isVideoOn);
    notifyListeners();
  }

  Future<void> toggleScreenShare() async {
     // TODO: Re-implement if needed for V2
  }

  Future<void> _playRingtone() async {
    if (_isPlayingRingtone) return;
    _isPlayingRingtone = true;
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/standardringtone.mp3'));
    } catch (_) {
      _isPlayingRingtone = false;
    }
  }

  Future<void> _stopRingtone() async {
    _isPlayingRingtone = false;
    await _audioPlayer.stop();
  }

  Future<void> startRingtone() => _playRingtone();
  Future<void> stopRingtone() => _stopRingtone();

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    _callSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
