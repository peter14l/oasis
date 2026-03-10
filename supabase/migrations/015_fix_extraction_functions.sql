-- =====================================================
-- FIX EXTRACTION FUNCTIONS
-- =====================================================
-- This migration fixes the extraction functions to handle cases where
-- no matches are found, preventing "FOREACH expression must not be null" errors.

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
        -- Use ARRAY(SELECT ...) to ensure we get an empty array instead of NULL if no matches
        SELECT ARRAY(
            SELECT (regexp_matches(NEW.content, '#([a-zA-Z0-9_]+)', 'g'))[1]
        ) INTO hashtag_matches;
        
        -- Process each hashtag
        IF hashtag_matches IS NOT NULL THEN
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
    END IF;
    
    RETURN NEW;
END;
$$;

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
        -- Use ARRAY(SELECT ...) to ensure we get an empty array instead of NULL if no matches
        SELECT ARRAY(
            SELECT (regexp_matches(NEW.content, '@([a-z0-9_]+)', 'g'))[1]
        ) INTO mention_matches;
        
        -- Process each mention
        IF mention_matches IS NOT NULL THEN
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
    END IF;
    
    RETURN NEW;
END;
$$;

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
        -- Use ARRAY(SELECT ...) to ensure we get an empty array instead of NULL if no matches
        SELECT ARRAY(
            SELECT (regexp_matches(NEW.content, '@([a-z0-9_]+)', 'g'))[1]
        ) INTO mention_matches;
        
        -- Process each mention
        IF mention_matches IS NOT NULL THEN
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
    END IF;
    
    RETURN NEW;
END;
$$;
