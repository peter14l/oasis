import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oasis/features/profile/domain/repositories/profile_repository.dart';
import 'package:oasis/features/wellbeing/presentation/providers/cozy_mode_state.dart';
import 'package:oasis/services/auth_service.dart';

class CozyModeProvider with ChangeNotifier {
  final ProfileRepository _profileRepository;
  Timer? _expirationTimer;

  CozyModeState _state = const CozyModeState();
  CozyModeState get state => _state;

  CozyMode? get activeMode => _state.activeMode;
  String? get customText => _state.customText;
  bool get hasActiveCozyStatus => _state.hasActiveCozyStatus;
  String get displayText => _state.displayText;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;

  CozyModeProvider({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository;

  /// Load cozy mode from current user's profile
  Future<void> loadCozyMode() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final profile = await _profileRepository.getProfile(userId);
      final status = profile.cozyStatus;
      final statusText = profile.cozyStatusText;
      final until = profile.cozyUntil;

      CozyMode? mode;
      if (status != null && status.isNotEmpty) {
        mode = CozyMode.values.where((m) => m.id == status).firstOrNull ??
            CozyMode.custom;
      }

      _state = CozyModeState(
        activeMode: mode,
        customText: statusText,
        until: until,
      );

      // Set up expiration timer if needed
      _scheduleExpiration(until);

      notifyListeners();
    } catch (e) {
      debugPrint('[CozyModeProvider] Error loading cozy mode: $e');
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  /// Set cozy mode for the current user
  Future<void> setCozyMode({
    required CozyMode mode,
    String? customText,
    Duration? duration,
  }) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      _state = _state.copyWith(error: 'Not authenticated');
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      DateTime? until;
      if (duration != null) {
        until = DateTime.now().add(duration);
      }

      final text = mode == CozyMode.custom ? customText : null;

      await _profileRepository.setCozyMode(
        userId: userId,
        status: mode.id,
        statusText: text,
        until: until,
      );

      _state = CozyModeState(
        activeMode: mode,
        customText: text,
        until: until,
      );

      // Set up expiration timer
      _scheduleExpiration(until);

      // Update user presence to reflect cozy status
      _updatePresenceStatus(mode);

      notifyListeners();
    } catch (e) {
      debugPrint('[CozyModeProvider] Error setting cozy mode: $e');
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  /// Clear cozy mode
  Future<void> clearCozyMode() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      await _profileRepository.clearCozyMode(userId);

      _expirationTimer?.cancel();
      _expirationTimer = null;

      _state = const CozyModeState();

      // Reset presence to online
      _updatePresenceStatus(null);

      notifyListeners();
    } catch (e) {
      debugPrint('[CozyModeProvider] Error clearing cozy mode: $e');
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    }
  }

  /// Schedule auto-clear when duration expires
  void _scheduleExpiration(DateTime? until) {
    _expirationTimer?.cancel();
    _expirationTimer = null;

    if (until != null) {
      final delay = until.difference(DateTime.now());
      if (delay.isNegative) {
        // Already expired
        clearCozyMode();
        return;
      }

      _expirationTimer = Timer(delay, () {
        clearCozyMode();
      });
    }
  }

  /// Update presence status to reflect cozy mode
  void _updatePresenceStatus(CozyMode? mode) {
    // Import and use presence provider to update status
    // This is handled by the PresenceProvider externally
    // We'll emit an event that can be consumed by other providers
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    super.dispose();
  }
}