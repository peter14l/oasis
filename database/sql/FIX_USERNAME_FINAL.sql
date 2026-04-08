-- =====================================================
-- FIX: USERNAME TRUNCATION & CONSTRAINT RELAXATION
-- =====================================================
-- This script fixes the issue where leading uppercase letters 
-- (like 'S' in Shreyas) were being stripped during account creation.
-- It also updates the database constraint to allow for manual 
-- fixes with mixed-case if desired.

BEGIN;

-- 1. Relax the username format constraint to be case-insensitive
-- This prevents the "violates check constraint" error when you try to use uppercase.
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS username_format;
ALTER TABLE public.profiles ADD CONSTRAINT username_format CHECK (username ~* '^[a-zA-Z0-9_]+$');

-- 2. Update the robust trigger function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_username TEXT;
    v_base_username TEXT;
    v_count INTEGER := 0;
BEGIN
    -- Extract name from Google Metadata or Email
    v_base_username := COALESCE(
        NEW.raw_user_meta_data->>'username', 
        NEW.raw_user_meta_data->>'full_name',
        SPLIT_PART(NEW.email, '@', 1)
    );

    -- FIX: Allow A-Z in the regex so they aren't stripped before LOWER() is called
    v_base_username := LOWER(REGEXP_REPLACE(v_base_username, '[^a-zA-Z0-9_]', '', 'g'));

    -- Ensure minimum length of 3
    IF CHAR_LENGTH(v_base_username) < 3 THEN
        v_base_username := v_base_username || '_user';
    END IF;

    -- Ensure maximum length
    v_base_username := LEFT(v_base_username, 25);
    v_username := v_base_username;

    -- Uniqueness Loop
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username) LOOP
        v_count := v_count + 1;
        v_username := v_base_username || v_count::TEXT;
    END LOOP;

    -- Insert with defaults
    INSERT INTO public.profiles (
        id, 
        email, 
        username, 
        full_name, 
        avatar_url, 
        xp, 
        posts_count, 
        followers_count, 
        following_count,
        created_at, 
        updated_at
    )
    VALUES (
        NEW.id, 
        NEW.email, 
        v_username, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', v_username),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL),
        0, 0, 0, 0, 
        NOW(), 
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        username = EXCLUDED.username,
        full_name = EXCLUDED.full_name;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;

-- Instruction:
-- Run this script in your Supabase SQL Editor. 
-- After running, you will be able to manually correct "hreyassengupta" to "shreyassengupta" 
-- (or "Shreyassengupta") without hitting the constraint error.
