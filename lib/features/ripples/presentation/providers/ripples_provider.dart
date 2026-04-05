import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/features/ripples/domain/models/ripple_entity.dart'
    show RipplesLayoutType;

/// Provider for ripples feature - manages UI state and session lifecycle.
/// Uses Maps internally for backward compatibility with existing screen code.
class RipplesProvider extends ChangeNotifier {
  static const String _lockoutEndTimeKey = 'ripples_lockout_end_time';
  static const String _layoutPreferenceKey = 'ripples_layout_preference';
  static const String _remainingDurationKey = 'ripples_remaining_duration';
  static const String _lastActiveKey = 'ripples_last_active';

  final SupabaseClient _supabase;

  List<Map<String, dynamic>> _ripples = [];
  bool _isLoading = false;
  String? _error;
  RipplesLayoutType _currentLayout = RipplesLayoutType.kineticCardStack;
  bool _isRipplesLocked = false;
  DateTime? _lockoutEndTime;
  Duration? _remainingDuration;
  String? _currentUserId;

  Timer? _activeSessionTimer;
  Timer? _lockoutCheckTimer;
  double _lockoutMultiplier = 1.0;
  DateTime? _lastSessionEndTime;

  final StreamController<void> _sessionEndController =
      StreamController<void>.broadcast();

  RipplesProvider({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseService().client {
    _startLockoutTimer();
  }

  // Getters
  List<Map<String, dynamic>> get ripples => _ripples;
  bool get isLoading => _isLoading;
  String? get error => _error;
  RipplesLayoutType get currentLayout => _currentLayout;
  bool get isRipplesLocked => _isRipplesLocked;
  DateTime? get lockoutEndTime => _lockoutEndTime;
  Duration? get remainingDuration => _remainingDuration;
  Stream<void> get onSessionEnd => _sessionEndController.stream;

  // Initialize for a user
  Future<void> initForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Load local state
    final lockoutTimeString = prefs.getString('${_lockoutEndTimeKey}_$userId');
    if (lockoutTimeString != null) {
      _lockoutEndTime = DateTime.parse(lockoutTimeString);
    }

    final layoutString = prefs.getString('${_layoutPreferenceKey}_$userId');
    if (layoutString != null) {
      _currentLayout = RipplesLayoutType.values.firstWhere(
        (e) => e.toString() == layoutString,
        orElse: () => RipplesLayoutType.kineticCardStack,
      );
    }

    final remainingMs = prefs.getInt('${_remainingDurationKey}_$userId');
    if (remainingMs != null) {
      _remainingDuration = Duration(milliseconds: remainingMs);
    }

    _currentUserId = userId;
    checkLockout();
    refreshRipples();
  }

  void _startLockoutTimer() {
    _lockoutCheckTimer?.cancel();
    _lockoutCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => checkLockout(),
    );
  }

  void onPaused() {
    _lockoutCheckTimer?.cancel();
    _lockoutCheckTimer = null;
    debugPrint('Ripples: Lockout check timer paused (background)');
  }

  void onResumed() {
    checkLockout();
    _startLockoutTimer();
    debugPrint('Ripples: Lockout check timer resumed');
  }

  void checkLockout() {
    if (_lockoutEndTime != null) {
      if (DateTime.now().isAfter(_lockoutEndTime!)) {
        _isRipplesLocked = false;
        _lockoutEndTime = null;
        if (_currentUserId != null) {
          SharedPreferences.getInstance().then(
            (prefs) => prefs.remove('${_lockoutEndTimeKey}_$_currentUserId'),
          );
        }
      } else {
        _isRipplesLocked = true;
      }
      notifyListeners();
    }
  }

  void startSession(Duration duration) {
    _activeSessionTimer?.cancel();
    _remainingDuration = duration;
    _activeSessionTimer = Timer(duration, endSession);
    _saveSessionState();
  }

  void pauseSession(Duration remaining) {
    _activeSessionTimer?.cancel();
    _remainingDuration = remaining;
    _saveSessionState();
    notifyListeners();
  }

