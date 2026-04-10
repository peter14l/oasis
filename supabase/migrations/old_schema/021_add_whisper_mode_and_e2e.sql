-- Add Whisper Mode and E2E Encryption Support
-- Migration: 021_add_whisper_mode_and_e2e.sql

-- Add Whisper Mode to conversations
ALTER TABLE conversations
ADD COLUMN IF NOT EXISTS is_whisper_mode BOOLEAN DEFAULT FALSE;

-- Add E2E encryption fields to profiles
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS public_key TEXT,
ADD COLUMN IF NOT EXISTS encrypted_private_key TEXT;

-- Add ephemeral and encryption fields to messages
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS is_ephemeral BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS encrypted_keys JSONB,
ADD COLUMN IF NOT EXISTS iv TEXT;

-- Create trigger function to mark messages as ephemeral in whisper mode
CREATE OR REPLACE FUNCTION handle_new_message_in_whisper_mode()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if the conversation is in whisper mode
  IF EXISTS (
    SELECT 1 FROM conversations 
    WHERE id = NEW.conversation_id 
    AND is_whisper_mode = TRUE
  ) THEN
    NEW.is_ephemeral := TRUE;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new messages
DROP TRIGGER IF EXISTS trigger_whisper_mode_messages ON messages;
CREATE TRIGGER trigger_whisper_mode_messages
  BEFORE INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_message_in_whisper_mode();

-- Create trigger function to set expiration when message is read
CREATE OR REPLACE FUNCTION set_message_expiration()
RETURNS TRIGGER AS $$
DECLARE
  v_is_ephemeral BOOLEAN;
  v_expires_at TIMESTAMPTZ;
BEGIN
  -- Get message details
  SELECT is_ephemeral, expires_at INTO v_is_ephemeral, v_expires_at
  FROM messages
  WHERE id = NEW.message_id;

  -- If message is ephemeral and has no expiration set, set it now
  IF v_is_ephemeral = TRUE AND v_expires_at IS NULL THEN
    UPDATE messages
    SET expires_at = NOW() + INTERVAL '24 hours'
    WHERE id = NEW.message_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for message reads
DROP TRIGGER IF EXISTS trigger_message_expiration ON message_read_receipts;
CREATE TRIGGER trigger_message_expiration
  AFTER INSERT ON message_read_receipts
  FOR EACH ROW
  EXECUTE FUNCTION set_message_expiration();

-- Create index for efficient expired message queries
CREATE INDEX IF NOT EXISTS idx_messages_expires_at 
ON messages(expires_at) 
WHERE expires_at IS NOT NULL;

-- Create index for whisper mode conversations
CREATE INDEX IF NOT EXISTS idx_conversations_whisper_mode 
ON conversations(is_whisper_mode) 
WHERE is_whisper_mode = TRUE;

-- Add RLS policies for encryption keys
-- Allow users to read their own public keys
CREATE POLICY "Users can read public keys"
ON profiles FOR SELECT
USING (true);

-- Allow users to update their own encryption keys
CREATE POLICY "Users can update own encryption keys"
ON profiles FOR UPDATE
USING (auth.uid() = id);
