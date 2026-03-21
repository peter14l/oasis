import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/screens/ripples_screen.dart';
import 'package:oasis_v2/services/ripples_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

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
    
    expect(find.byIcon(Icons.close), findsOneWidget);
    
    service.dispose();
  });

  testWidgets('FloatingActionPill expands on tap', (WidgetTester tester) async {
    final service = RipplesService();
    await tester.runAsync(() async {
      await tester.pumpWidget(createRipplesScreen(service));
      await tester.pump();
    });

    final pill = find.byType(FloatingActionPill);
    expect(pill, findsOneWidget);

    // Initial state: 2 buttons inside (Heart and Expand arrow)
    final innerButtons = find.descendant(of: pill, matching: find.byType(IconButton));
    expect(innerButtons, findsNWidgets(2));

    // Tap the expand button specifically
    final expandBtn = find.byKey(const ValueKey('expand_pill'));
    expect(expandBtn, findsOneWidget);
    
    await tester.tap(expandBtn);
    await tester.pump(); // Immediate rebuild for state change
    
    // Expanded state: 3 IconButtons inside (Heart, Comment, Share)
    // The Expand button is replaced by Comment/Share in the Row
    expect(innerButtons, findsNWidgets(3));
    
    service.dispose();
  });
}
