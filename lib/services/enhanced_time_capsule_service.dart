import 'package:flutter/foundation.dart';
import 'package:oasis_v2/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

/// Enhanced time capsule model with collaborative and location features
/// This is a standalone model that doesn't extend TimeCapsule to avoid
/// constructor parameter mismatches
class EnhancedTimeCapsule {
  final String id;
  final String userId;
  final String? username;
  final String? userAvatar;
  final String content;
  final List<String> imageUrls;
  final DateTime unlockAt;
  final bool isUnlocked;
  final DateTime createdAt;
  final bool isCollaborative;
  final List<String> contributorIds;
  final String? locationTrigger; // JSON encoded lat/lng
  final double? locationRadius; // meters
  final String? musicUrl;
  final String? musicTitle;
  final List<CapsuleContribution>? contributions;

  EnhancedTimeCapsule({
    required this.id,
    required this.userId,
    this.username,
    this.userAvatar,
    required this.content,
    this.imageUrls = const [],
    required this.unlockAt,
    this.isUnlocked = false,
    required this.createdAt,
    this.isCollaborative = false,
    this.contributorIds = const [],
    this.locationTrigger,
    this.locationRadius,
    this.musicUrl,
    this.musicTitle,
    this.contributions,
  });

  factory EnhancedTimeCapsule.fromJson(Map<String, dynamic> json) {
    return EnhancedTimeCapsule(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'],
      userAvatar: json['user_avatar'],
      content: json['content'] ?? '',
      imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? [],
      unlockAt: DateTime.parse(json['unlock_at']),
      isUnlocked: json['is_unlocked'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      isCollaborative: json['is_collaborative'] ?? false,
      contributorIds: (json['contributor_ids'] as List?)?.cast<String>() ?? [],
      locationTrigger: json['location_trigger'],
      locationRadius: (json['location_radius'] as num?)?.toDouble(),
      musicUrl: json['music_url'],
      musicTitle: json['music_title'],
      contributions:
          (json['contributions'] as List?)
              ?.map((c) => CapsuleContribution.fromJson(c))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'user_avatar': userAvatar,
      'content': content,
      'image_urls': imageUrls,
      'unlock_at': unlockAt.toIso8601String(),
      'is_unlocked': isUnlocked,
      'created_at': createdAt.toIso8601String(),
      'is_collaborative': isCollaborative,
      'contributor_ids': contributorIds,
      'location_trigger': locationTrigger,
      'location_radius': locationRadius,
      'music_url': musicUrl,
      'music_title': musicTitle,
    };
  }

  bool get hasLocationTrigger => locationTrigger != null;
  bool get hasMusic => musicUrl != null && musicUrl!.isNotEmpty;

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(unlockAt)) return Duration.zero;
    return unlockAt.difference(now);
  }
}

class CapsuleContribution {
  final String id;
  final String capsuleId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;

  CapsuleContribution({
    required this.id,
    required this.capsuleId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    this.imageUrls = const [],
    required this.createdAt,
  });

  factory CapsuleContribution.fromJson(Map<String, dynamic> json) {
    return CapsuleContribution(
      id: json['id'],
      capsuleId: json['capsule_id'],
      userId: json['user_id'],
      username: json['username'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
      content: json['content'] ?? '',
      imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capsule_id': capsuleId,
      'user_id': userId,
      'content': content,
      'image_urls': imageUrls,
    };
  }
}

/// Enhanced time capsule service with collaborative and location features
class EnhancedTimeCapsuleService {
  final _supabase = SupabaseService().client;
  final _uuid = const Uuid();

