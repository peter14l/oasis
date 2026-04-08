-- Add voice message columns to messages table
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_url TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_duration INTEGER;

-- Update the constraint to include voice_url
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS message_has_content;
ALTER TABLE public.messages ADD CONSTRAINT message_has_content CHECK (
    content IS NOT NULL OR 
    image_url IS NOT NULL OR 
    video_url IS NOT NULL OR
    file_url IS NOT NULL OR
    voice_url IS NOT NULL
);
