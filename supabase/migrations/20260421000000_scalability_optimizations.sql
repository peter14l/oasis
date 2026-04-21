-- 1. Optimize handle_new_message to remove O(N) unread_count updates
-- This prevents database IOPS spikes in large group chats.
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Update conversation last message info (single row update, fast)
    UPDATE public.conversations
    SET 
        last_message_id = NEW.id,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id
    AND (last_message_at IS NULL OR NEW.created_at >= last_message_at);

    -- We NO LONGER update unread_count for all participants here.
    -- Unread counts are now calculated dynamically or via a separate lightweight mechanism.
    
    -- Update sender's record to trigger realtime updates for their conversation list
    UPDATE public.conversation_participants
    SET updated_at = NOW()
    WHERE conversation_id = NEW.conversation_id
    AND user_id = NEW.sender_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Consolidate sendMessage into a single RPC
-- This reduces network round-trips from 5-6 down to 1.
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
    p_signal_sender_content TEXT DEFAULT NULL
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_message_id UUID := uuid_generate_v4();
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
        voice_duration
    ) VALUES (
        v_message_id, p_conversation_id, p_sender_id, p_content,
        CASE WHEN p_message_type = 'image' THEN p_media_url ELSE NULL END,
        CASE WHEN p_message_type = 'voice' THEN p_media_url ELSE NULL END,
        CASE WHEN p_message_type = 'document' THEN p_media_url ELSE NULL END,
        p_media_file_name, p_media_file_size,
        p_reply_to_id, p_is_ephemeral, p_ephemeral_duration,
        p_encrypted_keys, p_iv, p_signal_message_type, p_signal_sender_content,
        p_voice_duration
    );

    -- 3. Trigger notifications (Atomic batch insert)
    -- This offloads client-side looping and multiple HTTP requests.
    INSERT INTO notifications (user_id, type, actor_id, conversation_id, message_id, title, message)
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

-- 3. Update get_user_conversations_v2 to calculate unread counts dynamically
-- This allows us to remove the unread_count column update from the hot path.
CREATE OR REPLACE FUNCTION get_user_conversations_v2(p_user_id UUID)
RETURNS TABLE (
    id UUID,
    type TEXT,
    name TEXT,
    image_url TEXT,
    is_whisper_mode BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    unread_count INTEGER,
    cleared_at TIMESTAMPTZ,
    all_participants JSONB,
    last_message_data JSONB,
    sort_time TIMESTAMPTZ
) 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH user_convs AS (
        SELECT 
            c.id,
            c.type,
            c.name,
            c.image_url,
            c.is_whisper_mode,
            c.created_at,
            c.updated_at,
            cp.cleared_at as my_cleared,
            cp.last_read_at as my_last_read
        FROM conversations c
        JOIN conversation_participants cp ON c.id = cp.conversation_id
        WHERE cp.user_id = p_user_id
    ),
    unread_counts AS (
        -- Dynamic calculation of unread counts
        SELECT 
            uc.id as conversation_id,
            COUNT(m.id)::int as count
        FROM user_convs uc
        LEFT JOIN messages m ON m.conversation_id = uc.id
            AND m.sender_id != p_user_id
            AND (m.created_at > uc.my_last_read OR uc.my_last_read IS NULL)
            AND (uc.my_cleared IS NULL OR m.created_at > uc.my_cleared)
        GROUP BY uc.id
    ),
    latest_msgs AS (
        SELECT DISTINCT ON (m.conversation_id)
            m.conversation_id,
            m.id as msg_id,
            m.content as msg_content,
            m.sender_id as msg_sender_id,
            m.created_at as msg_created_at,
            m.image_url as msg_image_url,
            m.video_url as msg_video_url,
            m.file_url as msg_file_url,
            m.voice_url as msg_voice_url,
            m.iv as msg_iv,
            m.encrypted_keys as msg_encrypted_keys,
            m.signal_message_type as msg_signal_type,
            m.signal_sender_content as msg_signal_sender_content
        FROM messages m
        JOIN user_convs uc ON m.conversation_id = uc.id
        WHERE uc.my_cleared IS NULL OR m.created_at > uc.my_cleared
        ORDER BY m.conversation_id, m.created_at DESC
    )
    SELECT 
        uc.id,
        uc.type,
        uc.name,
        uc.image_url,
        uc.is_whisper_mode,
        uc.created_at,
        uc.updated_at,
        COALESCE(ur.count, 0) as unread_count,
        uc.my_cleared as cleared_at,
        (
            SELECT jsonb_agg(jsonb_build_object(
                'user_id', cp2.user_id,
                'profile', jsonb_build_object(
                    'username', p.username,
                    'full_name', p.full_name,
                    'avatar_url', p.avatar_url
                )
            ))
            FROM conversation_participants cp2
            JOIN profiles p ON cp2.user_id = p.id
            WHERE cp2.conversation_id = uc.id
        ) as all_participants,
        CASE 
            WHEN lm.msg_id IS NOT NULL THEN
                jsonb_build_object(
                    'id', lm.msg_id,
                    'content', lm.msg_content,
                    'sender_id', lm.msg_sender_id,
                    'created_at', lm.msg_created_at,
                    'image_url', lm.msg_image_url,
                    'video_url', lm.msg_video_url,
                    'file_url', lm.msg_file_url,
                    'voice_url', lm.msg_voice_url,
                    'iv', lm.msg_iv,
                    'encrypted_keys', lm.msg_encrypted_keys,
                    'signal_message_type', lm.msg_signal_type,
                    'signal_sender_content', lm.msg_signal_sender_content
                )
            ELSE NULL
        END as last_message_data,
        COALESCE(lm.msg_created_at, uc.created_at) as sort_time
    FROM user_convs uc
    LEFT JOIN unread_counts ur ON uc.id = ur.conversation_id
    LEFT JOIN latest_msgs lm ON uc.id = lm.conversation_id
    ORDER BY sort_time DESC;
END;
$$ LANGUAGE plpgsql;
