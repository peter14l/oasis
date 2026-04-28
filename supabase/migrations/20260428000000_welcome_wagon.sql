-- =====================================================
-- OASIS - WELCOME WAGON
-- =====================================================
-- Welcome messages for new connections

-- =====================================================
-- WELCOME TEMPLATES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.welcome_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    template_text TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    include_privacy_tips BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_welcome_templates_user_id ON public.welcome_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_welcome_templates_is_active ON public.welcome_templates(is_active) WHERE is_active = TRUE;

-- =====================================================
-- WELCOME SETTINGS TABLE (per-user settings)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.welcome_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    welcome_enabled BOOLEAN DEFAULT TRUE,
    send_on_follow BOOLEAN DEFAULT TRUE,
    send_on_circle_join BOOLEAN DEFAULT TRUE,
    send_first_dm BOOLEAN DEFAULT FALSE,
    last_template_id UUID REFERENCES public.welcome_templates(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- RLS POLICIES
-- =====================================================
ALTER TABLE public.welcome_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.welcome_settings ENABLE ROW LEVEL SECURITY;

-- Users can view their own templates
CREATE POLICY "Users can view own welcome templates"
ON public.welcome_templates FOR SELECT
USING (auth.uid() = user_id OR user_id IS NULL);

-- Users can insert their own templates
CREATE POLICY "Users can insert own welcome templates"
ON public.welcome_templates FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own templates
CREATE POLICY "Users can update own welcome templates"
ON public.welcome_templates FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own templates
CREATE POLICY "Users can delete own welcome templates"
ON public.welcome_templates FOR DELETE
USING (auth.uid() = user_id);

-- Public templates (defaults) are viewable by everyone
CREATE POLICY "Public welcome templates are viewable by everyone"
ON public.welcome_templates FOR SELECT
USING (user_id IS NULL);

-- Users can view their own settings
CREATE POLICY "Users can view own welcome settings"
ON public.welcome_settings FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own settings
CREATE POLICY "Users can insert own welcome settings"
ON public.welcome_settings FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own settings
CREATE POLICY "Users can update own welcome settings"
ON public.welcome_settings FOR UPDATE
USING (auth.uid() = user_id);

-- =====================================================
-- DEFAULT TEMPLATES
-- =====================================================
INSERT INTO public.welcome_templates (user_id, template_text, is_default, include_privacy_tips) VALUES
(NULL, 'Welcome to Oasis! 🎉 Your privacy matters - check Settings → Privacy to lock things down.', TRUE, TRUE),
(NULL, 'Hey! Feel free to browse, but remember - what happens here stays here. ✨', TRUE, TRUE),
(NULL, 'Welcome! Questions? Check out the guide in Settings → Help.', TRUE, FALSE)
ON CONFLICT DO NOTHING;

-- =====================================================
-- WELCOME MESSAGE FUNCTION
-- =====================================================
CREATE OR REPLACE FUNCTION send_welcome_message(
    p_recipient_id UUID,
    p_sender_id UUID,
    p_trigger_type TEXT DEFAULT 'follow'
)
RETURNS UUID AS $$
DECLARE
    v_template_text TEXT;
    v_message_content TEXT;
    v_conversation_id UUID;
    v_message_id UUID;
    v_settings RECORD;
    v_template RECORD;
BEGIN
    -- Get user's welcome settings
    SELECT * INTO v_settings
    FROM public.welcome_settings
    WHERE user_id = p_sender_id;

    -- If welcome is disabled, return NULL
    IF v_settings.welcome_enabled IS FALSE THEN
        RETURN NULL;
    END IF;

    -- Check trigger type
    IF p_trigger_type = 'follow' AND v_settings.send_on_follow IS FALSE THEN
        RETURN NULL;
    ELSIF p_trigger_type = 'circle' AND v_settings.send_on_circle_join IS FALSE THEN
        RETURN NULL;
    ELSIF p_trigger_type = 'dm' AND v_settings.send_first_dm IS FALSE THEN
        RETURN NULL;
    END IF;

    -- Get the active template
    IF v_settings.last_template_id IS NOT NULL THEN
        SELECT template_text INTO v_template_text
        FROM public.welcome_templates
        WHERE id = v_settings.last_template_id AND is_active = TRUE;
    END IF;

    -- If no custom template, use random default
    IF v_template_text IS NULL THEN
        SELECT template_text INTO v_template_text
        FROM public.welcome_templates
        WHERE user_id IS NULL AND is_default = TRUE AND is_active = TRUE
        ORDER BY RANDOM()
        LIMIT 1;
    END IF;

    -- If still NULL, use hardcoded fallback
    IF v_template_text IS NULL THEN
        v_template_text := 'Welcome to Oasis! 🎉 Your privacy matters - check Settings → Privacy to lock things down.';
    END IF;

    -- Create or get conversation
    SELECT public.get_or_create_direct_conversation(p_sender_id, p_recipient_id) INTO v_conversation_id;

    -- Send the welcome message
    INSERT INTO public.messages (conversation_id, sender_id, content, message_type)
    VALUES (v_conversation_id, p_sender_id, v_template_text, 'welcome')
    RETURNING id INTO v_message_id;

    RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FOLLOW TRIGGER (Send welcome on new follower)
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_welcome_on_follow()
RETURNS TRIGGER AS $$
DECLARE
    v_welcome_message_id UUID;
BEGIN
    -- Only send welcome if this is a new follow (not unfollow/refollow)
    -- The OLD row is NULL on INSERT
    IF TG_OP = 'INSERT' THEN
        -- Try to send welcome message to the new follower
        BEGIN
            v_welcome_message_id := send_welcome_message(NEW.follower_id, NEW.following_id, 'follow');
        EXCEPTION WHEN OTHERS THEN
            -- Silently ignore errors - don't break the follow
            NULL;
        END;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_welcome_on_follow ON public.follows;
CREATE TRIGGER trigger_welcome_on_follow
    AFTER INSERT ON public.follows
    FOR EACH ROW
    EXECUTE FUNCTION trigger_welcome_on_follow();

-- =====================================================
-- AUTO-CREATE WELCOME SETTINGS FOR NEW USERS
-- =====================================================
CREATE OR REPLACE FUNCTION create_welcome_settings_for_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.welcome_settings (user_id, welcome_enabled, send_on_follow)
    VALUES (NEW.id, TRUE, TRUE)
    ON CONFLICT DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_create_welcome_settings ON public.profiles;
CREATE TRIGGER trigger_create_welcome_settings
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION create_welcome_settings_for_user();