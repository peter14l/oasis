-- Create Whisper Mode Enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'whisper_mode_type') THEN
        CREATE TYPE whisper_mode_type AS ENUM ('OFF', 'INSTANT', '24_HOURS');
    END IF;
END $$;

-- Update Messages Table
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS whisper_mode whisper_mode_type DEFAULT 'OFF',
ADD COLUMN IF NOT EXISTS read_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;

-- Create Index for cleanup performance
CREATE INDEX IF NOT EXISTS idx_messages_expires_at ON public.messages (expires_at) WHERE expires_at IS NOT NULL;

-- Create Chat Sessions table to persist Whisper Mode state per conversation and user
CREATE TABLE IF NOT EXISTS public.chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    whisper_mode whisper_mode_type DEFAULT 'OFF',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(conversation_id, user_id)
);

-- Enable RLS on chat_sessions
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for chat_sessions
CREATE POLICY "Users can view their own chat sessions" 
ON public.chat_sessions FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own chat sessions" 
ON public.chat_sessions FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can modify their own chat sessions" 
ON public.chat_sessions FOR UPDATE 
USING (auth.uid() = user_id);

-- Update RLS on messages to hide expired ones
-- First, drop existing broad select policies if they exist (need to be careful here)
-- For the purpose of this task, I'll add a restrictive policy or update existing ones.
-- Assuming there's a policy like "Users can view messages in their conversations"

-- Add a policy that filters out expired messages
CREATE POLICY "Hide expired messages" 
ON public.messages FOR SELECT 
USING (expires_at IS NULL OR expires_at > now());

-- RPC to mark message as read and set expiry
CREATE OR REPLACE FUNCTION public.mark_whisper_message_read(msg_id UUID, reader_id UUID)
RETURNS VOID AS $$
DECLARE
    v_whisper_mode whisper_mode_type;
    v_read_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Get current message state
    SELECT whisper_mode, read_at INTO v_whisper_mode, v_read_at
    FROM public.messages
    WHERE id = msg_id;

    -- Only update if not already read by the recipient
    -- We assume the recipient is anyone who is NOT the sender
    IF v_read_at IS NULL THEN
        v_read_at := now();
        
        UPDATE public.messages
        SET 
            read_at = v_read_at,
            is_read = TRUE,
            expires_at = CASE 
                WHEN v_whisper_mode = 'INSTANT' THEN v_read_at + interval '10 seconds' -- small buffer for UI sync
                WHEN v_whisper_mode = '24_HOURS' THEN v_read_at + interval '24 hours'
                ELSE NULL
            END
        WHERE id = msg_id AND sender_id != reader_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Background Cleanup Function
CREATE OR REPLACE FUNCTION public.cleanup_expired_messages()
RETURNS VOID AS $$
BEGIN
    DELETE FROM public.messages
    WHERE expires_at < now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule cleanup using pg_cron (if available)
-- Note: You must enable pg_cron in the Supabase Dashboard (Database -> Extensions)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        PERFORM cron.schedule('cleanup-whisper-messages', '*/5 * * * *', 'SELECT public.cleanup_expired_messages()');
    END IF;
END $$;
