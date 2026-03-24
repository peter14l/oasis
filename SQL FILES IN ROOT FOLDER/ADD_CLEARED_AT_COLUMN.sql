-- =====================================================
-- ADD CLEARED_AT COLUMN FOR "CLEAR FOR ME" FEATURE
-- =====================================================
-- This script adds a cleared_at timestamp to the conversation_participants table.
-- Messages created before this timestamp will be hidden for the specific user.

ALTER TABLE public.conversation_participants 
ADD COLUMN IF NOT EXISTS cleared_at TIMESTAMPTZ;

-- Reset unread count logic can also use this if needed in the future
