-- =====================================================
-- CLEANUP OLD SCHEMA
-- =====================================================
-- Run this FIRST if you've already run the old 20231115000000_initial_schema.sql
-- This will drop all old tables and types to start fresh

-- WARNING: This will delete ALL data in your database!
-- Only run this if you're okay with losing existing data.

-- Drop all triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS before_user_deleted ON auth.users;
DROP TRIGGER IF EXISTS handle_profiles_updated_at ON public.profiles;
DROP TRIGGER IF EXISTS handle_communities_updated_at ON public.communities;
DROP TRIGGER IF EXISTS handle_posts_updated_at ON public.posts;
DROP TRIGGER IF EXISTS handle_comments_updated_at ON public.comments;
DROP TRIGGER IF EXISTS handle_messages_updated_at ON public.messages;

-- Drop all functions
DROP FUNCTION IF EXISTS public.handle_updated_at();
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.handle_user_deleted();
DROP FUNCTION IF EXISTS public.get_user_feed(uuid, int, int);
DROP FUNCTION IF EXISTS public.get_user_notifications(uuid, int, int);

-- Drop all storage policies
DROP POLICY IF EXISTS "Profile pictures are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own profile picture" ON storage.objects;

-- Drop all RLS policies
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile." ON public.profiles;
DROP POLICY IF EXISTS "Communities are viewable by everyone." ON public.communities;
DROP POLICY IF EXISTS "Authenticated users can create communities" ON public.communities;
DROP POLICY IF EXISTS "Community creators can update their communities" ON public.communities;
DROP POLICY IF EXISTS "Public posts are viewable by everyone." ON public.posts;
DROP POLICY IF EXISTS "Users can create posts" ON public.posts;
DROP POLICY IF EXISTS "Users can update their own posts" ON public.posts;
DROP POLICY IF EXISTS "Users can delete their own posts" ON public.posts;

-- Drop all tables (in reverse order of dependencies)
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.message_reads CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.conversation_participants CASCADE;
DROP TABLE IF EXISTS public.conversations CASCADE;
DROP TABLE IF EXISTS public.reactions CASCADE;
DROP TABLE IF EXISTS public.comments CASCADE;
DROP TABLE IF EXISTS public.posts CASCADE;
DROP TABLE IF EXISTS public.community_members CASCADE;
DROP TABLE IF EXISTS public.communities CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Drop custom types
DROP TYPE IF EXISTS notification_type CASCADE;
DROP TYPE IF EXISTS reaction_type CASCADE;
DROP TYPE IF EXISTS post_type CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;

-- Drop storage buckets (optional - comment out if you want to keep uploaded files)
DELETE FROM storage.buckets WHERE id IN ('profile_pictures', 'post_media', 'community_media');

-- Note: Extensions are kept as they're harmless and may be used by other parts of Supabase
-- If you really want to remove them, uncomment the following:
-- DROP EXTENSION IF EXISTS "uuid-ossp" CASCADE;
-- DROP EXTENSION IF EXISTS "pgcrypto" CASCADE;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Old schema cleaned up successfully. You can now run the new migrations (001-007).';
END $$;

