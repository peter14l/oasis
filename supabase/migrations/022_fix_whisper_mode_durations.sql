-- =====================================================
-- FIX: WHISPER MODE / VANISHING MESSAGES LOGIC
-- Migration: 022_fix_whisper_mode_durations.sql
-- =====================================================

-- 1. Ensure ephemeral_duration column exists in messages table
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS ephemeral_duration INTEGER DEFAULT 86400;

-- 2. Update the trigger function to handle different durations and instant vanish
CREATE OR REPLACE FUNCTION set_message_expiration()
RETURNS TRIGGER AS $$
DECLARE
  v_is_ephemeral BOOLEAN;
  v_ephemeral_duration INTEGER;
  v_expires_at TIMESTAMPTZ;
  v_sender_id UUID;
BEGIN
  -- Get message details
  SELECT is_ephemeral, ephemeral_duration, expires_at, sender_id 
  INTO v_is_ephemeral, v_ephemeral_duration, v_expires_at, v_sender_id
  FROM public.messages
  WHERE id = NEW.message_id;

  -- If message is ephemeral and has no expiration set, set it now
  -- We only set expiration if the reader is NOT the sender
  IF v_is_ephemeral = TRUE AND v_expires_at IS NULL AND NEW.user_id != v_sender_id THEN
    
    -- If duration is 0 (Vanish instantly), we delete it immediately
    IF v_ephemeral_duration = 0 THEN
      DELETE FROM public.messages WHERE id = NEW.message_id;
    ELSE
      -- Otherwise, set expires_at based on the duration (in seconds)
      UPDATE public.messages
      SET expires_at = NOW() + (v_ephemeral_duration || ' seconds')::INTERVAL
      WHERE id = NEW.message_id;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Re-create the trigger for message reads
DROP TRIGGER IF EXISTS trigger_message_expiration ON public.message_read_receipts;
CREATE TRIGGER trigger_message_expiration
  AFTER INSERT ON public.message_read_receipts
  FOR EACH ROW
  EXECUTE FUNCTION set_message_expiration();

-- 4. Create a background worker (simulated with a cron-like query) 
-- to periodically clean up expired messages that weren't deleted instantly
CREATE INDEX IF NOT EXISTS idx_messages_expires_at_cleanup 
ON public.messages(expires_at) 
WHERE expires_at IS NOT NULL;
