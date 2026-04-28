-- Sync Sanctuary presence fields across profiles and user_status
-- Ensures Mood Orbit, Cozy Hours, Fortress Mode, and Pulse Status are available in both tables

-- 1. Add missing columns to profiles table if they don't exist
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS current_mood TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS mood_emoji TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS cozy_status TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fortress_mode BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fortress_message TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pulse_status TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pulse_text TEXT;

-- 2. Add sanctuary columns to user_status table for real-time sync
ALTER TABLE public.user_status ADD COLUMN IF NOT EXISTS mood TEXT;
ALTER TABLE public.user_status ADD COLUMN IF NOT EXISTS mood_emoji TEXT;
ALTER TABLE public.user_status ADD COLUMN IF NOT EXISTS cozy_status TEXT;
ALTER TABLE public.user_status ADD COLUMN IF NOT EXISTS fortress_mode BOOLEAN DEFAULT FALSE;
ALTER TABLE public.user_status ADD COLUMN IF NOT EXISTS fortress_message TEXT;
ALTER TABLE public.user_status ADD COLUMN IF NOT EXISTS pulse_status TEXT;
ALTER TABLE public.user_status ADD COLUMN IF NOT EXISTS pulse_text TEXT;

-- 3. Function to sync profile changes to user_status
CREATE OR REPLACE FUNCTION public.sync_profile_to_status()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_status (
        user_id, status, mood, mood_emoji, cozy_status, fortress_mode, fortress_message, pulse_status, pulse_text, updated_at
    )
    VALUES (
        NEW.id, 
        'online', 
        NEW.current_mood, 
        NEW.mood_emoji, 
        NEW.cozy_status, 
        NEW.fortress_mode, 
        NEW.fortress_message,
        NEW.pulse_status,
        NEW.pulse_text,
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        mood = EXCLUDED.mood,
        mood_emoji = EXCLUDED.mood_emoji,
        cozy_status = EXCLUDED.cozy_status,
        fortress_mode = EXCLUDED.fortress_mode,
        fortress_message = EXCLUDED.fortress_message,
        pulse_status = EXCLUDED.pulse_status,
        pulse_text = EXCLUDED.pulse_text,
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger to keep user_status in sync with profile updates
DROP TRIGGER IF EXISTS trigger_sync_profile_to_status ON public.profiles;
CREATE TRIGGER trigger_sync_profile_to_status
AFTER UPDATE OF current_mood, mood_emoji, cozy_status, fortress_mode, fortress_message, pulse_status, pulse_text ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_profile_to_status();
