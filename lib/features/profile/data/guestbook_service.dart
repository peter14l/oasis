import 'package:flutter/foundation.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/features/profile/domain/models/guestbook_entry.dart';

class GuestbookService {
  final SupabaseService _supabaseService = SupabaseService();

  Future<List<GuestbookEntry>> getGuestbookEntries(String profileId) async {
    try {
      final response = await _supabaseService.client
          .from('guestbook_entries')
          .select('*, profiles(username, full_name, avatar_url)')
          .eq('profile_id', profileId)
          .order('created_at', ascending: false)
          .limit(20);
          
      return (response as List).map((json) => GuestbookEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[GuestbookService] Error fetching entries: $e');
      return [];
    }
  }

  Future<GuestbookEntry?> signGuestbook({
    required String profileId,
    required String visitorId,
    required String message,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('guestbook_entries')
          .insert({
            'profile_id': profileId,
            'visitor_id': visitorId,
            'message': message,
          })
          .select('*, profiles(username, full_name, avatar_url)')
          .single();
          
      return GuestbookEntry.fromJson(response);
    } catch (e) {
      debugPrint('[GuestbookService] Error signing guestbook: $e');
      return null;
    }
  }

  Future<void> removeEntry(String entryId) async {
    try {
      await _supabaseService.client
          .from('guestbook_entries')
          .delete()
          .eq('id', entryId);
    } catch (e) {
      debugPrint('[GuestbookService] Error removing entry: $e');
    }
  }
}
