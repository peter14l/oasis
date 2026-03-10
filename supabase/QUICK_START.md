# 🚀 Quick Start Guide - Supabase Setup

This is a streamlined guide to get your Supabase backend up and running in ~30 minutes.

## Prerequisites

- [ ] Supabase account (sign up at [supabase.com](https://supabase.com))
- [ ] Supabase project created
- [ ] Project URL and anon key ready

## ⚠️ Important: If You've Run Old Migrations

**If you've already run `20231115000000_initial_schema.sql`:**

You need to clean up the old schema first! The new schema is significantly different and improved.

👉 **See `MIGRATION_FROM_OLD_SCHEMA.md` for detailed instructions**

**Quick version:**
1. Run `000_cleanup_old_schema.sql` first (⚠️ deletes all data!)
2. Then continue with steps below

**If this is a fresh database:** Continue with Step 1 below.

## Step-by-Step Setup

### 1️⃣ Run Database Migrations (15 min)

Open your Supabase Dashboard → SQL Editor and run these files **in order**:

#### Migration 1: Initial Schema
```sql
-- Copy and paste content from: 001_initial_schema.sql
-- Creates: profiles, posts, communities, follows, likes, bookmarks, comments, notifications
```
✅ Verify: Go to Database → Tables, you should see 10 new tables

#### Migration 2: Messaging Schema
```sql
-- Copy and paste content from: 002_messaging_schema.sql
-- Creates: conversations, messages, participants, read receipts, reactions, typing indicators
```
✅ Verify: You should now have 16 total tables

#### Migration 3: Core RLS Policies
```sql
-- Copy and paste content from: 003_rls_policies.sql
-- Creates: Security policies for core tables
```
✅ Verify: Go to any table → Policies tab, you should see policies

#### Migration 4: Messaging RLS Policies
```sql
-- Copy and paste content from: 004_messaging_rls_policies.sql
-- Creates: Security policies for messaging tables
```
✅ Verify: Check messaging tables have policies

#### Migration 5: Triggers & Functions
```sql
-- Copy and paste content from: 005_triggers_and_functions.sql
-- Creates: Auto-update triggers for counts and timestamps
```
✅ Verify: Go to Database → Functions, you should see multiple functions

#### Migration 6: Notification Triggers
```sql
-- Copy and paste content from: 006_notification_triggers.sql
-- Creates: Notification triggers and utility functions
```
✅ Verify: Check functions include get_feed_posts, get_user_conversations

#### Migration 7: Storage Setup
```sql
-- Copy and paste content from: 007_storage_setup.sql
-- Creates: Storage buckets and policies
```
✅ Verify: Go to Storage, you should see 5 buckets

### 2️⃣ Configure Authentication (10 min)

#### Enable Email Auth (Already Done)
Email authentication is enabled by default ✅

#### Enable Google OAuth
1. Go to **Authentication → Providers → Google**
2. Toggle **Enable Sign in with Google**
3. Add your credentials:
   - **Client ID**: `your-google-client-id`
   - **Client Secret**: `your-google-client-secret`
4. Add authorized redirect URI:
   ```
   https://[YOUR-PROJECT-ID].supabase.co/auth/v1/callback
   ```
5. Click **Save**

**Don't have Google OAuth credentials?**
- Go to [Google Cloud Console](https://console.cloud.google.com)
- Create OAuth 2.0 credentials
- Add redirect URI above
- Copy Client ID and Secret

#### Enable Apple Sign In (Optional)
1. Go to **Authentication → Providers → Apple**
2. Toggle **Enable Sign in with Apple**
3. Add your credentials:
   - **Service ID**: `your-service-id`
   - **Team ID**: `your-team-id`
   - **Key ID**: `your-key-id`
   - **Private Key**: `your-private-key`
4. Add redirect URI:
   ```
   https://[YOUR-PROJECT-ID].supabase.co/auth/v1/callback
   ```
5. Click **Save**

### 3️⃣ Enable Realtime (5 min)

1. Go to **Database → Replication**
2. Find and enable these tables:
   - [ ] `messages`
   - [ ] `typing_indicators`
   - [ ] `notifications`
   - [ ] `conversation_participants`
3. Click **Save**

### 4️⃣ Update Your .env File (2 min)

1. Go to **Settings → API** in Supabase Dashboard
2. Copy your **Project URL** and **anon public** key
3. Update your `.env` file in the Flutter project root:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

4. Make sure `.env` is in your `.gitignore`

### 5️⃣ Verify Setup (5 min)

#### Test 1: Check Tables
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```
Expected: 16 tables

#### Test 2: Check RLS
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```
Expected: All tables have `rowsecurity = true`

#### Test 3: Check Storage
Go to **Storage** tab
Expected: 5 buckets (profile-pictures, post-images, post-videos, community-images, message-attachments)

#### Test 4: Check Functions
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name;
```
Expected: Multiple functions including get_feed_posts, get_user_conversations

#### Test 5: Test Authentication
1. Go to **Authentication → Users**
2. Click **Add User** (or use your app to sign up)
3. Check that a profile is auto-created in the `profiles` table

## ✅ Setup Complete!

If all tests pass, your Supabase backend is ready! 🎉

## What's Next?

### Option 1: Test in Supabase Dashboard
Try creating some test data:

```sql
-- Create a test post (replace user_id with your test user's ID)
INSERT INTO posts (user_id, content)
VALUES ('your-user-id-here', 'My first post!');

-- Check if it worked
SELECT * FROM posts;

-- Check if post count incremented
SELECT username, posts_count FROM profiles;
```

### Option 2: Connect Your Flutter App
1. Make sure `.env` is updated with your Supabase credentials
2. Run your Flutter app: `flutter run`
3. Try signing up/logging in
4. Check if profile is created in Supabase

### Option 3: Start Phase 3
Follow the `IMPLEMENTATION_GUIDE.md` to start implementing real features in your Flutter app.

## 🆘 Troubleshooting

### Migration Fails
**Error**: "relation already exists"
**Fix**: Table already exists. Either drop it or skip that part.

**Error**: "permission denied"
**Fix**: Make sure you're running as postgres user or with proper permissions.

### Authentication Not Working
**Error**: "Invalid login credentials"
**Fix**: 
1. Check that user exists in Authentication → Users
2. Verify email/password are correct
3. Check if email confirmation is required

**Error**: "Google sign in failed"
**Fix**:
1. Verify Google OAuth credentials are correct
2. Check redirect URI matches exactly
3. Make sure Google OAuth is enabled in Google Cloud Console

### Storage Upload Fails
**Error**: "Storage upload failed"
**Fix**:
1. Verify bucket exists in Storage tab
2. Check storage policies are created
3. Verify user is authenticated
4. Check file size (default limit is 50MB)

### Realtime Not Working
**Error**: "Realtime updates not received"
**Fix**:
1. Verify replication is enabled for the table
2. Check RLS policies allow SELECT on the table
3. Verify you're subscribed to the correct channel

## 📊 Quick Reference

### Your Supabase URLs
```
Dashboard: https://app.supabase.com/project/[YOUR-PROJECT-ID]
API URL: https://[YOUR-PROJECT-ID].supabase.co
Storage: https://[YOUR-PROJECT-ID].supabase.co/storage/v1
```

### Important Tables
- `profiles` - User profiles
- `posts` - User posts
- `communities` - Communities
- `messages` - Chat messages
- `notifications` - User notifications

### Important Functions
- `get_feed_posts(user_id, limit, offset)` - Get feed
- `get_user_conversations(user_id)` - Get chats
- `get_or_create_direct_conversation(user1_id, user2_id)` - Start DM

### Storage Buckets
- `profile-pictures` - User avatars
- `post-images` - Post images
- `post-videos` - Post videos
- `community-images` - Community logos
- `message-attachments` - Message files

## 📚 More Help

- **Detailed Setup**: See `README.md`
- **Setup Checklist**: See `SETUP_CHECKLIST.md`
- **Database Diagram**: See `DATABASE_DIAGRAM.md`
- **Implementation Guide**: See `../IMPLEMENTATION_GUIDE.md`

## 🎯 Success Checklist

- [ ] All 7 migrations ran successfully
- [ ] 16 tables exist in database
- [ ] RLS is enabled on all tables
- [ ] 5 storage buckets created
- [ ] Email auth works
- [ ] Google OAuth configured (optional)
- [ ] Apple Sign In configured (optional)
- [ ] Realtime enabled for 4 tables
- [ ] .env file updated
- [ ] Test user can sign up
- [ ] Profile auto-created on signup

## 🎉 You're Ready!

Once all items are checked, you're ready to start building features!

Next: Open `../IMPLEMENTATION_GUIDE.md` and start Phase 3.

---

**Need more help?** Check the other documentation files or visit [Supabase Discord](https://discord.supabase.com).

