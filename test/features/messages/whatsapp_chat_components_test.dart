import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/features/messages/presentation/providers/chat_state.dart';
import 'package:oasis/features/messages/presentation/widgets/chat/whatsapp_status_icon.dart';
import 'package:oasis/features/messages/presentation/widgets/chat/whatsapp_bubble_animation.dart';

void main() {
  group('WhatsAppStatusIcon', () {
    testWidgets('renders Clock icon for sending / pending status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppStatusIcon(
              status: MessageStatus.sending,
              isRead: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
      expect(find.byIcon(Icons.done_rounded), findsNothing);
      expect(find.byIcon(Icons.done_all_rounded), findsNothing);
    });

    testWidgets('renders single check for sent status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppStatusIcon(
              status: MessageStatus.sent,
              isRead: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.done_rounded), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsNothing);
    });

    testWidgets('renders double check in grey for delivered status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppStatusIcon(
              status: MessageStatus.delivered,
              isRead: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.done_all_rounded));
      expect(icon.color, isNot(WhatsAppStatusIcon.whatsAppBlue));
    });

    testWidgets('renders double check in WhatsApp blue when isRead is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppStatusIcon(
              status: MessageStatus.delivered,
              isRead: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.done_all_rounded));
      expect(icon.color, equals(WhatsAppStatusIcon.whatsAppBlue));
    });

    testWidgets('renders red error icon on failed status and calls onRetry on tap', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WhatsAppStatusIcon(
              status: MessageStatus.failed,
              isRead: false,
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      await tester.tap(find.byType(WhatsAppStatusIcon));
      await tester.pump();

      expect(retryCalled, isTrue);
    });
  });

  group('WhatsAppBubbleAnimation', () {
    testWidgets('renders child immediately without animation when isFresh is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppBubbleAnimation(
              isMe: true,
              isFresh: false,
              child: Text('Historical Message'),
            ),
          ),
        ),
      );

      expect(find.text('Historical Message'), findsOneWidget);
    });

    testWidgets('animates fade and slide when isFresh is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatsAppBubbleAnimation(
              isMe: true,
              isFresh: true,
              child: Text('Fresh Message'),
            ),
          ),
        ),
      );

      expect(find.text('Fresh Message'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Fresh Message'), findsOneWidget);
    });
  });
}
