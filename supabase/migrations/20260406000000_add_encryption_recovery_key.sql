-- 20260406000000_add_encryption_recovery_key.sql
-- Adds a recovery key backup for end-to-end encryption private keys

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS encrypted_private_key_recovery TEXT;

COMMENT ON COLUMN public.profiles.encrypted_private_key_recovery IS 'RSA Private Key encrypted with a Recovery Key-derived key (redundant backup for PIN recovery)';
