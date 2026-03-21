import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RipplesLayoutType {
  kineticCardStack,
  focusDial,
  choiceMosaic,
  rippleSwipe,
}

class RipplesService extends ChangeNotifier {
  static const String _lockoutEndTimeKey = 'ripples_lockout_end_time';
  static const String _layoutPreferenceKey = 'ripples_layout_preference';

  bool _isRipplesLocked = false;
  DateTime? _lockoutEndTime;
  Timer? _activeSessionTimer;
  Timer? _lockoutCheckTimer;
  RipplesLayoutType _currentLayout = RipplesLayoutType.kineticCardStack;
  String? _currentUserId;

  bool get isRipplesLocked => _isRipplesLocked;
  DateTime? get lockoutEndTime => _lockoutEndTime;
  RipplesLayoutType get currentLayout => _currentLayout;

  // For UI to listen to session ending
  final StreamController<void> _sessionEndController = StreamController<void>.broadcast();
  Stream<void> get onSessionEnd => _sessionEndController.stream;

  RipplesService() {
    // Periodically check lockout status
    _lockoutCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) => checkLockout());
  }

  String _getUserKey(String baseKey) => _currentUserId != null ? '${baseKey}_${_currentUserId}' : baseKey;

  Future<void> initForUser(String userId) async {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Load Lockout State for this specific user
    final lockoutTimeString = prefs.getString(_getUserKey(_lockoutEndTimeKey));
    if (lockoutTimeString != null) {
      _lockoutEndTime = DateTime.parse(lockoutTimeString);
      checkLockout();
    } else {
      _lockoutEndTime = null;
      _isRipplesLocked = false;
    }

    // Load Layout Preference for this specific user
    final layoutString = prefs.getString(_getUserKey(_layoutPreferenceKey));
    if (layoutString != null) {
      _currentLayout = RipplesLayoutType.values.firstWhere(
        (e) => e.toString() == layoutString,
        orElse: () => RipplesLayoutType.kineticCardStack,
      );
    }

    notifyListeners();
  }

  void checkLockout() {
    if (_lockoutEndTime != null) {
      if (DateTime.now().isAfter(_lockoutEndTime!)) {
        _isRipplesLocked = false;
        _lockoutEndTime = null;
        if (_currentUserId != null) {
          SharedPreferences.getInstance().then((prefs) => prefs.remove(_getUserKey(_lockoutEndTimeKey)));
        }
      } else {
        _isRipplesLocked = true;
      }
      notifyListeners();
    }
  }

  void startSession(Duration duration) {
    _activeSessionTimer?.cancel();
    _activeSessionTimer = Timer(duration, endSession);
  }

  /// Cancels the session timer without triggering a lockout (user exited early)
  void cancelSession() {
    _activeSessionTimer?.cancel();
    _activeSessionTimer = null;
    notifyListeners();
  }

  /// Ends the session naturally (timer finished) and triggers the 30-min lockout
  void endSession() {
    _activeSessionTimer?.cancel();
    _activeSessionTimer = null;
    
    // 30 minute lockout
    _lockoutEndTime = DateTime.now().add(const Duration(minutes: 30));
    _isRipplesLocked = true;
    
    if (_currentUserId != null) {
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setString(_getUserKey(_lockoutEndTimeKey), _lockoutEndTime!.toIso8601String()),
      );
    }
    
    notifyListeners();
    _sessionEndController.add(null);
  }

  Future<void> setLayoutPreference(RipplesLayoutType type) async {
    _currentLayout = type;
    if (_currentUserId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getUserKey(_layoutPreferenceKey), type.toString());
    }
    notifyListeners();
  }

  List<String> fetchDummyVideos() {
    return [
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
    ];
  }

  @override
  void dispose() {
    _activeSessionTimer?.cancel();
    _lockoutCheckTimer?.cancel();
    _sessionEndController.close();
    super.dispose();
  }
}
