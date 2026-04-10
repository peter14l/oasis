-- =====================================================
-- FIX MESSAGE ATTACHMENTS STORAGE ACCESS
-- =====================================================
-- This migration fixes the message-attachments bucket to allow
-- public read access so images can load in the chat UI

-- Update bucket to be public
UPDATE storage.buckets
SET public = true
WHERE id = 'message-attachments';

-- Drop the existing restrictive SELECT policy
DROP POLICY IF EXISTS "Conversation participants can view message attachments" ON storage.objects;

-- Create new public SELECT policy
CREATE POLICY "Message attachments are publicly accessible"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'message-attachments');

-- Note: Upload and delete policies remain authenticated-only for security
