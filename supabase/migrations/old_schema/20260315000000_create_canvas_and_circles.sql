-- Migration for "The Canvas" and "The Circle of Commitments" Features

-- ==========================================
-- 1. THE CANVAS FEATURE
-- ==========================================

-- Canvases Table
CREATE TABLE IF NOT EXISTS canvases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT DEFAULT 'Our Canvas',
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
    cover_color TEXT DEFAULT '#3B82F6',
    is_encrypted BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Canvas Members Table
CREATE TABLE IF NOT EXISTS canvas_members (
    canvas_id UUID REFERENCES canvases(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (canvas_id, user_id)
);

-- Canvas Items Table
CREATE TABLE IF NOT EXISTS canvas_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    canvas_id UUID REFERENCES canvases(id) ON DELETE CASCADE,
    author_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    content TEXT,
    x_pos DOUBLE PRECISION NOT NULL,
    y_pos DOUBLE PRECISION NOT NULL,
    rotation DOUBLE PRECISION DEFAULT 0.0,
    scale DOUBLE PRECISION DEFAULT 1.0,
    color TEXT DEFAULT '#252930',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 2. THE CIRCLE OF COMMITMENTS FEATURE
-- ==========================================

-- Circles Table
CREATE TABLE IF NOT EXISTS circles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT DEFAULT 'My Circle',
    emoji TEXT DEFAULT '🌊',
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
    streak_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Circle Members Table
CREATE TABLE IF NOT EXISTS circle_members (
    circle_id UUID REFERENCES circles(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member', -- 'admin' or 'member'
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (circle_id, user_id)
);

-- Commitments Table
CREATE TABLE IF NOT EXISTS commitments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    circle_id UUID REFERENCES circles(id) ON DELETE CASCADE,
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    due_date DATE NOT NULL,
    status TEXT DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Commitment Responses Table
CREATE TABLE IF NOT EXISTS commitment_responses (
    commitment_id UUID REFERENCES commitments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    intent TEXT NOT NULL,
    completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    note TEXT,
    PRIMARY KEY (commitment_id, user_id)
);


-- ==========================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

ALTER TABLE canvases ENABLE ROW LEVEL SECURITY;
ALTER TABLE canvas_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE canvas_items ENABLE ROW LEVEL SECURITY;

ALTER TABLE circles ENABLE ROW LEVEL SECURITY;
ALTER TABLE circle_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE commitments ENABLE ROW LEVEL SECURITY;
ALTER TABLE commitment_responses ENABLE ROW LEVEL SECURITY;


-- Canvases Policies
CREATE POLICY "Users can view canvases they are members of"
    ON canvases FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM canvas_members
            WHERE canvas_id = canvases.id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert canvases"
    ON canvases FOR INSERT
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Canvas members can update canvases"
    ON canvases FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM canvas_members
            WHERE canvas_id = canvases.id
            AND user_id = auth.uid()
        )
    );

-- Canvas Members Policies
CREATE POLICY "Users can view canvas members of their canvases"
    ON canvas_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM canvas_members AS cm
            WHERE cm.canvas_id = canvas_members.canvas_id
            AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can add themselves or be added to canvases"
    ON canvas_members FOR INSERT
    WITH CHECK (true); -- Ideally restrict to creators, but open for now to let creator add members

CREATE POLICY "Users can remove themselves from canvases"
    ON canvas_members FOR DELETE
    USING (user_id = auth.uid());


-- Canvas Items Policies
CREATE POLICY "Users can view items in their canvases"
    ON canvas_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM canvas_members
            WHERE canvas_id = canvas_items.canvas_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can add items to their canvases"
    ON canvas_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM canvas_members
            WHERE canvas_id = canvas_items.canvas_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update items in their canvases"
    ON canvas_items FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM canvas_members
            WHERE canvas_id = canvas_items.canvas_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own items"
    ON canvas_items FOR DELETE
    USING (author_id = auth.uid());


-- Circles Policies
CREATE POLICY "Users can view circles they are members of"
    ON circles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM circle_members
            WHERE circle_id = circles.id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create circles"
    ON circles FOR INSERT
    WITH CHECK (auth.uid() = created_by);

-- Circle Members Policies
CREATE POLICY "Users can view circle members of their circles"
    ON circle_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM circle_members AS cm
            WHERE cm.circle_id = circle_members.circle_id
            AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can add members to circles"
    ON circle_members FOR INSERT
    WITH CHECK (true); 

CREATE POLICY "Users can leave circles"
    ON circle_members FOR DELETE
    USING (user_id = auth.uid());


-- Commitments Policies
CREATE POLICY "Users can view commitments in their circles"
    ON commitments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM circle_members
            WHERE circle_id = commitments.circle_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Circle members can add commitments"
    ON commitments FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM circle_members
            WHERE circle_id = commitments.circle_id
            AND user_id = auth.uid()
        )
    );

-- Commitment Responses Policies
CREATE POLICY "Users can view commitment responses in their circles"
    ON commitment_responses FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM commitments c
            JOIN circle_members cm ON cm.circle_id = c.circle_id
            WHERE c.id = commitment_responses.commitment_id
            AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can respond to commitments in their circles"
    ON commitment_responses FOR INSERT
    WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM commitments c
            JOIN circle_members cm ON cm.circle_id = c.circle_id
            WHERE c.id = commitment_responses.commitment_id
            AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own commitment responses"
    ON commitment_responses FOR UPDATE
    USING (user_id = auth.uid());


-- ==========================================
-- 4. REALTIME SETUP
-- ==========================================
-- Enable realtime for the tables that are subscribed to in the app
ALTER PUBLICATION supabase_realtime ADD TABLE canvas_items;
ALTER PUBLICATION supabase_realtime ADD TABLE commitments;
ALTER PUBLICATION supabase_realtime ADD TABLE commitment_responses;
