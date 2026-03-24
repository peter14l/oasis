-- Migration: Update canvas_items for Collaboration 2.0
-- Adds reactions, locking, and presence tracking for items

ALTER TABLE canvas_items 
ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS last_modified_by UUID REFERENCES profiles(id),
ADD COLUMN IF NOT EXISTS unlock_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS group_id TEXT,
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- Ensure RLS allows updating these fields
-- Assuming existing policies allow update if is_canvas_member
