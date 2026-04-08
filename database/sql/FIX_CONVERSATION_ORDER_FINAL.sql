-- FIX: Ensure last_message_at only updates if the new message is actually newer
-- and ensure last_message_id is always in sync with last_message_at.

CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Update the conversation's last message info ONLY IF the new message is newer or equal
    -- This prevents out-of-order messages from breaking the preview/sorting.
    UPDATE public.conversations
    SET 
        last_message_id = NEW.id,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id
    AND (last_message_at IS NULL OR NEW.created_at >= last_message_at);

    -- 2. Update participants (unread count and updated_at timestamp)
    -- Recipients get unread_count incremented
    UPDATE public.conversation_participants
    SET 
        unread_count = unread_count + 1,
        updated_at = NOW()
    WHERE conversation_id = NEW.conversation_id
    AND user_id != NEW.sender_id;
    
    -- Sender only gets updated_at timestamp (to trigger rearrangement)
    UPDATE public.conversation_participants
    SET updated_at = NOW()
    WHERE conversation_id = NEW.conversation_id
    AND user_id = NEW.sender_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-sync all conversations one last time to fix any existing corruption
DO $$
DECLARE
    conv_record RECORD;
    latest_msg_id UUID;
    latest_msg_at TIMESTAMPTZ;
BEGIN
    FOR conv_record IN SELECT id FROM public.conversations LOOP
        -- Find the latest message for this conversation based on created_at
        SELECT id, created_at INTO latest_msg_id, latest_msg_at
        FROM public.messages
        WHERE conversation_id = conv_record.id
        ORDER BY created_at DESC
        LIMIT 1;

        -- Update the conversation if a message exists
        IF latest_msg_id IS NOT NULL THEN
            UPDATE public.conversations
            SET 
                last_message_id = latest_msg_id,
                last_message_at = latest_msg_at,
                updated_at = NOW()
            WHERE id = conv_record.id;
        END IF;
    END LOOP;
END $$;
