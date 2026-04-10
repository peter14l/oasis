-- =====================================================
-- FIX: INSTAGRAM-STYLE VANISH MODE (REOPEN LOGIC)
-- Migration: 023_vanish_mode_reopen_logic.sql
-- =====================================================

-- 1. Update the trigger function to NOT delete immediately.
-- Instead, it sets a generous expires_at (e.g., 24h) even for "instant" messages,
-- allowing the app to handle the "vanish on reopen" logic via session timestamps.
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
    
    -- For Vanish Mode (duration 0), we set a 24h safety expiry in the DB,
    -- but the app will hide it as soon as the session ends.
    IF v_ephemeral_duration = 0 THEN
      UPDATE public.messages
      SET expires_at = NOW() + INTERVAL '24 hours'
      WHERE id = NEW.message_id;
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
