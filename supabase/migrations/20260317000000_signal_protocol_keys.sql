-- Signal Protocol Key Distribution Schema
-- Migration: 20260317000000_signal_protocol_keys.sql

-- Create table to store Signal Protocol users' key bundles
CREATE TABLE IF NOT EXISTS signal_keys (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  identity_key TEXT NOT NULL,
  registration_id INT NOT NULL,
  signed_prekey JSONB NOT NULL,    -- { "keyId": int, "publicKey": string, "signature": string }
  onetime_prekeys JSONB NOT NULL,  -- { "1": "publicKeyPem1", "2": "publicKeyPem2", ... }
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE signal_keys ENABLE ROW LEVEL SECURITY;

-- Everyone can read key bundles
CREATE POLICY "Anyone can read signal keys"
ON signal_keys FOR SELECT
USING (true);

-- Users can insert their own keys
CREATE POLICY "Users can insert their own signal keys"
ON signal_keys FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own keys
CREATE POLICY "Users can update their own signal keys"
ON signal_keys FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_signal_keys_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_signal_keys_updated_at ON signal_keys;
CREATE TRIGGER trigger_signal_keys_updated_at
BEFORE UPDATE ON signal_keys
FOR EACH ROW
EXECUTE FUNCTION update_signal_keys_updated_at();
