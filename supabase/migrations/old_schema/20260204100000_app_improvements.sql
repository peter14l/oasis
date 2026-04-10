-- Migration: Add message reactions table
-- Created: 2026-02-04

-- Create message_reactions table
CREATE TABLE IF NOT EXISTS public.message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reaction VARCHAR(10) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure one reaction per user per message
    CONSTRAINT unique_user_message_reaction UNIQUE (message_id, user_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON public.message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_user_id ON public.message_reactions(user_id);

-- Enable RLS
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies (drop existing first to make migration idempotent)
DROP POLICY IF EXISTS "Users can view reactions in their conversations" ON public.message_reactions;
DROP POLICY IF EXISTS "Users can add reactions in their conversations" ON public.message_reactions;
DROP POLICY IF EXISTS "Users can remove their own reactions" ON public.message_reactions;

-- Users can view reactions on messages in conversations they're part of
CREATE POLICY "Users can view reactions in their conversations"
    ON public.message_reactions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.messages m
            JOIN public.conversation_participants cp ON cp.conversation_id = m.conversation_id
            WHERE m.id = message_reactions.message_id
            AND cp.user_id = auth.uid()
        )
    );

-- Users can add reactions to messages in their conversations
CREATE POLICY "Users can add reactions in their conversations"
    ON public.message_reactions FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (
            SELECT 1 FROM public.messages m
            JOIN public.conversation_participants cp ON cp.conversation_id = m.conversation_id
            WHERE m.id = message_reactions.message_id
            AND cp.user_id = auth.uid()
        )
    );

-- Users can remove their own reactions
CREATE POLICY "Users can remove their own reactions"
    ON public.message_reactions FOR DELETE
    USING (auth.uid() = user_id);

-- Add mood column to posts table
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS mood VARCHAR(50);

-- Add mood index for filtering
CREATE INDEX IF NOT EXISTS idx_posts_mood ON public.posts(mood) WHERE mood IS NOT NULL;

-- Add wellness tracking table
CREATE TABLE IF NOT EXISTS public.wellness_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_type VARCHAR(50) NOT NULL,
    achievement_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_user_achievement UNIQUE (user_id, achievement_type, achievement_name)
);

-- Create index for user achievements
CREATE INDEX IF NOT EXISTS idx_wellness_achievements_user ON public.wellness_achievements(user_id);

-- Enable RLS for achievements
ALTER TABLE public.wellness_achievements ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view own achievements" ON public.wellness_achievements;
DROP POLICY IF EXISTS "System can insert achievements" ON public.wellness_achievements;

-- Users can view their own achievements
CREATE POLICY "Users can view own achievements"
    ON public.wellness_achievements FOR SELECT
    USING (auth.uid() = user_id);

-- System can insert achievements (via service role)
CREATE POLICY "System can insert achievements"
    ON public.wellness_achievements FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Add chat themes table
CREATE TABLE IF NOT EXISTS public.chat_themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    theme_name VARCHAR(50) DEFAULT 'default',
    background_color VARCHAR(20),
    background_image_url TEXT,
    bubble_color VARCHAR(20),
    text_color VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_user_conversation_theme UNIQUE (conversation_id, user_id)
);

-- Enable RLS for chat themes
ALTER TABLE public.chat_themes ENABLE ROW LEVEL SECURITY;

-- Drop existing policy first
DROP POLICY IF EXISTS "Users can manage own chat themes" ON public.chat_themes;

-- Users can manage their own chat themes
CREATE POLICY "Users can manage own chat themes"
    ON public.chat_themes FOR ALL
    USING (auth.uid() = user_id);

-- Add focus mode settings to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS focus_mode_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS focus_mode_schedule JSONB;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS wind_down_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS wind_down_time TIME;

-- Add vault mode table for protected content
CREATE TABLE IF NOT EXISTS public.vault_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    item_type VARCHAR(20) NOT NULL, -- 'post', 'conversation', 'collection'
    item_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for vault items
ALTER TABLE public.vault_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policy first
DROP POLICY IF EXISTS "Users can manage own vault items" ON public.vault_items;

-- Users can manage their own vault items
CREATE POLICY "Users can manage own vault items"
    ON public.vault_items FOR ALL
    USING (auth.uid() = user_id);

-- Add poll tables
CREATE TABLE IF NOT EXISTS public.polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    poll_type VARCHAR(20) DEFAULT 'single', -- 'single', 'multiple', 'this_or_that', 'quiz'
    is_anonymous BOOLEAN DEFAULT FALSE,
    ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.poll_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    option_order INT DEFAULT 0,
    is_correct BOOLEAN DEFAULT FALSE -- For quiz type
);

CREATE TABLE IF NOT EXISTS public.poll_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES public.poll_options(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_poll_vote UNIQUE (poll_id, user_id, option_id)
);

-- Enable RLS for polls
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

-- Poll policies (drop existing first)
DROP POLICY IF EXISTS "Anyone can view polls" ON public.polls;
DROP POLICY IF EXISTS "Anyone can view poll options" ON public.poll_options;
DROP POLICY IF EXISTS "Users can vote" ON public.poll_votes;
DROP POLICY IF EXISTS "Users can view votes" ON public.poll_votes;

CREATE POLICY "Anyone can view polls"
    ON public.polls FOR SELECT USING (true);

CREATE POLICY "Anyone can view poll options"
    ON public.poll_options FOR SELECT USING (true);

CREATE POLICY "Users can vote"
    ON public.poll_votes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view votes"
    ON public.poll_votes FOR SELECT USING (true);
