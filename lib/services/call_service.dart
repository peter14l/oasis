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
import 'package:permission_handler/permission_handler.dart';

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

  /// Lock the current call ID when starting to answer, to prevent race conditions.
  void setAnswering(String callId) {
    _currentCallId = callId;
  }

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

  bool _isScreenSharing = false;
  String? _remoteScreenShareUserId;

  bool get isMuted => _isMuted;
  bool get isVideoOn => _isVideoOn;
  bool get isScreenSharing => _isScreenSharing;
  String? get remoteScreenShareUserId => _remoteScreenShareUserId;

  Future<void> initLocalStream(bool isVideo) async {
    // Check and request permissions for mobile
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        throw Exception('Microphone permission denied');
      }

      if (isVideo) {
        final camStatus = await Permission.camera.request();
        if (camStatus != PermissionStatus.granted) {
          throw Exception('Camera permission denied');
        }
      }
    }

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

    // Configure audio session for mobile
    await _configureAudioSession(isVideo);

    notifyListeners();
  }

  Future<void> _configureAudioSession(bool isVideo) async {
    if (kIsWeb) return;

    try {
      if (Platform.isIOS || Platform.isAndroid) {
        // NOTE: setAppleAudioCategory might be renamed or missing in this version
        // of flutter_webrtc. Commenting out to fix build error.
        /*
        await Helper.setAppleAudioCategory(
          AppleAudioCategory.playAndRecord,
          appleAudioCategoryOptions: [
            AppleAudioCategoryOption.allowBluetooth,
            AppleAudioCategoryOption.defaultToSpeaker,
          ],
        );
        */
        
        // Use speakerphone by default for video calls, earpiece for voice calls
        await Helper.setSpeakerphoneOn(isVideo);
      }
    } catch (e) {
      debugPrint('[CallService] Error configuring audio session: $e');
    }
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
      debugPrint('[CallService] onTrack: ${event.track.kind} from $remoteUserId');
      MediaStream stream;
      if (event.streams.isNotEmpty) {
        stream = event.streams[0];
      } else {
        // Fallback for Unified Plan where streams might be empty
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
      
      // Ensure the audio track is enabled
      if (event.track.kind == 'audio') {
        event.track.enabled = true;
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
    
    try {
      // Use raw signaling data for diagnostics (Temporary bypass)
      final payload = data;

      await _signalingChannel!.sendBroadcastMessage(
        event: 'signaling',
        payload: {
          'sender_id': _supabase.auth.currentUser!.id,
          'recipient_id': recipientId,
          ...payload,
        },
      );
    } catch (e) {
      debugPrint('[CallService] Error sending signaling: $e');
    }
  }

  Future<Map<String, dynamic>> _encryptData(String recipientId, Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    final encrypted = await _signal.encryptMessage(recipientId, jsonStr);
    
    // Mapping for Supabase signaling types: 1 = PreKey, 2 = Whisper
    int dbType = encrypted.getType();
    if (dbType == 3) dbType = 1;

    return {
      'e2ee': true,
      'payload': base64Encode(encrypted.serialize()),
      'signal_message_type': dbType,
    };
  }

  Future<Map<String, dynamic>> _decryptData(String senderId, Map<String, dynamic> encryptedData, {int attempt = 0}) async {
    if (encryptedData['e2ee'] != true) return encryptedData;
    
    try {
      int signalType = encryptedData['signal_message_type'];
      if (signalType == 1) signalType = 3;

      final decryptedJson = await _signal.decryptMessage(
        senderId,
        encryptedData['payload'],
        signalType,
      );

      if (decryptedJson.startsWith('🔒')) {
        // If this is the first attempt, try one retry after a short delay
        // (the session might still be establishing)
        if (attempt < 2) {
          await Future.delayed(const Duration(milliseconds: 500));
          return _decryptData(senderId, encryptedData, attempt: attempt + 1);
        }
        throw Exception('Decryption failed: Message locked');
      }

      return jsonDecode(decryptedJson);
    } catch (e) {
      if (attempt < 2) {
        await Future.delayed(const Duration(milliseconds: 500));
        return _decryptData(senderId, encryptedData, attempt: attempt + 1);
      }
      debugPrint('[CallService] Decryption error after $attempt attempts: $e');
      rethrow;
    }
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
    
    // Use raw offer directly (Temporary bypass)
    final decryptedOffer = offer;

    await pc.setRemoteDescription(RTCSessionDescription(decryptedOffer['sdp'], decryptedOffer['sdp_type']));
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
        .listen((data) async {
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
              try {
                // Use raw answer (Temporary bypass)
                await _handleSignalingData(updatedCall.receiverId, updatedCall.answer!);
              } catch (e) {
                debugPrint('[CallService] Error processing answer: $e');
              }
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
            final decryptedData = await _decryptData(senderId, payload);
            await _handleSignalingData(senderId, decryptedData);
          } catch (e) {
            debugPrint('[CallService] Signaling processing error: $e');
          }
        });
      }
    }).subscribe();
  }

  Future<void> toggleScreenShare() async {
    try {
      if (_isScreenSharing) {
        // Stop screen share
        _isScreenSharing = false;
        
        // Revert to camera if video was on
        await initLocalStream(_isVideoOn);
      } else {
        // Start screen share
        final MediaStream screenStream = await navigator.mediaDevices.getDisplayMedia({
          'video': true,
          'audio': false,
        });

        if (screenStream.getVideoTracks().isNotEmpty) {
          final screenTrack = screenStream.getVideoTracks().first;
          
          // Replace track in all peer connections
          for (var pc in _peerConnections.values) {
            final senders = await pc.getSenders();
            final videoSender = senders.firstWhere((s) => s.track?.kind == 'video');
            await videoSender.replaceTrack(screenTrack);
          }

          _isScreenSharing = true;
          
          // Notify remote users about screen share state
          final userId = _supabase.auth.currentUser!.id;
          for (var remoteId in _peerConnections.keys) {
            await _sendSignaling(remoteId, {
              'type': 'screen_share_state',
              'userId': userId,
              'isSharing': true,
            });
          }

          screenTrack.onEnded = () {
            toggleScreenShare();
          };
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[CallService] Error toggling screen share: $e');
    }
  }

  Future<void> _handleSignalingData(String senderId, Map<String, dynamic> data) async {
    final type = data['type'];
    final pc = _peerConnections[senderId];
    
    if (type == 'offer') {
      if (pc != null) {
        await pc.setRemoteDescription(RTCSessionDescription(data['sdp'], data['sdp_type']));
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        
        await _sendSignaling(senderId, {
          'type': 'answer',
          'sdp': answer.sdp,
          'sdp_type': answer.type,
        });
      }
    } else if (type == 'answer') {
      if (pc != null && pc.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        await pc.setRemoteDescription(RTCSessionDescription(data['sdp'], data['sdp_type']));
        await _applyBitrateConstraints(pc);
        await _flushCandidateQueue(senderId, pc);
      }
    } else if (type == 'candidate') {
      if (pc != null) {
        debugPrint('[CallService] Adding ICE candidate from $senderId');
        await pc.addCandidate(RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        ));
      } else {
        debugPrint('[CallService] Queuing ICE candidate from $senderId');
        _candidateQueue[senderId] ??= [];
        _candidateQueue[senderId]!.add(data);
      }
    } else if (type == 'screen_share_state') {
      final isSharing = data['isSharing'] as bool;
      if (isSharing) {
        _remoteScreenShareUserId = data['userId'];
      } else if (_remoteScreenShareUserId == data['userId']) {
        _remoteScreenShareUserId = null;
      }
      notifyListeners();
    }
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
    // Dismiss any desktop OS notification shown for this call.
    DesktopCallNotifier.instance.dismissIncomingCall();
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
