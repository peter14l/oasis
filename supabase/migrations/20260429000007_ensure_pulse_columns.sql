-- Ensure all pulse columns exist in profiles and user_status
-- Fixes PGRST204: Could not find the column of 'profiles' in the schema cache

-- 1. Ensure all columns exist in public.profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pulse_status TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pulse_text TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pulse_since TIMESTAMPTZ;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pulse_visible BOOLEAN DEFAULT TRUE;

-- 2. Ensure all columns exist in public.user_status for real-time sync
ALTER TABLE public.user_status ADD COLUMN IF NOT EXISTS pulse_status TEXT;
ALTER TABLE public.user_status ADD COLUMN IF NOT EXISTS pulse_text TEXT;
ALTER TABLE public.user_status ADD COLUMN IF NOT EXISTS pulse_since TIMESTAMPTZ;

-- 3. Update the sync function to include pulse_since
CREATE OR REPLACE FUNCTION public.sync_profile_to_status()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_status (
        user_id, status, mood, mood_emoji, cozy_status, fortress_mode, fortress_message, pulse_status, pulse_text, pulse_since, updated_at
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
        NEW.pulse_since,
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
        pulse_since = EXCLUDED.pulse_since,
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Re-create trigger with all columns
DROP TRIGGER IF EXISTS trigger_sync_profile_to_status ON public.profiles;
CREATE TRIGGER trigger_sync_profile_to_status
AFTER UPDATE OF current_mood, mood_emoji, cozy_status, fortress_mode, fortress_message, pulse_status, pulse_text, pulse_since ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_profile_to_status();
