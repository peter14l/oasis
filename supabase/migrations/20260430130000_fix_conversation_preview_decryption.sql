-- Migration: Update get_user_conversations_v2 to include E2EE metadata in last_message_data
-- This ensures that chat previews (like in the Bento Grid) can be decrypted by the client.

CREATE OR REPLACE FUNCTION public.get_user_conversations_v2(p_user_id UUID)
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
SECURITY DEFINER SET search_path = public AS $$
BEGIN
    RETURN QUERY
    WITH user_convs AS (
        SELECT c.id, c.type, c.name, c.image_url, c.is_whisper_mode, c.created_at, c.updated_at, cp.unread_count as my_unread, cp.cleared_at as my_cleared
        FROM conversations c JOIN conversation_participants cp ON c.id = cp.conversation_id WHERE cp.user_id = p_user_id
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
            m.signal_sender_content as msg_signal_sender_content, 
            m.share_data as msg_share_data,
            m.voice_duration as msg_voice_duration
        FROM messages m 
        JOIN user_convs uc ON m.conversation_id = uc.id 
        WHERE uc.my_cleared IS NULL OR m.created_at > uc.my_cleared
        ORDER BY m.conversation_id, m.created_at DESC
    )
    SELECT uc.id, uc.type, uc.name, uc.image_url, uc.is_whisper_mode, uc.created_at, uc.updated_at, uc.my_unread, uc.my_cleared,
        (SELECT jsonb_agg(jsonb_build_object('user_id', cp2.user_id, 'profile', jsonb_build_object('username', p.username, 'avatar_url', p.avatar_url))) FROM conversation_participants cp2 JOIN profiles p ON cp2.user_id = p.id WHERE cp2.conversation_id = uc.id),
        CASE WHEN lm.msg_id IS NOT NULL THEN 
            jsonb_build_object(
                'id', lm.msg_id, 
                'content', lm.msg_content, 
                'sender_id', lm.msg_sender_id, 
                'created_at', lm.msg_created_at, 
                'image_url', lm.msg_image_url, 
                'voice_url', lm.msg_voice_url,
                'voice_duration', lm.msg_voice_duration,
                'share_data', lm.msg_share_data,
                'iv', lm.msg_iv,
                'encrypted_keys', lm.msg_encrypted_keys,
                'signal_message_type', lm.msg_signal_type,
                'signal_sender_content', lm.msg_signal_sender_content
            ) 
        ELSE NULL END,
        COALESCE(lm.msg_created_at, uc.created_at)
    FROM user_convs uc LEFT JOIN latest_msgs lm ON uc.id = lm.conversation_id
    ORDER BY sort_time DESC;
END;
$$ LANGUAGE plpgsql;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';
