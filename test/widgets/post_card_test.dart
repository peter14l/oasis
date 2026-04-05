import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/features/feed/domain/models/post.dart';
import 'package:oasis/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis/widgets/post_card.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';

// We need a simple mock for ProfileProvider
class MockProfileProvider extends ChangeNotifier implements ProfileProvider {
  @override
  List<UserProfileEntity> get following => [];

  @override
  Future<void> followUser({
    required String followerId,
    required String followingId,
  }) async {}

  @override
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('PostCard like button toggles', (WidgetTester tester) async {
    // Set a larger surface size to avoid overflow
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;

    final post = Post(
      id: '1',
      userId: 'user1',
      username: 'testuser',
      userAvatar: '',
      content: 'Hello world',
      imageUrl: 'https://example.com/image.jpg',
      timestamp: DateTime.now(),
      likes: 10,
      isLiked: false,
    );

    bool likeCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<ProfileProvider>(
            create: (_) => MockProfileProvider(),
            child: ListView(
              children: [
                PostCard(
                  post: post,
                  onLike: () {
                    likeCalled = true;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Find by key
    final likeButton = find.byKey(const ValueKey('post_card_like_button'));
    expect(likeButton, findsOneWidget);

    await tester.ensureVisible(likeButton);
    await tester.tap(likeButton);
    await tester.pump(
      const Duration(milliseconds: 500),
    ); // Fixed duration instead of pumpAndSettle

    expect(likeCalled, isTrue);

    // Reset surface size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('PostCard double tap always likes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;

    final post = Post(
      id: '1',
      userId: 'user1',
      username: 'testuser',
      userAvatar: '',
      content: 'Hello world',
      imageUrl: 'https://example.com/image.jpg',
      timestamp: DateTime.now(),
      likes: 10,
      isLiked: true, // ALREADY LIKED
    );

    bool likeCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<ProfileProvider>(
            create: (_) => MockProfileProvider(),
            child: ListView(
              children: [
                PostCard(
                  post: post,
                  onLike: () {
                    likeCalled = true;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Double tap the image area
    final aspectRatioFinder = find.byType(AspectRatio);
    await tester.ensureVisible(aspectRatioFinder);

    await tester.tap(aspectRatioFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(aspectRatioFinder);
    await tester.pump(const Duration(milliseconds: 500));

    // Since it was already liked, double tap should NOT call onLike (toggle off)
    expect(likeCalled, isFalse);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
