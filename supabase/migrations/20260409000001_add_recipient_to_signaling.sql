-- Migration to add recipient_id to call signaling for Mesh P2P
-- Description: Allows targeting specific peers in a multi-participant call.

ALTER TABLE call_signaling ADD COLUMN IF NOT EXISTS recipient_id UUID REFERENCES profiles(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_call_signaling_recipient_id ON call_signaling(recipient_id);

-- Update RLS policies to include recipient-based access
DROP POLICY IF EXISTS "Users can see signaling for calls they are part of" ON call_signaling;
CREATE POLICY "Users can see signaling meant for them or sent by them"
    ON call_signaling FOR SELECT
    USING (auth.uid() = recipient_id OR auth.uid() = sender_id);
