import 'package:flutter_test/flutter_test.dart';
import 'package:oasis_v2/services/ripples_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('RipplesService Unit Tests', () {
    late RipplesService ripplesService;
    late MockSupabaseClient mockSupabase;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockSupabase = MockSupabaseClient();
      ripplesService = RipplesService(supabase: mockSupabase);
    });

    test('Initial layout should be kineticCardStack', () {
      expect(ripplesService.currentLayout, RipplesLayoutType.kineticCardStack);
    });

    test('Lockout check logic', () {
      ripplesService.checkLockout();
      expect(ripplesService.isRipplesLocked, false);
    });
  });
}
