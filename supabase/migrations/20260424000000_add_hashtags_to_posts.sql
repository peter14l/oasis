-- Add hashtags column to posts table
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS hashtags TEXT[] DEFAULT '{}';

-- Index for hashtag searching
CREATE INDEX IF NOT EXISTS idx_posts_hashtags ON public.posts USING GIN (hashtags);

-- Update extraction function to also populate the hashtags column
CREATE OR REPLACE FUNCTION extract_hashtags_from_post()
RETURNS TRIGGER AS $$
DECLARE
    hashtag_text TEXT;
    hashtag_record RECORD;
    hashtag_matches TEXT[];
    found_hashtags TEXT[] := '{}';
BEGIN
    -- Extract hashtags from content (matches #word)
    -- Using a regex that doesn't include the # in the capture group
    SELECT ARRAY(
        SELECT DISTINCT LOWER(substring(m[1] from 1))
        FROM regexp_matches(NEW.content, '#([a-zA-Z0-9_]+)', 'g') AS m
    ) INTO hashtag_matches;

    -- Update the NEW.hashtags column directly if content has tags
    IF hashtag_matches IS NOT NULL AND array_length(hashtag_matches, 1) > 0 THEN
        NEW.hashtags := hashtag_matches;
        
        -- Process each hashtag for the junction tables (trending, usage counts, etc)
        FOREACH hashtag_text IN ARRAY hashtag_matches
        LOOP
            -- Insert or update global hashtag registry
            INSERT INTO public.hashtags (tag, normalized_tag, usage_count, last_used_at)
            VALUES (hashtag_text, hashtag_text, 1, NOW())
            ON CONFLICT (normalized_tag) DO UPDATE SET
                usage_count = public.hashtags.usage_count + 1,
                last_used_at = NOW();
            
            -- Get the hashtag ID
            SELECT id INTO hashtag_record FROM public.hashtags WHERE normalized_tag = hashtag_text;

            -- Link hashtag to post in junction table
            INSERT INTO public.post_hashtags (post_id, hashtag_id)
            VALUES (NEW.id, hashtag_record.id)
            ON CONFLICT (post_id, hashtag_id) DO NOTHING;
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
