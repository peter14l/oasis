import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Use a hybrid approach: check String.fromEnvironment (for builds) first,
  // then fallback to dotenv (for local run).
  static String get supabaseUrl {
    const fromEnv = String.fromEnvironment('SUPABASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    const fromEnv = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  // Enable debug logging only in development builds
  static bool get debug => kDebugMode;

  // Storage buckets
  static const String profilePicturesBucket = 'profile-pictures';
  static const String postImagesBucket = 'post-images';
  static const String postVideosBucket = 'post-videos';
  static const String communityImagesBucket = 'community-images';
  static const String messageAttachmentsBucket = 'message-attachments';
  static const String storiesBucket = 'stories';

  // Table names - Core
  static const String profilesTable = 'profiles';
  static const String postsTable = 'posts';
  static const String communitiesTable = 'communities';
  static const String communityMembersTable = 'community_members';
  static const String followsTable = 'follows';
  static const String likesTable = 'likes';
  static const String bookmarksTable = 'bookmarks';
  static const String commentsTable = 'comments';
  static const String commentLikesTable = 'comment_likes';
  static const String notificationsTable = 'notifications';

  // Table names - Messaging
  static const String conversationsTable = 'conversations';
  static const String conversationParticipantsTable =
      'conversation_participants';
  static const String messagesTable = 'messages';
  static const String messageReadReceiptsTable = 'message_read_receipts';
  static const String messageReactionsTable = 'message_reactions';
  static const String messageMediaViewsTable = 'message_media_views';
  static const String typingIndicatorsTable = 'typing_indicators';
  static const String storiesTable = 'stories';
  static const String timeCapsulesTable = 'time_capsules';

  // Function names
  static const String getFeedPostsFn = 'get_feed_posts';
  static const String getFollowingFeedPostsFn = 'get_following_feed_posts';
  static const String getUserConversationsFn = 'get_user_conversations';
  static const String getOrCreateDirectConversationFn =
      'get_or_create_direct_conversation';
  static const String resetUnreadCountFn = 'reset_unread_count';
  static const String deleteUserAccountFn = 'delete_user_account';

  // Channel names for realtime
  static const String postsChannel = 'public:posts';
  static const String messagesChannel = 'public:messages';
  static const String notificationsChannel = 'public:notifications';
  static const String typingIndicatorsChannel = 'public:typing_indicators';
  static const String conversationParticipantsChannel =
      'public:conversation_participants';
}
