-- Migration: Add username to message_reactions table for denormalization
-- Created: 2026-03-19

-- Add username column to message_reactions
ALTER TABLE public.message_reactions ADD COLUMN IF NOT EXISTS username TEXT;

-- Update existing reactions with username if possible (optional, but good for data integrity)
UPDATE public.message_reactions mr
SET username = p.username
FROM public.profiles p
WHERE mr.user_id = p.id AND mr.username IS NULL;

-- Set default for future rows if needed, or just let the app handle it
ALTER TABLE public.message_reactions ALTER COLUMN username SET DEFAULT 'Unknown';
