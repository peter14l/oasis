-- Add storage provider info to content tables
ALTER TABLE posts ADD COLUMN IF NOT EXISTS storage_provider TEXT DEFAULT 'supabase';
ALTER TABLE ripples ADD COLUMN IF NOT EXISTS storage_provider TEXT DEFAULT 'supabase';
