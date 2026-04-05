import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/features/ripples/domain/models/ripple_entity.dart';

/// Remote data source for ripples - handles all Supabase API calls.
class RippleRemoteDatasource {
  final SupabaseClient _supabase;

  RippleRemoteDatasource({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseService().client;

  /// Fetches ripples from Supabase with profile data and like/save status.
  Future<List<RippleEntity>> getRipples() async {
    final userId = _supabase.auth.currentUser?.id;

    final response = await _supabase
        .from('ripples')
        .select('''
          *,
          profiles:user_id (
            username,
            avatar_url,
            is_private
          ),
          ripple_likes!left (
            user_id
          ),
          ripple_saves!left (
            user_id
          )
        ''')
        .or('is_private.eq.false,user_id.eq.$userId')
        .order('created_at', ascending: false);

    final ripplesData = List<Map<String, dynamic>>.from(response);

    // Process ripples to add is_liked and is_saved fields
    for (var ripple in ripplesData) {
      final likes = ripple['ripple_likes'] as List<dynamic>?;
      ripple['is_liked'] =
          likes != null && likes.any((l) => l['user_id'] == userId);
      ripple.remove('ripple_likes');

      final saves = ripple['ripple_saves'] as List<dynamic>?;
      ripple['is_saved'] =
          saves != null && saves.any((s) => s['user_id'] == userId);
      ripple.remove('ripple_saves');
    }

    return ripplesData.map((json) => RippleEntity.fromJson(json)).toList();
  }

  /// Creates a new ripple in Supabase.
  Future<RippleEntity> createRipple({
    required String userId,
    required String videoUrl,
    String? thumbnailUrl,
    String? caption,
    bool isPrivate = false,
  }) async {
    final data =
        await _supabase
            .from('ripples')
            .insert({
              'user_id': userId,
              'video_url': videoUrl,
              'thumbnail_url': thumbnailUrl,
              'caption': caption,
              'is_private': isPrivate,
            })
            .select()
            .single();

    return RippleEntity.fromJson(data);
  }

  /// Deletes a ripple by ID.
  Future<void> deleteRipple(String rippleId) async {
    await _supabase.from('ripples').delete().eq('id', rippleId);
  }

  /// Likes a ripple.
  Future<void> likeRipple(String rippleId, String userId) async {
    await _supabase.from('ripple_likes').upsert({
      'ripple_id': rippleId,
      'user_id': userId,
    });
  }

  /// Removes like from a ripple.
  Future<void> unlikeRipple(String rippleId, String userId) async {
    await _supabase.from('ripple_likes').delete().match({
      'ripple_id': rippleId,
      'user_id': userId,
    });
  }

  /// Saves a ripple.
  Future<void> saveRipple(String rippleId, String userId) async {
    await _supabase.from('ripple_saves').upsert({
      'ripple_id': rippleId,
      'user_id': userId,
    });
  }

  /// Removes a ripple from saved.
  Future<void> unsaveRipple(String rippleId, String userId) async {
    await _supabase.from('ripple_saves').delete().match({
      'ripple_id': rippleId,
      'user_id': userId,
    });
  }

  /// Comments on a ripple.
  Future<RippleCommentEntity> commentOnRipple({
    required String rippleId,
    required String userId,
    required String content,
  }) async {
    final data =
        await _supabase
            .from('ripple_comments')
            .insert({
              'ripple_id': rippleId,
              'user_id': userId,
              'content': content,
            })
            .select()
            .single();

    return RippleCommentEntity.fromJson(data);
  }

  /// Gets comments for a ripple.
  Future<List<RippleCommentEntity>> getComments(String rippleId) async {
    final response = await _supabase
        .from('ripple_comments')
        .select('*, profiles:user_id(username, avatar_url)')
        .eq('ripple_id', rippleId)
        .order('created_at', ascending: true);

    return response.map((json) => RippleCommentEntity.fromJson(json)).toList();
  }

  /// Gets a single ripple by ID.
  Future<RippleEntity?> getRippleById(String rippleId) async {
    final userId = _supabase.auth.currentUser?.id;

    final response =
        await _supabase
            .from('ripples')
            .select('''
          *,
          profiles:user_id (
            username,
            avatar_url,
            is_private
          ),
          ripple_likes!left (
            user_id
          ),
          ripple_saves!left (
            user_id
          )
        ''')
            .eq('id', rippleId)
            .maybeSingle();

    if (response == null) return null;

    final ripple = Map<String, dynamic>.from(response);
    final likes = ripple['ripple_likes'] as List<dynamic>?;
    ripple['is_liked'] =
        likes != null && likes.any((l) => l['user_id'] == userId);
    ripple.remove('ripple_likes');

    final saves = ripple['ripple_saves'] as List<dynamic>?;
    ripple['is_saved'] =
        saves != null && saves.any((s) => s['user_id'] == userId);
    ripple.remove('ripple_saves');

    return RippleEntity.fromJson(ripple);
  }
}
