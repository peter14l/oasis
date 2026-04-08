-- =====================================================
-- RIPPLES STORAGE RLS POLICIES
-- =====================================================
-- This script applies RLS policies for the 'ripples-videos' bucket.
-- Convention: files are stored at path '{user_id}/{filename}'

-- 1. Ensure the bucket is public (allows public URL access)
UPDATE storage.buckets 
SET public = true 
WHERE id = 'ripples-videos';

-- 2. SELECT: Anyone can view ripples (Publicly accessible)
CREATE POLICY "Ripples are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'ripples-videos');

-- 3. INSERT: Authenticated users can upload to their own folder
CREATE POLICY "Users can upload their own ripples"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'ripples-videos' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. UPDATE: Users can update their own ripples
CREATE POLICY "Users can update their own ripples"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'ripples-videos' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- 5. DELETE: Users can delete their own ripples
CREATE POLICY "Users can delete their own ripples"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'ripples-videos' AND
    (storage.foldername(name))[1] = auth.uid()::text
);
