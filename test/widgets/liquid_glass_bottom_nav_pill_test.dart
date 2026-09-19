import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/widgets/liquid_glass_bottom_nav_pill.dart';

void main() {
  testWidgets('LiquidGlassBottomNavPill renders with compact height and handles gestures',
      (WidgetTester tester) async {
    int selectedIndex = 0;

    final destinations = [
      const LiquidNavDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        tooltip: 'Home',
      ),
      const LiquidNavDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search),
        tooltip: 'Search',
      ),
      const LiquidNavDestination(
        icon: Icon(Icons.chat_outlined),
        selectedIcon: Icon(Icons.chat),
        tooltip: 'Messages',
      ),
      const LiquidNavDestination(
        icon: Icon(Icons.person_outlined),
        selectedIcon: Icon(Icons.person),
        tooltip: 'Profile',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: LiquidGlassBottomNavPill(
              currentIndex: selectedIndex,
              onDestinationSelected: (index) {
                selectedIndex = index;
              },
              destinations: destinations,
              disableTransparency: true, // test solid shell layout and logic directly
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify widget rendered
    expect(find.byType(LiquidGlassBottomNavPill), findsOneWidget);

    // Verify pill container inside LiquidGlassBottomNavPill has height 52.0 and compact width
    final pillContainerFinder = find.descendant(
      of: find.byType(LiquidGlassBottomNavPill),
      matching: find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == 52.0 && widget.width != null,
      ),
    );
    expect(pillContainerFinder, findsOneWidget);

    final Size pillSize = tester.getSize(pillContainerFinder);
    expect(pillSize.height, equals(52.0));
    // 4 destinations * 68.0 + 10 padding = 282.0 width
    expect(pillSize.width, equals(282.0));

    // Test tap on destination 2 (Messages)
    await tester.tap(find.byIcon(Icons.chat_outlined));
    await tester.pumpAndSettle();
    expect(selectedIndex, equals(2));

    // Test horizontal drag across the pill
    final gesture = await tester.startGesture(tester.getCenter(pillContainerFinder));
    await tester.pump(const Duration(milliseconds: 50));
    // Drag to the left
    await gesture.moveBy(const Offset(-60.0, 0.0));
    await tester.pump(const Duration(milliseconds: 100));
    // Drag to the right
    await gesture.moveBy(const Offset(120.0, 0.0));
    await tester.pump(const Duration(milliseconds: 100));
    // Release
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
