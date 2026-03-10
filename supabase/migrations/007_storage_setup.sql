-- =====================================================
-- MORROW V2 - STORAGE BUCKETS SETUP
-- =====================================================
-- This migration creates storage buckets and policies for file uploads

-- =====================================================
-- CREATE STORAGE BUCKETS
-- =====================================================

-- Profile pictures bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-pictures', 'profile-pictures', true)
ON CONFLICT (id) DO NOTHING;

-- Post images bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('post-images', 'post-images', true)
ON CONFLICT (id) DO NOTHING;

-- Post videos bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('post-videos', 'post-videos', true)
ON CONFLICT (id) DO NOTHING;

-- Community images bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('community-images', 'community-images', true)
ON CONFLICT (id) DO NOTHING;

-- Message attachments bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('message-attachments', 'message-attachments', false)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STORAGE POLICIES - PROFILE PICTURES
-- =====================================================

-- Anyone can view profile pictures
CREATE POLICY "Profile pictures are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-pictures');

-- Users can upload their own profile pictures
CREATE POLICY "Users can upload their own profile pictures"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'profile-pictures' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can update their own profile pictures
CREATE POLICY "Users can update their own profile pictures"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'profile-pictures' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own profile pictures
CREATE POLICY "Users can delete their own profile pictures"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'profile-pictures' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- STORAGE POLICIES - POST IMAGES
-- =====================================================

-- Anyone can view post images
CREATE POLICY "Post images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'post-images');

-- Authenticated users can upload post images
CREATE POLICY "Authenticated users can upload post images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'post-images' AND
    auth.role() = 'authenticated'
);

-- Users can update their own post images
CREATE POLICY "Users can update their own post images"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'post-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own post images
CREATE POLICY "Users can delete their own post images"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'post-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- STORAGE POLICIES - POST VIDEOS
-- =====================================================

-- Anyone can view post videos
CREATE POLICY "Post videos are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'post-videos');

-- Authenticated users can upload post videos
CREATE POLICY "Authenticated users can upload post videos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'post-videos' AND
    auth.role() = 'authenticated'
);

-- Users can update their own post videos
CREATE POLICY "Users can update their own post videos"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'post-videos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own post videos
CREATE POLICY "Users can delete their own post videos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'post-videos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- STORAGE POLICIES - COMMUNITY IMAGES
-- =====================================================

-- Anyone can view community images
CREATE POLICY "Community images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'community-images');

-- Authenticated users can upload community images
CREATE POLICY "Authenticated users can upload community images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'community-images' AND
    auth.role() = 'authenticated'
);

-- Community admins can update community images
CREATE POLICY "Community admins can update community images"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'community-images' AND
    auth.role() = 'authenticated'
);

-- Community admins can delete community images
CREATE POLICY "Community admins can delete community images"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'community-images' AND
    auth.role() = 'authenticated'
);

-- =====================================================
-- STORAGE POLICIES - MESSAGE ATTACHMENTS
-- =====================================================

-- Only conversation participants can view message attachments
CREATE POLICY "Conversation participants can view message attachments"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'message-attachments' AND
    auth.role() = 'authenticated'
);

-- Authenticated users can upload message attachments
CREATE POLICY "Authenticated users can upload message attachments"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'message-attachments' AND
    auth.role() = 'authenticated'
);

-- Users can delete their own message attachments
CREATE POLICY "Users can delete their own message attachments"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'message-attachments' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

