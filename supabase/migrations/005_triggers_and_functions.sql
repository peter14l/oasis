-- =====================================================
-- OASIS - TRIGGERS AND FUNCTIONS
-- =====================================================
-- This migration creates triggers and functions for automatic updates

-- =====================================================
-- UPDATED_AT TRIGGER FUNCTION
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_posts_updated_at ON public.posts;
CREATE TRIGGER update_posts_updated_at
    BEFORE UPDATE ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_communities_updated_at ON public.communities;
CREATE TRIGGER update_communities_updated_at
    BEFORE UPDATE ON public.communities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_comments_updated_at ON public.comments;
CREATE TRIGGER update_comments_updated_at
    BEFORE UPDATE ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_conversations_updated_at ON public.conversations;
CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON public.conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_messages_updated_at ON public.messages;
CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- PROFILE CREATION TRIGGER
-- =====================================================
-- Automatically create profile when user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, username, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL)
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- LIKE COUNT TRIGGERS
-- =====================================================
-- Increment likes count when a like is added
CREATE OR REPLACE FUNCTION increment_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.posts
    SET likes_count = likes_count + 1
    WHERE id = NEW.post_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_post_likes_count ON public.likes;
CREATE TRIGGER trigger_increment_post_likes_count
    AFTER INSERT ON public.likes
    FOR EACH ROW
    EXECUTE FUNCTION increment_post_likes_count();

-- Decrement likes count when a like is removed
CREATE OR REPLACE FUNCTION decrement_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.posts
    SET likes_count = GREATEST(0, likes_count - 1)
    WHERE id = OLD.post_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_post_likes_count ON public.likes;
CREATE TRIGGER trigger_decrement_post_likes_count
    AFTER DELETE ON public.likes
    FOR EACH ROW
    EXECUTE FUNCTION decrement_post_likes_count();

-- =====================================================
-- COMMENT COUNT TRIGGERS
-- =====================================================
-- Increment comments count when a comment is added
CREATE OR REPLACE FUNCTION increment_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.posts
    SET comments_count = comments_count + 1
    WHERE id = NEW.post_id;
    
    -- If it's a reply, increment the parent comment's replies count
    IF NEW.parent_comment_id IS NOT NULL THEN
        UPDATE public.comments
        SET replies_count = replies_count + 1
        WHERE id = NEW.parent_comment_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_post_comments_count ON public.comments;
CREATE TRIGGER trigger_increment_post_comments_count
    AFTER INSERT ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION increment_post_comments_count();

-- Decrement comments count when a comment is deleted
CREATE OR REPLACE FUNCTION decrement_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.posts
    SET comments_count = GREATEST(0, comments_count - 1)
    WHERE id = OLD.post_id;
    
    -- If it's a reply, decrement the parent comment's replies count
    IF OLD.parent_comment_id IS NOT NULL THEN
        UPDATE public.comments
        SET replies_count = GREATEST(0, replies_count - 1)
        WHERE id = OLD.parent_comment_id;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_post_comments_count ON public.comments;
CREATE TRIGGER trigger_decrement_post_comments_count
    AFTER DELETE ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION decrement_post_comments_count();

-- =====================================================
-- COMMENT LIKES COUNT TRIGGERS
-- =====================================================
-- Increment comment likes count
CREATE OR REPLACE FUNCTION increment_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.comments
    SET likes_count = likes_count + 1
    WHERE id = NEW.comment_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_comment_likes_count ON public.comment_likes;
CREATE TRIGGER trigger_increment_comment_likes_count
    AFTER INSERT ON public.comment_likes
    FOR EACH ROW
    EXECUTE FUNCTION increment_comment_likes_count();

-- Decrement comment likes count
CREATE OR REPLACE FUNCTION decrement_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.comments
    SET likes_count = GREATEST(0, likes_count - 1)
    WHERE id = OLD.comment_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_comment_likes_count ON public.comment_likes;
CREATE TRIGGER trigger_decrement_comment_likes_count
    AFTER DELETE ON public.comment_likes
    FOR EACH ROW
    EXECUTE FUNCTION decrement_comment_likes_count();

-- =====================================================
-- FOLLOWER COUNT TRIGGERS
-- =====================================================
-- Increment follower/following counts
CREATE OR REPLACE FUNCTION increment_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
    -- Increment follower count for the user being followed
    UPDATE public.profiles
    SET followers_count = followers_count + 1
    WHERE id = NEW.following_id;
    
    -- Increment following count for the follower
    UPDATE public.profiles
    SET following_count = following_count + 1
    WHERE id = NEW.follower_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_follow_counts ON public.follows;
CREATE TRIGGER trigger_increment_follow_counts
    AFTER INSERT ON public.follows
    FOR EACH ROW
    EXECUTE FUNCTION increment_follow_counts();

-- Decrement follower/following counts
CREATE OR REPLACE FUNCTION decrement_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
    -- Decrement follower count for the user being unfollowed
    UPDATE public.profiles
    SET followers_count = GREATEST(0, followers_count - 1)
    WHERE id = OLD.following_id;
    
    -- Decrement following count for the unfollower
    UPDATE public.profiles
    SET following_count = GREATEST(0, following_count - 1)
    WHERE id = OLD.follower_id;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_follow_counts ON public.follows;
CREATE TRIGGER trigger_decrement_follow_counts
    AFTER DELETE ON public.follows
    FOR EACH ROW
    EXECUTE FUNCTION decrement_follow_counts();

-- =====================================================
-- POST COUNT TRIGGERS
-- =====================================================
-- Increment post count when a post is created
CREATE OR REPLACE FUNCTION increment_user_posts_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.profiles
    SET posts_count = posts_count + 1
    WHERE id = NEW.user_id;
    
    -- If post is in a community, increment community posts count
    IF NEW.community_id IS NOT NULL THEN
        UPDATE public.communities
        SET posts_count = posts_count + 1
        WHERE id = NEW.community_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_user_posts_count ON public.posts;
CREATE TRIGGER trigger_increment_user_posts_count
    AFTER INSERT ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION increment_user_posts_count();

-- Decrement post count when a post is deleted
CREATE OR REPLACE FUNCTION decrement_user_posts_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.profiles
    SET posts_count = GREATEST(0, posts_count - 1)
    WHERE id = OLD.user_id;
    
    -- If post was in a community, decrement community posts count
    IF OLD.community_id IS NOT NULL THEN
        UPDATE public.communities
        SET posts_count = GREATEST(0, posts_count - 1)
        WHERE id = OLD.community_id;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_user_posts_count ON public.posts;
CREATE TRIGGER trigger_decrement_user_posts_count
    AFTER DELETE ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION decrement_user_posts_count();

