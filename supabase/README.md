# Oasis V2 - Supabase Database Setup

This directory contains all the SQL migrations needed to set up the Oasis V2 database in Supabase.

## 📋 Prerequisites

1. A Supabase project (create one at [supabase.com](https://supabase.com))
2. Access to your Supabase SQL Editor
3. Your Supabase project URL and anon key

## 🚀 Quick Start

### Step 1: Run Migrations in Order

Open your Supabase SQL Editor and run the migration files in the following order:

1. **001_initial_schema.sql** - Creates core tables (profiles, posts, communities, etc.)
2. **002_messaging_schema.sql** - Creates messaging and chat tables
3. **003_rls_policies.sql** - Sets up Row Level Security for core tables
4. **004_messaging_rls_policies.sql** - Sets up RLS for messaging tables
5. **005_triggers_and_functions.sql** - Creates triggers for automatic updates
6. **006_notification_triggers.sql** - Creates notification triggers and utility functions
7. **007_storage_setup.sql** - Sets up storage buckets and policies

### Step 2: Configure Environment Variables

Update your `.env` file in the Flutter project root:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### Step 3: Enable Realtime (Optional but Recommended)

For real-time features like messaging and notifications:

1. Go to Database → Replication in your Supabase dashboard
2. Enable replication for these tables:
   - `messages`
   - `typing_indicators`
   - `notifications`
   - `conversation_participants`

### Step 4: Configure Authentication

1. Go to Authentication → Providers in your Supabase dashboard
2. Enable the following providers:
   - **Email** (already enabled by default)
   - **Google** (configure with your OAuth credentials)
   - **Apple** (configure with your Apple credentials)

#### Google OAuth Setup:
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create OAuth 2.0 credentials
3. Add authorized redirect URIs:
   - `https://your-project-id.supabase.co/auth/v1/callback`
   - `oasis://login-callback` (for mobile)
4. Copy Client ID and Client Secret to Supabase

#### Apple Sign In Setup:
1. Go to [Apple Developer](https://developer.apple.com)
2. Create a Sign in with Apple service
3. Configure your Service ID and Key
4. Add redirect URI: `https://your-project-id.supabase.co/auth/v1/callback`
5. Copy credentials to Supabase

## 📊 Database Schema Overview

### Core Tables

#### `profiles`
Extends `auth.users` with additional user information:
- Username, display name, bio, location
- Avatar URL, cover photo
- Follower/following/post counts
- Privacy settings

#### `posts`
User-generated content:
- Text content, images, videos
- Like/comment/share counts
- Community association
- Timestamps

#### `communities`
User-created communities:
- Name, description, theme
- Privacy settings, rules
- Member and post counts
- Creator and moderator info

#### `follows`
User following relationships:
- Follower → Following mapping
- Timestamps

#### `likes` & `bookmarks`
User interactions with posts:
- User → Post mapping
- Timestamps

#### `comments`
Post comments with threading:
- Parent comment support (replies)
- Like counts
- Edit/delete tracking

### Messaging Tables

#### `conversations`
Chat conversations (direct or group):
- Type (direct/group)
- Last message tracking
- Participant management

#### `messages`
Individual messages:
- Text, images, videos, files
- Reply-to support
- Edit/delete tracking
- Read receipts

#### `conversation_participants`
User participation in conversations:
- Unread counts
- Mute settings
- Last read timestamps

### Notification Tables

#### `notifications`
User notifications:
- Type (like, comment, follow, mention, etc.)
- Actor (who triggered the notification)
- Related content (post, comment, community)
- Read status

## 🔒 Security Features

### Row Level Security (RLS)

All tables have RLS enabled with policies that ensure:

1. **Privacy**: Users can only see content they're authorized to view
2. **Ownership**: Users can only modify their own content
3. **Community Access**: Community content respects privacy settings
4. **Message Privacy**: Only conversation participants can access messages

### Key Security Policies

- Public profiles are viewable by everyone
- Private profiles only viewable by followers
- Posts respect user privacy settings
- Messages only accessible to conversation participants
- Notifications only viewable by the recipient
- Community content respects community privacy settings

## 🔄 Automatic Updates

The database includes triggers for automatic updates:

### Count Updates
- Follower/following counts auto-update on follow/unfollow
- Post counts auto-update on post creation/deletion
- Like/comment counts auto-update on interactions
- Community member counts auto-update on join/leave

### Notifications
- Automatic notification creation for:
  - New likes
  - New comments
  - New followers
  - Mentions (future)
  - Community invites (future)

### Messaging
- Unread counts auto-increment on new messages
- Last message tracking auto-updates
- Conversation timestamps auto-update

## 📦 Storage Buckets

The following storage buckets are created:

1. **profile-pictures** (public)
   - User profile photos
   - Path: `{user_id}/{filename}`

2. **post-images** (public)
   - Post images
   - Path: `{user_id}/{filename}`

3. **post-videos** (public)
   - Post videos
   - Path: `{user_id}/{filename}`

4. **community-images** (public)
   - Community logos and covers
   - Path: `{community_id}/{filename}`

5. **message-attachments** (private)
   - Message files and media
   - Path: `{user_id}/{filename}`

## 🛠️ Utility Functions

### `get_feed_posts(user_id, limit, offset)`
Fetches feed posts for a user with pagination.

### `get_following_feed_posts(user_id, limit, offset)`
Fetches posts from users the current user follows.

### `get_user_conversations(user_id)`
Fetches all conversations for a user with last message info.

### `get_or_create_direct_conversation(user1_id, user2_id)`
Gets existing or creates new direct conversation between two users.

### `reset_unread_count(conversation_id, user_id)`
Resets unread message count for a user in a conversation.

### `delete_user_account()`
Safely deletes a user account and all related data.

## 🧪 Testing the Setup

After running all migrations, test the setup:

```sql
-- Check if all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Check storage buckets
SELECT * FROM storage.buckets;
```

## 🔧 Troubleshooting

### Issue: Migration fails with "relation already exists"
**Solution**: Some tables might already exist. You can either:
- Drop the existing tables (⚠️ this will delete data)
- Modify the migration to use `CREATE TABLE IF NOT EXISTS`

### Issue: RLS policies conflict
**Solution**: Drop existing policies before creating new ones:
```sql
DROP POLICY IF EXISTS "policy_name" ON table_name;
```

### Issue: Storage bucket already exists
**Solution**: The migrations use `ON CONFLICT DO NOTHING`, so this shouldn't be an issue. If it persists, check the storage dashboard.

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Realtime Guide](https://supabase.com/docs/guides/realtime)

## 🆘 Support

If you encounter issues:
1. Check the Supabase logs in your dashboard
2. Verify all migrations ran successfully
3. Ensure RLS is enabled on all tables
4. Check that storage buckets are created
5. Verify authentication providers are configured

## 📝 Notes

- All timestamps use `TIMESTAMPTZ` for timezone awareness
- UUIDs are used for all primary keys
- Indexes are created for frequently queried columns
- Cascading deletes ensure data integrity
- Triggers maintain count accuracy
- Functions are marked `SECURITY DEFINER` where needed for elevated privileges

