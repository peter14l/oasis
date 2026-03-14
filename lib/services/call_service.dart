import 'package:flutter/foundation.dart';
import 'package:morrow_v2/models/call.dart';
import 'package:morrow_v2/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class CallService extends ChangeNotifier {
  final _supabase = SupabaseService().client;
  final _uuid = const Uuid();

  Future<Call> initiateCall({
    required String conversationId,
    required CallType type,
    required String channelName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final callData = {
      'id': _uuid.v4(),
      'conversation_id': conversationId,
      'host_id': user.id,
      'channel_name': channelName,
      'type': type.name,
      'status': CallStatus.pinging.name,
      'started_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('calls')
        .insert(callData)
        .select()
        .single();

    return Call.fromJson(response);
  }

  Future<void> endCall(String callId) async {
    await _supabase
        .from('calls')
        .update({
          'status': CallStatus.ended.name,
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', callId);
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
