import 'package:flutter/foundation.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'call.dart';
import 'call_repository.dart';

/// Supabase-backed [CallRepository] against the `call_sessions` table.
class SupabaseCallRepository implements CallRepository {
  final SupabaseClient? _clientOverride;

  SupabaseCallRepository({SupabaseClient? client}) : _clientOverride = client;

  SupabaseClient get _client => _clientOverride ?? SupabaseService().client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Call> createCall({
    required String conversationId,
    required String callerId,
    required String receiverId,
    required CallType type,
    required String roomName,
  }) async {
    final row = await _client
        .from('call_sessions')
        .insert({
          'conversation_id': conversationId,
          'caller_id': callerId,
          'receiver_id': receiverId,
          'status': CallStatus.ringing.name,
          'type': type.name,
          'room_name': roomName,
        })
        .select()
        .single();
    return Call.fromRow(row);
  }

  @override
  Future<Call?> getCall(String callId) async {
    final row = await _client
        .from('call_sessions')
        .select()
        .eq('id', callId)
        .maybeSingle();
    return row == null ? null : Call.fromRow(row);
  }

  @override
  Future<Call?> acceptCall(String callId) async {
    final row = await _client
        .from('call_sessions')
        .update({
          'status': CallStatus.active.name,
          'started_at': DateTime.now().toIso8601String(),
        })
        .eq('id', callId)
        .eq('status', CallStatus.ringing.name)
        .select()
        .maybeSingle();
    return row == null ? null : Call.fromRow(row);
  }

  @override
  Future<Call?> declineCall(String callId) async {
    final row = await _client
        .from('call_sessions')
        .update({'status': CallStatus.declined.name})
        .eq('id', callId)
        .eq('status', CallStatus.ringing.name)
        .select()
        .maybeSingle();
    return row == null ? null : Call.fromRow(row);
  }

  @override
  Future<Call?> markMissed(String callId) async {
    final row = await _client
        .from('call_sessions')
        .update({
          'status': CallStatus.missed.name,
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', callId)
        .eq('status', CallStatus.ringing.name)
        .select()
        .maybeSingle();
    return row == null ? null : Call.fromRow(row);
  }

  @override
  Future<Call?> endCall(String callId) async {
    final row = await _client
        .from('call_sessions')
        .update({
          'status': CallStatus.ended.name,
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', callId)
        .inFilter('status', [
          CallStatus.ringing.name,
          CallStatus.active.name,
        ])
        .select()
        .maybeSingle();
    return row == null ? null : Call.fromRow(row);
  }

  @override
  Stream<Call> watchCall(String callId) {
    return _client
        .from('call_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .handleError((error) {
          debugPrint('[CallRepository] watchCall error: $error');
        })
        .where((rows) => rows.isNotEmpty)
        .map((rows) => Call.fromRow(rows.first));
  }

  @override
  Stream<List<Call>> watchCallsFor(String userId) {
    return _client
        .from('call_sessions')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .handleError((error) {
          debugPrint('[CallRepository] watchCallsFor error: $error');
        })
        .map((rows) => rows.map(Call.fromRow).toList());
  }
}
