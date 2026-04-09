-- Call Notifications Trigger
-- This trigger sends push notifications when a user is invited to a call

-- First, enable the http extension for invoking edge functions
CREATE EXTENSION IF NOT EXISTS http;

-- Function to handle call notification - directly invokes edge function
CREATE OR REPLACE FUNCTION handle_call_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_host_id UUID;
  v_call_type TEXT;
BEGIN
  -- Only trigger for new invitees (status = 'invited')
  IF NEW.status = 'invited' THEN
    -- Get call details
    SELECT host_id, type INTO v_host_id, v_call_type
    FROM calls
    WHERE id = NEW.call_id;
    
    -- Don't notify the caller themselves
    IF NEW.user_id != v_host_id THEN
      -- Insert notification record
      INSERT INTO notifications (user_id, type, actor_id, content)
      VALUES (
        NEW.user_id,
        'call',
        v_host_id,
        json_build_object(
          'call_id', NEW.call_id,
          'type', v_call_type
        )::text
      );
      
      -- Directly invoke the push notification edge function
      -- This sends the FCM push notification immediately
      PERFORM
        http((
          'POST',
          '/functions/v1/push-notifications',
          ARRAY[
            ('Content-Type', 'application/json')
          ],
          json_build_object(
            'record', json_build_object(
              'user_id', NEW.user_id,
              'type', 'call',
              'actor_id', v_host_id,
              'content', json_build_object(
                'call_id', NEW.call_id,
                'type', v_call_type
              )::text
            )
          )::text
        )::http_request);
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on call_participants
DROP TRIGGER IF EXISTS call_participants_notification_trigger ON call_participants;

CREATE TRIGGER call_participants_notification_trigger
AFTER INSERT ON call_participants
FOR EACH ROW
EXECUTE FUNCTION handle_call_notification();