-- Migration: Add user_status table for presence polling fallback
-- Date: 2026-04-15
-- Purpose: Support online/offline status polling when realtime replication is unavailable

CREATE TABLE IF NOT EXISTS public.user_status (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    status TEXT DEFAULT 'offline',
    last_seen TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_status ENABLE ROW LEVEL SECURITY;

-- Users can view all status (to see if others are online)
DROP POLICY IF EXISTS "Everyone can view user status" ON public.user_status;
CREATE POLICY "Everyone can view user status" ON public.user_status
    FOR SELECT USING (true);

-- Users can update only their own status
DROP POLICY IF EXISTS "Users can update own status" ON public.user_status;
CREATE POLICY "Users can update own status" ON public.user_status
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can insert their own status
DROP POLICY IF EXISTS "Users can insert own status" ON public.user_status;
CREATE POLICY "Users can insert own status" ON public.user_status
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_user_status_updated_at ON public.user_status;
CREATE TRIGGER set_user_status_updated_at
    BEFORE UPDATE ON public.user_status
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
