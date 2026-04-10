import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/services/iap_service.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final _supabase = SupabaseService().client;
  bool _isPro = false;

  bool get isPro => _isPro;

  Future<void> init() async {
    await _updateProStatus();
    
    // Listen to Auth changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _updateProStatus();
    });

    // Listen to IAP changes
    IAPService().addListener(() {
      _updateProStatus();
    });
  }

  Future<void> _updateProStatus() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // 1. Check Auth Metadata (Secure app_metadata updated by triggers)
      final appMetadata = user.appMetadata;
      bool status = appMetadata['is_pro'] as bool? ?? false;
      
      // 2. If metadata says false, double check the profiles table (The Source of Truth)
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

  /// Refreshes the Pro status from the server
  Future<void> refresh() async {
    await _updateProStatus();
  }
}
