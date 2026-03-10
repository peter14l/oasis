-- =====================================================
-- FIX GET_FOLLOWING_FEED_POSTS FUNCTION
-- =====================================================
-- This migration fixes a bug in the get_following_feed_posts function
-- where it was checking if the user follows themselves instead of
-- checking if the user follows the post author.

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
    WHERE 
        -- Show posts from users you follow
        (EXISTS (
            SELECT 1 FROM public.follows f 
            WHERE f.follower_id = p_user_id AND f.following_id = pr.id
        ))
        -- Also show your own posts
        OR p.user_id = p_user_id
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;
