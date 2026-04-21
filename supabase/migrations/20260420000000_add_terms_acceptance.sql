-- TERMS OF SERVICE & PRIVACY POLICY ACCEPTANCE MIGRATION
-- Adds server-side audit trail for user consent.

-- 1. Add columns to profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS has_accepted_terms BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS accepted_terms_at TIMESTAMPTZ;

-- 2. Update metadata sync function
-- This ensures that when auth.signUp() is called with metadata, it syncs to the profile.
CREATE OR REPLACE FUNCTION public.handle_user_metadata_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Sync Pro Status
  IF NEW.raw_user_meta_data->>'is_pro' IS NOT NULL THEN
    UPDATE public.profiles
    SET is_pro = (NEW.raw_user_meta_data->>'is_pro')::BOOLEAN
    WHERE id = NEW.id;
  END IF;

  -- Sync Terms Acceptance (New)
  IF NEW.raw_user_meta_data->>'has_accepted_terms' IS NOT NULL THEN
    UPDATE public.profiles
    SET 
      has_accepted_terms = (NEW.raw_user_meta_data->>'has_accepted_terms')::BOOLEAN,
      accepted_terms_at = (NEW.raw_user_meta_data->>'accepted_terms_at')::TIMESTAMPTZ
    WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
