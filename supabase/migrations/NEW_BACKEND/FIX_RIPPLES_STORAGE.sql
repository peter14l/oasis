-- =====================================================
-- OASIS - RIPPLES STORAGE SETUP
-- =====================================================

-- 1. Create Storage Bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('ripples-videos', 'ripples-videos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage Policies

-- SELECT: Anyone can view ripples
DROP POLICY IF EXISTS "Ripples are publicly accessible" ON storage.objects;
CREATE POLICY "Ripples are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'ripples-videos');

-- INSERT: Authenticated users can upload ripples to their own folder
DROP POLICY IF EXISTS "Users can upload their own ripples" ON storage.objects;
CREATE POLICY "Users can upload their own ripples"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'ripples-videos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- UPDATE: Users can update their own ripples
DROP POLICY IF EXISTS "Users can update their own ripples" ON storage.objects;
CREATE POLICY "Users can update their own ripples"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'ripples-videos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- DELETE: Users can delete their own ripples
DROP POLICY IF EXISTS "Users can delete their own ripples" ON storage.objects;
CREATE POLICY "Users can delete their own ripples"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'ripples-videos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);
