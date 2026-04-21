-- Migration to fix notifications table schema and update send_message_v2
-- This adds missing columns to notifications and fixes the INSERT statement in the RPC.

-- 1. Add missing columns to notifications table
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS title TEXT;

-- 2. Drop previous versions of the function to avoid overloading issues
DROP FUNCTION IF EXISTS public.send_message_v2(UUID, UUID, TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER, UUID, BOOLEAN, INTEGER, JSONB, TEXT, INTEGER, TEXT);
DROP FUNCTION IF EXISTS public.send_message_v2(UUID, UUID, TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER, UUID, BOOLEAN, INTEGER, JSONB, TEXT, INTEGER, TEXT, whisper_mode_type);
DROP FUNCTION IF EXISTS public.send_message_v2(UUID, UUID, TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER, UUID, BOOLEAN, INTEGER, JSONB, TEXT, INTEGER, TEXT, whisper_mode_type, UUID, UUID, UUID, UUID, JSONB, JSONB, TEXT);

-- 3. Re-create the final version with the fixed notifications insert
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
    p_call_id UUID DEFAULT NULL,
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

    -- 2. Insert message
    INSERT INTO messages (
        id, conversation_id, sender_id, content, 
        image_url, voice_url, file_url, file_name, file_size,
        reply_to_id, is_ephemeral, ephemeral_duration,
        encrypted_keys, iv, signal_message_type, signal_sender_content,
        voice_duration, whisper_mode,
        call_id, ripple_id, story_id, post_id,
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
        p_call_id, p_ripple_id, p_story_id, p_post_id,
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
            WHEN p_encrypted_keys IS NOT NULL THEN 'New encrypted message' 
            WHEN p_message_type = 'image' THEN '📷 Sent a photo'
            WHEN p_message_type = 'voice' THEN '🎤 Sent a voice message'
            ELSE p_content 
        END
    FROM conversation_participants cp
    WHERE cp.conversation_id = p_conversation_id
    AND cp.user_id != p_sender_id;

    -- 4. Return the message data with sender profile for immediate UI update
    SELECT jsonb_build_object(
        'id', m.id,
        'conversation_id', m.conversation_id,
        'sender_id', m.sender_id,
        'content', m.content,
        'created_at', m.created_at,
        'image_url', m.image_url,
        'voice_url', m.voice_url,
        'file_url', m.file_url,
        'voice_duration', m.voice_duration,
        'is_ephemeral', m.is_ephemeral,
        'ephemeral_duration', m.ephemeral_duration,
        'whisper_mode', m.whisper_mode,
        'media_view_mode', m.media_view_mode,
        'location_data', m.location_data,
        'sender_profile', jsonb_build_object(
            'username', p.username,
            'avatar_url', p.avatar_url
        )
    ) INTO v_result
    FROM messages m
    JOIN profiles p ON m.sender_id = p.id
    WHERE m.id = v_message_id;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
