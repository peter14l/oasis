-- FIX: RLS policies for conversations are too restrictive.
-- Allow any participant to update the last_message_id and last_message_at.

DROP POLICY IF EXISTS "Conversation admins can update conversations" ON public.conversations;

CREATE POLICY "Participants can update last message info"
ON public.conversations FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_participants
        WHERE conversation_id = conversations.id
        AND user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.conversation_participants
        WHERE conversation_id = conversations.id
        AND user_id = auth.uid()
    )
);

-- Also ensure handle_new_message() trigger uses SECURITY DEFINER 
-- to bypass RLS when updating the conversations table if needed.

CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- 1. Update the conversation's last message info ONLY IF the new message is newer or equal
    UPDATE public.conversations
    SET 
        last_message_id = NEW.id,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id
    AND (last_message_at IS NULL OR NEW.created_at >= last_message_at);

    -- 2. Update participants (unread count and updated_at timestamp)
    UPDATE public.conversation_participants
    SET 
        unread_count = unread_count + 1,
        updated_at = NOW()
    WHERE conversation_id = NEW.conversation_id
    AND user_id != NEW.sender_id;
    
    -- Sender only gets updated_at timestamp
    UPDATE public.conversation_participants
    SET updated_at = NOW()
    WHERE conversation_id = NEW.conversation_id
    AND user_id = NEW.sender_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
