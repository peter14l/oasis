-- =====================================================
-- MORROW V2 - DATABASE HARD RESET SCRIPT
-- =====================================================
-- This script wipes all user data and related content.
-- Run this in your Supabase SQL Editor.

BEGIN;

-- 1. Disable triggers to prevent unnecessary notification/count logic during wipe
SET session_replication_role = 'replica';

-- 2. Clear Social & Community Data
TRUNCATE TABLE public.likes CASCADE;
TRUNCATE TABLE public.bookmarks CASCADE;
TRUNCATE TABLE public.comments CASCADE;
TRUNCATE TABLE public.comment_likes CASCADE;
TRUNCATE TABLE public.follows CASCADE;
TRUNCATE TABLE public.notifications CASCADE;
TRUNCATE TABLE public.posts CASCADE;
TRUNCATE TABLE public.stories CASCADE;
TRUNCATE TABLE public.time_capsules CASCADE;

-- 3. Clear Messaging & Encryption Data
TRUNCATE TABLE public.messages CASCADE;
TRUNCATE TABLE public.message_reactions CASCADE;
TRUNCATE TABLE public.message_read_receipts CASCADE;
TRUNCATE TABLE public.conversation_participants CASCADE;
TRUNCATE TABLE public.conversations CASCADE;
TRUNCATE TABLE public.chat_themes CASCADE;
TRUNCATE TABLE public.signal_keys CASCADE; -- Deletes all Signal Pre-Keys/Bundles
TRUNCATE TABLE public.typing_indicators CASCADE;

-- 4. Clear Feature Specific Data
TRUNCATE TABLE public.calls CASCADE;
TRUNCATE TABLE public.call_participants CASCADE;
TRUNCATE TABLE public.study_sessions CASCADE;
TRUNCATE TABLE public.study_session_participants CASCADE;

-- 5. Clear Canvases & Circles
TRUNCATE TABLE public.canvas_items CASCADE;
TRUNCATE TABLE public.canvas_members CASCADE;
TRUNCATE TABLE public.canvases CASCADE;
TRUNCATE TABLE public.commitment_responses CASCADE;
TRUNCATE TABLE public.commitments CASCADE;
TRUNCATE TABLE public.circle_members CASCADE;
TRUNCATE TABLE public.circles CASCADE;
TRUNCATE TABLE public.community_members CASCADE;
TRUNCATE TABLE public.communities CASCADE;

-- 6. Wipe Profiles and Auth Users
-- Deleting from auth.users will cascade to public.profiles via established foreign keys.
DELETE FROM auth.users;

-- 7. Re-enable triggers
SET session_replication_role = 'origin';

COMMIT;

-- Print Success
DO $$ BEGIN
    RAISE NOTICE 'Database reset complete. All users and related data have been purged.';
END $$;
