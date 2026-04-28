-- =====================================================
-- OASIS - WARM WHISPER (Part 12)
-- =====================================================
-- Encrypted care pings that show you care without requiring a response.

-- =====================================================
-- WARM WHISPERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.warm_whispers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    message TEXT, -- Short message (max 100 chars)
    is_anonymous BOOLEAN DEFAULT FALSE,
    revealed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for recipient inbox
CREATE INDEX IF NOT EXISTS idx_warm_whispers_recipient_id ON public.warm_whispers(recipient_id);

-- =====================================================
-- RLS POLICIES
-- =====================================================
ALTER TABLE public.warm_whispers ENABLE ROW LEVEL SECURITY;

-- Senders can see whispers they sent
CREATE POLICY "Users can view own sent whispers"
ON public.warm_whispers FOR SELECT
USING (auth.uid() = sender_id);

-- Recipients can see whispers sent to them
CREATE POLICY "Users can view own received whispers"
ON public.warm_whispers FOR SELECT
USING (auth.uid() = recipient_id);

-- Users can send whispers
CREATE POLICY "Users can send whispers"
ON public.warm_whispers FOR INSERT
WITH CHECK (auth.uid() = sender_id);

-- Recipients can mark whispers as revealed
CREATE POLICY "Recipients can update received whispers"
ON public.warm_whispers FOR UPDATE
USING (auth.uid() = recipient_id);

-- =====================================================
-- NOTIFICATION TRIGGER
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_warm_whisper_notification()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (
        user_id,
        actor_id,
        type,
        message_id -- We'll use this field to link to the whisper if needed, or just type
    )
    VALUES (
        NEW.recipient_id,
        CASE WHEN NEW.is_anonymous THEN NULL ELSE NEW.sender_id END,
        'warm_whisper'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_warm_whisper_notification ON public.warm_whispers;
CREATE TRIGGER trigger_warm_whisper_notification
    AFTER INSERT ON public.warm_whispers
    FOR EACH ROW
    EXECUTE FUNCTION trigger_warm_whisper_notification();
