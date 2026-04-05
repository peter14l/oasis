import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/services/session_registry_service.dart';
import 'package:oasis/features/circles/presentation/widgets/circles/commitment_card.dart';
import 'package:oasis/features/circles/domain/models/circles_models.dart';
import 'package:oasis/widgets/fluid_mesh_background.dart';
import 'package:oasis/widgets/canvas/scattered_polaroid_spread.dart';
import 'package:oasis/features/canvas/domain/models/canvas_models.dart';
import 'test_setup.dart';

void main() {
  setupTestEnvironment();

  group('RegisteredAccount Model Tests', () {
    test('RegisteredAccount JSON serialization', () {
      // Mock User for Session
const User({
        id: 'user1',
        appMetadata: {},
        userMetadata: {},
        aud: '',
        createdAt: '',
      );

      final session = Session(
        accessToken: 'access',
        tokenType: 'bearer',
        user: user,
      );

      final account = RegisteredAccount(
        userId: 'user1',
        email: 'test@test.com',
        username: 'testuser',
        session: session,
        lastUsed: DateTime(2024, 1, 1),
      );

      final json = account.toJson();
      expect(json['userId'], 'user1');
      expect(json['username'], 'testuser');

      final fromJson = RegisteredAccount.fromJson(json);
      expect(fromJson.userId, 'user1');
      expect(fromJson.email, 'test@test.com');
    });
  });

  group('Widget UI Tests (Phase 4)', () {
    testWidgets('FluidMeshBackground renders without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FluidMeshBackground(streakCount: 5)),
        ),
      );

      expect(find.byType(FluidMeshBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('ScatteredPolaroidSpread renders items', (
      WidgetTester tester,
    ) async {
      final items = [
        CanvasItemEntity(
          id: '1',
          canvasId: 'c1',
          authorId: 'a1',
          type: CanvasItemType.photo,
          content: 'https://example.com/image.jpg',
          createdAt: DateTime.now(),
          xPos: 0,
          yPos: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScatteredPolaroidSpread(items: items)),
        ),
      );

      expect(find.byType(ScatteredPolaroidSpread), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('CommitmentCard long press visual check', (
      WidgetTester tester,
    ) async {
      final commitment = CommitmentEntity(
        id: '1',
        circleId: 'c1',
        createdBy: 'u1',
        title: 'Test CommitmentEntity',
        dueDate: DateTime.now(),
        status: CommitmentStatus.open,
        responses: {
          'current_user': CommitmentResponseEntity(
            userId: 'current_user',
            intent: MemberIntent.inTrying,
            completed: false,
          ),
        },
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: CommitmentCard(
              commitment: commitment,
              currentUserId: 'current_user',
              onMarkComplete: () {},
              onSetIntent: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('HOLD TO VERIFY'), findsOneWidget);

      // Simulate long press start
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CommitmentCard)),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Should see custom paint for fluid fill (Stack should have children)
      expect(find.byType(CustomPaint), findsWidgets);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
