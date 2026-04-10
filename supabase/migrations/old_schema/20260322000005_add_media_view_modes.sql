-- Migration: 20260322000005_add_media_view_modes.sql
-- Description: Add support for View Once, View Twice, and Unlimited media modes

-- 1. Add media_view_mode to messages table
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS media_view_mode TEXT DEFAULT 'unlimited' 
CHECK (media_view_mode IN ('unlimited', 'once', 'twice'));

-- 2. Create message_media_views table for tracking per-user views
CREATE TABLE IF NOT EXISTS public.message_media_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    view_count INTEGER DEFAULT 0,
    last_viewed_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint: one entry per user per message
    UNIQUE(message_id, user_id)
);

-- 3. Create indexes
CREATE INDEX IF NOT EXISTS idx_message_media_views_message_id ON public.message_media_views(message_id);
CREATE INDEX IF NOT EXISTS idx_message_media_views_user_id ON public.message_media_views(user_id);

-- 4. Enable RLS
ALTER TABLE public.message_media_views ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
-- Users can see their own view counts
CREATE POLICY "Users can see their own media view counts"
    ON public.message_media_views FOR SELECT
    USING (auth.uid() = user_id);

-- Senders can see view counts for messages they sent (to show 'Opened' status)
CREATE POLICY "Senders can see media view counts for their messages"
    ON public.message_media_views FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.messages
            WHERE messages.id = message_media_views.message_id
            AND messages.sender_id = auth.uid()
        )
    );

-- Users can insert/update their own view counts
CREATE POLICY "Users can insert their own media view counts"
    ON public.message_media_views FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own media view counts"
    ON public.message_media_views FOR UPDATE
    USING (auth.uid() = user_id);

-- 6. Add to SupabaseConfig (optional documentation/reference)
-- message_media_views table added
