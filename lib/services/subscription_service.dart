import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/core/network/supabase_client.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final _supabase = SupabaseService().client;
  bool _isPro = false;

  bool get isPro => _isPro;

  Future<void> init() async {
    await _updateProStatus();
    _supabase.auth.onAuthStateChange.listen((data) {
      _updateProStatus();
    });
  }

  Future<void> _updateProStatus() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // Check metadata first (fastest)
      final userMetadata = user.userMetadata ?? {};
      bool status = userMetadata['is_pro'] as bool? ?? false;
      
      // If metadata is false, double check the profiles table (more reliable)
      if (!status) {
        try {
          final profile = await _supabase
              .from('profiles')
              .select('is_pro')
              .eq('id', user.id)
              .maybeSingle();
          if (profile != null) {
            status = profile['is_pro'] as bool? ?? false;
          }
        } catch (e) {
          debugPrint('Error double-checking Pro status: $e');
        }
      }
      
      _isPro = status;
    } else {
      _isPro = false;
    }
    notifyListeners();
  }

  /// Toggle Pro status for testing purposes.
  /// 
  /// ⚠️ WARNING: In production, this should be handled by a secure backend 
  /// webhook triggered by the payment provider. Direct client-side updates 
  /// to 'is_pro' are a security risk.
  Future<void> debugToggleProStatus(bool isPro) async {
    if (!kDebugMode) return;

    final user = _supabase.auth.currentUser;
    if (user != null) {
      // We only update the local state for debugging UI flows.
      // Do NOT update the 'profiles' table or Auth metadata directly from the client in production.
      _isPro = isPro;
      notifyListeners();
      
      debugPrint('SubscriptionService: [DEBUG] Pro status toggled locally to: $isPro');
    }
  }
}
