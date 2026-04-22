import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/features/calling/domain/models/call_entity.dart';
import 'package:oasis/features/calling/domain/models/call_participant_entity.dart';
import 'package:oasis/features/messages/data/signal/signal_service.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';

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
  final List<CallParticipantEntity> _participants = [];
  MediaStream? _localStream;
  String? _currentCallId;
  CallEntity? _currentCall;
  StreamSubscription? _callSubscription;

  MediaStream? get localStream => _localStream;
  Map<String, MediaStream> get remoteStreams => _remoteStreams;
  List<CallParticipantEntity> get participants => _participants;
  CallEntity? get currentCall => _currentCall;
  
  /// Get the first remote stream for 1-on-1 convenience.
  MediaStream? get remoteStream => _remoteStreams.isNotEmpty ? _remoteStreams.values.first : null;
  
  String? get currentCallId => _currentCallId;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      // Recommendation 2: Added TURN server for restricted networks
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  // Media state
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

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    _isVideoOn = isVideo;
    _isMuted = false;
    notifyListeners();
  }

  Future<RTCPeerConnection> _createPeerConnection(String remoteUserId, CallType type) async {
    final pc = await createPeerConnection(_configuration);
    
    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    pc.onIceCandidate = (candidate) {
      _sendEncryptedSignaling(remoteUserId, {
        'type': 'candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    pc.onTrack = (event) async {
      // Recommendation: Track Fallback (Section B.1)
      // Handles cases where tracks arrive without a stream container
      if (event.streams.isNotEmpty) {
        _remoteStreams[remoteUserId] = event.streams[0];
      } else {
        _remoteStreams[remoteUserId] ??= await createLocalMediaStream('remote_$remoteUserId');
        _remoteStreams[remoteUserId]!.addTrack(event.track);
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
    // Recommendation 1: Bitrate Constraints (Section E.1)
    // Limits video bandwidth to 1.5Mbps to save data/battery
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

  Future<void> _sendEncryptedSignaling(String recipientId, Map<String, dynamic> data) async {
    if (_currentCallId == null) return;
    
    final jsonStr = jsonEncode(data);
    final encrypted = await _signal.encryptMessage(recipientId, jsonStr);
    
    await _supabase.from('call_signaling').insert({
      'call_id': _currentCallId,
      'sender_id': _supabase.auth.currentUser!.id,
      'recipient_id': recipientId, // Add recipient_id to schema if needed or filter in stream
      'candidate': base64Encode(encrypted.serialize()),
      'signal_message_type': encrypted.getType(),
    });
  }

  Future<void> joinCall(CallEntity call) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    _currentCallId = call.id;
    _currentCall = call;
    await initLocalStream(call.type == CallType.video);

    await _supabase.from('call_participants').upsert({
      'call_id': call.id,
      'user_id': user.id,
      'joined_at': DateTime.now().toIso8601String(),
      'status': 'joined',
    }, onConflict: 'call_id,user_id');

    _subscribeToCall(call.id);
    _subscribeToSignaling(call.id);
    _subscribeToParticipants(call.id);
  }

  void _subscribeToCall(String callId) {
    _callSubscription?.cancel();
    _callSubscription = _supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .listen((data) {
          if (data.isNotEmpty) {
            _currentCall = CallEntity.fromJson(data.first);
            notifyListeners();
          }
        });
  }

  void _subscribeToSignaling(String callId) {
    final userId = _supabase.auth.currentUser!.id;
    
    _supabase
        .from('call_signaling')
        .stream(primaryKey: ['id'])
        .eq('call_id', callId)
        .handleError((error) {
          debugPrint('[CallService] Signaling stream error: $error');
        })
        .listen((data) async {
          for (var item in data) {
            final senderId = item['sender_id'];
            final recipientId = item['recipient_id'];
            
            // Only process if it's meant for us and not from us
            if (recipientId == userId && senderId != userId) {
              try {
                final decryptedJson = await _signal.decryptMessage(
                  senderId,
                  item['candidate'],
                  item['signal_message_type'],
                );
                
                if (decryptedJson.startsWith('🔒')) {
                  debugPrint('[CallService] Skipping encrypted/invalid signal message');
                  continue; // Skip processing if decryption failed or session reset is required
                }
                
                final signalData = jsonDecode(decryptedJson);
                await _handleSignalingData(senderId, signalData);
              } catch (e) {
                debugPrint('[CallService] Signaling decryption error: $e');
              }
            }
          }
        });
  }

  Future<void> _handleSignalingData(String senderId, Map<String, dynamic> data) async {
    final type = data['type'];
    
    if (type == 'offer') {
      final pc = await _getOrCreatePeerConnection(senderId);
      await pc.setRemoteDescription(RTCSessionDescription(data['sdp'], data['sdp_type']));
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      
      await _applyBitrateConstraints(pc);
      
      _sendEncryptedSignaling(senderId, {
        'type': 'answer',
        'sdp': answer.sdp,
        'sdp_type': answer.type,
      });

      // Flush any queued candidates that arrived before the connection was created
      await _flushCandidateQueue(senderId, pc);
    } else if (type == 'answer') {
      final pc = _peerConnections[senderId];
      if (pc != null) {
        await pc.setRemoteDescription(RTCSessionDescription(data['sdp'], data['sdp_type']));
        await _applyBitrateConstraints(pc);

        // Flush any queued candidates
        await _flushCandidateQueue(senderId, pc);
      }
    } else if (type == 'candidate') {
      final pc = _peerConnections[senderId];
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
    // We need to know the call type here, let's assume stored or passed
    // For now, default to video if local stream has video
    final hasVideo = _localStream?.getVideoTracks().isNotEmpty ?? false;
    return _createPeerConnection(remoteUserId, hasVideo ? CallType.video : CallType.voice);
  }

  void _subscribeToParticipants(String callId) {
    _supabase
        .from('call_participants')
        .stream(primaryKey: ['id'])
        .eq('call_id', callId)
        .handleError((error) {
          debugPrint('[CallService] Participants stream error: $error');
        })
        .listen((data) async {
          _participants.clear();
          _participants.addAll(data.map((p) => CallParticipantEntity.fromJson(p)));
          notifyListeners();

          final userId = _supabase.auth.currentUser!.id;

          // Scalability Optimization: SFU vs Mesh (Section F.1)
          if (SupabaseConfig.isSFUEnabled) {
            // SFU MODE: Connect only to the media server
            // The server acts as a single peer for all participants
            if (!_peerConnections.containsKey('SFU_SERVER')) {
              await _initiatePeerConnection('SFU_SERVER');
              debugPrint('[CallService] Connected to SFU Server for $callId');
            }
          } else {
            // MESH MODE: Full Mesh architecture (n*(n-1)/2 connections)
            for (var participant in data) {
              final pUserId = participant['user_id'];
              final status = participant['status'];
              
              if (pUserId != userId) {
                if (status == 'joined') {
                  _stopRingtone(); // Stop ringing when someone joins
                  _setAudioForCall();
                  if (!_peerConnections.containsKey(pUserId)) {
                    // The joining user always initiates the offer to already-joined participants.
                    // Using userId > pUserId tiebreaker only to prevent double-offer when
                    // BOTH users see each other as 'joined' in the same stream snapshot.
                    // This is safe because the callee always joins after the host.
                    final isCallee = _currentCall?.hostId != userId;
                    final shouldOffer = isCallee || userId.compareTo(pUserId) > 0;
                    if (shouldOffer) {
                      await _initiatePeerConnection(pUserId);
                    }
                  }
                } else if (status == 'rejected' || status == 'left') {
                  _removePeer(pUserId);
                }
              }
            }
          }
          
          // Stop ringtone if we are joined and there are other active participants
          if (data.any((p) => p['user_id'] != userId && p['status'] == 'joined')) {
            _stopRingtone();
          }
        });
  }

  Future<void> _initiatePeerConnection(String remoteUserId) async {
    final hasVideo = _localStream?.getVideoTracks().isNotEmpty ?? false;
    final pc = await _createPeerConnection(remoteUserId, hasVideo ? CallType.video : CallType.voice);
    
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    
    _sendEncryptedSignaling(remoteUserId, {
      'type': 'offer',
      'sdp': offer.sdp,
      'sdp_type': offer.type,
    });
  }

  void _removePeer(String userId) {
    _peerConnections[userId]?.close();
    _peerConnections.remove(userId);
    _remoteStreams.remove(userId);
    _candidateQueue.remove(userId);
    notifyListeners();
  }

  // Media Controls
  void toggleMute() {
    if (_localStream == null) return;
    _isMuted = !_isMuted;
    _localStream!.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
    _updateParticipantMediaState();
    notifyListeners();
  }

  Future<void> toggleVideo() async {
    if (_localStream == null) return;

    if (!_isVideoOn && _localStream!.getVideoTracks().isEmpty) {
      // If we're turning video ON but don't have a track (started as voice call)
      try {
        final Map<String, dynamic> constraints = {
          'audio': false, // Only need video
          'video': {'facingMode': 'user'},
        };
        final videoStream = await navigator.mediaDevices.getUserMedia(constraints);
        final videoTrack = videoStream.getVideoTracks().first;
        
        _localStream!.addTrack(videoTrack);
        _isVideoOn = true;
        
        // Update tracks for all peer connections
        for (var entry in _peerConnections.entries) {
          final remoteUserId = entry.key;
          final pc = entry.value;
          final senders = await pc.getSenders();
          
          bool foundVideoSender = false;
          for (var sender in senders) {
            if (sender.track?.kind == 'video') {
              await sender.replaceTrack(videoTrack);
              foundVideoSender = true;
              break;
            }
          }

          if (!foundVideoSender) {
            // If no video sender exists, add the track and renegotiate
            await pc.addTrack(videoTrack, _localStream!);
            await _renegotiate(remoteUserId);
          }
        }
      } catch (e) {
        debugPrint('[CallService] Error acquiring video track: $e');
        return;
      }
    } else {
      _isVideoOn = !_isVideoOn;
      _localStream!.getVideoTracks().forEach((track) {
        track.enabled = _isVideoOn;
      });
    }
    
    _updateParticipantMediaState();
    notifyListeners();
  }

  Future<void> _renegotiate(String remoteUserId) async {
    final pc = _peerConnections[remoteUserId];
    if (pc == null) return;
    
    try {
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      
      _sendEncryptedSignaling(remoteUserId, {
        'type': 'offer',
        'sdp': offer.sdp,
        'sdp_type': offer.type,
      });
    } catch (e) {
      debugPrint('[CallService] Renegotiation error for $remoteUserId: $e');
    }
  }

  Future<void> toggleScreenShare() async {
    if (_isScreenSharing) {
      // Switch back to camera
      await _localStream?.dispose();
      await initLocalStream(_isVideoOn);
      // Update tracks for all peer connections
      for (var pc in _peerConnections.values) {
        final senders = await pc.getSenders();
        for (var sender in senders) {
          if (sender.track?.kind == 'video') {
            sender.replaceTrack(_localStream!.getVideoTracks().first);
          } else if (sender.track?.kind == 'audio') {
            sender.replaceTrack(_localStream!.getAudioTracks().first);
          }
        }
      }
      _isScreenSharing = false;
    } else {
      try {
        final MediaStream screenStream = await navigator.mediaDevices.getDisplayMedia({
          'video': true,
          'audio': true,
        });
        
        // Replace tracks in all peer connections
        for (var pc in _peerConnections.values) {
          final senders = await pc.getSenders();
          final screenVideoTrack = screenStream.getVideoTracks().first;
          for (var sender in senders) {
            if (sender.track?.kind == 'video') {
              sender.replaceTrack(screenVideoTrack);
            }
          }
        }
        
        // Update local display if needed (maybe keep local camera preview separate?)
        // For simplicity, replace local stream's video track
        _isScreenSharing = true;
      } catch (e) {
        debugPrint('Error starting screen share: $e');
      }
    }
    _updateParticipantMediaState();
    notifyListeners();
  }

  Future<void> _updateParticipantMediaState() async {
    if (_currentCallId == null) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('call_participants')
        .update({
          'is_muted': _isMuted,
          'is_video_on': _isVideoOn,
          'is_screen_sharing': _isScreenSharing,
        })
        .match({'call_id': _currentCallId!, 'user_id': userId});
  }

  Future<void> endCall() async {
    if (_currentCallId == null) return;
    
    final callId = _currentCallId!;
    _cleanup(); // Clear local state immediately to avoid races

    await _supabase
        .from('call_participants')
        .update({
          'status': 'left',
          'left_at': DateTime.now().toIso8601String(),
        })
        .match({'call_id': callId, 'user_id': _supabase.auth.currentUser!.id});
  }

  void _cleanup() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    for (var pc in _peerConnections.values) {
      pc.close();
    }
    _peerConnections.clear();
    _remoteStreams.clear();
    _candidateQueue.clear();
    _currentCallId = null;
    _incomingCall = null; // Clear incoming call as well
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
        .from('call_participants')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .handleError((error) {
          debugPrint('[CallService] Incoming call stream error: $error');
        })
        .listen((data) async {
      final now = DateTime.now();
      for (var participant in data) {
        if (participant['status'] == 'invited') {
          final callId = participant['call_id'];
          final createdAt = DateTime.parse(participant['created_at'] as String);
          
          // Skip if call invite is older than 5 minutes (stale)
          if (now.difference(createdAt).inMinutes > 5) {
            debugPrint('[CallService] Ignoring stale call invite: $callId (Created at: $createdAt)');
            // Clean up stale invite in DB so it doesn't trigger again
            _supabase
                .from('call_participants')
                .update({'status': 'missed'})
                .match({'call_id': callId, 'user_id': user.id})
                .then((_) => debugPrint('[CallService] Marked stale call as missed: $callId'))
                .catchError((e) => debugPrint('[CallService] Error marking stale call: $e'));
            continue;
          }

          // Fetch call details
          try {
            final callData = await _supabase
                .from('calls')
                .select()
                .eq('id', callId)
                .single();
            
            final call = CallEntity.fromJson(callData);
            
            // Only show UI if call is still in pinging status
            if (call.status == CallStatus.pinging) {
              _incomingCall = call;
              _playRingtone(); // Start ringing for invitee
              notifyListeners();
              return;
            } else {
              debugPrint('[CallService] Ignoring call $callId with status: ${call.status}');
              // If call ended or was cancelled, mark as missed
              _supabase
                  .from('call_participants')
                  .update({'status': 'missed'})
                  .match({'call_id': callId, 'user_id': user.id})
                  .then((_) => debugPrint('[CallService] Marked inactive call as missed: $callId'))
                  .catchError((e) => debugPrint('[CallService] Error marking inactive call: $e'));
            }
          } catch (e) {
            debugPrint('Error fetching incoming call details: $e');
          }
        }
      }
      if (_incomingCall != null) {
        _incomingCall = null;
        _stopRingtone();
        notifyListeners();
      }
    });
  }

  Future<void> answerCall(CallEntity call) async {
    _stopRingtone();
    await joinCall(call);
    _incomingCall = null;
    notifyListeners();
  }

  Future<void> rejectCall(CallEntity call) async {
    _stopRingtone();
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('call_participants')
        .update({'status': 'rejected'})
        .match({'call_id': call.id, 'user_id': user.id});
    
    _incomingCall = null;
    notifyListeners();
  }

  Future<void> _setAudioForCall() async {
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          usageType: AndroidUsageType.voiceCommunication,
          contentType: AndroidContentType.speech,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: {
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      ));
    } catch (e) {
      debugPrint('[CallService] Error setting audio context: $e');
    }
  }

  Future<void> _playRingtone() async {
    if (_isPlayingRingtone) return;
    _isPlayingRingtone = true;
    try {
      // Set audio context for calling
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          usageType: AndroidUsageType.voiceCommunicationSignalling,
          contentType: AndroidContentType.music,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: {
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      ));

      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/standardringtone.mp3'));
    } catch (e) {
      _isPlayingRingtone = false;
      debugPrint('[CallService] Error playing ringtone: $e');
    }
  }

  Future<void> _stopRingtone() async {
    _isPlayingRingtone = false;
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('[CallService] Error stopping ringtone: $e');
    }
  }

  /// Public access to control ringtone from provider if needed
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
