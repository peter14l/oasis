-- =====================================================
-- FIX: relation "metadata" does not exist
-- =====================================================
-- This script fixes the error thrown when liking a post.
-- The error is caused by a trigger on the 'notifications' table
-- which tries to query a non-existent 'metadata' table to get
-- project configuration for push notifications.
-- =====================================================

-- 1. Create the 'metadata' table if it doesn't exist to satisfy the queries
CREATE TABLE IF NOT EXISTS public.metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Insert placeholder values to prevent NULL results in the trigger
-- You should replace these with your actual project values if push notifications are needed.
INSERT INTO public.metadata (key, value) 
VALUES 
    ('supabase_project_ref', 'placeholder-ref'),
    ('supabase_anon_key', 'placeholder-key')
ON CONFLICT (key) DO NOTHING;

-- 3. Robust version of the notify_push_service function
-- It now checks if the metadata table exists and has values before proceeding.
CREATE OR REPLACE FUNCTION public.notify_push_service()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_project_ref TEXT;
    v_anon_key TEXT;
BEGIN
    -- Try to get config from metadata table
    SELECT value INTO v_project_ref FROM public.metadata WHERE key = 'supabase_project_ref';
    SELECT value INTO v_anon_key FROM public.metadata WHERE key = 'supabase_anon_key';

    -- Only attempt to call the edge function if we have the configuration
    IF v_project_ref IS NOT NULL AND v_anon_key IS NOT NULL AND v_project_ref != 'placeholder-ref' THEN
        PERFORM
            net.http_post(
                url := 'https://' || v_project_ref || '.supabase.co/functions/v1/push-notifications',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || v_anon_key
                ),
                body := jsonb_build_object('record', row_to_json(NEW))
            );
    END IF;
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Prevent the entire transaction (like a post) from failing if notification fails
    RAISE WARNING 'Push notification trigger failed: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Re-apply the trigger
DROP TRIGGER IF EXISTS trigger_notify_push_service ON public.notifications;
CREATE TRIGGER trigger_notify_push_service
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION notify_push_service();

-- 5. Cleanup stale triggers on likes table (from previous migrations)
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT tgname
        FROM pg_trigger
        WHERE tgrelid = 'public.likes'::regclass
          AND tgisinternal = FALSE
          AND tgname NOT IN (
            'trigger_increment_post_likes_count',
            'trigger_decrement_post_likes_count',
            'trigger_create_like_notification'
          )
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.likes', r.tgname);
    END LOOP;
END;
$$;
