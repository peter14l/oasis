-- CLEAR ALL TEXT MESSAGES FROM DATABASE (GLOBAL)
-- This script removes all messages for all users and resets conversation state.

-- 1. Clear all messages (This will also clear receipts and reactions via CASCADE)
DELETE FROM public.messages;

-- 2. Reset conversation pointers (last_message_id and last_message_at)
UPDATE public.conversations 
SET 
    last_message_id = NULL, 
    last_message_at = NULL,
    updated_at = NOW();

-- 3. Reset unread counts and cleared timestamps for all participants
UPDATE public.conversation_participants 
SET 
    unread_count = 0, 
    last_read_at = NOW(),
    cleared_at = NULL;
