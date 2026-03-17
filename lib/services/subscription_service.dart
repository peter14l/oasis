import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis_v2/services/supabase_service.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final _supabase = SupabaseService().client;
  bool _isPro = false;

  bool get isPro => _isPro;

  Future<void> init() async {
    _updateProStatus();
    _supabase.auth.onAuthStateChange.listen((data) {
      _updateProStatus();
    });
  }

  void _updateProStatus() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final userMetadata = user.userMetadata ?? {};
      _isPro = userMetadata['is_pro'] as bool? ?? false;
    } else {
      _isPro = false;
    }
    notifyListeners();
  }

  /// Toggle Pro status for testing purposes
  Future<void> debugToggleProStatus(bool isPro) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // Update the user metadata in Supabase
      await _supabase.auth.updateUser(UserAttributes(data: {'is_pro': isPro}));
      _isPro = isPro;
      notifyListeners();
    }
  }
}
