import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/services/revenuecat_service.dart';

class SubscriptionService extends ChangeNotifier {
  static SubscriptionService? _instance;
  
  final SupabaseClient? _client;
  bool _isPro = false;

  SubscriptionService._internal({SupabaseClient? client}) : _client = client;

  factory SubscriptionService({SupabaseClient? client}) {
    _instance ??= SubscriptionService._internal(client: client);
    return _instance!;
  }

  /// Use for testing purposes to reset the singleton.
  @visibleForTesting
  static void reset(SubscriptionService service) {
    _instance = service;
  }

  SupabaseClient get _supabase => _client ?? SupabaseService().client;
  bool get isPro => _isPro;

  @visibleForTesting
  void setProStatus(bool status) {
    _isPro = status;
    notifyListeners();
  }

  Future<void> init() async {
    await _updateProStatus();
    
    // Listen to Auth changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _updateProStatus();
    });

    // Listen to RevenueCat changes
    RevenueCatService().addListener(() {
      _updateProStatus();
    });
  }

  Future<void> _updateProStatus() async {
    // 1. Check RevenueCat (Primary source of truth now)
    bool status = RevenueCatService().isPro;

    // 2. Fallback to Supabase/Legacy logic if RevenueCat says false
    if (!status) {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // 1. Check Auth Metadata (Secure app_metadata updated by triggers)
        final appMetadata = user.appMetadata;
        status = appMetadata['is_pro'] as bool? ?? false;
        
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
      }
    }
    
    _isPro = status;
    notifyListeners();
  }

  /// Refreshes the Pro status from the server
  Future<void> refresh() async {
    await RevenueCatService().refresh();
    await _updateProStatus();
  }
}
