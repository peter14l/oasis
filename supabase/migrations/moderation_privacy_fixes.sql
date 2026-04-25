-- Moderation and Privacy Fixes for Feed RPCs

-- Drop existing functions first because we are changing the return type signature (parameter names/types)
DROP FUNCTION IF EXISTS get_feed_posts(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_following_feed_posts(UUID, INTEGER, INTEGER);

-- Function to get feed posts (for you) with blocking and privacy filters
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
    content TEXT,
    image_url TEXT,
    video_url TEXT,
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
        pr.username,
        pr.full_name,
        pr.avatar_url,
        p.content,
        p.image_url,
        p.video_url,
        p.likes_count,
        p.comments_count,
        p.shares_count,
        p.created_at,
        EXISTS(SELECT 1 FROM public.likes l WHERE l.post_id = p.id AND l.user_id = p_user_id) as is_liked,
        EXISTS(SELECT 1 FROM public.bookmarks b WHERE b.post_id = p.id AND b.user_id = p_user_id) as is_bookmarked
    FROM public.posts p
    INNER JOIN public.profiles pr ON p.user_id = pr.id
    WHERE 
        -- Show posts from public profiles or followed users
        (pr.is_private = FALSE OR pr.id = p_user_id OR EXISTS (
            SELECT 1 FROM public.follows f 
            WHERE f.follower_id = p_user_id AND f.following_id = pr.id
        ))
        -- Filter out blocked users (both directions)
        AND NOT is_user_blocked(p_user_id, p.user_id)
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Function to get following feed posts with blocking filters
CREATE OR REPLACE FUNCTION get_following_feed_posts(
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
    content TEXT,
    image_url TEXT,
    video_url TEXT,
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
        pr.username,
        pr.full_name,
        pr.avatar_url,
        p.content,
        p.image_url,
        p.video_url,
        p.likes_count,
        p.comments_count,
        p.shares_count,
        p.created_at,
        EXISTS(SELECT 1 FROM public.likes l WHERE l.post_id = p.id AND l.user_id = p_user_id) as is_liked,
        EXISTS(SELECT 1 FROM public.bookmarks b WHERE b.post_id = p.id AND b.user_id = p_user_id) as is_bookmarked
    FROM public.posts p
    INNER JOIN public.profiles pr ON p.user_id = pr.id
    WHERE EXISTS (
        SELECT 1 FROM public.follows f 
        WHERE f.follower_id = p_user_id AND f.following_id = p.user_id
    )
    -- Filter out blocked users (both directions)
    AND NOT is_user_blocked(p_user_id, p.user_id)
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;
