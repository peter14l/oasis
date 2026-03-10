# Morrow V2 - Database Schema Diagram

## Entity Relationship Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CORE SOCIAL FEATURES                               │
└─────────────────────────────────────────────────────────────────────────────┘

auth.users (Supabase Auth)
    │
    │ (1:1)
    ▼
┌──────────────┐
│   profiles   │ ◄──────────────────────────────────────┐
├──────────────┤                                         │
│ id (PK)      │                                         │
│ username     │                                         │
│ email        │                                         │
│ full_name    │                                         │
│ avatar_url   │                                         │
│ bio          │                                         │
│ location     │                                         │
│ is_private   │                                         │
│ *_count      │                                         │
└──────────────┘                                         │
    │                                                    │
    │ (1:N)                                              │
    ▼                                                    │
┌──────────────┐         ┌──────────────┐               │
│    posts     │         │   follows    │               │
├──────────────┤         ├──────────────┤               │
│ id (PK)      │         │ id (PK)      │               │
│ user_id (FK) │         │ follower_id  │───────────────┘
│ content      │         │ following_id │───────────────┐
│ image_url    │         └──────────────┘               │
│ video_url    │                                        │
│ community_id │                                        │
│ *_count      │                                        │
└──────────────┘                                        │
    │                                                   │
    │ (1:N)                                             │
    ├──────────────┬──────────────┬──────────────┐     │
    ▼              ▼              ▼              ▼     │
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐│
│  likes   │  │bookmarks │  │ comments │  │  shares  ││
├──────────┤  ├──────────┤  ├──────────┤  ├──────────┤│
│ id (PK)  │  │ id (PK)  │  │ id (PK)  │  │ (future) ││
│ user_id  │  │ user_id  │  │ user_id  │  └──────────┘│
│ post_id  │  │ post_id  │  │ post_id  │              │
└──────────┘  └──────────┘  │ parent_id│              │
                            │ content  │              │
                            └──────────┘              │
                                │                     │
                                │ (1:N)               │
                                ▼                     │
                            ┌──────────────┐          │
                            │comment_likes │          │
                            ├──────────────┤          │
                            │ id (PK)      │          │
                            │ user_id      │          │
                            │ comment_id   │          │
                            └──────────────┘          │
                                                      │
┌─────────────────────────────────────────────────────┼──────────────────────┐
│                      COMMUNITIES                    │                      │
└─────────────────────────────────────────────────────┼──────────────────────┘
                                                      │
┌──────────────────┐                                  │
│   communities    │                                  │
├──────────────────┤                                  │
│ id (PK)          │                                  │
│ name             │                                  │
│ slug             │                                  │
│ description      │                                  │
│ image_url        │                                  │
│ creator_id (FK)  │──────────────────────────────────┘
│ is_private       │
│ members_count    │
│ posts_count      │
└──────────────────┘
    │
    │ (1:N)
    ▼
┌──────────────────────┐
│  community_members   │
├──────────────────────┤
│ id (PK)              │
│ community_id (FK)    │
│ user_id (FK)         │
│ role                 │ (member, moderator, admin)
└──────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                            MESSAGING SYSTEM                                  │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│   conversations      │
├──────────────────────┤
│ id (PK)              │
│ type                 │ (direct, group)
│ name                 │
│ image_url            │
│ created_by (FK)      │
│ last_message_id (FK) │
│ last_message_at      │
└──────────────────────┘
    │
    │ (1:N)
    ├──────────────────────┬──────────────────────┐
    ▼                      ▼                      ▼
┌──────────────────────┐ ┌──────────────┐ ┌──────────────────┐
│conversation_         │ │   messages   │ │typing_indicators │
│  participants        │ ├──────────────┤ ├──────────────────┤
├──────────────────────┤ │ id (PK)      │ │ id (PK)          │
│ id (PK)              │ │ conv_id (FK) │ │ conv_id (FK)     │
│ conversation_id (FK) │ │ sender_id    │ │ user_id (FK)     │
│ user_id (FK)         │ │ content      │ │ is_typing        │
│ role                 │ │ image_url    │ └──────────────────┘
│ last_read_at         │ │ video_url    │
│ unread_count         │ │ file_url     │
│ is_muted             │ │ reply_to_id  │
└──────────────────────┘ │ is_edited    │
                         │ is_deleted   │
                         └──────────────┘
                             │
                             │ (1:N)
                             ├──────────────────┬──────────────────┐
                             ▼                  ▼                  ▼
                    ┌──────────────────┐ ┌──────────────┐ ┌──────────────┐
                    │message_read_     │ │message_      │ │   (future)   │
                    │  receipts        │ │ reactions    │ │              │
                    ├──────────────────┤ ├──────────────┤ └──────────────┘
                    │ id (PK)          │ │ id (PK)      │
                    │ message_id (FK)  │ │ message_id   │
                    │ user_id (FK)     │ │ user_id      │
                    │ read_at          │ │ emoji        │
                    └──────────────────┘ └──────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           NOTIFICATIONS                                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│  notifications   │
├──────────────────┤
│ id (PK)          │
│ user_id (FK)     │ ──► Recipient
│ actor_id (FK)    │ ──► Who triggered it
│ type             │ ──► like, comment, follow, mention, etc.
│ post_id (FK)     │ ──► Related post (optional)
│ comment_id (FK)  │ ──► Related comment (optional)
│ community_id     │ ──► Related community (optional)
│ content          │ ──► Notification text
│ is_read          │
│ created_at       │
└──────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                          STORAGE BUCKETS                                     │
└─────────────────────────────────────────────────────────────────────────────┘

