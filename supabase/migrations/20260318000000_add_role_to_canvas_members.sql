-- Add role column to canvas_members table
ALTER TABLE canvas_members ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'member';
