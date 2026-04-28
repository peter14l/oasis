-- =====================================================
-- Add Pulse Status to Profiles
-- Check-in Pulse - Location-Free Presence Feature
-- =====================================================

-- Add pulse status columns to profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pulse_status VARCHAR(50);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pulse_text VARCHAR(100);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pulse_since TIMESTAMPTZ;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pulse_visible BOOLEAN DEFAULT TRUE;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_profiles_pulse_status ON public.profiles(pulse_status) WHERE pulse_status IS NOT NULL;

-- Add RLS policy for viewing pulse status (friends only or public based on visibility)
-- Pulse status is visible to authenticated users (friends can see each other's status)
