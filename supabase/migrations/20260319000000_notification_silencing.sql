-- =====================================================
-- MORROW V2 - NOTIFICATION SILENCING LOGIC
-- =====================================================
-- This migration ensures that muted or blocked interactions do not trigger notifications.

-- 1. FUNCTION: Filter Notifications
-- =====================================================
CREATE OR REPLACE FUNCTION public.filter_notification_insert()
RETURNS TRIGGER AS $$
DECLARE
    v_is_blocked BOOLEAN;
    v_is_muted_user BOOLEAN;
    v_is_muted_conversation BOOLEAN;
    v_conversation_id UUID;
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

    -- C. CHECK MUTED CONVERSATIONS (Specific to DMs)
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

-- 2. TRIGGER: Apply Filter Before Insert
-- =====================================================
DROP TRIGGER IF EXISTS trigger_filter_notification_insert ON public.notifications;
CREATE TRIGGER trigger_filter_notification_insert
    BEFORE INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION public.filter_notification_insert();

-- 3. RLS POLICY: Prevent messages from blocked users
-- =====================================================
-- This policy prevents inserting into the messages table if the recipient has blocked the sender.
-- Note: This requires checking conversation_participants to find the recipient.

CREATE OR REPLACE FUNCTION public.is_blocked_in_conversation(p_conversation_id UUID, p_sender_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.conversation_participants cp
        JOIN public.blocked_users bu ON cp.user_id = bu.blocker_id
        WHERE cp.conversation_id = p_conversation_id
        AND bu.blocked_id = p_sender_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply the policy to the messages table
-- We use a policy that checks BEFORE insert
-- DROP POLICY IF EXISTS "Prevent messages from blocked users" ON public.messages;
-- CREATE POLICY "Prevent messages from blocked users" ON public.messages
--     FOR INSERT
--     WITH CHECK (
--         NOT public.is_blocked_in_conversation(conversation_id, auth.uid())
--     );

-- 4. FUNCTION: Cleanup Existing Silenced Notifications
-- =====================================================
-- Clean up any notifications that might have slipped through before the block
DELETE FROM public.notifications n
USING public.blocked_users b
WHERE n.user_id = b.blocker_id AND n.actor_id = b.blocked_id;
