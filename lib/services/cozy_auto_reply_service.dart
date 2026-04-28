import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/features/profile/domain/repositories/profile_repository.dart';
import 'package:oasis/features/profile/data/repositories/profile_repository_impl.dart';

/// Service to generate and send auto-reply messages when users are in Cozy Mode.
class CozyAutoReplyService {
  final SupabaseClient _supabase;
  final ProfileRepository _profileRepository;

  CozyAutoReplyService({
    SupabaseClient? client,
    ProfileRepository? profileRepository,
  })  : _supabase = client ?? SupabaseService().client,
        _profileRepository = profileRepository ?? ProfileRepositoryImpl();

  /// Check if recipient has cozy mode active and get their status.
  Future<CozyStatusInfo?> getRecipientCozyStatus(String recipientId) async {
    try {
      final profile = await _profileRepository.getProfile(recipientId);
      
      if (profile.cozyStatus == null || profile.cozyStatus!.isEmpty) {
        return null;
      }

      // Check if cozy status has expired
      if (profile.cozyUntil != null && profile.cozyUntil!.isBefore(DateTime.now())) {
        return null;
      }

      return CozyStatusInfo(
        status: profile.cozyStatus!,
        statusText: profile.cozyStatusText,
        displayText: _formatCozyStatus(profile.cozyStatus!, profile.cozyStatusText, profile.displayName),
      );
    } catch (e) {
      debugPrint('[CozyAutoReplyService] Error getting cozy status: $e');
      return null;
    }
  }

  /// Generate an auto-reply message for cozy mode recipients.
  String generateAutoReply({
    required String recipientName,
    required String cozyStatus,
    String? customText,
  }) {
    final statusDisplay = _formatCozyStatus(cozyStatus, customText, recipientName);
    return '$recipientName is $statusDisplay - they\'ll get back to you soon! 💫';
  }

  /// Check if auto-reply should be sent for this conversation.
  /// Returns the auto-reply message if cozy mode is active, null otherwise.
  Future<String?> getAutoReplyIfNeeded({
    required String senderId,
    required String recipientId,
    required String recipientName,
  }) async {
    final cozyStatus = await getRecipientCozyStatus(recipientId);
    if (cozyStatus == null) return null;

    // Don't send auto-reply for messages from the same user
    if (senderId == recipientId) return null;

    // Check if we should rate-limit (only send one auto-reply per hour per sender)
    if (await _shouldRateLimitAutoReply(senderId, recipientId)) {
      return null;
    }

    // Record this auto-reply to prevent spam
    await _recordAutoReply(senderId, recipientId);

    return generateAutoReply(
      recipientName: recipientName,
      cozyStatus: cozyStatus.status,
      customText: cozyStatus.statusText,
    );
  }

  /// Format cozy status for display.
  String _formatCozyStatus(String status, String? customText, String recipientName) {
    // Map status IDs to friendly descriptions
    switch (status) {
      case 'cocoon':
        return 'in my cocoon';
      case 'reading':
        return 'in reading mode';
      case 'recharge':
        return 'offline recharging';
      case 'movie_night':
        return 'having a movie night';
      case 'deep_thought':
        return 'in deep thought';
      case 'sleepy':
        return 'feeling sleepy';
      case 'custom':
        if (customText != null && customText.isNotEmpty) {
          return customText;
        }
        return 'taking some time';
      default:
        return 'taking some cozy time';
    }
  }

  /// Rate-limit auto-replies (max 1 per hour per sender-recipient pair).
  Future<bool> _shouldRateLimitAutoReply(String senderId, String recipientId) async {
    try {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final response = await _supabase
          .from('cozy_auto_replies')
          .select('id')
          .eq('sender_id', senderId)
          .eq('recipient_id', recipientId)
          .gte('created_at', oneHourAgo.toIso8601String())
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('[CozyAutoReplyService] Error checking rate limit: $e');
      return true; // Fail safe - don't send if we can't check
    }
  }

  /// Record an auto-reply to prevent spam.
  Future<void> _recordAutoReply(String senderId, String recipientId) async {
    try {
      await _supabase.from('cozy_auto_replies').insert({
        'sender_id': senderId,
        'recipient_id': recipientId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[CozyAutoReplyService] Error recording auto-reply: $e');
    }
  }
}

/// Information about a user's cozy mode status.
class CozyStatusInfo {
  final String status;
  final String? statusText;
  final String displayText;

  CozyStatusInfo({
    required this.status,
    this.statusText,
    required this.displayText,
  });
}