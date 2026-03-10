-- =====================================================
-- STORIES FEATURE - DATABASE SCHEMA
-- =====================================================
-- This migration creates tables for Instagram-style stories feature
-- Stories expire after 24 hours

-- =====================================================
-- STORIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
    thumbnail_url TEXT,
    caption TEXT,
    duration INTEGER DEFAULT 5, -- seconds to display (for images)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours',
    view_count INTEGER DEFAULT 0,
    
    -- Constraints
    CONSTRAINT caption_length CHECK (caption IS NULL OR char_length(caption) <= 200)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_stories_user_id ON public.stories(user_id);
CREATE INDEX IF NOT EXISTS idx_stories_created_at ON public.stories(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stories_expires_at ON public.stories(expires_at);

-- =====================================================
-- STORY VIEWS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.story_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
    viewer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    viewed_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint to track unique views
    UNIQUE(story_id, viewer_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_story_views_story_id ON public.story_views(story_id);
CREATE INDEX IF NOT EXISTS idx_story_views_viewer_id ON public.story_views(viewer_id);
CREATE INDEX IF NOT EXISTS idx_story_views_viewed_at ON public.story_views(viewed_at DESC);

-- =====================================================
-- STORY REACTIONS TABLE (optional - for future)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.story_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    emoji TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint
    UNIQUE(story_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_story_reactions_story_id ON public.story_reactions(story_id);
CREATE INDEX IF NOT EXISTS idx_story_reactions_user_id ON public.story_reactions(user_id);

-- =====================================================
-- FUNCTION: Auto-delete expired stories
-- =====================================================
CREATE OR REPLACE FUNCTION delete_expired_stories()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.stories
    WHERE expires_at < NOW();
END;
$$;

-- =====================================================
-- FUNCTION: Increment story view count
-- =====================================================
CREATE OR REPLACE FUNCTION increment_story_view_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.stories
    SET view_count = view_count + 1
    WHERE id = NEW.story_id;
    
    RETURN NEW;
END;
$$;

-- Create trigger for view count
DROP TRIGGER IF EXISTS trigger_increment_story_view_count ON public.story_views;
CREATE TRIGGER trigger_increment_story_view_count
    AFTER INSERT ON public.story_views
    FOR EACH ROW
    EXECUTE FUNCTION increment_story_view_count();

-- =====================================================
-- FUNCTION: Get active stories for a user
-- =====================================================
CREATE OR REPLACE FUNCTION get_active_stories(target_user_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    media_url TEXT,
    media_type TEXT,
    thumbnail_url TEXT,
    caption TEXT,
    duration INTEGER,
    created_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    view_count INTEGER,
    has_viewed BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.user_id,
        s.media_url,
        s.media_type,
        s.thumbnail_url,
        s.caption,
        s.duration,
        s.created_at,
        s.expires_at,
        s.view_count,
        EXISTS(
            SELECT 1 FROM public.story_views sv
            WHERE sv.story_id = s.id AND sv.viewer_id = auth.uid()
        ) as has_viewed
    FROM public.stories s
    WHERE s.user_id = target_user_id
    AND s.expires_at > NOW()
    ORDER BY s.created_at ASC;
END;
$$;

-- =====================================================
-- FUNCTION: Get stories from following users
-- =====================================================
CREATE OR REPLACE FUNCTION get_following_stories(requesting_user_id UUID)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    story_count BIGINT,
    has_unviewed BOOLEAN,
    latest_story_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as user_id,
        p.username,
        p.avatar_url,
        COUNT(s.id) as story_count,
        BOOL_OR(NOT EXISTS(
            SELECT 1 FROM public.story_views sv
            WHERE sv.story_id = s.id AND sv.viewer_id = requesting_user_id
        )) as has_unviewed,
        MAX(s.created_at) as latest_story_at
    FROM public.profiles p
    INNER JOIN public.follows f ON f.following_id = p.id
    INNER JOIN public.stories s ON s.user_id = p.id
    WHERE f.follower_id = requesting_user_id
    AND s.expires_at > NOW()
    GROUP BY p.id, p.username, p.avatar_url
    ORDER BY has_unviewed DESC, latest_story_at DESC;
END;
$$;
