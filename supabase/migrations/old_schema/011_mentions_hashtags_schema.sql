-- =====================================================
-- MENTIONS & HASHTAGS FEATURE - DATABASE SCHEMA
-- =====================================================
-- This migration creates tables for user mentions and hashtags

-- =====================================================
-- HASHTAGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.hashtags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tag TEXT UNIQUE NOT NULL,
    normalized_tag TEXT UNIQUE NOT NULL, -- lowercase version for matching
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT tag_format CHECK (tag ~ '^[a-zA-Z0-9_]+$'),
    CONSTRAINT tag_length CHECK (char_length(tag) >= 2 AND char_length(tag) <= 50)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_hashtags_tag ON public.hashtags(tag);
CREATE INDEX IF NOT EXISTS idx_hashtags_normalized_tag ON public.hashtags(normalized_tag);
CREATE INDEX IF NOT EXISTS idx_hashtags_usage_count ON public.hashtags(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_hashtags_last_used_at ON public.hashtags(last_used_at DESC);

-- =====================================================
-- POST HASHTAGS TABLE (junction table)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.post_hashtags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    hashtag_id UUID NOT NULL REFERENCES public.hashtags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint
    UNIQUE(post_id, hashtag_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_post_hashtags_post_id ON public.post_hashtags(post_id);
CREATE INDEX IF NOT EXISTS idx_post_hashtags_hashtag_id ON public.post_hashtags(hashtag_id);

-- =====================================================
-- MENTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.mentions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    mentioned_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    mentioned_by_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure mention is in either post or comment
    CONSTRAINT mention_source CHECK (
        (post_id IS NOT NULL AND comment_id IS NULL) OR
        (post_id IS NULL AND comment_id IS NOT NULL)
    )
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_mentions_post_id ON public.mentions(post_id);
CREATE INDEX IF NOT EXISTS idx_mentions_comment_id ON public.mentions(comment_id);
CREATE INDEX IF NOT EXISTS idx_mentions_mentioned_user_id ON public.mentions(mentioned_user_id);
CREATE INDEX IF NOT EXISTS idx_mentions_mentioned_by_user_id ON public.mentions(mentioned_by_user_id);

-- =====================================================
-- FUNCTION: Extract and save hashtags from post
-- =====================================================
CREATE OR REPLACE FUNCTION extract_hashtags_from_post()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    hashtag_text TEXT;
    hashtag_record RECORD;
    hashtag_matches TEXT[];
BEGIN
    -- Extract hashtags from content (matches #word)
    IF NEW.content IS NOT NULL THEN
        hashtag_matches := regexp_matches(NEW.content, '#([a-zA-Z0-9_]+)', 'g');
        
        -- Process each hashtag
        FOREACH hashtag_text IN ARRAY hashtag_matches
        LOOP
            -- Insert or update hashtag
            INSERT INTO public.hashtags (tag, normalized_tag, usage_count, last_used_at)
            VALUES (hashtag_text, LOWER(hashtag_text), 1, NOW())
            ON CONFLICT (normalized_tag) 
            DO UPDATE SET 
                usage_count = public.hashtags.usage_count + 1,
                last_used_at = NOW()
            RETURNING * INTO hashtag_record;
            
            -- Link hashtag to post
            INSERT INTO public.post_hashtags (post_id, hashtag_id)
            VALUES (NEW.id, hashtag_record.id)
            ON CONFLICT (post_id, hashtag_id) DO NOTHING;
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for hashtag extraction
DROP TRIGGER IF EXISTS trigger_extract_hashtags_from_post ON public.posts;
CREATE TRIGGER trigger_extract_hashtags_from_post
    AFTER INSERT OR UPDATE OF content ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION extract_hashtags_from_post();

-- =====================================================
-- FUNCTION: Extract and save mentions from post
-- =====================================================
CREATE OR REPLACE FUNCTION extract_mentions_from_post()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    mention_username TEXT;
    mentioned_user_record RECORD;
    mention_matches TEXT[];
BEGIN
    -- Extract mentions from content (matches @username)
    IF NEW.content IS NOT NULL THEN
        mention_matches := regexp_matches(NEW.content, '@([a-z0-9_]+)', 'g');
        
        -- Process each mention
        FOREACH mention_username IN ARRAY mention_matches
        LOOP
            -- Find the mentioned user
            SELECT * INTO mentioned_user_record
            FROM public.profiles
            WHERE username = mention_username;
            
            -- If user exists, create mention
            IF FOUND THEN
                INSERT INTO public.mentions (
                    post_id, 
                    mentioned_user_id, 
                    mentioned_by_user_id
                )
                VALUES (
                    NEW.id, 
                    mentioned_user_record.id, 
                    NEW.user_id
                )
                ON CONFLICT DO NOTHING;
                
                -- Create notification for mentioned user
                INSERT INTO public.notifications (
                    user_id,
                    actor_id,
                    type,
                    post_id,
                    content
                )
                VALUES (
                    mentioned_user_record.id,
                    NEW.user_id,
                    'mention',
                    NEW.id,
                    'mentioned you in a post'
                );
            END IF;
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for mention extraction
DROP TRIGGER IF EXISTS trigger_extract_mentions_from_post ON public.posts;
CREATE TRIGGER trigger_extract_mentions_from_post
    AFTER INSERT OR UPDATE OF content ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION extract_mentions_from_post();

-- =====================================================
-- FUNCTION: Extract mentions from comments
-- =====================================================
CREATE OR REPLACE FUNCTION extract_mentions_from_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    mention_username TEXT;
    mentioned_user_record RECORD;
    mention_matches TEXT[];
BEGIN
    -- Extract mentions from content (matches @username)
    IF NEW.content IS NOT NULL THEN
        mention_matches := regexp_matches(NEW.content, '@([a-z0-9_]+)', 'g');
        
        -- Process each mention
        FOREACH mention_username IN ARRAY mention_matches
        LOOP
            -- Find the mentioned user
            SELECT * INTO mentioned_user_record
            FROM public.profiles
            WHERE username = mention_username;
            
            -- If user exists, create mention
            IF FOUND THEN
                INSERT INTO public.mentions (
                    comment_id, 
                    mentioned_user_id, 
                    mentioned_by_user_id
                )
                VALUES (
                    NEW.id, 
                    mentioned_user_record.id, 
                    NEW.user_id
                )
                ON CONFLICT DO NOTHING;
                
                -- Create notification for mentioned user
                INSERT INTO public.notifications (
                    user_id,
                    actor_id,
                    type,
                    comment_id,
                    content
                )
                VALUES (
                    mentioned_user_record.id,
                    NEW.user_id,
                    'mention',
                    NEW.id,
                    'mentioned you in a comment'
                );
            END IF;
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for comment mentions
DROP TRIGGER IF EXISTS trigger_extract_mentions_from_comment ON public.comments;
CREATE TRIGGER trigger_extract_mentions_from_comment
    AFTER INSERT OR UPDATE OF content ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION extract_mentions_from_comment();

-- =====================================================
-- FUNCTION: Get trending hashtags
-- =====================================================
CREATE OR REPLACE FUNCTION get_trending_hashtags(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    tag TEXT,
    usage_count INTEGER,
    recent_usage_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.id,
        h.tag,
        h.usage_count,
        COUNT(ph.id) as recent_usage_count
    FROM public.hashtags h
    LEFT JOIN public.post_hashtags ph ON ph.hashtag_id = h.id
    LEFT JOIN public.posts p ON p.id = ph.post_id
    WHERE p.created_at > NOW() - INTERVAL '7 days' OR p.created_at IS NULL
    GROUP BY h.id, h.tag, h.usage_count
    ORDER BY recent_usage_count DESC, h.usage_count DESC
    LIMIT limit_count;
END;
$$;

-- =====================================================
-- FUNCTION: Search hashtags
-- =====================================================
CREATE OR REPLACE FUNCTION search_hashtags(search_query TEXT, limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    tag TEXT,
    usage_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.id,
        h.tag,
        h.usage_count
    FROM public.hashtags h
    WHERE h.normalized_tag LIKE LOWER(search_query) || '%'
    ORDER BY h.usage_count DESC
    LIMIT limit_count;
END;
$$;
