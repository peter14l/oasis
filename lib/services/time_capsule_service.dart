import 'package:flutter/foundation.dart';
import 'package:oasis_v2/core/config/supabase_config.dart';
import 'package:oasis_v2/models/time_capsule.dart';
import 'package:oasis_v2/core/network/supabase_client.dart';
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

        if (activeCapsulesResponse.length >= 2) {
          throw Exception(
            'Free tier is limited to 2 active time capsules. Upgrade to Morrow Pro for unlimited capsules.',
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

  /// Get user's own capsules (visible only to the owner)
  Future<List<TimeCapsule>> getCapsules({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.timeCapsulesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response.isEmpty) return [];

      // Fetch profile for the current user
      final profileResponse = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('id, username, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      return (response as List).map((e) {
        final mergedData = Map<String, dynamic>.from(e);
        if (profileResponse != null) {
          mergedData[SupabaseConfig.profilesTable] = profileResponse;
        }
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
          .maybeSingle();

      return (response as List).map((e) {
        final mergedData = Map<String, dynamic>.from(e);
        if (profileResponse != null) {
          mergedData[SupabaseConfig.profilesTable] = profileResponse;
        }
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

  /// Get a single capsule by ID
  Future<TimeCapsule> getCapsule(String capsuleId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.timeCapsulesTable)
          .select()
          .eq('id', capsuleId)
          .single();

      // Fetch profile separately
      final profileResponse = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('username, avatar_url')
          .eq('id', response['user_id'])
          .single();

      final mergedData = Map<String, dynamic>.from(response);
      mergedData[SupabaseConfig.profilesTable] = profileResponse;

      return _transformResponse(mergedData);
    } catch (e) {
      debugPrint('Error getting capsule: $e');
      rethrow;
    }
  }

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
