# Migration Guide: Old Schema to New Schema

## Overview

You've already run the old migration file `20231115000000_initial_schema.sql`. The new schema (001-007) is significantly different and improved. This guide will help you migrate.

## Key Differences

### Old Schema Issues
- ❌ Uses custom ENUM types (harder to modify)
- ❌ Generic `reactions` table (not optimized)
- ❌ Missing important tables (follows, bookmarks, typing_indicators, etc.)
- ❌ Incomplete RLS policies
- ❌ Fewer automatic triggers
- ❌ Less comprehensive messaging system

### New Schema Benefits
- ✅ Uses TEXT with CHECK constraints (more flexible)
- ✅ Separate `likes` and `bookmarks` tables (better performance)
- ✅ Complete social features (follows, notifications, etc.)
- ✅ Comprehensive RLS policies
- ✅ Automatic count updates via triggers
- ✅ Full-featured messaging with read receipts, reactions, typing indicators
- ✅ Better organized (7 separate migration files)
- ✅ More utility functions

## Migration Options

### Option 1: Clean Slate (RECOMMENDED for Development)

**Best if:**
- You don't have important data yet
- You're still in development
- You want the cleanest setup

**Steps:**
1. Run `000_cleanup_old_schema.sql` to drop everything
2. Run migrations 001-007 in order
3. Reconfigure authentication providers
4. Re-enable realtime

**Time:** ~20 minutes

### Option 2: Keep Old Schema (NOT RECOMMENDED)

**Best if:**
- You have production data you can't lose
- You need time to plan a proper migration

**Drawbacks:**
- Missing many features
- Incompatible with new Flutter code
- Will need to migrate eventually anyway

## Recommended: Clean Slate Migration

### Step 1: Backup (Optional but Recommended)

If you have any data you want to keep:

```sql
-- Export profiles
COPY (SELECT * FROM public.profiles) TO '/tmp/profiles_backup.csv' CSV HEADER;

-- Export posts
COPY (SELECT * FROM public.posts) TO '/tmp/posts_backup.csv' CSV HEADER;

-- Export communities
COPY (SELECT * FROM public.communities) TO '/tmp/communities_backup.csv' CSV HEADER;
```

Or use Supabase Dashboard:
1. Go to Database → Backups
2. Create a manual backup

### Step 2: Clean Up Old Schema

Run this in Supabase SQL Editor:

```sql
-- Copy and paste content from: 000_cleanup_old_schema.sql
```

This will:
- Drop all old triggers
- Drop all old functions
- Drop all old policies
- Drop all old tables
- Drop all custom types
- Clean up storage buckets

**⚠️ WARNING: This deletes ALL data!**

### Step 3: Run New Migrations

Run these in order in Supabase SQL Editor:

1. **001_initial_schema.sql**
   - Creates core tables with better structure
   - Adds proper indexes
   - Sets up foreign keys

2. **002_messaging_schema.sql**
   - Creates comprehensive messaging system
   - Adds read receipts, reactions, typing indicators

3. **003_rls_policies.sql**
   - Sets up security for core tables
   - Privacy-respecting policies

4. **004_messaging_rls_policies.sql**
   - Sets up security for messaging
   - Participant-based access

5. **005_triggers_and_functions.sql**
   - Auto-update triggers for counts
   - Timestamp triggers
   - Profile creation trigger

6. **006_notification_triggers.sql**
   - Notification auto-creation
   - Utility functions (get_feed_posts, etc.)

7. **007_storage_setup.sql**
   - Creates 5 storage buckets
   - Sets up storage policies

### Step 4: Verify New Schema

```sql
-- Check tables (should be 16)
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Check storage buckets (should be 5)
SELECT * FROM storage.buckets;

-- Check functions
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name;
```

### Step 5: Reconfigure

1. **Authentication Providers**
   - Re-enable Google OAuth
   - Re-enable Apple Sign In
   - Add redirect URIs

2. **Realtime**
   - Enable for: messages, typing_indicators, notifications, conversation_participants

3. **Test**
   - Sign up a test user
   - Verify profile is created
   - Try creating a post
   - Check counts update

