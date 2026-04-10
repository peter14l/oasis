-- Add signal_message_type to messages table for Signal E2E Encryption
ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS signal_message_type INTEGER;
