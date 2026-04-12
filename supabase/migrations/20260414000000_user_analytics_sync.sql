-- Migration: User Analytics Sync Table
-- Date: 2026-04-14
-- Purpose: Server-side storage for user curation analytics (when sync is enabled)

-- Table for user analytics (synced from app)
CREATE TABLE IF NOT EXISTS public.user_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    category_id TEXT NOT NULL,
    interaction_count INTEGER DEFAULT 0,
    liked_posts TEXT[], -- Array of post_ids
    total_seconds INTEGER DEFAULT 0,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, category_id)
);

-- Enable RLS
ALTER TABLE public.user_analytics ENABLE ROW LEVEL SECURITY;

-- Users can view their own analytics
DROP POLICY IF EXISTS "Users can view own analytics" ON public.user_analytics;
CREATE POLICY "Users can view own analytics"
    ON public.user_analytics
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own analytics
DROP POLICY IF EXISTS "Users can insert own analytics" ON public.user_analytics;
CREATE POLICY "Users can insert own analytics"
    ON public.user_analytics
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own analytics
DROP POLICY IF EXISTS "Users can update own analytics" ON public.user_analytics;
CREATE POLICY "Users can update own analytics"
    ON public.user_analytics
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own analytics
DROP POLICY IF EXISTS "Users can delete own analytics" ON public.user_analytics;
CREATE POLICY "Users can delete own analytics"
    ON public.user_analytics
    FOR DELETE
    USING (auth.uid() = user_id);

-- Function to sync/save analytics from the app
CREATE OR REPLACE FUNCTION public.sync_user_analytics(
    p_category_id TEXT,
    p_interaction_count INTEGER,
    p_liked_posts TEXT[],
    p_total_seconds INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    INSERT INTO public.user_analytics (user_id, category_id, interaction_count, liked_posts, total_seconds)
    VALUES (v_user_id, p_category_id, p_interaction_count, p_liked_posts, p_total_seconds)
    ON CONFLICT (user_id, category_id) DO UPDATE
    SET interaction_count = EXCLUDED.interaction_count,
        liked_posts = EXCLUDED.liked_posts,
        total_seconds = EXCLUDED.total_seconds,
        synced_at = NOW();
END;
$$;

-- Function to delete user's analytics (for toggle OFF)
CREATE OR REPLACE FUNCTION public.delete_user_analytics()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    DELETE FROM public.user_analytics WHERE user_id = v_user_id;
END;
$$;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION public.sync_user_analytics(TEXT, INTEGER, TEXT[], INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user_analytics() TO authenticated;