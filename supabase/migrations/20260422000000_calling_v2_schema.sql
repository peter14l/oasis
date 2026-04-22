-- Phase 1: Clean Slate & Schema Overhaul
-- Migration: Calling V2 Schema
-- Description: Drops old calling tables and creates a simplified schema for V2 with ephemeral signaling.

-- 1. Database Cleanup
-- Remove foreign key from messages to prevent cascade issues
ALTER TABLE messages DROP COLUMN IF EXISTS call_id;

-- Drop old tables
DROP TABLE IF EXISTS call_signaling;
DROP TABLE IF EXISTS call_participants;
DROP TABLE IF EXISTS calls;

-- Drop old status type
DROP TYPE IF EXISTS call_status;

-- 2. Simplified Schema
-- Recreate call_status with new state machine
CREATE TYPE call_status AS ENUM ('ringing', 'active', 'ended', 'declined', 'missed');

-- Ensure call_type exists
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'call_type') THEN
        CREATE TYPE call_type AS ENUM ('voice', 'video');
    END IF;
END $$;

-- Recreate calls table
CREATE TABLE calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    caller_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    status call_status DEFAULT 'ringing',
    type call_type DEFAULT 'voice',
    offer JSONB,
    answer JSONB,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Everyone involved can see the call
CREATE POLICY "Users can see calls they are part of"
    ON calls FOR SELECT
    USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

-- Only caller can create the call
CREATE POLICY "Users can create calls"
    ON calls FOR INSERT
    WITH CHECK (auth.uid() = caller_id);

-- Both participants can update status, offer, answer, etc.
CREATE POLICY "Participants can update calls"
    ON calls FOR UPDATE
    USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

-- Performance Indexes
CREATE INDEX idx_calls_caller_id ON calls(caller_id);
CREATE INDEX idx_calls_receiver_id ON calls(receiver_id);
CREATE INDEX idx_calls_conversation_id ON calls(conversation_id);
CREATE INDEX idx_calls_status ON calls(status);

-- Enable Realtime for the calls table
ALTER PUBLICATION supabase_realtime ADD TABLE calls;

-- 3. Update send_message_v2 to remove call_id usage
CREATE OR REPLACE FUNCTION public.send_message_v2(
    p_conversation_id UUID,
    p_sender_id UUID,
    p_content TEXT,
    p_message_type TEXT DEFAULT 'text',
    p_media_url TEXT DEFAULT NULL,
    p_media_file_name TEXT DEFAULT NULL,
    p_media_file_size INTEGER DEFAULT NULL,
    p_voice_duration INTEGER DEFAULT NULL,
    p_reply_to_id UUID DEFAULT NULL,
    p_is_ephemeral BOOLEAN DEFAULT FALSE,
    p_ephemeral_duration INTEGER DEFAULT 86400,
    p_encrypted_keys JSONB DEFAULT NULL,
    p_iv TEXT DEFAULT NULL,
    p_signal_message_type INTEGER DEFAULT NULL,
    p_signal_sender_content TEXT DEFAULT NULL,
    p_whisper_mode whisper_mode_type DEFAULT 'OFF',
    p_ripple_id UUID DEFAULT NULL,
    p_story_id UUID DEFAULT NULL,
    p_post_id UUID DEFAULT NULL,
    p_share_data JSONB DEFAULT NULL,
    p_location_data JSONB DEFAULT NULL,
    p_media_view_mode TEXT DEFAULT 'unlimited'
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_message_id UUID := gen_random_uuid();
    v_recipient_id UUID;
    v_is_blocked BOOLEAN;
    v_result JSONB;
BEGIN
    -- 1. Check for blocks (only for direct messages)
    SELECT user_id INTO v_recipient_id
    FROM conversation_participants
    WHERE conversation_id = p_conversation_id
    AND user_id != p_sender_id
    LIMIT 1;

    IF v_recipient_id IS NOT NULL THEN
        SELECT EXISTS (
            SELECT 1 FROM blocked_users
            WHERE (blocker_id = v_recipient_id AND blocked_id = p_sender_id)
            OR (blocker_id = p_sender_id AND blocked_id = v_recipient_id)
        ) INTO v_is_blocked;

        IF v_is_blocked THEN
            RAISE EXCEPTION 'Message blocked';
        END IF;
    END IF;

    -- 2. Insert message (Removed call_id)
    INSERT INTO messages (
        id, conversation_id, sender_id, content, 
        image_url, voice_url, file_url, file_name, file_size,
        reply_to_id, is_ephemeral, ephemeral_duration,
        encrypted_keys, iv, signal_message_type, signal_sender_content,
        voice_duration, whisper_mode,
        ripple_id, story_id, post_id,
        share_data, location_data, media_view_mode
    ) VALUES (
        v_message_id, p_conversation_id, p_sender_id, p_content,
        CASE WHEN p_message_type IN ('image', 'gif', 'sticker') THEN p_media_url ELSE NULL END,
        CASE WHEN p_message_type = 'voice' THEN p_media_url ELSE NULL END,
        CASE WHEN p_message_type = 'document' THEN p_media_url ELSE NULL END,
        p_media_file_name, p_media_file_size,
        p_reply_to_id, p_is_ephemeral, p_ephemeral_duration,
        p_encrypted_keys, p_iv, p_signal_message_type, p_signal_sender_content,
        p_voice_duration, p_whisper_mode,
        p_ripple_id, p_story_id, p_post_id,
        p_share_data, p_location_data, p_media_view_mode
    );

    -- 3. Trigger notifications (Atomic batch insert)
    INSERT INTO notifications (user_id, type, actor_id, conversation_id, message_id, title, content)
    SELECT 
        cp.user_id, 
        'dm', 
        p_sender_id, 
        p_conversation_id, 
        v_message_id,
        (SELECT username FROM profiles WHERE id = p_sender_id),
        CASE 
            WHEN p_message_type = 'image' THEN 'Sent a photo'
            WHEN p_message_type = 'voice' THEN 'Sent a voice message'
            WHEN p_message_type = 'video' THEN 'Sent a video'
            WHEN p_message_type = 'document' THEN 'Sent a file'
            ELSE p_content
        END
    FROM conversation_participants cp
    WHERE cp.conversation_id = p_conversation_id
    AND cp.user_id != p_sender_id;

    -- 4. Update conversation metadata
    UPDATE conversations
    SET last_message_id = v_message_id,
        last_message_at = NOW()
    WHERE id = p_conversation_id;

    -- 5. Return the created message as JSON
    SELECT json_build_object(
        'id', m.id,
        'conversation_id', m.conversation_id,
        'sender_id', m.sender_id,
        'content', m.content,
        'message_type', p_message_type,
        'media_url', p_media_url,
        'file_name', m.file_name,
        'file_size', m.file_size,
        'reply_to_id', m.reply_to_id,
        'is_ephemeral', m.is_ephemeral,
        'ephemeral_duration', m.ephemeral_duration,
        'whisper_mode', m.whisper_mode,
        'created_at', m.created_at,
        'sender_profile', (SELECT json_build_object('username', username, 'avatar_url', avatar_url) FROM profiles WHERE id = p_sender_id)
    ) INTO v_result
    FROM messages m
    WHERE m.id = v_message_id;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
