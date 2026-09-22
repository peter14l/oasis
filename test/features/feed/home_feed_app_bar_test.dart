import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/features/feed/presentation/widgets/home_feed_app_bar.dart';
import 'package:oasis/features/notifications/presentation/providers/notification_provider.dart';
import 'package:oasis/features/notifications/presentation/providers/notification_state.dart';

class FakeNotificationProvider extends ChangeNotifier implements NotificationProvider {
  int _unread = 0;

  FakeNotificationProvider([int initialUnread = 0]) : _unread = initialUnread;

  @override
  int get unreadCount => _unread;

  @override
  NotificationState get state => NotificationState(unreadCount: _unread);

  void setUnread(int count) {
    _unread = count;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildTestWidget({
    required Widget child,
    required NotificationProvider notificationProvider,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<NotificationProvider>.value(
              value: notificationProvider,
            ),
          ],
          child: child,
        ),
      ),
    );
  }

  group('HomeFeedAppBar', () {
    testWidgets('renders OASIS brand wordmark and core actions', (tester) async {
      final notifProvider = FakeNotificationProvider(0);

      await tester.pumpWidget(
        buildTestWidget(
          child: const HomeFeedAppBar(),
          notificationProvider: notifProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Brand wordmark
      expect(find.text('OASIS'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Create button
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Notifications bell
      expect(find.byIcon(FluentIcons.alert_24_regular), findsOneWidget);

      // Notification badge should NOT be visible when unread count is 0
      expect(find.text('0'), findsNothing);

      // STRICT CONSTRAINT: Direct Messages button must NOT be present
      expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
      expect(find.byIcon(Icons.message_outlined), findsNothing);
      expect(find.byIcon(FluentIcons.chat_24_regular), findsNothing);
      expect(find.byIcon(FluentIcons.mail_24_regular), findsNothing);
    });

    testWidgets('renders Ripples button when onRipplesTap is provided', (tester) async {
      final notifProvider = FakeNotificationProvider(0);
      bool ripplesTapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          child: HomeFeedAppBar(
            onRipplesTap: () => ripplesTapped = true,
          ),
          notificationProvider: notifProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ripples'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

      await tester.tap(find.text('Ripples'));
      expect(ripplesTapped, isTrue);
    });

    testWidgets('shows badge with unread notifications count', (tester) async {
      final notifProvider = FakeNotificationProvider(5);

      await tester.pumpWidget(
        buildTestWidget(
          child: const HomeFeedAppBar(),
          notificationProvider: notifProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('caps unread badge text at 9+ when unread count exceeds 9', (tester) async {
      final notifProvider = FakeNotificationProvider(15);

      await tester.pumpWidget(
        buildTestWidget(
          child: const HomeFeedAppBar(),
          notificationProvider: notifProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('9+'), findsOneWidget);
    });
  });
}
