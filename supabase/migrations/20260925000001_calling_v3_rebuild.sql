-- Calling V3: fresh signaling schema for the rebuilt calling feature.
--
-- Replaces the V2 `calls` table (which overloaded the `offer` JSONB column to
-- carry both the E2EE key offer and the LiveKit room name) with a lean
-- `call_sessions` table. No E2EE offer storage — media is protected by
-- LiveKit DTLS-SRTP plus per-call access tokens.
--
-- Contract preserved for push-notifications edge function:
--   notifications row: type = 'call',
--   content = '{"call_id","type","conversation_id"}' (JSON string).

-- ---------------------------------------------------------------------------
-- 1. Remove V1/V2 calling objects
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS public.call_signaling CASCADE;
DROP TABLE IF EXISTS public.call_participants CASCADE;
DROP TABLE IF EXISTS public.calls CASCADE;
DROP FUNCTION IF EXISTS public.handle_call_insert_notification();
DROP FUNCTION IF EXISTS public.handle_call_notification();
DROP TYPE IF EXISTS call_status;
DROP TYPE IF EXISTS call_type;

-- ---------------------------------------------------------------------------
-- 2. Fresh table
-- One row per ringing attempt (one caller -> one receiver).
-- Multi-party calls = additional rows sharing the same room_name
-- (the caller invites a participant by inserting a row with that room_name).
-- ---------------------------------------------------------------------------
CREATE TABLE public.call_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    caller_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'ringing'
        CHECK (status IN ('ringing', 'active', 'ended', 'declined', 'missed')),
    type TEXT NOT NULL DEFAULT 'voice'
        CHECK (type IN ('voice', 'video')),
    room_name TEXT NOT NULL,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- 3. RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public.call_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can select their calls"
    ON public.call_sessions FOR SELECT
    USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

CREATE POLICY "Callers can create calls"
    ON public.call_sessions FOR INSERT
    WITH CHECK (auth.uid() = caller_id);

CREATE POLICY "Participants can update their calls"
    ON public.call_sessions FOR UPDATE
    USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

-- ---------------------------------------------------------------------------
-- 4. Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_call_sessions_caller_id ON public.call_sessions(caller_id);
CREATE INDEX idx_call_sessions_receiver_id ON public.call_sessions(receiver_id);
CREATE INDEX idx_call_sessions_conversation_id ON public.call_sessions(conversation_id);
CREATE INDEX idx_call_sessions_room_name ON public.call_sessions(room_name);
-- Hot path: "my ringing calls" watch for incoming calls
CREATE INDEX idx_call_sessions_receiver_ringing
    ON public.call_sessions(receiver_id)
    WHERE status = 'ringing';

-- ---------------------------------------------------------------------------
-- 5. Realtime (postgres_changes streams used by the app)
-- REPLICA IDENTITY FULL so UPDATE events carry full old+new payloads.
-- ---------------------------------------------------------------------------
ALTER TABLE public.call_sessions REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE public.call_sessions;

-- ---------------------------------------------------------------------------
-- 6. Push notification trigger
-- Inserts a notifications row on every incoming (ringing) call; the existing
-- notify_push_service() trigger on notifications then invokes the
-- push-notifications edge function (FCM).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_call_invite()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'ringing' THEN
        INSERT INTO public.notifications (user_id, type, actor_id, content)
        VALUES (
            NEW.receiver_id,
            'call',
            NEW.caller_id,
            jsonb_build_object(
                'call_id', NEW.id,
                'type', NEW.type,
                'conversation_id', NEW.conversation_id
            )::text
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_call_invite ON public.call_sessions;
CREATE TRIGGER trigger_notify_call_invite
    AFTER INSERT ON public.call_sessions
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_call_invite();
