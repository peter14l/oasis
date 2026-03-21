import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/config/supabase_config.dart';
import 'package:oasis_v2/models/user_profile.dart';
import 'package:oasis_v2/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ProfileService {
  final _supabase = SupabaseService().client;
  final _uuid = const Uuid();

  /// Get user profile by ID
  Future<UserProfile> getProfile(String userId) async {
    try {
      final response =
          await _supabase
              .from(SupabaseConfig.profilesTable)
              .select()
              .eq('id', userId)
              .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      rethrow;
    }
  }

  /// Get user profile by username
  Future<UserProfile> getProfileByUsername(String username) async {
    try {
      final response =
          await _supabase
              .from(SupabaseConfig.profilesTable)
              .select()
              .eq('username', username)
              .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching profile by username: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<UserProfile> updateProfile({
    required String userId,
    String? username,
    String? fullName,
    String? bio,
    String? location,
    String? website,
    String? bannerColor,
    File? avatarFile,
    File? bannerFile,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      final isPro = user?.userMetadata?['is_pro'] == true;
      if (!isPro && bannerColor != null) {
        throw Exception(
          'Upgrade to Morrow Pro to use custom banner colors and themes.',
        );
      }

      String? avatarUrl;
      String? bannerUrl;

      // Upload avatar if provided
      if (avatarFile != null) {
        try {
          final fileExt = avatarFile.path.split('.').last;
          final fileName = '${_uuid.v4()}.$fileExt';
          final fileBytes = await avatarFile.readAsBytes();

          await _supabase.storage
              .from(SupabaseConfig.profilePicturesBucket)
              .uploadBinary(
                '$userId/$fileName',
                fileBytes,
                fileOptions: FileOptions(
                  contentType: 'image/$fileExt',
                  upsert: true,
                ),
              );

          avatarUrl = _supabase.storage
              .from(SupabaseConfig.profilePicturesBucket)
              .getPublicUrl('$userId/$fileName');
        } catch (e) {
          debugPrint('Error uploading avatar: $e');
          throw Exception('Failed to upload avatar');
        }
      }

      // Upload banner if provided
      if (bannerFile != null) {
        try {
          final fileExt = bannerFile.path.split('.').last;
          final fileName = 'banner_${_uuid.v4()}.$fileExt';
          final fileBytes = await bannerFile.readAsBytes();

          await _supabase.storage
              .from(
                SupabaseConfig.profilePicturesBucket,
              ) // using same bucket for now
              .uploadBinary(
                '$userId/$fileName',
                fileBytes,
                fileOptions: FileOptions(
                  contentType: 'image/$fileExt',
                  upsert: true,
                ),
              );

          bannerUrl = _supabase.storage
              .from(SupabaseConfig.profilePicturesBucket)
              .getPublicUrl('$userId/$fileName');
        } catch (e) {
          debugPrint('Error uploading banner: $e');
          // Don't fail entire update if banner fails, just log it
        }
      }

      // Update profile
      final updateData = <String, dynamic>{};
      if (username != null) updateData['username'] = username;
      if (fullName != null) updateData['full_name'] = fullName;
      if (bio != null) updateData['bio'] = bio;
      if (location != null) updateData['location'] = location;
      if (website != null) updateData['website'] = website;
      if (bannerColor != null) updateData['banner_color'] = bannerColor;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (bannerUrl != null) updateData['banner_url'] = bannerUrl;

      await _supabase
          .from(SupabaseConfig.profilesTable)
          .update(updateData)
          .eq('id', userId);

      // Fetch updated profile
      return getProfile(userId);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (e is PostgrestException && e.code == '23505') {
        throw Exception('Username is already taken');
      }
      rethrow;
    }
  }

  /// Follow a user
  Future<void> followUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.followsTable).insert({
        'follower_id': followerId,
        'following_id': followingId,
      });
    } catch (e) {
      debugPrint('Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await _supabase
          .from(SupabaseConfig.followsTable)
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Check if user is following another user
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    try {
      final response =
          await _supabase
              .from(SupabaseConfig.followsTable)
              .select()
              .eq('follower_id', followerId)
              .eq('following_id', followingId)
              .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  /// Get user's followers
  Future<List<UserProfile>> getFollowers({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.followsTable)
          .select('''
            follower_id,
            ${SupabaseConfig.profilesTable}:follower_id (*)
          ''')
          .eq('following_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response.isEmpty) return [];

      final List<UserProfile> followers = [];
      for (final item in response) {
        final profileData = item[SupabaseConfig.profilesTable];
        if (profileData != null) {
          followers.add(UserProfile.fromJson(profileData));
        }
      }

      return followers;
    } catch (e) {
      debugPrint('Error fetching followers: $e');
      rethrow;
    }
  }

  /// Get users that the user is following
  Future<List<UserProfile>> getFollowing({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.followsTable)
          .select('''
            following_id,
            ${SupabaseConfig.profilesTable}:following_id (*)
          ''')
          .eq('follower_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response.isEmpty) return [];

      final List<UserProfile> following = [];
      for (final item in response) {
        final profileData = item[SupabaseConfig.profilesTable];
        if (profileData != null) {
          following.add(UserProfile.fromJson(profileData));
        }
      }

      return following;
    } catch (e) {
      debugPrint('Error fetching following: $e');
      rethrow;
    }
  }

  /// Search users by username or full name
  Future<List<UserProfile>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select()
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(limit);

      if (response.isEmpty) return [];

      return response
          .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      rethrow;
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacy({
    required String userId,
    required bool isPrivate,
  }) async {
    try {
      await _supabase
          .from(SupabaseConfig.profilesTable)
          .update({'is_private': isPrivate})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating privacy: $e');
      rethrow;
    }
  }
}