### Step 6: Restore Data (If Needed)

If you backed up data in Step 1:

```sql
-- Restore profiles (adjust as needed for new schema)
-- Note: You'll need to map old columns to new columns

-- Example:
INSERT INTO public.profiles (id, username, email, full_name, bio, avatar_url, location, is_private)
SELECT id, username, email, full_name, bio, avatar_url, location, is_private
FROM old_profiles_backup;
```

## Schema Mapping Guide

If you need to migrate data, here's how old columns map to new:

### Profiles
```
Old → New
-----------
id → id (same)
username → username (same)
full_name → full_name (same)
bio → bio (same)
avatar_url → avatar_url (same)
website → website (same)
location → location (same)
is_private → is_private (same)
role → (removed - not needed)
created_at → created_at (same)
updated_at → updated_at (same)

New columns added:
- email
- followers_count
- following_count
- posts_count
- is_verified
```

### Posts
```
Old → New
-----------
id → id (same)
user_id → user_id (same)
community_id → community_id (same)
title → (removed)
content → content (same)
post_type → (removed - inferred from content)
media_urls[0] → image_url
media_urls[1] → video_url (if video)
is_nsfw → (removed)
is_locked → (removed)
is_archived → (removed)
is_pinned → is_pinned (same)
created_at → created_at (same)
updated_at → updated_at (same)

New columns added:
- likes_count
- comments_count
- shares_count
- views_count
```

### Communities
```
Old → New
-----------
id → id (same)
name → name (same)
slug → slug (same)
description → description (same)
avatar_url → image_url
banner_url → cover_url
is_private → is_private (same)
is_restricted → (removed)
creator_id → creator_id (same)
created_at → created_at (same)
updated_at → updated_at (same)

New columns added:
- theme
- rules
- privacy_policy
- members_count
- posts_count
```

### Reactions → Likes
```
Old reactions table → New likes table
--------------------------------------
Only migrate reactions where reaction_type = 'like' and post_id is not null

INSERT INTO public.likes (user_id, post_id, created_at)
SELECT user_id, post_id, created_at
FROM old_reactions
WHERE post_id IS NOT NULL AND reaction_type = 'like';
```

### Messages
```
Old → New
-----------
id → id (same)
conversation_id → conversation_id (same)
user_id → sender_id
content → content (same)
media_urls[0] → image_url
media_urls[1] → video_url
is_edited → is_edited (same)
created_at → created_at (same)
updated_at → updated_at (same)

New columns added:
- file_url
- file_name
- file_size
- reply_to_id
- is_deleted
```

## Post-Migration Checklist

- [ ] All 16 tables exist
- [ ] RLS is enabled on all tables
- [ ] 5 storage buckets created
- [ ] Functions exist (get_feed_posts, etc.)
- [ ] Triggers are working (test by creating a post, check counts)
- [ ] Authentication providers configured
- [ ] Realtime enabled for required tables
- [ ] Test user can sign up
- [ ] Profile auto-created on signup
- [ ] Can create posts
- [ ] Counts auto-update
- [ ] Notifications auto-created

## Troubleshooting

### Error: "relation already exists"
**Solution:** Run `000_cleanup_old_schema.sql` first

### Error: "type already exists"
**Solution:** The cleanup script should have removed types. Run:
```sql
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS post_type CASCADE;
DROP TYPE IF EXISTS reaction_type CASCADE;
DROP TYPE IF EXISTS notification_type CASCADE;
```

### Error: "policy already exists"
**Solution:** Drop old policies manually or run cleanup script

### Data Loss
**Solution:** Restore from backup created in Step 1

## Need Help?

- Check `supabase/README.md` for detailed setup guide
- Check `supabase/SETUP_CHECKLIST.md` for verification steps
- Check `supabase/QUICK_START.md` for streamlined setup

## Summary

**Recommended Path:**
1. ✅ Run `000_cleanup_old_schema.sql`
2. ✅ Run migrations 001-007 in order
3. ✅ Reconfigure auth and realtime
4. ✅ Test everything works
5. ✅ Start Phase 3 implementation

**Time Required:** ~30 minutes

**Result:** Clean, production-ready database with all features!

