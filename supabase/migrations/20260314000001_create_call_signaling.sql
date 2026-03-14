-- Create call_signaling table for WebRTC signaling (Initial Version)
CREATE TABLE IF NOT EXISTS call_signaling (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_id UUID REFERENCES calls(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL, 
    data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE call_signaling ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can see signaling for calls they are part of"
    ON call_signaling FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM calls
            WHERE id = call_signaling.call_id
            AND (
                host_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM call_participants
                    WHERE call_id = call_signaling.call_id
                    AND user_id = auth.uid()
                )
            )
        )
    );

CREATE POLICY "Participants can insert signaling"
    ON call_signaling FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM calls
            WHERE id = call_signaling.call_id
            AND (
                host_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM call_participants
                    WHERE call_id = call_signaling.call_id
                    AND user_id = auth.uid()
                )
            )
        )
    );

-- Index
CREATE INDEX IF NOT EXISTS idx_call_signaling_call_id ON call_signaling(call_id);
