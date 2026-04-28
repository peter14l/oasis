-- =====================================================
-- OASIS - COZY NOTIFICATION SILENCING (Part 4)
-- =====================================================
-- Update the notification filter to respect Cozy Mode

CREATE OR REPLACE FUNCTION public.filter_notification_insert()
RETURNS TRIGGER AS $$
DECLARE
    v_is_blocked BOOLEAN;
    v_is_muted_user BOOLEAN;
    v_is_muted_conversation BOOLEAN;
    v_conversation_id UUID;
    v_is_cozy BOOLEAN;
BEGIN
    -- A. CHECK BLOCKS (Recipient blocked Actor)
    SELECT EXISTS (
        SELECT 1 FROM public.blocked_users
        WHERE blocker_id = NEW.user_id AND blocked_id = NEW.actor_id
    ) INTO v_is_blocked;

    IF v_is_blocked THEN
        -- Recipient has blocked the sender. Silently discard the notification.
        RETURN NULL;
    END IF;

    -- B. CHECK MUTED USERS (Recipient muted Actor)
    SELECT EXISTS (
        SELECT 1 FROM public.muted_users
        WHERE muter_id = NEW.user_id AND muted_id = NEW.actor_id
        AND (expires_at IS NULL OR expires_at > NOW())
    ) INTO v_is_muted_user;

    IF v_is_muted_user THEN
        -- Recipient has muted the user globally. Silently discard.
        RETURN NULL;
    END IF;

    -- C. CHECK COZY MODE (Respect "Cozy" status)
    -- Exempt 'warm_whisper' and 'dm' from being silenced here if they are urgent
    -- or just silence everything except 'warm_whisper' which is gentle.
    IF NEW.type != 'warm_whisper' THEN
        SELECT EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = NEW.user_id 
            AND cozy_until IS NOT NULL 
            AND cozy_until > NOW()
        ) INTO v_is_cozy;

        IF v_is_cozy THEN
            -- Recipient is in Cozy Mode. Silently discard non-urgent notifications.
            RETURN NULL;
        END IF;
    END IF;

    -- D. CHECK MUTED CONVERSATIONS (Specific to DMs)
    IF NEW.type = 'dm' AND NEW.message_id IS NOT NULL THEN
        -- Get conversation_id from the message
        SELECT conversation_id INTO v_conversation_id
        FROM public.messages
        WHERE id = NEW.message_id;

        IF v_conversation_id IS NOT NULL THEN
            SELECT is_muted INTO v_is_muted_conversation
            FROM public.conversation_participants
            WHERE conversation_id = v_conversation_id AND user_id = NEW.user_id;

            IF v_is_muted_conversation THEN
                -- Recipient has muted this specific conversation. Silently discard.
                RETURN NULL;
            END IF;
        END IF;
    END IF;

    -- If we reach here, the notification is allowed.
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
