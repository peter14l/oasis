-- =====================================================
-- OASIS - NOTIFICATION TRIGGERS
-- =====================================================
-- This migration creates triggers for automatic notification creation

-- =====================================================
-- NOTIFICATION CREATION FUNCTIONS
-- =====================================================

-- Create notification for new like
CREATE OR REPLACE FUNCTION create_like_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_post_user_id UUID;
BEGIN
    -- Get the post owner's user_id
    SELECT user_id INTO v_post_user_id
    FROM public.posts
    WHERE id = NEW.post_id;
    
    -- Don't create notification if user likes their own post
    IF v_post_user_id != NEW.user_id THEN
        INSERT INTO public.notifications (user_id, actor_id, type, post_id)
        VALUES (v_post_user_id, NEW.user_id, 'like', NEW.post_id)
        ON CONFLICT DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_create_like_notification ON public.likes;
CREATE TRIGGER trigger_create_like_notification
    AFTER INSERT ON public.likes
    FOR EACH ROW
    EXECUTE FUNCTION create_like_notification();

-- Create notification for new comment
CREATE OR REPLACE FUNCTION create_comment_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_post_user_id UUID;
    v_parent_comment_user_id UUID;
BEGIN
    -- Get the post owner's user_id
    SELECT user_id INTO v_post_user_id
    FROM public.posts
    WHERE id = NEW.post_id;
    
    -- Create notification for post owner
    IF v_post_user_id != NEW.user_id THEN
        INSERT INTO public.notifications (user_id, actor_id, type, post_id, comment_id, content)
        VALUES (v_post_user_id, NEW.user_id, 'comment', NEW.post_id, NEW.id, NEW.content)
        ON CONFLICT DO NOTHING;
    END IF;
    
    -- If it's a reply to another comment, notify the parent comment author
    IF NEW.parent_comment_id IS NOT NULL THEN
        SELECT user_id INTO v_parent_comment_user_id
        FROM public.comments
        WHERE id = NEW.parent_comment_id;
        
        IF v_parent_comment_user_id != NEW.user_id AND v_parent_comment_user_id != v_post_user_id THEN
            INSERT INTO public.notifications (user_id, actor_id, type, post_id, comment_id, content)
            VALUES (v_parent_comment_user_id, NEW.user_id, 'comment', NEW.post_id, NEW.id, NEW.content)
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_create_comment_notification ON public.comments;
CREATE TRIGGER trigger_create_comment_notification
    AFTER INSERT ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION create_comment_notification();

-- Create notification for new follower
CREATE OR REPLACE FUNCTION create_follow_notification()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (user_id, actor_id, type)
    VALUES (NEW.following_id, NEW.follower_id, 'follow')
    ON CONFLICT DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_create_follow_notification ON public.follows;
CREATE TRIGGER trigger_create_follow_notification
    AFTER INSERT ON public.follows
    FOR EACH ROW
    EXECUTE FUNCTION create_follow_notification();

-- =====================================================
-- COMMUNITY MEMBER COUNT TRIGGERS
-- =====================================================

-- Increment community members count
CREATE OR REPLACE FUNCTION increment_community_members_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.communities
    SET members_count = members_count + 1
    WHERE id = NEW.community_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_community_members_count ON public.community_members;
CREATE TRIGGER trigger_increment_community_members_count
    AFTER INSERT ON public.community_members
    FOR EACH ROW
    EXECUTE FUNCTION increment_community_members_count();

-- Decrement community members count
CREATE OR REPLACE FUNCTION decrement_community_members_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.communities
    SET members_count = GREATEST(0, members_count - 1)
    WHERE id = OLD.community_id;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_community_members_count ON public.community_members;
CREATE TRIGGER trigger_decrement_community_members_count
    AFTER DELETE ON public.community_members
    FOR EACH ROW
    EXECUTE FUNCTION decrement_community_members_count();

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Function to delete user account and all related data
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS VOID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Delete all user data (cascading deletes will handle related records)
    DELETE FROM public.profiles WHERE id = v_user_id;
    
    -- Delete auth user
    DELETE FROM auth.users WHERE id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get feed posts (for you)
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
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Function to get following feed posts
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
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Function to get user's conversations with last message
CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id UUID)
RETURNS TABLE (
    conversation_id UUID,
    conversation_type TEXT,
    conversation_name TEXT,
    conversation_image_url TEXT,
    other_user_id UUID,
    other_user_username TEXT,
    other_user_full_name TEXT,
    other_user_avatar_url TEXT,
    last_message_content TEXT,
    last_message_at TIMESTAMPTZ,
    unread_count INTEGER,
    is_muted BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as conversation_id,
        c.type as conversation_type,
        c.name as conversation_name,
        c.image_url as conversation_image_url,
        CASE 
            WHEN c.type = 'direct' THEN (
                SELECT cp2.user_id 
                FROM public.conversation_participants cp2 
                WHERE cp2.conversation_id = c.id AND cp2.user_id != p_user_id 
                LIMIT 1
            )
            ELSE NULL
        END as other_user_id,
        CASE 
            WHEN c.type = 'direct' THEN (
                SELECT pr.username 
                FROM public.conversation_participants cp2 
                INNER JOIN public.profiles pr ON cp2.user_id = pr.id
                WHERE cp2.conversation_id = c.id AND cp2.user_id != p_user_id 
                LIMIT 1
            )
            ELSE NULL
        END as other_user_username,
        CASE 
            WHEN c.type = 'direct' THEN (
                SELECT pr.full_name 
                FROM public.conversation_participants cp2 
                INNER JOIN public.profiles pr ON cp2.user_id = pr.id
                WHERE cp2.conversation_id = c.id AND cp2.user_id != p_user_id 
                LIMIT 1
            )
            ELSE NULL
        END as other_user_full_name,
        CASE 
            WHEN c.type = 'direct' THEN (
                SELECT pr.avatar_url 
                FROM public.conversation_participants cp2 
                INNER JOIN public.profiles pr ON cp2.user_id = pr.id
                WHERE cp2.conversation_id = c.id AND cp2.user_id != p_user_id 
                LIMIT 1
            )
            ELSE NULL
        END as other_user_avatar_url,
        m.content as last_message_content,
        c.last_message_at,
        cp.unread_count,
        cp.is_muted
    FROM public.conversations c
    INNER JOIN public.conversation_participants cp ON c.id = cp.conversation_id
    LEFT JOIN public.messages m ON c.last_message_id = m.id
    WHERE cp.user_id = p_user_id
    ORDER BY c.last_message_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql;

