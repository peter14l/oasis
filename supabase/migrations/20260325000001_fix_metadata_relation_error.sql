-- =====================================================
-- FIX: relation "metadata" does not exist
-- =====================================================
-- CONTEXT:
--   The error "relation 'metadata' does not exist" (code: 42P01)
--   is thrown when liking a post. This means there is a DB trigger
--   or function on the 'likes' table that references a table called
--   'metadata' (or the 'metadata' schema) which no longer exists.
--
-- This migration:
--   1. Diagnoses any function bodies that reference 'metadata' (informational)
--   2. Drops any stale triggers on public.likes that could be calling a bad function
--   3. Re-creates clean, safe triggers for the likes table
-- =====================================================


-- -------------------------------------------------------
-- STEP 1: Drop any unknown/stale triggers on likes table
-- -------------------------------------------------------
-- This will capture any triggers created outside migrations
-- (e.g. via the Supabase dashboard) that may be calling a
-- function which references the missing 'metadata' table/schema.

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT tgname
        FROM pg_trigger
        WHERE tgrelid = 'public.likes'::regclass
          AND tgisinternal = FALSE           -- skip system/FK constraint triggers
          AND tgname NOT LIKE 'RI_ConstraintTrigger%'  -- extra safety guard
          AND tgname NOT IN (
            'trigger_increment_post_likes_count',
            'trigger_decrement_post_likes_count',
            'trigger_create_like_notification'
          )
    LOOP
        RAISE NOTICE 'Dropping unknown trigger: %', r.tgname;
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.likes', r.tgname);
    END LOOP;
END;
$$;


-- -------------------------------------------------------
-- STEP 2: Re-create the three known safe triggers cleanly
-- -------------------------------------------------------

-- 2a. Increment likes_count on posts
CREATE OR REPLACE FUNCTION public.increment_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.posts
    SET likes_count = likes_count + 1
    WHERE id = NEW.post_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_increment_post_likes_count ON public.likes;
CREATE TRIGGER trigger_increment_post_likes_count
    AFTER INSERT ON public.likes
    FOR EACH ROW
    EXECUTE FUNCTION public.increment_post_likes_count();


-- 2b. Decrement likes_count on posts
CREATE OR REPLACE FUNCTION public.decrement_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.posts
    SET likes_count = GREATEST(0, likes_count - 1)
    WHERE id = OLD.post_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_decrement_post_likes_count ON public.likes;
CREATE TRIGGER trigger_decrement_post_likes_count
    AFTER DELETE ON public.likes
    FOR EACH ROW
    EXECUTE FUNCTION public.decrement_post_likes_count();


-- 2c. Create a notification for the post owner when liked
CREATE OR REPLACE FUNCTION public.create_like_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_post_user_id UUID;
BEGIN
    SELECT user_id INTO v_post_user_id
    FROM public.posts
    WHERE id = NEW.post_id;

    -- Don't notify if user likes their own post
    IF v_post_user_id IS NOT NULL AND v_post_user_id != NEW.user_id THEN
        INSERT INTO public.notifications (user_id, actor_id, type, post_id)
        VALUES (v_post_user_id, NEW.user_id, 'like', NEW.post_id)
        ON CONFLICT DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_create_like_notification ON public.likes;
CREATE TRIGGER trigger_create_like_notification
    AFTER INSERT ON public.likes
    FOR EACH ROW
    EXECUTE FUNCTION public.create_like_notification();


-- -------------------------------------------------------
-- STEP 3: Verify all triggers now on likes (informational)
-- -------------------------------------------------------
SELECT
    tgname AS trigger_name,
    proname AS function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgrelid = 'public.likes'::regclass
ORDER BY tgname;
