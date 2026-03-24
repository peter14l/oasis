-- =====================================================
-- FIX: GOOGLE AUTH PROFILE CREATION TRIGGER
-- =====================================================
-- This script updates the handle_new_user function to properly
-- sanitize usernames (lowercase, no spaces) to prevent 
-- "Internal Server Error" during Google Sign-In.

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_username TEXT;
BEGIN
    -- 1. Get raw username from metadata or email prefix
    v_username := COALESCE(
        NEW.raw_user_meta_data->>'username', 
        SPLIT_PART(NEW.email, '@', 1)
    );

    -- 2. Sanitize: Lowercase and replace anything NOT a-z, 0-9 with underscore
    v_username := LOWER(REGEXP_REPLACE(v_username, '[^a-zA-Z0-9_]', '_', 'g'));

    -- 3. Ensure minimum length (3 chars) by padding if necessary
    IF CHAR_LENGTH(v_username) < 3 THEN
        v_username := v_username || '_user';
    END IF;

    -- 4. Trim to maximum length (30 chars)
    v_username := LEFT(v_username, 30);

    INSERT INTO public.profiles (id, email, username, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        v_username,
        COALESCE(NEW.raw_user_meta_data->>'full_name', v_username),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL)
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Print Success
DO $$ BEGIN
    RAISE NOTICE 'Trigger function handle_new_user has been updated with sanitization logic.';
END $$;
