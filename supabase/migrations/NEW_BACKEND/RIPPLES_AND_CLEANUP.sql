-- =====================================================
-- OASIS - RIPPLES AND SCHEMA CLEANUP
-- =====================================================

-- 1. Correct Posts Table Columns (Ensuring Arrays)
ALTER TABLE public.posts DROP COLUMN IF EXISTS media_types;
ALTER TABLE public.posts ADD COLUMN media_types TEXT[] DEFAULT '{}';
ALTER TABLE public.posts DROP COLUMN IF EXISTS media_urls;
ALTER TABLE public.posts ADD COLUMN media_urls TEXT[] DEFAULT '{}';
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS mood VARCHAR(50);
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS dominant_color VARCHAR(20);

-- 2. Ripples System
CREATE TABLE IF NOT EXISTS public.ripples (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    caption TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    saves_count INT DEFAULT 0,
    is_private BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS public.ripple_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ripple_id UUID REFERENCES public.ripples(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(ripple_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.ripple_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ripple_id UUID REFERENCES public.ripples(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ripple_saves (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ripple_id UUID REFERENCES public.ripples(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(ripple_id, user_id)
);

-- RLS for Ripples
ALTER TABLE public.ripples ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ripple_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ripple_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ripple_saves ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view ripples" ON public.ripples;
CREATE POLICY "Users can view ripples" ON public.ripples FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can create ripples" ON public.ripples;
CREATE POLICY "Users can create ripples" ON public.ripples FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete their own ripples" ON public.ripples;
CREATE POLICY "Users can delete their own ripples" ON public.ripples FOR DELETE USING (auth.uid() = user_id);

-- 3. Utility Functions

-- Re-create get_feed_posts (Fixing potential empty feed)
DROP FUNCTION IF EXISTS get_feed_posts(UUID, INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION get_feed_posts(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    username TEXT,
    full_name TEXT,
    avatar_url TEXT,
    is_verified BOOLEAN,
    content TEXT,
    image_url TEXT,
    media_urls TEXT[],
    media_types TEXT[],
    community_id UUID,
    community_name TEXT,
    mood TEXT,
    thumbnail_url TEXT,
    dominant_color TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    shares_count INTEGER,
    created_at TIMESTAMPTZ,
    is_liked BOOLEAN,
    is_bookmarked BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        pr.username::TEXT,
        pr.full_name::TEXT,
        pr.avatar_url::TEXT,
        pr.is_verified,
        p.content::TEXT,
        p.image_url::TEXT,
        p.media_urls,
        p.media_types,
        p.community_id,
        c.name::TEXT as community_name,
        p.mood::TEXT,
        p.thumbnail_url::TEXT,
        p.dominant_color::TEXT,
        p.likes_count,
        p.comments_count,
        p.shares_count,
        p.created_at,
        EXISTS(SELECT 1 FROM public.likes l WHERE l.post_id = p.id AND l.user_id = p_user_id) as is_liked,
        EXISTS(SELECT 1 FROM public.bookmarks b WHERE b.post_id = p.id AND b.user_id = p_user_id) as is_bookmarked
    FROM public.posts p
    INNER JOIN public.profiles pr ON p.user_id = pr.id
    LEFT JOIN public.communities c ON p.community_id = c.id
    WHERE 
        (pr.is_private = FALSE OR pr.id = p_user_id OR EXISTS (
            SELECT 1 FROM public.follows f 
            WHERE f.follower_id = p_user_id AND f.following_id = pr.id
        ))
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Add get_community_posts
DROP FUNCTION IF EXISTS get_community_posts(UUID, INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION get_community_posts(
    p_community_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    username TEXT,
    full_name TEXT,
    avatar_url TEXT,
    is_verified BOOLEAN,
    content TEXT,
    image_url TEXT,
    media_urls TEXT[],
    media_types TEXT[],
    community_id UUID,
    community_name TEXT,
    mood TEXT,
    thumbnail_url TEXT,
    dominant_color TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    shares_count INTEGER,
    created_at TIMESTAMPTZ,
    is_liked BOOLEAN,
    is_bookmarked BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        pr.username::TEXT,
        pr.full_name::TEXT,
        pr.avatar_url::TEXT,
        pr.is_verified,
        p.content::TEXT,
        p.image_url::TEXT,
        p.media_urls,
        p.media_types,
        p.community_id,
        c.name::TEXT as community_name,
        p.mood::TEXT,
        p.thumbnail_url::TEXT,
        p.dominant_color::TEXT,
        p.likes_count,
        p.comments_count,
        p.shares_count,
        p.created_at,
        -- Note: These status checks will return false unless we pass a user_id to the function
        -- For community viewing, we might need a version that accepts auth.uid()
        FALSE as is_liked,
        FALSE as is_bookmarked
    FROM public.posts p
    INNER JOIN public.profiles pr ON p.user_id = pr.id
    LEFT JOIN public.communities c ON p.community_id = c.id
    WHERE p.community_id = p_community_id
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;
