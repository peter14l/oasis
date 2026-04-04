-- =====================================================
-- FRESH WHISPER MODE IMPLEMENTATION
-- Centralized server-side logic for Vanish Mode
-- =====================================================
w
-- 1. Clean up ALL old whisper-related triggers and functions
DROP TRIGGER IF EXISTS trigger_whisper_mode_messages ON public.messages;
DROP TRIGGER IF EXISTS trigger_message_expiration ON public.message_read_receipts;
DROP FUNCTION IF EXISTS public.handle_new_message_in_whisper_mode();
DROP FUNCTION IF EXISTS public.set_message_expiration();
DROP FUNCTION IF EXISTS public.cleanup_vanish_mode_messages(UUID);

-- 2. Update conversations table to use a proper mode column
-- Mode: 0 = Off, 1 = Instant, 2 = 24 Hours
ALTER TABLE public.conversations 
ADD COLUMN IF NOT EXISTS whisper_mode INTEGER DEFAULT 0;

-- 3. Trigger to automatically mark new messages as ephemeral
CREATE OR REPLACE FUNCTION public.handle_message_whisper_settings()
RETURNS TRIGGER AS $$
DECLARE
    v_whisper_mode INTEGER;
BEGIN
    -- Get current conversation whisper mode
    SELECT whisper_mode INTO v_whisper_mode
    FROM public.conversations
    WHERE id = NEW.conversation_id;

    -- If whisper mode is enabled (1 or 2)
    IF v_whisper_mode > 0 THEN
        NEW.is_ephemeral := TRUE;
        -- Set duration: 0 for Instant, 86400 for 24h
        NEW.ephemeral_duration := CASE 
            WHEN v_whisper_mode = 1 THEN 0 
            WHEN v_whisper_mode = 2 THEN 86400 
            ELSE 86400 
        END;
    ELSE
        NEW.is_ephemeral := FALSE;
        NEW.ephemeral_duration := 86400; -- default
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_message_whisper_settings
    BEFORE INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_message_whisper_settings();

-- 4. Trigger to set expires_at when a message is read
CREATE OR REPLACE FUNCTION public.apply_message_expiration()
RETURNS TRIGGER AS $$
DECLARE
    v_is_ephemeral BOOLEAN;
    v_duration INTEGER;
    v_sender_id UUID;
BEGIN
    -- Get message metadata
    SELECT is_ephemeral, ephemeral_duration, sender_id 
    INTO v_is_ephemeral, v_duration, v_sender_id
    FROM public.messages
    WHERE id = NEW.message_id;

    -- Only apply if it's ephemeral, hasn't expired yet, and the reader is NOT the sender
    IF v_is_ephemeral = TRUE AND NEW.user_id != v_sender_id THEN
        -- Check if expires_at is already set (by another recipient)
        -- We only set it once (the first time it's seen by a recipient)
        UPDATE public.messages
        SET expires_at = CASE 
            WHEN v_duration = 0 THEN NOW() -- Instant vanish
            ELSE NOW() + (v_duration || ' seconds')::INTERVAL -- 24h vanish
        END
        WHERE id = NEW.message_id AND expires_at IS NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_apply_expiration
    AFTER INSERT ON public.message_read_receipts
    FOR EACH ROW
    EXECUTE FUNCTION public.apply_message_expiration();

-- 5. Helper function for manual/lazy cleanup
CREATE OR REPLACE FUNCTION public.cleanup_expired_messages(p_conversation_id UUID)
RETURNS void AS $$
BEGIN
    DELETE FROM public.messages
    WHERE conversation_id = p_conversation_id
      AND is_ephemeral = TRUE
      AND expires_at <= NOW();
END;
$$ LANGUAGE plpgsql;
