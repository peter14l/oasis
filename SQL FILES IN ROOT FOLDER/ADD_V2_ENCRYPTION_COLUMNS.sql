-- 1. Add columns for Version 2 (Secure) Encryption
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS encrypted_private_key_v2 TEXT,
ADD COLUMN IF NOT EXISTS key_salt TEXT,
ADD COLUMN IF NOT EXISTS has_upgraded_security BOOLEAN DEFAULT FALSE;

-- 2. Add an index to help the app quickly identify users needing upgrades
CREATE INDEX IF NOT EXISTS idx_profiles_security_upgrade 
ON profiles(has_upgraded_security) 
WHERE has_upgraded_security = FALSE;

-- 3. (Optional) Commentary for documentation
COMMENT ON COLUMN profiles.encrypted_private_key_v2 IS 'RSA Private Key encrypted with a PIN-derived Argon2id key (v2)';
COMMENT ON COLUMN profiles.key_salt IS 'Unique salt used for Argon2id key derivation from user PIN';
