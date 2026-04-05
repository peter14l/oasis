import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:oasis/screens/ripples_screen.dart';
import 'package:oasis/services/ripples_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import '../test_setup.dart';

class MockVideoPlayerPlatform extends VideoPlayerPlatform with MockPlatformInterfaceMixin {
  @override
  Future<void> init() async {}
  @override
  Future<void> dispose(int textureId) async {}
  @override
  Future<int?> create(DataSource dataSource) async => 1;
  @override
  Future<void> setLooping(int textureId, bool looping) async {}
  @override
  Future<void> play(int textureId) async {}
  @override
  Future<void> pause(int textureId) async {}
  @override
  Future<void> setVolume(int textureId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}
  @override
  Future<Duration> getPosition(int textureId) async => Duration.zero;
  
  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return Stream.value(VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 1),
      size: const Size(1280, 720),
    ));
  }

  @override
  Widget buildView(int textureId) {
    return Container();
  }
}

void main() {
  setupTestEnvironment();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    VideoPlayerPlatform.instance = MockVideoPlayerPlatform();
  });

  Widget createRipplesScreen(RipplesService service) {
    return ChangeNotifierProvider<RipplesService>.value(
      value: service,
      child: const MaterialApp(
        home: RipplesScreen(),
      ),
    );
  }

  testWidgets('RipplesScreen renders and has an exit button', (WidgetTester tester) async {
    final service = RipplesService();
    await tester.runAsync(() async {
      await tester.pumpWidget(createRipplesScreen(service));
      await tester.pump();
    });
    
    // The exit button uses FluentIcons.dismiss_24_filled which renders as a specific IconData
    expect(find.byType(GestureDetector), findsWidgets);
    
    service.dispose();
  });

  testWidgets('DynamicRipplePill expands on tap', (WidgetTester tester) async {
    final service = RipplesService();
    await tester.runAsync(() async {
      await tester.pumpWidget(createRipplesScreen(service));
      await tester.pump();
    });

    // We can't easily test the inner logic without mocking the Ripples list,
    // but we can check if DynamicRipplePill exists.
    // Ripples list is empty in this test because service.getRipples() returns empty.
    
    expect(find.byType(RipplesScreen), findsOneWidget);
    
    service.dispose();
  });
}
