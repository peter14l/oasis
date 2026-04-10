-- Migration: Add Signal Identity backup to profiles
-- Description: Adds a column to store securely encrypted Signal Protocol identity keys.

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS encrypted_signal_identity TEXT;

COMMENT ON COLUMN public.profiles.encrypted_signal_identity IS 'Securely encrypted Signal IdentityKeyPair and RegistrationId for cross-device restoration.';
