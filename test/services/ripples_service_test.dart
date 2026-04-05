import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/features/ripples/presentation/providers/ripples_provider.dart';
import 'package:oasis/features/ripples/domain/models/ripple_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('RipplesProvider Unit Tests', () {
    late RipplesProvider ripplesService;
    late MockSupabaseClient mockSupabase;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockSupabase = MockSupabaseClient();
      ripplesService = RipplesProvider(supabase: mockSupabase);
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