  Future<void> _saveSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_remainingDuration != null && _currentUserId != null) {
      await prefs.setInt(
        '${_remainingDurationKey}_$_currentUserId',
        _remainingDuration!.inMilliseconds,
      );
      await prefs.setString(
        '${_lastActiveKey}_$_currentUserId',
        DateTime.now().toIso8601String(),
      );
    }
  }

  Future<void> endSession() async {
    _activeSessionTimer?.cancel();
    _activeSessionTimer = null;
    _remainingDuration = null;

    // Adaptive Lockout Logic
    if (_lastSessionEndTime != null) {
      final diff = DateTime.now().difference(_lastSessionEndTime!).inMinutes;
      if (diff < 65) {
        _lockoutMultiplier += 0.5;
      }
    }

    const baseLockout = Duration(minutes: 30);
    final actualLockoutMinutes =
        (baseLockout.inMinutes * _lockoutMultiplier).round();

    final lockoutEnd = DateTime.now().add(
      Duration(minutes: actualLockoutMinutes),
    );
    _lastSessionEndTime = lockoutEnd;
    _isRipplesLocked = true;
    _lockoutEndTime = lockoutEnd;

    final prefs = await SharedPreferences.getInstance();
    if (_currentUserId != null) {
      await prefs.setString(
        '${_lockoutEndTimeKey}_$_currentUserId',
        lockoutEnd.toIso8601String(),
      );
      await prefs.remove('${_remainingDurationKey}_$_currentUserId');
    }

    notifyListeners();
    _sessionEndController.add(null);
  }

  Future<void> setLayoutPreference(RipplesLayoutType type) async {
    _currentLayout = type;
    if (_currentUserId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_layoutPreferenceKey}_$_currentUserId',
        type.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> refreshRipples() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;

      // Fetch ripples with profiles and check if current user liked/saved them
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

      _ripples = ripplesData;
    } catch (e) {
      debugPrint('Error fetching ripples: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> likeRipple(String rippleId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Update locally first for instant feedback
    final index = _ripples.indexWhere((r) => r['id'] == rippleId);
    if (index != -1 && !(_ripples[index]['is_liked'] ?? false)) {
      _ripples[index]['is_liked'] = true;
      _ripples[index]['likes_count'] =
          (_ripples[index]['likes_count'] ?? 0) + 1;
      notifyListeners();
    }

    try {
      await _supabase.from('ripple_likes').upsert({
        'ripple_id': rippleId,
        'user_id': userId,
      });
    } catch (e) {
      debugPrint('Error liking ripple: $e');
    }
  }

  Future<void> unlikeRipple(String rippleId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Update locally first
    final index = _ripples.indexWhere((r) => r['id'] == rippleId);
    if (index != -1 && (_ripples[index]['is_liked'] ?? false)) {
      _ripples[index]['is_liked'] = false;
      _ripples[index]['likes_count'] =
          (_ripples[index]['likes_count'] ?? 0) - 1;
      if (_ripples[index]['likes_count'] < 0) {
        _ripples[index]['likes_count'] = 0;
      }
      notifyListeners();
    }

    try {
      await _supabase.from('ripple_likes').delete().match({
        'ripple_id': rippleId,
        'user_id': userId,
      });
    } catch (e) {
      debugPrint('Error unliking ripple: $e');
    }
  }

  Future<void> saveRipple(String rippleId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final index = _ripples.indexWhere((r) => r['id'] == rippleId);
    if (index != -1) {
      _ripples[index]['is_saved'] = true;
      notifyListeners();
    }

    try {
      await _supabase.from('ripple_saves').upsert({
        'ripple_id': rippleId,
        'user_id': userId,
      });
    } catch (e) {
      debugPrint('Error saving ripple: $e');
    }
  }

  Future<void> unsaveRipple(String rippleId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final index = _ripples.indexWhere((r) => r['id'] == rippleId);
    if (index != -1) {
      _ripples[index]['is_saved'] = false;
      notifyListeners();
    }

    try {
      await _supabase.from('ripple_saves').delete().match({
        'ripple_id': rippleId,
        'user_id': userId,
      });
    } catch (e) {
      debugPrint('Error unsaving ripple: $e');
    }
  }

  Future<void> commentOnRipple(String rippleId, String comment) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase.from('ripple_comments').insert({
        'ripple_id': rippleId,
        'user_id': userId,
        'content': comment,
      });

      // Update local count
      final index = _ripples.indexWhere((r) => r['id'] == rippleId);
      if (index != -1) {
        _ripples[index]['comments_count'] =
            (_ripples[index]['comments_count'] ?? 0) + 1;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error commenting on ripple: $e');
    }
  }

  @override
  void dispose() {
    _activeSessionTimer?.cancel();
    _lockoutCheckTimer?.cancel();
    _sessionEndController.close();
    super.dispose();
  }
}