storage.buckets
├── profile-pictures (public)
│   └── {user_id}/
│       └── {filename}
│
├── post-images (public)
│   └── {user_id}/
│       └── {filename}
│
├── post-videos (public)
│   └── {user_id}/
│       └── {filename}
│
├── community-images (public)
│   └── {community_id}/
│       └── {filename}
│
└── message-attachments (private)
    └── {user_id}/
        └── {filename}
```

## Table Relationships

### One-to-One (1:1)
- `auth.users` ↔ `profiles` - Each auth user has one profile

### One-to-Many (1:N)
- `profiles` → `posts` - User can have many posts
- `profiles` → `comments` - User can have many comments
- `profiles` → `likes` - User can like many posts
- `profiles` → `bookmarks` - User can bookmark many posts
- `profiles` → `communities` - User can create many communities
- `profiles` → `community_members` - User can join many communities
- `profiles` → `notifications` - User can have many notifications
- `posts` → `comments` - Post can have many comments
- `posts` → `likes` - Post can have many likes
- `posts` → `bookmarks` - Post can be bookmarked by many users
- `comments` → `comment_likes` - Comment can have many likes
- `comments` → `comments` - Comment can have many replies (self-referencing)
- `communities` → `community_members` - Community can have many members
- `communities` → `posts` - Community can have many posts
- `conversations` → `messages` - Conversation can have many messages
- `conversations` → `conversation_participants` - Conversation can have many participants
- `messages` → `message_read_receipts` - Message can have many read receipts
- `messages` → `message_reactions` - Message can have many reactions

### Many-to-Many (M:N)
- `profiles` ↔ `profiles` (via `follows`) - Users can follow each other
- `profiles` ↔ `communities` (via `community_members`) - Users can join communities
- `profiles` ↔ `conversations` (via `conversation_participants`) - Users can be in conversations

## Key Indexes

### Performance Indexes
```sql
-- Profiles
idx_profiles_username
idx_profiles_email
idx_profiles_created_at

-- Posts
idx_posts_user_id
idx_posts_community_id
idx_posts_created_at
idx_posts_is_pinned

-- Communities
idx_communities_slug
idx_communities_creator_id
idx_communities_members_count

-- Follows
idx_follows_follower_id
idx_follows_following_id

-- Likes
idx_likes_user_id
idx_likes_post_id

-- Comments
idx_comments_post_id
idx_comments_user_id
idx_comments_parent_comment_id

-- Messages
idx_messages_conversation_id
idx_messages_sender_id
idx_messages_created_at

-- Notifications
idx_notifications_user_id
idx_notifications_is_read
idx_notifications_type
```

## Automatic Triggers

### Count Updates
- `likes` INSERT/DELETE → updates `posts.likes_count`
- `comments` INSERT/DELETE → updates `posts.comments_count`
- `comment_likes` INSERT/DELETE → updates `comments.likes_count`
- `follows` INSERT/DELETE → updates `profiles.followers_count` & `following_count`
- `posts` INSERT/DELETE → updates `profiles.posts_count`
- `community_members` INSERT/DELETE → updates `communities.members_count`
- `messages` INSERT → updates `conversation_participants.unread_count`

### Timestamp Updates
- All tables with `updated_at` auto-update on UPDATE

### Notification Creation
- `likes` INSERT → creates notification for post owner
- `comments` INSERT → creates notification for post owner & parent comment author
- `follows` INSERT → creates notification for followed user

### Profile Creation
- `auth.users` INSERT → creates profile in `profiles` table

## Security (RLS Policies)

### Public Access
- Public profiles viewable by everyone
- Public communities viewable by everyone
- Public posts viewable by everyone

### Private Access
- Private profiles only viewable by followers
- Private communities only viewable by members
- Messages only viewable by conversation participants
- Notifications only viewable by recipient
- Bookmarks only viewable by owner

### Ownership
- Users can only update/delete their own content
- Community creators/admins can manage communities
- Conversation admins can manage conversations

## Realtime Channels

Enable realtime for these tables:
- `messages` - Real-time chat
- `typing_indicators` - Typing status
- `notifications` - Instant notifications
- `conversation_participants` - Unread counts

## Utility Functions

### Feed Functions
- `get_feed_posts(user_id, limit, offset)` - Get personalized feed
- `get_following_feed_posts(user_id, limit, offset)` - Get following feed

### Messaging Functions
- `get_user_conversations(user_id)` - Get all conversations with details
- `get_or_create_direct_conversation(user1_id, user2_id)` - Get/create DM
- `reset_unread_count(conversation_id, user_id)` - Mark messages as read

### Account Functions
- `delete_user_account()` - Safely delete account and all data

## Data Flow Examples

### Creating a Post
```
1. User uploads image → post-images bucket
2. User creates post → posts table
3. Trigger increments → profiles.posts_count
4. If in community → communities.posts_count increments
```

### Liking a Post
```
1. User likes post → likes table
2. Trigger increments → posts.likes_count
3. Trigger creates → notification for post owner
```

### Sending a Message
```
1. User sends message → messages table
2. Trigger updates → conversations.last_message_id & last_message_at
3. Trigger increments → conversation_participants.unread_count (for others)
4. Realtime broadcasts → message to all participants
```

### Following a User
```
1. User follows → follows table
2. Trigger increments → profiles.followers_count (followed user)
3. Trigger increments → profiles.following_count (follower)
4. Trigger creates → notification for followed user
```

## Notes

- All IDs are UUIDs for security and scalability
- All timestamps use TIMESTAMPTZ for timezone awareness
- Cascading deletes ensure data integrity
- Unique constraints prevent duplicates
- Check constraints ensure data validity
- Indexes optimize query performance

