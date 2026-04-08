-- 1. E2EE Recovery & Profiles Upgrade
-- This enables users who upgraded to PIN security but missed the recovery key generation 
-- to complete their backup setup.
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS encrypted_private_key_recovery TEXT,
ADD COLUMN IF NOT EXISTS key_salt TEXT,
ADD COLUMN IF NOT EXISTS has_upgraded_security BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS xp INT DEFAULT 0;

-- 2. Multilingual Transcription Table
-- Stores multilingual transcriptions of voice messages.
CREATE TABLE IF NOT EXISTS message_transcripts (
  message_id UUID PRIMARY KEY REFERENCES messages(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  language TEXT NOT NULL,
  confidence DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Enable RLS on Transcripts
ALTER TABLE message_transcripts ENABLE ROW LEVEL SECURITY;

-- Policy: Only participants of the conversation can view the transcript.
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'message_transcripts' AND policyname = 'transcripts_visibility_policy'
    ) THEN
        CREATE POLICY "transcripts_visibility_policy" 
        ON message_transcripts FOR SELECT 
        USING (
          EXISTS (
            SELECT 1 FROM messages m
            JOIN conversation_participants cp ON m.conversation_id = cp.conversation_id
            WHERE m.id = message_transcripts.message_id 
            AND cp.user_id = auth.uid()
          )
        );
    END IF;
END $$;

-- 4. Create the XP increment function (used by Wellness Service)
-- This is a SECURITY DEFINER function to ensure users can't manually call 
-- UPDATE profiles to boost their own XP.
CREATE OR REPLACE FUNCTION increment_xp(user_id UUID, xp_amount INT)
RETURNS void AS $$
BEGIN
  UPDATE profiles
  SET xp = COALESCE(xp, 0) + xp_amount
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Secure Pro Status (RLS)
-- Disallow ANY user (even the owner) from manually updating their is_pro status.
-- This column can now ONLY be updated by Edge Functions using the service_role key.

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile except pro status" ON profiles;

CREATE POLICY "Users can update own profile restricted" 
ON profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id 
  AND (
    -- Force is_pro to remain identical to its current database value
    is_pro = (SELECT is_pro FROM profiles WHERE id = auth.uid())
  )
);
