import 'package:flutter/foundation.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:uuid/uuid.dart';
import 'package:oasis/features/badging/domain/models/trust_badge.dart';

class BadgeService {
  final _supabase = SupabaseService().client;
  final _uuid = const Uuid();

  /// Get all available badges
  Future<List<TrustBadge>> getBadges() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.trustBadgesTable)
          .select()
          .order('name');

      if (response.isEmpty) return [];

      return response
          .map((json) => TrustBadge.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      return [];
    }
  }

  /// Get badge by ID
  Future<TrustBadge?> getBadge(String badgeId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.trustBadgesTable)
          .select()
          .eq('id', badgeId)
          .maybeSingle();

      if (response == null) return null;
      return TrustBadge.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching badge: $e');
      return null;
    }
  }

  /// Get user's earned badges
  Future<List<TrustBadge>> getUserBadges(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.userBadgesTable)
          .select('''
            ${SupabaseConfig.trustBadgesTable}:badge_id (
              id,
              name,
              description,
              icon,
              criteria
            )
          ''')
          .eq('user_id', userId);

      if (response.isEmpty) return [];

      final List<TrustBadge> badges = [];
      for (final item in response) {
        final badgeData = item[SupabaseConfig.trustBadgesTable];
        if (badgeData != null) {
          badges.add(TrustBadge.fromJson(badgeData));
        }
      }

      return badges;
    } catch (e) {
      debugPrint('Error fetching user badges: $e');
      return [];
    }
  }

  /// Check if user has a specific badge
  Future<bool> hasBadge(String userId, String badgeId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.userBadgesTable)
          .select()
          .eq('user_id', userId)
          .eq('badge_id', badgeId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking badge: $e');
      return false;
    }
  }

  /// Award a badge to a user
  Future<bool> awardBadge(String userId, String badgeId) async {
    try {
      // Check if user already has this badge
      final hasAlready = await hasBadge(userId, badgeId);
      if (hasAlready) return true;

      await _supabase.from(SupabaseConfig.userBadgesTable).insert({
        'id': _uuid.v4(),
        'user_id': userId,
        'badge_id': badgeId,
      });

      return true;
    } catch (e) {
      debugPrint('Error awarding badge: $e');
      return false;
    }
  }

  /// Check eligibility and award badges for a user
  Future<List<String>> checkBadgeEligibility(String userId) async {
    final awardedBadges = <String>[];

    try {
      // Check Safe Space badge - created a circle (community)
      final communities = await _supabase
          .from(SupabaseConfig.communitiesTable)
          .select('id')
          .eq('creator_id', userId)
          .maybeSingle();

      if (communities != null) {
        final awarded = await awardBadge(userId, 'safeSpace');
        if (awarded) awardedBadges.add('safeSpace');
      }

      // Check Shield badge - verified reports
      final reports = await _supabase
          .from('moderation_reports')
          .select('id')
          .eq('reporter_id', userId)
          .eq('verified', true);

      if (reports.isNotEmpty) {
        final awarded = await awardBadge(userId, 'shield');
        if (awarded) awardedBadges.add('shield');
      }

      // Check Welcomer badge - helped 10+ new members
      final welcomers = await _supabase
          .from('new_member_helps')
          .select('id')
          .eq('helper_id', userId)
          .count();

      if (welcomers != null && welcomers.count >= 10) {
        final awarded = await awardBadge(userId, 'welcomer');
        if (awarded) awardedBadges.add('welcomer');
      }

      // Check Privacy Guard badge - all privacy features enabled
      final privacySettings = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('privacy_settings')
          .eq('id', userId)
          .maybeSingle();

      if (privacySettings != null) {
        final settings = privacySettings['privacy_settings'] as Map<String, dynamic>?;
        if (settings != null) {
          final enabledCount = settings.values.where((v) => v == true).length;
          if (enabledCount >= 5) {
            final awarded = await awardBadge(userId, 'privacyGuard');
            if (awarded) awardedBadges.add('privacyGuard');
          }
        }
      }

      return awardedBadges;
    } catch (e) {
      debugPrint('Error checking badge eligibility: $e');
      return awardedBadges;
    }
  }

  /// Initialize default badges in database
  Future<void> initializeBadges() async {
    try {
      final defaultBadges = [
        {
          'id': 'safeSpace',
          'name': 'Safe Space',
          'description': 'Created a trusted community space',
          'icon': '🌿',
          'criteria': {'action': 'created_circle', 'count': 1},
        },
        {
          'id': 'shield',
          'name': 'Shield',
          'description': 'Helped keep the community safe',
          'icon': '🛡️',
          'criteria': {'action': 'verified_report', 'count': 1},
        },
        {
          'id': 'welcomer',
          'name': 'Welcomer',
          'description': 'Welcomed and helped new members',
          'icon': '🌟',
          'criteria': {'action': 'helped_new_members', 'count': 10},
        },
        {
          'id': 'calmCreator',
          'name': 'Calm Creator',
          'description': 'Maintained a positive presence',
          'icon': '💚',
          'criteria': {'action': 'no_violations', 'months': 6},
        },
        {
          'id': 'privacyGuard',
          'name': 'Privacy Guard',
          'description': 'Enabled all privacy features',
          'icon': '🔒',
          'criteria': {'action': 'privacy_features_enabled', 'count': 5},
        },
      ];

      for (final badge in defaultBadges) {
        await _supabase.from(SupabaseConfig.trustBadgesTable).upsert(badge);
      }
    } catch (e) {
      debugPrint('Error initializing badges: $e');
    }
  }
}