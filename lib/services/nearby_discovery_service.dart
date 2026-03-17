import 'package:flutter/foundation.dart';
import 'package:oasis_v2/services/supabase_service.dart';
import 'dart:math' as math;

/// Nearby discovery service for finding users and events
class NearbyDiscoveryService {
  final _supabase = SupabaseService().client;

  /// Find nearby users within radius (in km)
  Future<List<NearbyUser>> findNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 50,
  }) async {
    final user = _supabase.auth.currentUser;
    final isPro = user?.userMetadata?['is_pro'] == true;
    if (!isPro && radiusKm > 10.0) {
      radiusKm = 10.0;
    }

    try {
      // Using PostGIS ST_DWithin for efficient distance queries
      // This requires a PostGIS extension in Supabase
      final response = await _supabase.rpc(
        'find_nearby_users',
        params: {
          'lat': latitude,
          'lng': longitude,
          'radius_km': radiusKm,
          'max_results': limit,
        },
      );

      if (response == null) return [];

      return (response as List)
          .map((u) => NearbyUser.fromJson(u as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error finding nearby users: $e');
      // Fallback to simple query
      return _findNearbyUsersFallback(latitude, longitude, radiusKm, limit);
    }
  }

  /// Fallback method without PostGIS
  Future<List<NearbyUser>> _findNearbyUsersFallback(
    double latitude,
    double longitude,
    double radiusKm,
    int limit,
  ) async {
    try {
      // Get users with location data
      final response = await _supabase
          .from('profiles')
          .select('id, username, avatar_url, bio, location_lat, location_lng')
          .not('location_lat', 'is', null)
          .not('location_lng', 'is', null)
          .limit(200);

      final users = <NearbyUser>[];
      for (final profile in response) {
        final userLat = profile['location_lat'] as double?;
        final userLng = profile['location_lng'] as double?;

        if (userLat == null || userLng == null) continue;

        final distance = _calculateDistance(
          latitude,
          longitude,
          userLat,
          userLng,
        );

        if (distance <= radiusKm) {
          users.add(
            NearbyUser(
              id: profile['id'],
              username: profile['username'] ?? 'Unknown',
              avatarUrl: profile['avatar_url'],
              bio: profile['bio'],
              distanceKm: distance,
              latitude: userLat,
              longitude: userLng,
            ),
          );
        }
      }

      // Sort by distance and limit
      users.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return users.take(limit).toList();
    } catch (e) {
      debugPrint('Error in fallback nearby users: $e');
      return [];
    }
  }

  /// Find nearby events
  Future<List<NearbyEvent>> findNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 20,
  }) async {
    final user = _supabase.auth.currentUser;
    final isPro = user?.userMetadata?['is_pro'] == true;
    if (!isPro) {
      throw Exception('Upgrade to Morrow Pro to access nearby events.');
    }
    try {
      final response = await _supabase
          .from('events')
          .select('''
            id, title, description, cover_image_url,
            location_name, location_lat, location_lng,
            start_time, end_time, host_id,
            profiles:host_id (username, avatar_url)
          ''')
          .gte('end_time', DateTime.now().toIso8601String())
          .not('location_lat', 'is', null)
          .limit(100);

      final events = <NearbyEvent>[];
      for (final event in response) {
        final eventLat = event['location_lat'] as double?;
        final eventLng = event['location_lng'] as double?;

        if (eventLat == null || eventLng == null) continue;

        final distance = _calculateDistance(
          latitude,
          longitude,
          eventLat,
          eventLng,
        );

        if (distance <= radiusKm) {
          final host = event['profiles'];
          events.add(
            NearbyEvent(
              id: event['id'],
              title: event['title'],
              description: event['description'],
              coverImageUrl: event['cover_image_url'],
              locationName: event['location_name'],
              latitude: eventLat,
              longitude: eventLng,
              distanceKm: distance,
              startTime: DateTime.parse(event['start_time']),
              endTime: DateTime.parse(event['end_time']),
              hostId: event['host_id'],
              hostUsername: host?['username'] ?? 'Unknown',
              hostAvatarUrl: host?['avatar_url'],
            ),
          );
        }
      }

      events.sort((a, b) => a.startTime.compareTo(b.startTime));
      return events.take(limit).toList();
    } catch (e) {
      debugPrint('Error finding nearby events: $e');
      return [];
    }
  }

  /// Update user's location
  Future<void> updateUserLocation(double latitude, double longitude) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('profiles')
          .update({
            'location_lat': latitude,
            'location_lng': longitude,
            'location_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double deg) => deg * math.pi / 180;
}

/// Nearby user model
class NearbyUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final List<String>? commonInterests;
  final int? mutualFollowers;

  NearbyUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    this.commonInterests,
    this.mutualFollowers,
  });

  factory NearbyUser.fromJson(Map<String, dynamic> json) {
    return NearbyUser(
      id: json['id'],
      username: json['username'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
      latitude: (json['location_lat'] ?? 0).toDouble(),
      longitude: (json['location_lng'] ?? 0).toDouble(),
      commonInterests: (json['common_interests'] as List?)?.cast<String>(),
      mutualFollowers: json['mutual_followers'],
    );
  }

  String get distanceText {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m away';
    }
    return '${distanceKm.toStringAsFixed(1)}km away';
  }
}

/// Nearby event model
class NearbyEvent {
  final String id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final String? locationName;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final DateTime startTime;
  final DateTime endTime;
  final String hostId;
  final String hostUsername;
  final String? hostAvatarUrl;
  final int? attendeeCount;

  NearbyEvent({
    required this.id,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.locationName,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.startTime,
    required this.endTime,
    required this.hostId,
    required this.hostUsername,
    this.hostAvatarUrl,
    this.attendeeCount,
  });

  String get distanceText {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m away';
    }
    return '${distanceKm.toStringAsFixed(1)}km away';
  }

  bool get isHappeningNow {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isUpcoming => DateTime.now().isBefore(startTime);
}
