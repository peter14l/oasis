import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:oasis/models/call.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:uuid/uuid.dart';

class CallService extends ChangeNotifier {
  final _supabase = SupabaseService().client;
  final _uuid = const Uuid();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String? _currentCallId;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  Future<void> initWebRTC(bool isVideo) async {
    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': isVideo ? {'facingMode': 'user'} : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    
    _peerConnection = await createPeerConnection(_configuration);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onIceCandidate = (candidate) {
      // Send candidate to Supabase
      _sendIceCandidate(candidate);
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        notifyListeners();
      }
    };
  }

  Future<Call> initiateCall({
    required String conversationId,
    required CallType type,
    required String channelName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await initWebRTC(type == CallType.video);

    final RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    final callData = {
      'id': _uuid.v4(),
      'conversation_id': conversationId,
      'host_id': user.id,
      'channel_name': channelName,
      'type': type.name,
      'status': CallStatus.pinging.name,
      'started_at': DateTime.now().toIso8601String(),
      'sdp': offer.sdp,
      'sdp_type': offer.type,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('calls')
        .insert(callData)
        .select()
        .single();
    
    _currentCallId = callData['id'];
    final call = Call.fromJson(response);
    _subscribeToSignaling(call.id);
    
    return call;
  }

  Future<void> answerCall(Call call) async {
    await initWebRTC(call.type == CallType.video);

    final RTCSessionDescription offer = RTCSessionDescription(call.sdp, call.sdpType);
    await _peerConnection!.setRemoteDescription(offer);

    final RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    
    _currentCallId = call.id;

    await _supabase
        .from('calls')
        .update({
          'sdp': answer.sdp,
          'sdp_type': answer.type,
          'status': CallStatus.active.name,
        })
        .eq('id', call.id);

    _subscribeToSignaling(call.id);
  }

  void _subscribeToSignaling(String callId) {
    _supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .listen((data) async {
          if (data.isEmpty) return;
          final updatedCall = Call.fromJson(data.first);

          if (updatedCall.status == CallStatus.active && 
              _peerConnection?.getRemoteDescription() == null &&
              updatedCall.sdpType == 'answer') {
            final RTCSessionDescription answer = RTCSessionDescription(
              updatedCall.sdp,
              updatedCall.sdpType,
            );
            await _peerConnection!.setRemoteDescription(answer);
          }

          if (updatedCall.status == CallStatus.ended) {
            _handleCallEnd();
          }
        }, onError: (error) {
          debugPrint('[CallService] Signaling stream error (calls): $error');
        });

    // Handle ICE candidates
    _supabase
        .from('call_signaling')
        .stream(primaryKey: ['id'])
        .eq('call_id', callId)
        .listen((data) async {
          for (var item in data) {
            final senderId = item['sender_id'];
            if (senderId != _supabase.auth.currentUser?.id) {
              final candidate = RTCIceCandidate(
                item['candidate'],
                item['sdpMid'],
                item['sdpMLineIndex'],
              );
              await _peerConnection!.addCandidate(candidate);
            }
          }
        }, onError: (error) {
          debugPrint('[CallService] Signaling stream error (ICE): $error');
        });
  }

  Future<void> _sendIceCandidate(RTCIceCandidate candidate) async {
    final user = _supabase.auth.currentUser;
    if (user == null || _peerConnection == null || _currentCallId == null) return;

    await _supabase.from('call_signaling').insert({
      'call_id': _currentCallId,
      'sender_id': user.id,
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  void _handleCallEnd() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _remoteStream?.getTracks().forEach((track) => track.stop());
    _peerConnection?.close();
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    _currentCallId = null;
    notifyListeners();
  }

  Future<void> endCall(String callId) async {
    await _supabase
        .from('calls')
        .update({
          'status': CallStatus.ended.name,
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', callId);
    _handleCallEnd();
  }

  Future<void> joinCall(String callId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase
        .from('call_participants')
        .upsert({
          'call_id': callId,
          'user_id': user.id,
          'joined_at': DateTime.now().toIso8601String(),
          'status': 'joined',
        });
  }
}
