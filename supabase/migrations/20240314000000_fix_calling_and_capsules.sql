-- Migration to fix call schema and capsule relationships
-- Date: 2024-03-14

-- 1. Fix 'calls' table missing columns
ALTER TABLE calls ADD COLUMN IF NOT EXISTS sdp TEXT;
ALTER TABLE calls ADD COLUMN IF NOT EXISTS sdp_type TEXT;

-- 2. Enhance 'time_capsules' table with collaborative features
ALTER TABLE time_capsules ADD COLUMN IF NOT EXISTS is_collaborative BOOLEAN DEFAULT FALSE;
ALTER TABLE time_capsules ADD COLUMN IF NOT EXISTS contributor_ids UUID[] DEFAULT '{}';
ALTER TABLE time_capsules ADD COLUMN IF NOT EXISTS location_trigger TEXT;
ALTER TABLE time_capsules ADD COLUMN IF NOT EXISTS location_radius DOUBLE PRECISION;
ALTER TABLE time_capsules ADD COLUMN IF NOT EXISTS music_url TEXT;
ALTER TABLE time_capsules ADD COLUMN IF NOT EXISTS music_title TEXT;

-- 3. Create 'capsule_contributions' table if missing
CREATE TABLE IF NOT EXISTS capsule_contributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    capsule_id UUID REFERENCES time_capsules(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_urls TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable RLS and add policies for capsule_contributions
ALTER TABLE capsule_contributions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = 'Users can contribute to capsules they are invited to'
    ) THEN
        CREATE POLICY "Users can contribute to capsules they are invited to"
            ON capsule_contributions FOR INSERT
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM time_capsules
                    WHERE id = capsule_id
                    AND (user_id = auth.uid() OR contributor_ids @> ARRAY[auth.uid()])
                )
            );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = 'Users can view contributions for capsules they can see'
    ) THEN
        CREATE POLICY "Users can view contributions for capsules they can see"
            ON capsule_contributions FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM time_capsules
                    WHERE id = capsule_id
                )
            );
    END IF;
END $$;