  /// Create a collaborative time capsule
  Future<EnhancedTimeCapsule> createCollaborativeCapsule({
    required String userId,
    required String content,
    required DateTime unlockAt,
    required List<String> contributorIds,
    List<String>? imageUrls,
    String? locationTrigger,
    double? locationRadius,
    String? musicUrl,
    String? musicTitle,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      final isPro = user?.userMetadata?['is_pro'] == true;

      if (!isPro) {
        if (contributorIds.isNotEmpty) {
          throw Exception(
            'Upgrade to Oasis Pro to invite contributors to time capsules.',
          );
        }
        if (locationTrigger != null) {
          throw Exception(
            'Upgrade to Oasis Pro to create location-triggered time capsules.',
          );
        }
        if (musicUrl != null) {
          throw Exception(
            'Upgrade to Oasis Pro to add music to time capsules.',
          );
        }

        final activeCapsulesResponse = await _supabase
            .from('time_capsules')
            .select('id')
            .eq('user_id', userId)
            .eq('is_unlocked', false);

        if (activeCapsulesResponse.length >= 3) {
          throw Exception(
            'Free tier is limited to 3 active time capsules. Upgrade to Oasis Pro for unlimited capsules.',
          );
        }
      }

      final capsuleId = _uuid.v4();

      final capsuleData = {
        'id': capsuleId,
        'user_id': userId,
        'content': content,
        'image_urls': imageUrls ?? [],
        'unlock_at': unlockAt.toIso8601String(),
        'is_unlocked': false,
        'is_collaborative': true,
        'contributor_ids': [userId, ...contributorIds],
        'location_trigger': locationTrigger,
        'location_radius': locationRadius,
        'music_url': musicUrl,
        'music_title': musicTitle,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('time_capsules').insert(capsuleData);

      // Notify contributors
      for (final contributorId in contributorIds) {
        await _supabase.from('notifications').insert({
          'user_id': contributorId,
          'type': 'capsule_invite',
          'title': 'Time Capsule Invitation',
          'body': "You've been invited to contribute to a time capsule!",
          'data': {'capsule_id': capsuleId},
        });
      }

      return EnhancedTimeCapsule.fromJson(capsuleData);
    } catch (e) {
      debugPrint('Error creating collaborative capsule: $e');
      rethrow;
    }
  }

  /// Add contribution to a collaborative capsule
  Future<CapsuleContribution> addContribution({
    required String capsuleId,
    required String userId,
    required String content,
    List<String>? imageUrls,
  }) async {
    try {
      final contributionId = _uuid.v4();

      final data = {
        'id': contributionId,
        'capsule_id': capsuleId,
        'user_id': userId,
        'content': content,
        'image_urls': imageUrls ?? [],
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('capsule_contributions').insert(data);

      // Get user info
      final userResponse =
          await _supabase
              .from('profiles')
              .select('username, avatar_url')
              .eq('id', userId)
              .single();

      return CapsuleContribution(
        id: contributionId,
        capsuleId: capsuleId,
        userId: userId,
        username: userResponse['username'] ?? 'Unknown',
        avatarUrl: userResponse['avatar_url'],
        content: content,
        imageUrls: imageUrls ?? [],
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error adding contribution: $e');
      rethrow;
    }
  }

  /// Check if location trigger is satisfied
  bool isLocationSatisfied(
    EnhancedTimeCapsule capsule,
    double currentLat,
    double currentLng,
  ) {
    if (!capsule.hasLocationTrigger) return true;
    if (capsule.locationRadius == null) return true;

    try {
      // Parse location trigger (expected format: "lat,lng")
      final parts = capsule.locationTrigger!.split(',');
      if (parts.length != 2) return true;

      final targetLat = double.parse(parts[0]);
      final targetLng = double.parse(parts[1]);

      // Calculate distance (simple Haversine approximation)
      final distance = _calculateDistance(
        currentLat,
        currentLng,
        targetLat,
        targetLng,
      );

      return distance <= capsule.locationRadius!;
    } catch (e) {
      debugPrint('Error checking location: $e');
      return true;
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Pi / 180
    final a =
        0.5 -
        _cos((lat2 - lat1) * p) / 2 +
        _cos(lat1 * p) * _cos(lat2 * p) * (1 - _cos((lon2 - lon1) * p)) / 2;
    return 12742000 * _asin(_sqrt(a)); // 2 * R * 1000; R = 6371 km
  }

  // Math helpers
  double _cos(double x) =>
      x >= 0 ? (1 - x * x / 2) : -(1 - x * x / 2); // Simplified
  double _asin(double x) => x; // Simplified for small angles
  double _sqrt(double x) =>
      x >= 0 ? x * (1.5 - 0.5 * x) : 0; // Newton approximation

  /// Get capsules where user can contribute
  Future<List<EnhancedTimeCapsule>> getContributableCapsules(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('time_capsules')
          .select()
          .eq('is_collaborative', true)
          .contains('contributor_ids', [userId])
          .eq('is_unlocked', false)
          .order('unlock_at', ascending: true);

      return response
          .map<EnhancedTimeCapsule>((c) => EnhancedTimeCapsule.fromJson(c))
          .toList();
    } catch (e) {
      debugPrint('Error getting contributable capsules: $e');
      return [];
    }
  }

  /// Get contributions for a capsule
  Future<List<CapsuleContribution>> getContributions(String capsuleId) async {
    try {
      final response = await _supabase
          .from('capsule_contributions')
          .select('''
            *,
            profiles (username, avatar_url)
          ''')
          .eq('capsule_id', capsuleId)
          .order('created_at', ascending: true);

      return response.map<CapsuleContribution>((c) {
        final profile = c['profiles'];
        return CapsuleContribution(
          id: c['id'],
          capsuleId: c['capsule_id'],
          userId: c['user_id'],
          username: profile?['username'] ?? 'Unknown',
          avatarUrl: profile?['avatar_url'],
          content: c['content'] ?? '',
          imageUrls: (c['image_urls'] as List?)?.cast<String>() ?? [],
          createdAt: DateTime.parse(c['created_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting contributions: $e');
      return [];
    }
  }
}
