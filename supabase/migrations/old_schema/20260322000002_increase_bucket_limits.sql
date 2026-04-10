-- Increase file size limit for storage buckets to 150MB (157286400 bytes)
UPDATE storage.buckets 
SET file_size_limit = 157286400 
WHERE id IN (
  'message-attachments',
  'post-images',
  'post-videos',
  'community-images'
);

-- Also ensure profile pictures have a reasonable limit if they didn't have one
UPDATE storage.buckets
SET file_size_limit = 10485760 -- 10MB
WHERE id = 'profile-pictures' AND file_size_limit IS NULL;
