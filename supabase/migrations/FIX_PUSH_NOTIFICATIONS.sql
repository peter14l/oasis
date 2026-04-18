-- =====================================================
-- FIX: PUSH NOTIFICATIONS (BACKGROUND & E2EE)
-- =====================================================
-- This script:
-- 1. Enables pg_net for async HTTP requests.
-- 2. Creates the notify_push_service trigger function with E2EE metadata support.
-- 3. Sets up the trigger on the notifications table.
-- 4. Secures the metadata table with RLS.

-- 1. Enable pg_net extension
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Improved push notification trigger function
CREATE OR REPLACE FUNCTION public.notify_push_service()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_payload JSONB;
BEGIN
  -- Build a rich payload including message metadata for E2EE decryption
  -- We fetch metadata from the messages table to include it in the push payload
  v_payload := jsonb_build_object(
    'record', row_to_json(NEW),
    'metadata', (
      SELECT jsonb_build_object(
        'encrypted_keys', encrypted_keys,
        'iv', iv,
        'signal_message_type', signal_message_type,
        'signal_sender_content', signal_sender_content,
        'conversation_id', conversation_id
      )
      FROM public.messages
      WHERE id = NEW.message_id
    )
  );

  -- Call the push-notifications Edge Function
  PERFORM
    net.http_post(
      url := 'https://' || (SELECT value FROM public.metadata WHERE key = 'supabase_project_ref') || '.supabase.co/functions/v1/push-notifications',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (SELECT value FROM public.metadata WHERE key = 'supabase_anon_key')
      ),
      body := v_payload
    );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Prevent database operation from failing if push notification fails
  RAISE WARNING 'Push notification trigger failed: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Re-create the trigger on the notifications table
DROP TRIGGER IF EXISTS trigger_notify_push_service ON public.notifications;
CREATE TRIGGER trigger_notify_push_service
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION notify_push_service();

-- 4. Secure the Metadata table
-- Enable RLS to prevent unauthorized modification of system config
ALTER TABLE public.metadata ENABLE ROW LEVEL SECURITY;

-- Allow reading the config (needed by the trigger and app if necessary)
DROP POLICY IF EXISTS "Public read access for metadata" ON public.metadata;
CREATE POLICY "Public read access for metadata" 
ON public.metadata 
FOR SELECT 
TO authenticated, anon
USING (true);

-- Only allow service_role (system) to manage the config values
DROP POLICY IF EXISTS "Service role only write" ON public.metadata;
CREATE POLICY "Service role only write" 
ON public.metadata 
FOR ALL 
TO service_role 
USING (true) 
WITH CHECK (true);

-- =====================================================
-- VERIFICATION
-- =====================================================
-- Ensure your 'metadata' table contains the correct project ref and anon key
-- for the Edge Function to be reachable.
--
-- INSERT INTO public.metadata (key, value) 
-- VALUES 
--   ('supabase_project_ref', 'your-project-ref'),
--   ('supabase_anon_key', 'your-anon-key')
-- ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
