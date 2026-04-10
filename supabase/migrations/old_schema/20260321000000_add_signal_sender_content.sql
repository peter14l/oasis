-- Add columns to store the sender's encrypted copy of the message for Signal
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS signal_sender_content TEXT,
ADD COLUMN IF NOT EXISTS signal_sender_message_type INTEGER;
