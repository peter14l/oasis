import 'package:flutter/foundation.dart';
import 'package:oasis_v2/models/time_capsule.dart';
import 'package:oasis_v2/services/time_capsule_service.dart';

class CapsuleProvider with ChangeNotifier {
  final TimeCapsuleService _service = TimeCapsuleService();

  List<TimeCapsule> _capsules = [];
  bool _isLoading = false;
  String? _error;

  List<TimeCapsule> get capsules => _capsules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCapsules(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _capsules = await _service.getCapsules(userId: userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading capsules: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyUnlockedCapsules(String userId) async {
    // This could be a separate list or just filter?
    // For now, let's just support the main feed list.
    // If we need personal ones, we can add another method/list.
  }

  void addCapsule(TimeCapsule capsule) {
    _capsules.insert(0, capsule);
    notifyListeners();
  }
}
