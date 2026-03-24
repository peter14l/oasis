-- Add updated_at to conversation_participants to track any change (for realtime sorting)
ALTER TABLE public.conversation_participants 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Consolidate all message post-processing into ONE function to ensure order and consistency
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Update the conversation's last message info FIRST
    UPDATE public.conversations
    SET 
        last_message_id = NEW.id,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;

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

-- Replace old triggers with the new consolidated one
DROP TRIGGER IF EXISTS trigger_update_conversation_last_message ON public.messages;
DROP TRIGGER IF EXISTS trigger_increment_unread_count ON public.messages;

CREATE TRIGGER trigger_handle_new_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_message();
