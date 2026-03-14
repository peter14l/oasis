-- 1. Clear all messaging data 
-- (Deleting conversations will cascade to messages, participants, receipts, and reactions)
DELETE FROM public.conversations;

-- 2. Reset encryption keys for all profiles
UPDATE public.profiles
SET public_key = NULL,
    encrypted_private_key = NULL;

-- 3. Clear transient messaging data
DELETE FROM public.typing_indicators;
DELETE FROM public.chat_themes;

-- 4. Fix time_capsules relationship (if needed, ensuring foreign key exists)
-- This confirms the user_id references profiles.id correctly
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'time_capsules_user_id_fkey'
    ) THEN
        ALTER TABLE public.time_capsules 
        ADD CONSTRAINT time_capsules_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;
END $$;
