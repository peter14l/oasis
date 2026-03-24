-- =====================================================
-- MASTER CONSOLIDATED SCHEMA (MORROW V2 -> V4)
-- =====================================================

-- 1. BASE SCHEMA UPDATES (CORE COLUMNS)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_pro BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS ripples_lockout_multiplier FLOAT DEFAULT 1.0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS ripples_last_session_end TIMESTAMPTZ;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS ripples_remaining_duration_ms BIGINT DEFAULT 0;

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_url TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_duration INTEGER;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS ripple_id UUID; -- REFERENCES public.ripples(id) added later
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS story_id UUID;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS share_data JSONB;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_ephemeral BOOLEAN DEFAULT FALSE;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS ephemeral_duration INTEGER DEFAULT 86400;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

ALTER TABLE public.conversation_participants ADD COLUMN IF NOT EXISTS cleared_at TIMESTAMPTZ;
ALTER TABLE public.conversation_participants ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE;

-- 2. RIPPLES SYSTEM
CREATE TABLE IF NOT EXISTS public.ripples (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  video_url TEXT NOT NULL,
  thumbnail_url TEXT,
  caption TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  saves_count INT DEFAULT 0,
  is_private BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS public.ripple_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ripple_id UUID REFERENCES ripples(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(ripple_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.ripple_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ripple_id UUID REFERENCES ripples(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ripple_saves (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ripple_id UUID REFERENCES ripples(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(ripple_id, user_id)
);

-- 3. WHISPER MODE & INSTAGRAM-STYLE VANISH LOGIC
-- Messages are now cleaned up when the chat is closed/opened, rather than instantly via trigger.
DROP TRIGGER IF EXISTS trigger_message_expiration ON public.message_read_receipts;
DROP FUNCTION IF EXISTS set_message_expiration();
DROP FUNCTION IF EXISTS delete_expired_messages();

CREATE OR REPLACE FUNCTION cleanup_vanish_mode_messages(p_conversation_id UUID)
RETURNS void AS $$
BEGIN
    -- Delete messages that are ephemeral and have been read by ANY recipient
    DELETE FROM public.messages m
    WHERE m.conversation_id = p_conversation_id
      AND m.is_ephemeral = true
      AND EXISTS (
          SELECT 1 FROM public.message_read_receipts r 
          WHERE r.message_id = m.id 
          AND r.user_id != m.sender_id
      );
END;
$$ LANGUAGE plpgsql;

-- 4. CONSOLIDATED MESSAGE HANDLING (LAST MESSAGE & UNREAD)
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.conversations
    SET 
        last_message_id = NEW.id,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id
    AND (last_message_at IS NULL OR NEW.created_at >= last_message_at);

    UPDATE public.conversation_participants
    SET 
        unread_count = unread_count + 1,
        updated_at = NOW()
    WHERE conversation_id = NEW.conversation_id
    AND user_id != NEW.sender_id;
    
    UPDATE public.conversation_participants
    SET updated_at = NOW()
    WHERE conversation_id = NEW.conversation_id
    AND user_id = NEW.sender_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_handle_new_message ON public.messages;
CREATE TRIGGER trigger_handle_new_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_message();

-- 5. ROBUST AUTH & PROFILE CREATION
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_username TEXT;
    v_base_username TEXT;
    v_count INTEGER := 0;
BEGIN
    v_base_username := COALESCE(
        NEW.raw_user_meta_data->>'username', 
        NEW.raw_user_meta_data->>'full_name',
        SPLIT_PART(NEW.email, '@', 1)
    );
    v_base_username := LOWER(REGEXP_REPLACE(v_base_username, '[^a-zA-Z0-9_]', '', 'g'));
    IF CHAR_LENGTH(v_base_username) < 3 THEN
        v_base_username := v_base_username || '_user';
    END IF;
    v_base_username := LEFT(v_base_username, 25);
    v_username := v_base_username;
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username) LOOP
        v_count := v_count + 1;
        v_username := v_base_username || v_count::TEXT;
    END LOOP;
    INSERT INTO public.profiles (id, email, username, full_name, avatar_url, xp, created_at, updated_at)
    VALUES (NEW.id, NEW.email, v_username, COALESCE(NEW.raw_user_meta_data->>'full_name', v_username), COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL), 0, NOW(), NOW())
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. RPC: GET CONVERSATIONS V2 (BULLETPROOF)
CREATE OR REPLACE FUNCTION get_user_conversations_v2(p_user_id UUID)
RETURNS TABLE (
    id UUID, type TEXT, name TEXT, image_url TEXT, is_whisper_mode BOOLEAN, created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ, unread_count INTEGER, cleared_at TIMESTAMPTZ, all_participants JSONB, last_message_data JSONB, sort_time TIMESTAMPTZ
) 
SECURITY DEFINER SET search_path = public AS $$
BEGIN
    RETURN QUERY
    WITH user_convs AS (
        SELECT c.id, c.type, c.name, c.image_url, c.is_whisper_mode, c.created_at, c.updated_at, cp.unread_count as my_unread, cp.cleared_at as my_cleared
        FROM conversations c JOIN conversation_participants cp ON c.id = cp.conversation_id WHERE cp.user_id = p_user_id
    ),
    latest_msgs AS (
        SELECT DISTINCT ON (m.conversation_id) m.conversation_id, m.id as msg_id, m.content as msg_content, m.sender_id as msg_sender_id, m.created_at as msg_created_at, m.image_url as msg_image_url, m.video_url as msg_video_url, m.file_url as msg_file_url, m.voice_url as msg_voice_url, m.iv as msg_iv, m.encrypted_keys as msg_encrypted_keys, m.signal_message_type as msg_signal_type, m.signal_sender_content as msg_signal_sender_content, m.share_data as msg_share_data
        FROM messages m JOIN user_convs uc ON m.conversation_id = uc.id WHERE uc.my_cleared IS NULL OR m.created_at > uc.my_cleared
        ORDER BY m.conversation_id, m.created_at DESC
    )
    SELECT uc.id, uc.type, uc.name, uc.image_url, uc.is_whisper_mode, uc.created_at, uc.updated_at, uc.my_unread, uc.my_cleared,
        (SELECT jsonb_agg(jsonb_build_object('user_id', cp2.user_id, 'profile', jsonb_build_object('username', p.username, 'avatar_url', p.avatar_url))) FROM conversation_participants cp2 JOIN profiles p ON cp2.user_id = p.id WHERE cp2.conversation_id = uc.id),
        CASE WHEN lm.msg_id IS NOT NULL THEN jsonb_build_object('id', lm.msg_id, 'content', lm.msg_content, 'sender_id', lm.msg_sender_id, 'created_at', lm.msg_created_at, 'image_url', lm.msg_image_url, 'share_data', lm.msg_share_data) ELSE NULL END,
        COALESCE(lm.msg_created_at, uc.created_at)
    FROM user_convs uc LEFT JOIN latest_msgs lm ON uc.id = lm.conversation_id
    ORDER BY sort_time DESC;
END;
$$ LANGUAGE plpgsql;
