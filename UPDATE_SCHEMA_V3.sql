-- =====================================================
-- MORROW V2 TO V3 - SCHEMA UPDATES
-- =====================================================

-- 1. Add is_pro column to public.profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_pro BOOLEAN DEFAULT FALSE;

-- Create/Update function to handle sync from auth.users metadata
CREATE OR REPLACE FUNCTION public.handle_user_metadata_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.raw_user_meta_data->>'is_pro' IS NOT NULL THEN
    UPDATE public.profiles
    SET is_pro = (NEW.raw_user_meta_data->>'is_pro')::BOOLEAN
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger for metadata sync
DROP TRIGGER IF EXISTS on_auth_user_metadata_updated ON auth.users;
CREATE TRIGGER on_auth_user_metadata_updated
  AFTER UPDATE OF raw_user_meta_data ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_user_metadata_update();

-- Sync existing pro data from auth.users
UPDATE public.profiles p
SET is_pro = (u.raw_user_meta_data->>'is_pro')::BOOLEAN
FROM auth.users u
WHERE p.id = u.id AND u.raw_user_meta_data->>'is_pro' IS NOT NULL;


-- 2. Add message_id column to notifications table for E2E decryption
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_notifications_message_id ON public.notifications(message_id);


-- 3. Add voice message columns to messages table
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_url TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_duration INTEGER;

-- Update the message content constraint to include voice_url
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS message_has_content;
ALTER TABLE public.messages ADD CONSTRAINT message_has_content CHECK (
    content IS NOT NULL OR 
    image_url IS NOT NULL OR 
    video_url IS NOT NULL OR
    file_url IS NOT NULL OR
    voice_url IS NOT NULL
);


-- 4. Increase storage bucket limits to 150MB (157286400 bytes)
UPDATE storage.buckets 
SET file_size_limit = 157286400 
WHERE id IN (
  'message-attachments',
  'post-images',
  'post-videos',
  'community-images'
);

-- Ensure profile pictures have a reasonable 10MB limit
UPDATE storage.buckets
SET file_size_limit = 10485760
WHERE id = 'profile-pictures' AND (file_size_limit IS NULL OR file_size_limit < 10485760);
