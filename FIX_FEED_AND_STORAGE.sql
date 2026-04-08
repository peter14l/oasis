-- =====================================================
-- OASIS - FIX FEED AND STORAGE POLICIES
-- =====================================================

-- 1. ENSURE POSTS TABLE HAS ALL REQUIRED COLUMNS
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS media_urls TEXT[] DEFAULT '{}';
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS media_types TEXT[] DEFAULT '{}';
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS mood VARCHAR(50);
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS dominant_color TEXT;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS video_url TEXT;

-- 2. RE-CREATE FEED RPC FUNCTIONS
-- This ensures the feed correctly returns all columns expected by the Flutter app.

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
        COALESCE(p.media_urls, ARRAY[]::TEXT[]),
        COALESCE(p.media_types, ARRAY[]::TEXT[]),
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

DROP FUNCTION IF EXISTS get_following_feed_posts(UUID, INTEGER, INTEGER);
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
        COALESCE(p.media_urls, ARRAY[]::TEXT[]),
        COALESCE(p.media_types, ARRAY[]::TEXT[]),
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
    WHERE EXISTS (
        SELECT 1 FROM public.follows f 
        WHERE f.follower_id = p_user_id AND f.following_id = p.user_id
    )
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- 3. SETUP STORAGE BUCKETS AND POLICIES

-- Create Buckets if they don't exist
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('profile-pictures', 'profile-pictures', true),
    ('post-images', 'post-images', true),
    ('post-videos', 'post-videos', true),
    ('community-images', 'community-images', true),
    ('message-attachments', 'message-attachments', false),
    ('stories', 'stories', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies for 'profile-pictures'
DROP POLICY IF EXISTS "Public View Profile Pictures" ON storage.objects;
CREATE POLICY "Public View Profile Pictures" ON storage.objects FOR SELECT USING (bucket_id = 'profile-pictures');
CREATE POLICY "Authenticated Upload Profile Pictures" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'profile-pictures' AND auth.role() = 'authenticated');
CREATE POLICY "Owners Update Profile Pictures" ON storage.objects FOR UPDATE USING (bucket_id = 'profile-pictures' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Owners Delete Profile Pictures" ON storage.objects FOR DELETE USING (bucket_id = 'profile-pictures' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage Policies for 'post-images'
CREATE POLICY "Public View Post Images" ON storage.objects FOR SELECT USING (bucket_id = 'post-images');
CREATE POLICY "Authenticated Upload Post Images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'post-images' AND auth.role() = 'authenticated');
CREATE POLICY "Owners Update Post Images" ON storage.objects FOR UPDATE USING (bucket_id = 'post-images' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Owners Delete Post Images" ON storage.objects FOR DELETE USING (bucket_id = 'post-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage Policies for 'post-videos'
CREATE POLICY "Public View Post Videos" ON storage.objects FOR SELECT USING (bucket_id = 'post-videos');
CREATE POLICY "Authenticated Upload Post Videos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'post-videos' AND auth.role() = 'authenticated');
CREATE POLICY "Owners Update Post Videos" ON storage.objects FOR UPDATE USING (bucket_id = 'post-videos' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Owners Delete Post Videos" ON storage.objects FOR DELETE USING (bucket_id = 'post-videos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage Policies for 'community-images'
CREATE POLICY "Public View Community Images" ON storage.objects FOR SELECT USING (bucket_id = 'community-images');
CREATE POLICY "Authenticated Upload Community Images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'community-images' AND auth.role() = 'authenticated');

-- Storage Policies for 'message-attachments'
CREATE POLICY "Authenticated View Message Attachments" ON storage.objects FOR SELECT USING (bucket_id = 'message-attachments' AND auth.role() = 'authenticated');
CREATE POLICY "Authenticated Upload Message Attachments" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'message-attachments' AND auth.role() = 'authenticated');

-- Storage Policies for 'stories'
CREATE POLICY "Public View Stories" ON storage.objects FOR SELECT USING (bucket_id = 'stories');
CREATE POLICY "Authenticated Upload Stories" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'stories' AND auth.role() = 'authenticated');
