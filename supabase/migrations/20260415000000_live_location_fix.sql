-- Add 'live_location' to allowed media_view_mode values
-- Fixes: "Failed to share live location" - check constraint violation

ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_media_view_mode_check;

ALTER TABLE messages ADD CONSTRAINT messages_media_view_mode_check 
    CHECK (media_view_mode IN ('unlimited', 'once', 'twice', 'live_location'));