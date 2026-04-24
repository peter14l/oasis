-- Migration: Update send_message_v2 to support is_spoiler
-- Description: Adds p_is_spoiler parameter to the RPC function.

-- 1. Drop existing overloads to avoid conflicts
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT oid::regprocedure as proc_name 
              FROM pg_proc 
              WHERE proname = 'send_message_v2' 
              AND pronamespace = 'public'::regnamespace) 
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.proc_name;
    END LOOP;
END $$;

-- 2. Recreate with p_is_spoiler
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
    p_media_view_mode TEXT DEFAULT 'unlimited',
    p_is_spoiler BOOLEAN DEFAULT FALSE
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
        ripple_id, story_id, post_id,
        share_data, location_data, media_view_mode,
        is_spoiler
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
        p_share_data, p_location_data, p_media_view_mode,
        p_is_spoiler
    );

    -- 3. Trigger notifications
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
        'is_spoiler', m.is_spoiler,
        'created_at', m.created_at,
        'sender_profile', (SELECT json_build_object('username', username, 'avatar_url', avatar_url) FROM profiles WHERE id = p_sender_id)
    ) INTO v_result
    FROM messages m
    WHERE m.id = v_message_id;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
