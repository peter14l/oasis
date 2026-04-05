# Supabase Setup Checklist

Use this checklist to ensure your Supabase backend is properly configured.

## 📝 Pre-Setup

- [ ] Create a Supabase project at [supabase.com](https://supabase.com)
- [ ] Note down your project URL and anon key
- [ ] Update `.env` file in your Flutter project root

## 🗄️ Database Setup

### Run SQL Migrations (in order)

- [ ] **001_initial_schema.sql**
  - Creates: profiles, posts, communities, community_members, follows, likes, bookmarks, comments, comment_likes, notifications
  - Verify: Check that all tables exist in Database → Tables

- [ ] **002_messaging_schema.sql**
  - Creates: conversations, conversation_participants, messages, message_read_receipts, message_reactions, typing_indicators
  - Verify: Check that messaging tables exist

- [ ] **003_rls_policies.sql**
  - Creates: RLS policies for core tables
  - Verify: Go to Database → Tables → Select a table → Policies tab

- [ ] **004_messaging_rls_policies.sql**
  - Creates: RLS policies for messaging tables
  - Verify: Check policies on messaging tables

- [ ] **005_triggers_and_functions.sql**
  - Creates: Triggers for auto-updates (counts, timestamps)
  - Verify: Go to Database → Functions

- [ ] **006_notification_triggers.sql**
  - Creates: Notification triggers and utility functions
  - Verify: Check functions like `get_feed_posts`, `get_user_conversations`

- [ ] **007_storage_setup.sql**
  - Creates: Storage buckets and policies
  - Verify: Go to Storage → Check for 5 buckets

## 🔐 Authentication Setup

### Email Authentication
- [ ] Already enabled by default
- [ ] Test: Try signing up with email/password

### Google OAuth
- [ ] Go to Authentication → Providers → Google
- [ ] Enable Google provider
- [ ] Add your Google OAuth credentials:
  - Client ID
  - Client Secret
- [ ] Add authorized redirect URIs:
  - `https://[YOUR-PROJECT-ID].supabase.co/auth/v1/callback`
  - `oasis://login-callback`
- [ ] Test: Try signing in with Google

### Apple Sign In
- [ ] Go to Authentication → Providers → Apple
- [ ] Enable Apple provider
- [ ] Add your Apple credentials:
  - Service ID
  - Team ID
  - Key ID
  - Private Key
- [ ] Add redirect URI:
  - `https://[YOUR-PROJECT-ID].supabase.co/auth/v1/callback`
- [ ] Test: Try signing in with Apple

## 📡 Realtime Setup

Enable realtime for these tables (Database → Replication):

- [ ] **messages** - For real-time chat
- [ ] **typing_indicators** - For typing status
- [ ] **notifications** - For instant notifications
- [ ] **conversation_participants** - For unread counts

## 💾 Storage Setup

Verify storage buckets exist (Storage tab):

- [ ] **profile-pictures** (public)
- [ ] **post-images** (public)
- [ ] **post-videos** (public)
- [ ] **community-images** (public)
- [ ] **message-attachments** (private)

## 🔍 Verification Tests

Run these SQL queries to verify setup:

### 1. Check all tables exist
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```
Expected: 16 tables

### 2. Check RLS is enabled
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```
Expected: All tables should have `rowsecurity = true`

### 3. Check storage buckets
```sql
SELECT * FROM storage.buckets;
```
Expected: 5 buckets

### 4. Check functions exist
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name;
```
Expected: Multiple functions including:
- `get_feed_posts`
- `get_following_feed_posts`
- `get_user_conversations`
- `get_or_create_direct_conversation`
- `delete_user_account`

### 5. Test profile creation trigger
```sql
-- This should automatically create a profile when a user signs up
-- Test by signing up a new user and checking the profiles table
SELECT * FROM public.profiles;
```

## 🧪 Manual Testing

### Test Authentication
- [ ] Sign up with email/password
- [ ] Verify profile is created in `profiles` table
- [ ] Sign out
- [ ] Sign in with same credentials
- [ ] Try Google Sign In (if configured)
- [ ] Try Apple Sign In (if configured)

### Test Database Operations
- [ ] Create a test post via SQL:
```sql
INSERT INTO public.posts (user_id, content)
VALUES (
  (SELECT id FROM public.profiles LIMIT 1),
  'Test post content'
);
```
- [ ] Verify post appears in `posts` table
- [ ] Verify `posts_count` incremented in `profiles` table

### Test RLS Policies
- [ ] Try to view posts as authenticated user (should work)
- [ ] Try to view another user's private data (should fail)
- [ ] Try to update another user's post (should fail)

### Test Storage
- [ ] Upload a test image to `profile-pictures` bucket
- [ ] Verify it's publicly accessible
- [ ] Try to upload to another user's folder (should fail)

## 🚨 Common Issues & Solutions

### Issue: "relation already exists"
**Solution**: Table already exists. Either drop it or skip that part of the migration.

### Issue: "permission denied for schema public"
**Solution**: Make sure you're running migrations as the postgres user or with proper permissions.

### Issue: RLS policies blocking all access
**Solution**: Check that policies are correctly written and that `auth.uid()` is working.

### Issue: Storage upload fails
**Solution**: 
1. Check bucket exists
2. Verify storage policies are created
3. Check file size limits
4. Verify user is authenticated

### Issue: Realtime not working
**Solution**:
1. Verify replication is enabled for the table
2. Check that you're subscribed to the correct channel
3. Verify RLS policies allow SELECT on the table

## 📊 Performance Optimization (Optional)

After basic setup is complete:

- [ ] Add additional indexes for frequently queried columns
- [ ] Configure connection pooling (for high traffic)
- [ ] Set up database backups
- [ ] Configure point-in-time recovery
- [ ] Set up monitoring and alerts

## 🔒 Security Checklist

- [ ] RLS is enabled on all tables
- [ ] Storage policies are configured correctly
- [ ] API keys are stored in `.env` (not committed to git)
- [ ] `.env` is in `.gitignore`
- [ ] Authentication providers are properly configured
- [ ] Rate limiting is configured (in Supabase dashboard)

## 📱 Flutter App Configuration

After Supabase setup is complete:

- [ ] Update `.env` file with Supabase URL and anon key
- [ ] Verify `lib/config/supabase_config.dart` has correct table names
- [ ] Test authentication flow in app
- [ ] Test data fetching in app
- [ ] Test real-time features in app

## ✅ Final Verification

- [ ] All migrations ran successfully
- [ ] All tables exist with correct schema
- [ ] RLS policies are in place
- [ ] Storage buckets are created
- [ ] Authentication providers are configured
- [ ] Realtime is enabled for required tables
- [ ] Test user can sign up and sign in
- [ ] Test data can be created and fetched
- [ ] App connects to Supabase successfully

## 🎉 You're Ready!

Once all items are checked, your Supabase backend is ready for development!

Next steps:
1. Implement services in Flutter app
2. Connect screens to real data
3. Test all features
4. Deploy to production

---

**Need Help?**
- Supabase Discord: https://discord.supabase.com
- Supabase Docs: https://supabase.com/docs
- GitHub Issues: Create an issue in your repo

