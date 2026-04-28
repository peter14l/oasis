-- Fortress Mode: One-tap lock with custom away messages
-- Allows users to lock the app with a "fortress" status visible to friends

-- Add fortress mode columns to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fortress_mode BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fortress_message VARCHAR(200);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fortress_until TIMESTAMPTZ;

-- Enable realtime for fortress status changes
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;

-- Create index for efficient fortress queries
CREATE INDEX IF NOT EXISTS idx_profiles_fortress_mode ON profiles(id) WHERE fortress_mode = true;

-- RLS policy to allow reading fortress status (but not modifying)
-- Friends can see if someone is in fortress mode and their away message
DROP POLICY IF EXISTS "Allow read fortress status" ON profiles;
CREATE POLICY "Allow read fortress status" ON profiles FOR SELECT USING (
  true
);

-- Only users can update their own fortress status
DROP POLICY IF EXISTS "Allow update own fortress status" ON profiles;
CREATE POLICY "Allow update own fortress status" ON profiles FOR UPDATE USING (
  auth.uid() = id
);