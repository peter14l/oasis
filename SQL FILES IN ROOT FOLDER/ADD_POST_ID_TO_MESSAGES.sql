-- Add post_id column to messages table
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_messages_post_id ON public.messages(post_id);
