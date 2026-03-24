-- =====================================================
-- TRIGGER FOR PUSH NOTIFICATIONS
-- =====================================================

-- 1. Enable pg_net extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Create the function that calls the Edge Function
CREATE OR REPLACE FUNCTION public.notify_push_service()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Call the push-notifications Edge Function
  -- The payload includes the new notification record
  PERFORM
    net.http_post(
      url := 'https://' || (SELECT value FROM metadata WHERE key = 'supabase_project_ref') || '.supabase.co/functions/v1/push-notifications',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (SELECT value FROM metadata WHERE key = 'supabase_anon_key')
      ),
      body := jsonb_build_object('record', row_to_json(NEW))
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Create the trigger
DROP TRIGGER IF EXISTS trigger_notify_push_service ON public.notifications;
CREATE TRIGGER trigger_notify_push_service
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION notify_push_service();

-- Note: Ensure 'metadata' table exists or use hardcoded values/environment variables if preferred.
-- For now, I'll assume you have a way to inject these or I will provide a version using standard Supabase variables.
