import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oasis_v2/services/ripples_service.dart';
import 'dart:async';

void main() {
  group('RipplesService Tests', () {
    late RipplesService ripplesService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      ripplesService = RipplesService();
    });

    test('Initial state is not locked', () {
      expect(ripplesService.isRipplesLocked, false);
      expect(ripplesService.lockoutEndTime, null);
    });

    test('startSession starts a timer and ends session after duration', () {
      final duration = const Duration(milliseconds: 100);
      bool sessionEnded = false;
      
      ripplesService.onSessionEnd.listen((_) {
        sessionEnded = true;
      });

      ripplesService.startSession(duration);
      
      // Wait for timer to fire
      Timer(const Duration(milliseconds: 200), () {
        expect(sessionEnded, true);
        expect(ripplesService.isRipplesLocked, true);
        expect(ripplesService.lockoutEndTime, isNotNull);
      });
    });

    test('setLayoutPreference updates and persists layout', () async {
      await ripplesService.setLayoutPreference(RipplesLayoutType.choiceMosaic);
      expect(ripplesService.currentLayout, RipplesLayoutType.choiceMosaic);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ripples_layout_preference'), RipplesLayoutType.choiceMosaic.toString());
    });

    test('checkLockout correctly clears expired lockout', () async {
      final pastTime = DateTime.now().subtract(const Duration(minutes: 1));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ripples_lockout_end_time', pastTime.toIso8601String());
      
      // Create new service to load from prefs
      final newService = RipplesService();
      await Future.delayed(Duration.zero); // Let init complete
      
      newService.checkLockout();
      expect(newService.isRipplesLocked, false);
      expect(newService.lockoutEndTime, null);
    });
  });
}
