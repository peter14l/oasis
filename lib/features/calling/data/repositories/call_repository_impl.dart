import 'dart:async';
import 'package:oasis_v2/core/network/supabase_client.dart';
import '../../domain/models/call_entity.dart';
import '../../domain/models/call_participant_entity.dart';
import '../../domain/repositories/call_repository.dart';

/// Implementation of CallRepository using Supabase
class CallRepositoryImpl implements CallRepository {
  SupabaseService get _supabase => SupabaseService();

  @override
  Future<CallEntity> createCall({
    required String conversationId,
    required String hostId,
    required CallType type,
  }) async {
    final now = DateTime.now();
    final channelName = 'call_${now.millisecondsSinceEpoch}';

    final response =
        await _supabase.client
            .from('calls')
            .insert({
              'conversation_id': conversationId,
              'host_id': hostId,
              'channel_name': channelName,
              'type': type.name,
              'status': CallStatus.pinging.name,
              'started_at': now.toIso8601String(),
              'created_at': now.toIso8601String(),
            })
            .select()
            .single();

    return CallEntity.fromJson(response);
  }

  @override
  Future<CallEntity?> getCall(String callId) async {
    final response =
        await _supabase.client
            .from('calls')
            .select()
            .eq('id', callId)
            .maybeSingle();

    if (response == null) return null;
    return CallEntity.fromJson(response);
  }

  @override
  Future<List<CallEntity>> getActiveCalls(String userId) async {
    // Get calls where user is host or participant
    final response = await _supabase.client
        .from('calls')
        .select()
        .or('host_id.eq.$userId,status.eq.${CallStatus.active.name}')
        .order('created_at', ascending: false);

    return response.map((json) => CallEntity.fromJson(json)).toList();
  }

  @override
  Future<CallEntity> acceptCall(String callId, String userId) async {
    final response =
        await _supabase.client
            .from('calls')
            .update({'status': CallStatus.active.name})
            .eq('id', callId)
            .select()
            .single();

    // Update participant status
    await _supabase.client
        .from('call_participants')
        .update({
          'status': 'joined',
          'joined_at': DateTime.now().toIso8601String(),
        })
        .eq('call_id', callId)
        .eq('user_id', userId);

    return CallEntity.fromJson(response);
  }

  @override
  Future<void> declineCall(String callId, String userId) async {
    await _supabase.client
        .from('call_participants')
        .update({'status': 'declined'})
        .eq('call_id', callId)
        .eq('user_id', userId);
  }

  @override
  Future<CallEntity> endCall(String callId) async {
    final response =
        await _supabase.client
            .from('calls')
            .update({
              'status': CallStatus.ended.name,
              'ended_at': DateTime.now().toIso8601String(),
            })
            .eq('id', callId)
            .select()
            .single();

    return CallEntity.fromJson(response);
  }

  @override
  Future<List<CallParticipantEntity>> getCallParticipants(String callId) async {
    final response = await _supabase.client
        .from('call_participants')
        .select()
        .eq('call_id', callId);

    return response
        .map((json) => CallParticipantEntity.fromJson(json))
        .toList();
  }

  @override
  Future<CallParticipantEntity> addParticipant({
    required String callId,
    required String userId,
  }) async {
    final now = DateTime.now();
    final response =
        await _supabase.client
            .from('call_participants')
            .insert({
              'call_id': callId,
              'user_id': userId,
              'status': 'invited',
              'created_at': now.toIso8601String(),
            })
            .select()
            .single();

    return CallParticipantEntity.fromJson(response);
  }

  @override
  Future<CallParticipantEntity> updateParticipant({
    required String participantId,
    bool? isMuted,
    bool? isVideoOn,
    bool? isScreenSharing,
    String? status,
  }) async {
    final updates = <String, dynamic>{};
    if (isMuted != null) updates['is_muted'] = isMuted;
    if (isVideoOn != null) updates['is_video_on'] = isVideoOn;
    if (isScreenSharing != null) updates['is_screen_sharing'] = isScreenSharing;
    if (status != null) {
      updates['status'] = status;
      if (status == 'joined') {
        updates['joined_at'] = DateTime.now().toIso8601String();
      } else if (status == 'left') {
        updates['left_at'] = DateTime.now().toIso8601String();
      }
    }

    final response =
        await _supabase.client
            .from('call_participants')
            .update(updates)
            .eq('id', participantId)
            .select()
            .single();

    return CallParticipantEntity.fromJson(response);
  }

  @override
  Future<String> getCallToken(String callId, String userId) async {
    // Call Agora/RTC token generation service
    // This would call a cloud function
    return '';
  }

  @override
  Stream<CallEntity> watchCall(String callId) {
    // Real-time call updates would use Supabase realtime
    return const Stream.empty();
  }

  @override
  Stream<List<CallParticipantEntity>> watchParticipants(String callId) {
    // Real-time participant updates would use Supabase realtime
    return const Stream.empty();
  }
}
