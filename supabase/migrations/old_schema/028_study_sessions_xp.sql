-- Add XP and Level system to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS xp INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS level INTEGER DEFAULT 1;

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

-- RLS for Study Sessions
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_session_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can see active study sessions"
    ON study_sessions FOR SELECT
    USING (status = 'active');

CREATE POLICY "Users can create study sessions"
    ON study_sessions FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Participants can see their sessions"
    ON study_session_participants FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can join sessions"
    ON study_session_participants FOR INSERT
    WITH CHECK (auth.uid() = user_id);
