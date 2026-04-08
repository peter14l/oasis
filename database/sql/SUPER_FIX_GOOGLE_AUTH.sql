-- =====================================================
-- SUPER FIX: RESET AUTH TRIGGER & GOOGLE SIGN-IN FIX
-- =====================================================
-- This script wipes the existing trigger and applies a robust
-- version that handles:
-- 1. Username sanitization (no spaces, lowercase)
-- 2. Length constraints (minimum 3 chars)
-- 3. Uniqueness (appends numbers if name is taken)
-- 4. Default column values (xp, counts, etc.)

-- 1. Clean up existing triggers to avoid conflicts
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- 2. Create the ROBUST profile creator
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

    -- Sanitize: lowercase, remove everything except a-z, A-Z, 0-9, and underscores
    v_base_username := LOWER(REGEXP_REPLACE(v_base_username, '[^a-zA-Z0-9_]', '', 'g'));

    -- Ensure minimum length of 3 (important for your DB constraints!)
    IF CHAR_LENGTH(v_base_username) < 3 THEN
        v_base_username := v_base_username || '_user';
    END IF;

    -- Ensure maximum length of 25 (to leave room for numbers)
    v_base_username := LEFT(v_base_username, 25);
    v_username := v_base_username;

    -- Uniqueness Loop: If 'peter' exists, try 'peter1', 'peter2', etc.
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username) LOOP
        v_count := v_count + 1;
        v_username := v_base_username || v_count::TEXT;
    END LOOP;

    -- Final Insert with defaults
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
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Re-attach the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- 4. Verify Success
DO $$ BEGIN
    RAISE NOTICE 'Auth reset and Google fix applied successfully.';
END $$;
