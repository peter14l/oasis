-- =====================================================
-- FIX: SYNCHRONIZE CONVERSATION LAST MESSAGE
-- =====================================================
-- This script ensures all conversations point to their actual latest message.
-- This fixes issues where previews show the first message instead of the last.

DO $$
DECLARE
    conv_record RECORD;
    latest_msg_id UUID;
    latest_msg_at TIMESTAMPTZ;
BEGIN
    FOR conv_record IN SELECT id FROM public.conversations LOOP
        -- Find the latest message for this conversation
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
                last_message_at = latest_msg_at
            WHERE id = conv_record.id;
        END IF;
    END LOOP;
END $$;
