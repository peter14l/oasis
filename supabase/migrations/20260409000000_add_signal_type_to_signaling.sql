-- Migration to add Signal Protocol message type to call signaling
-- Description: Allows distinguishing between PreKey and Whisper messages in E2EE signaling.

ALTER TABLE call_signaling ADD COLUMN IF NOT EXISTS signal_message_type INTEGER;
COMMENT ON COLUMN call_signaling.signal_message_type IS 'Signal Protocol message type (1 = PreKey, 2 = Whisper)';
