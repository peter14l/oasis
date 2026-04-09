-- =====================================================
-- FIX: PostgrestException (code 42846) - http_request cast error
-- =====================================================
-- This script fixes the "cannot cast type record to http_request" 
-- error that occurs when initiating a call.
-- 
-- The error was caused by a redundant and malformed manual http 
-- invocation inside the 'handle_call_notification' function.
-- Since the function already inserts into the 'notifications' table,
-- and there is a global trigger on that table to handle push 
-- notifications via a robust service, the manual call was unnecessary.
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_call_notification()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_host_id UUID;
  v_call_type TEXT;
BEGIN
  -- Only trigger for new invitees (status = 'invited')
  IF NEW.status = 'invited' THEN
    -- Get call details
    SELECT host_id, type INTO v_host_id, v_call_type
    FROM public.calls
    WHERE id = NEW.call_id;
    
    -- Don't notify the caller themselves
    IF NEW.user_id != v_host_id THEN
      -- Insert notification record
      -- This insertion will naturally trigger the existing notify_push_service
      -- which sends the push notification correctly using the pg_net extension.
      INSERT INTO public.notifications (user_id, type, actor_id, content)
      VALUES (
        NEW.user_id,
        'call',
        v_host_id,
        json_build_object(
          'call_id', NEW.call_id,
          'type', v_call_type
        )::text
      )
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-apply trigger to ensure it's pointing to the correct function
DROP TRIGGER IF EXISTS call_participants_notification_trigger ON public.call_participants;

CREATE TRIGGER call_participants_notification_trigger
AFTER INSERT ON public.call_participants
FOR EACH ROW
EXECUTE FUNCTION public.handle_call_notification();
