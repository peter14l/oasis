import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/widgets/splash_screen.dart';

void main() {
  group('SplashScreen Tests', () {
    testWidgets('SplashScreen displays app name and loading indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen(onInitComplete: () {})),
      );

      // Verify splash screen displays app name
      expect(find.text('Oasis'), findsOneWidget);

      // Verify loading indicator exists
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Pump a few frames to let animation progress
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('SplashScreen applies correct dark theme background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: SplashScreen(onInitComplete: () {}),
        ),
      );

      // Pump to build the widget
      await tester.pump();

      // Verify the scaffold has dark background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF080A0E)));
    });

    testWidgets('SplashScreen applies correct light theme background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: SplashScreen(onInitComplete: () {}),
        ),
      );

      // Pump to build the widget
      await tester.pump();

      // Verify the scaffold has light background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFFF8F9FA)));
    });

    testWidgets('SplashScreen callback fires after delay', (
      WidgetTester tester,
    ) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            onInitComplete: () {
              callbackCalled = true;
            },
          ),
        ),
      );

      // Pump past the callback delay (500ms in splash screen)
      await tester.pump(const Duration(milliseconds: 600));

      // Callback should have been called
      expect(callbackCalled, isTrue);
    });

    testWidgets('SplashScreen renders without crashing', (
      WidgetTester tester,
    ) async {
      // The splash screen should render without crashing
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen(onInitComplete: () {})),
      );

      // Should still render without crashing
      expect(find.byType(SplashScreen), findsOneWidget);

      // Clean up the timer
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
