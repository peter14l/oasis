-- Consolidated SQL Setup for Oasis V2: Calling, XP System, and Study Sessions
-- Updated for idempotency (handles existing policies)

-- 1. CALLING SYSTEM (Voice & Video)
------------------------------------------------------------------

-- Call status enum
DO $$ BEGIN
    CREATE TYPE call_status AS ENUM ('pinging', 'active', 'ended', 'missed', 'rejected');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Call type enum
DO $$ BEGIN
    CREATE TYPE call_type AS ENUM ('voice', 'video');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Calls table
CREATE TABLE IF NOT EXISTS calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    host_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    channel_name TEXT NOT NULL,
    status call_status DEFAULT 'pinging',
    type call_type DEFAULT 'voice',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    agora_token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Call participants table
CREATE TABLE IF NOT EXISTS call_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_id UUID REFERENCES calls(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ,
    left_at TIMESTAMPTZ,
    is_muted BOOLEAN DEFAULT FALSE,
    is_video_on BOOLEAN DEFAULT TRUE,
    is_screen_sharing BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'invited',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(call_id, user_id)
);

-- 2. XP & LEVEL SYSTEM
------------------------------------------------------------------

-- Add XP and Level to profiles if they don't exist
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS xp INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS level INTEGER DEFAULT 1;


-- 3. STUDY SESSIONS (Focus Mode)
------------------------------------------------------------------

-- Study Sessions Table
CREATE TABLE IF NOT EXISTS study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ DEFAULT NOW(),
    duration_minutes INTEGER NOT NULL,
    status TEXT DEFAULT 'active', -- active, completed, cancelled
    is_locked_in BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Study Session Participants
CREATE TABLE IF NOT EXISTS study_session_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES study_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    exit_status TEXT DEFAULT 'joined', -- joined, completed, left_early
    xp_earned INTEGER DEFAULT 0,
    UNIQUE(session_id, user_id)
);

-- 4. ROW LEVEL SECURITY (RLS)
------------------------------------------------------------------

ALTER TABLE calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_session_participants ENABLE ROW LEVEL SECURITY;

-- DROP policies if they exist to prevent errors on re-run
DROP POLICY IF EXISTS "Users can see calls they are part of" ON calls;
DROP POLICY IF EXISTS "Anyone can see active study sessions" ON study_sessions;
DROP POLICY IF EXISTS "Users can join study sessions" ON study_session_participants;

-- Calls: Users can see calls in their conversations
CREATE POLICY "Users can see calls they are part of"
    ON calls FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversation_participants
            WHERE conversation_id = calls.conversation_id
            AND user_id = auth.uid()
        )
    );

-- Study Sessions: Anyone can see active sessions
CREATE POLICY "Anyone can see active study sessions"
    ON study_sessions FOR SELECT
    USING (status = 'active');

-- Join Policy: Users can join study sessions
CREATE POLICY "Users can join study sessions"
    ON study_session_participants FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 5. PERFORMANCE INDEXES
------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_calls_conv_id ON calls(conversation_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_status ON study_sessions(status);
CREATE INDEX IF NOT EXISTS idx_profiles_xp ON profiles(xp DESC);
