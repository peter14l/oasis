import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced moderation service with timed mutes and shadow mute
class EnhancedModerationService extends ChangeNotifier {
  static const String _mutedUsersKey = 'muted_users';
  static const String _blockedUsersKey = 'blocked_users';

  final _supabase = SupabaseService().client;
  final SharedPreferences _prefs;

  Map<String, MuteInfo> _mutedUsers = {};
  Set<String> _blockedUsers = {};

  EnhancedModerationService(this._prefs) {
    _loadSettings();
  }

  static Future<EnhancedModerationService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return EnhancedModerationService(prefs);
  }

  bool isUserMuted(String userId) {
    final muteInfo = _mutedUsers[userId];
    if (muteInfo == null) return false;

    // Check if mute has expired
    if (muteInfo.expiresAt != null &&
        DateTime.now().isAfter(muteInfo.expiresAt!)) {
      // Remove expired mute
      _mutedUsers.remove(userId);
      _saveMutedUsers();
      return false;
    }

    return true;
  }

  bool isUserBlocked(String userId) => _blockedUsers.contains(userId);

  MuteInfo? getMuteInfo(String userId) => _mutedUsers[userId];

  /// Mute a user (optionally with duration)
  Future<void> muteUser(
    String userId, {
    MuteDuration duration = MuteDuration.indefinite,
    bool isShadowMute = false,
  }) async {
    DateTime? expiresAt;
    if (duration != MuteDuration.indefinite) {
      expiresAt = DateTime.now().add(duration.duration!);
    }

    _mutedUsers[userId] = MuteInfo(
      userId: userId,
      mutedAt: DateTime.now(),
      expiresAt: expiresAt,
      duration: duration,
      isShadowMute: isShadowMute,
    );

    await _saveMutedUsers();
    await _syncToServer(
      'mute',
      userId,
      expiresAt: expiresAt?.toIso8601String(),
    );
    notifyListeners();
  }

  /// Unmute a user
  Future<void> unmuteUser(String userId) async {
    _mutedUsers.remove(userId);
    await _saveMutedUsers();
    await _removeFromServer('mute', userId);
    notifyListeners();
  }

  /// Block a user
  Future<void> blockUser(String userId) async {
    _blockedUsers.add(userId);
    // Also mute them
    _mutedUsers.remove(userId);
    await _saveBlockedUsers();
    await _syncToServer('block', userId);
    notifyListeners();
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    _blockedUsers.remove(userId);
    await _saveBlockedUsers();
    await _removeFromServer('block', userId);
    notifyListeners();
  }

  /// Get all muted users
  List<MuteInfo> getMutedUsersList() {
    // Clean up expired mutes
    final now = DateTime.now();
    _mutedUsers.removeWhere(
      (_, info) => info.expiresAt != null && now.isAfter(info.expiresAt!),
    );
    return _mutedUsers.values.toList();
  }

  /// Get all blocked users
  Set<String> getBlockedUsersList() => Set.from(_blockedUsers);

  // Time remaining for mute
  Duration? getMuteTimeRemaining(String userId) {
    final info = _mutedUsers[userId];
    if (info == null || info.expiresAt == null) return null;

    final remaining = info.expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  void _loadSettings() {
    // Load muted users
    final mutedJson = _prefs.getString(_mutedUsersKey);
    if (mutedJson != null) {
      final Map decoded = jsonDecode(mutedJson);
      _mutedUsers = decoded.map(
        (key, value) => MapEntry(
          key as String,
          MuteInfo.fromJson(value as Map<String, dynamic>),
        ),
      );
    }

    // Load blocked users
    final blocked = _prefs.getStringList(_blockedUsersKey);
    if (blocked != null) {
      _blockedUsers = blocked.toSet();
    }
  }

  Future<void> _saveMutedUsers() async {
    final json = jsonEncode(
      _mutedUsers.map((key, value) => MapEntry(key, value.toJson())),
    );
    await _prefs.setString(_mutedUsersKey, json);
  }

  Future<void> _saveBlockedUsers() async {
    await _prefs.setStringList(_blockedUsersKey, _blockedUsers.toList());
  }

  Future<void> _syncToServer(
    String type,
    String targetUserId, {
    String? expiresAt,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _supabase.from('user_moderation').upsert({
        'user_id': currentUserId,
        'target_user_id': targetUserId,
        'action_type': type,
        'expires_at': expiresAt,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error syncing moderation to server: $e');
    }
  }

  Future<void> _removeFromServer(String type, String targetUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _supabase
          .from('user_moderation')
          .delete()
          .eq('user_id', currentUserId)
          .eq('target_user_id', targetUserId)
          .eq('action_type', type);
    } catch (e) {
      debugPrint('Error removing moderation from server: $e');
    }
  }

  /// Sync moderation list from server
  Future<void> syncFromServer() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      final response = await _supabase
          .from('user_moderation')
          .select()
          .eq('user_id', currentUserId);

      _mutedUsers.clear();
      _blockedUsers.clear();

      for (final item in response) {
        final targetId = item['target_user_id'] as String;
        final type = item['action_type'] as String;

        if (type == 'block') {
          _blockedUsers.add(targetId);
        } else if (type == 'mute') {
          final expiresAt =
              item['expires_at'] != null
                  ? DateTime.parse(item['expires_at'])
                  : null;

          if (expiresAt == null || expiresAt.isAfter(DateTime.now())) {
            _mutedUsers[targetId] = MuteInfo(
              userId: targetId,
              mutedAt: DateTime.parse(
                item['created_at'] ?? DateTime.now().toIso8601String(),
              ),
              expiresAt: expiresAt,
              duration:
                  MuteDuration.indefinite, // Will be calculated from expiresAt
            );
          }
        }
      }

      await _saveMutedUsers();
      await _saveBlockedUsers();
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing moderation from server: $e');
    }
  }
}

enum MuteDuration {
  hours24('24 hours', Duration(hours: 24)),
  days7('7 days', Duration(days: 7)),
  days30('30 days', Duration(days: 30)),
  indefinite('Forever', null);

  final String label;
  final Duration? duration;
  const MuteDuration(this.label, this.duration);
}

class MuteInfo {
  final String userId;
  final DateTime mutedAt;
  final DateTime? expiresAt;
  final MuteDuration duration;
  final bool isShadowMute;

  MuteInfo({
    required this.userId,
    required this.mutedAt,
    this.expiresAt,
    this.duration = MuteDuration.indefinite,
    this.isShadowMute = false,
  });

  factory MuteInfo.fromJson(Map<String, dynamic> json) {
    return MuteInfo(
      userId: json['user_id'],
      mutedAt: DateTime.parse(json['muted_at']),
      expiresAt:
          json['expires_at'] != null
              ? DateTime.parse(json['expires_at'])
              : null,
      isShadowMute: json['is_shadow_mute'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'muted_at': mutedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_shadow_mute': isShadowMute,
    };
  }

  String get remainingTimeText {
    if (expiresAt == null) return 'Forever';

    final remaining = expiresAt!.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';

    if (remaining.inDays > 0) {
      return '${remaining.inDays}d remaining';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h remaining';
    } else {
      return '${remaining.inMinutes}m remaining';
    }
  }
}
