-- Migration to safely patch missing columns that might still be referenced by live DB triggers.
-- Since the exact trigger/view causing the 'cozy_until' error is hidden in the live DB,
-- re-adding these columns as harmless nullables will unblock the RPCs.

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS cozy_status TEXT,
ADD COLUMN IF NOT EXISTS cozy_until TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS fortress_mode BOOLEAN DEFAULT FALSE;

ALTER TABLE public.conversations 
ADD COLUMN IF NOT EXISTS cozy_status TEXT,
ADD COLUMN IF NOT EXISTS cozy_until TIMESTAMPTZ;

NOTIFY pgrst, 'reload schema';
