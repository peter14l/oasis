import 'package:flutter/foundation.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/features/feed/domain/models/post.dart';

class AdService {
  final _supabase = SupabaseService().client;

  Future<List<Post>> getHouseAds() async {
    try {
      final response = await _supabase
          .from('house_ads')
          .select()
          .eq('is_active', true);

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        return Post(
          id: json['id'] as String,
          userId: 'oasis_system',
          username: 'Oasis Sponsored',
          userAvatar: 'https://oasis.app/logo.png',
          content: '${json['title'] as String}\n\n${json['body'] as String}',
          imageUrl: json['image_url'] as String?,
          timestamp: DateTime.parse(json['created_at'] as String),
          isAd: true,
        );
      }).toList();
    } catch (e) {
      debugPrint('[AdService] Error fetching house ads: $e');
      return [];
    }
  }
}
