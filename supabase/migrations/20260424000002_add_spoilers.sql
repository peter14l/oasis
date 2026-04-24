-- Add is_spoiler column to posts and messages tables
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS is_spoiler BOOLEAN DEFAULT FALSE;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_spoiler BOOLEAN DEFAULT FALSE;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';
