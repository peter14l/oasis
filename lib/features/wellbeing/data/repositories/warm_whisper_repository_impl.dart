import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/features/wellbeing/domain/models/warm_whisper.dart';
import 'package:oasis/features/wellbeing/domain/repositories/warm_whisper_repository.dart';

class WarmWhisperRepositoryImpl implements WarmWhisperRepository {
  final SupabaseClient _supabase;

  WarmWhisperRepositoryImpl({SupabaseClient? client})
      : _supabase = client ?? SupabaseService().client;

  @override
  Future<void> sendWhisper({
    required String recipientId,
    String? message,
    bool isAnonymous = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final remaining = await getRemainingWhisperCount();
      if (remaining <= 0) {
        throw Exception('Daily whisper limit reached (max 3 per day)');
      }

      await _supabase.from('warm_whispers').insert({
        'sender_id': userId,
        'recipient_id': recipientId,
        'message': message,
        'is_anonymous': isAnonymous,
      });
    } catch (e) {
      debugPrint('WarmWhisperRepositoryImpl: Error sending whisper: $e');
      rethrow;
    }
  }

  @override
  Future<List<WarmWhisper>> getReceivedWhispers() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('warm_whispers')
          .select('*, profiles:sender_id(*)')
          .eq('recipient_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => WarmWhisper.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('WarmWhisperRepositoryImpl: Error getting received whispers: $e');
      return [];
    }
  }

  @override
  Future<List<WarmWhisper>> getSentWhispers() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('warm_whispers')
          .select('*, profiles:recipient_id(*)')
          .eq('sender_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => WarmWhisper.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('WarmWhisperRepositoryImpl: Error getting sent whispers: $e');
      return [];
    }
  }

  @override
  Future<void> markAsRevealed(String whisperId) async {
    try {
      await _supabase
          .from('warm_whispers')
          .update({'revealed_at': DateTime.now().toIso8601String()})
          .eq('id', whisperId);
    } catch (e) {
      debugPrint('WarmWhisperRepositoryImpl: Error marking whisper as revealed: $e');
      rethrow;
    }
  }

  @override
  Future<int> getRemainingWhisperCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final startOfDay = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );

      final response = await _supabase
          .from('warm_whispers')
          .select('id')
          .eq('sender_id', userId)
          .gte('created_at', startOfDay.toIso8601String());

      final count = response.length;
      return (3 - count).toInt().clamp(0, 3);
    } catch (e) {
      debugPrint('WarmWhisperRepositoryImpl: Error getting whisper count: $e');
      return 0;
    }
  }
}
