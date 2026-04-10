-- =====================================================
-- FIX GET_FOLLOWING_STORIES FUNCTION
-- =====================================================
-- This migration updates the get_following_stories function to include
-- the current user's own stories in the list, not just followed users.

DROP FUNCTION IF EXISTS get_following_stories(uuid);

CREATE OR REPLACE FUNCTION get_following_stories(requesting_user_id UUID)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    story_count BIGINT,
    has_unviewed BOOLEAN,
    latest_story_at TIMESTAMPTZ,
    stories jsonb
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
        MAX(s.created_at) as latest_story_at,
        jsonb_agg(
            jsonb_build_object(
                'id', s.id,
                'user_id', s.user_id,
                'media_url', s.media_url,
                'media_type', s.media_type,
                'thumbnail_url', s.thumbnail_url,
                'caption', s.caption,
                'duration', s.duration,
                'created_at', s.created_at,
                'expires_at', s.expires_at,
                'view_count', s.view_count,
                'has_viewed', EXISTS(
                    SELECT 1 FROM public.story_views sv
                    WHERE sv.story_id = s.id AND sv.viewer_id = requesting_user_id
                )
            ) ORDER BY s.created_at ASC
        ) as stories
    FROM public.profiles p
    INNER JOIN public.stories s ON s.user_id = p.id
    WHERE 
        -- Include followed users OR the current user
        (p.id = requesting_user_id OR EXISTS (
            SELECT 1 FROM public.follows f 
            WHERE f.follower_id = requesting_user_id AND f.following_id = p.id
        ))
        AND s.expires_at > NOW()
    GROUP BY p.id, p.username, p.avatar_url
    ORDER BY 
        -- Put current user first
        (p.id = requesting_user_id) DESC,
        -- Then unviewed stories
        has_unviewed DESC, 
        -- Then latest
        latest_story_at DESC;
END;
$$;
