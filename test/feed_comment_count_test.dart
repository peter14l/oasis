import 'package:flutter_test/flutter_test.dart';
import 'package:oasis_v2/providers/feed_provider.dart';
import 'package:oasis_v2/models/post.dart';
import 'package:oasis_v2/services/feed_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';

class MockFeedService extends Mock implements FeedService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeedProvider Comment Count Tests', () {
    late FeedProvider feedProvider;
    late MockFeedService mockFeedService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockFeedService = MockFeedService();
      feedProvider = FeedProvider(feedService: mockFeedService);
    });

    test('updatePostCommentCount updates the correct post', () {
      final post = Post(
        id: 'post1',
        userId: 'user1',
        username: 'testuser',
        userAvatar: '',
        content: 'Hello',
        timestamp: DateTime.now(),
        comments: 0,
      );

      feedProvider.addPost(post);
      expect(feedProvider.posts.first.comments, 0);

      feedProvider.updatePostCommentCount('post1', 5);
      expect(feedProvider.posts.first.comments, 5);
    });
  });
}
