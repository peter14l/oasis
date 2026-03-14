import 'package:flutter/foundation.dart';
import 'package:morrow_v2/config/supabase_config.dart';
import 'package:morrow_v2/models/time_capsule.dart';
import 'package:morrow_v2/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class TimeCapsuleService {
  final _supabase = SupabaseService().client;
  final _uuid = const Uuid();

  /// Create a new time capsule
  Future<TimeCapsule> createCapsule({
    required String userId,
    required String content,
    required DateTime unlockDate,
    String? mediaUrl,
    String mediaType = 'none',
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      final isPro = user?.userMetadata?['is_pro'] == true;
      if (!isPro) {
        final activeCapsulesResponse = await _supabase
            .from(SupabaseConfig.timeCapsulesTable)
            .select('id')
            .eq('user_id', userId)
            .eq('is_locked', true);

        if (activeCapsulesResponse.length >= 3) {
          throw Exception(
            'Free tier is limited to 3 active time capsules. Upgrade to Morrow Pro for unlimited capsules.',
          );
        }
      }

      final capsuleId = _uuid.v4();

      final capsuleData = {
        'id': capsuleId,
        'user_id': userId,
        'content': content,
        'unlock_date': unlockDate.toIso8601String(),
        'media_url': mediaUrl,
        'media_type': mediaType,
        'is_locked': true, // Always locked initially
      };

      await _supabase
          .from(SupabaseConfig.timeCapsulesTable)
          .insert(capsuleData);

      // Fetch the created capsule
      final response =
          await _supabase
              .from(SupabaseConfig.timeCapsulesTable)
              .select()
              .eq('id', capsuleId)
              .single();

      // Fetch profile separately to avoid relationship error
      final profileResponse = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('username, avatar_url')
          .eq('id', userId)
          .single();

      final mergedData = Map<String, dynamic>.from(response);
      mergedData[SupabaseConfig.profilesTable] = profileResponse;

      return _transformResponse(mergedData);
    } catch (e) {
      debugPrint('Error creating time capsule: $e');
      rethrow;
    }
  }

  /// Get all capsules (feed)
  /// In a real app, this might be filtered by friends or public
  Future<List<TimeCapsule>> getCapsules({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.timeCapsulesTable)
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response.isEmpty) return [];

      // Fetch profiles for all capsules in the list
      final userIds = (response as List).map((e) => e['user_id']).toSet().toList();
      final profilesResponse = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('id, username, avatar_url')
          .inFilter('id', userIds);

      final profilesMap = {
        for (var p in profilesResponse) p['id']: p
      };

      return response.map((e) {
        final mergedData = Map<String, dynamic>.from(e);
        mergedData[SupabaseConfig.profilesTable] = profilesMap[e['user_id']];
        return _transformResponse(mergedData);
      }).toList();
    } catch (e) {
      debugPrint('Error getting capsules: $e');
      rethrow;
    }
  }

  /// Get ONLY unlocked capsules for a user (My Past Capsules)
  Future<List<TimeCapsule>> getMyUnlockedCapsules(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from(SupabaseConfig.timeCapsulesTable)
          .select()
          .eq('user_id', userId)
          .lte('unlock_date', now)
          .order('unlock_date', ascending: false);

      if (response.isEmpty) return [];

      // Fetch profile for the current user
      final profileResponse = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('username, avatar_url')
          .eq('id', userId)
          .single();

      return (response as List).map((e) {
        final mergedData = Map<String, dynamic>.from(e);
        mergedData[SupabaseConfig.profilesTable] = profileResponse;
        return _transformResponse(mergedData);
      }).toList();
    } catch (e) {
      debugPrint('Error getting unlocked capsules: $e');
      rethrow;
    }
  }

  /// Check and update lock status if needed
  /// Use this if we want to update the DB status,
  /// though strictly speaking we can compute isLocked on the fly from unlockDate.
  /// For this implementation, we'll mostly rely on DateTime comparison in the Model/UI.

  TimeCapsule _transformResponse(Map<String, dynamic> data) {
    final map = Map<String, dynamic>.from(data);
    final profile = map[SupabaseConfig.profilesTable];

    if (profile != null) {
      map['username'] = profile['username'];
      map['user_avatar'] = profile['avatar_url'];
    }

    // Recalculate is_locked based on server time or local time vs unlock_date?
    // Let's trust the data for now, but strictly:
    final unlockDate = DateTime.parse(map['unlock_date']);
    map['is_locked'] = DateTime.now().isBefore(unlockDate);

    return TimeCapsule.fromJson(map);
  }
}
