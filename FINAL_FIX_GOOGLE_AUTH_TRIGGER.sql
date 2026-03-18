-- =====================================================
-- FINAL FIX: ROBUST GOOGLE AUTH PROFILE TRIGGER
-- =====================================================
-- This script provides the most robust version of the handle_new_user function.
-- It handles:
-- 1. Character sanitization (lowercase alphanumeric + underscores)
-- 2. Length constraints (minimum 3 characters for DB CHECK constraint)
-- 3. Uniqueness (appends numbers if username is already taken)
-- 4. Default values (sets counts to 0 explicitly)

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_username TEXT;
    v_base_username TEXT;
    v_count INTEGER := 0;
BEGIN
    -- 1. Extract name from Google Metadata or Email
    v_base_username := COALESCE(
        NEW.raw_user_meta_data->>'username', 
        NEW.raw_user_meta_data->>'full_name',
        SPLIT_PART(NEW.email, '@', 1)
    );

    -- 2. Clean: Lowercase and remove invalid chars (everything except a-z, A-Z, 0-9, _)
    v_base_username := LOWER(REGEXP_REPLACE(v_base_username, '[^a-zA-Z0-9_]', '', 'g'));

    -- 3. Length Guard: Ensure it's at least 3 chars (for the CHECK constraint)
    -- If it's too short (e.g. 'ab'), it becomes 'ab_user'
    IF CHAR_LENGTH(v_base_username) < 3 THEN
        v_base_username := v_base_username || '_user';
    END IF;

    -- 4. Truncate if too long (max 30)
    v_base_username := LEFT(v_base_username, 25);
    v_username := v_base_username;

    -- 5. Uniqueness Guard: If 'peter' exists, try 'peter1', 'peter2', etc.
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username) LOOP
        v_count := v_count + 1;
        v_username := v_base_username || v_count::TEXT;
    END LOOP;

    -- 6. Final Insert
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

-- Print Success
DO $$ BEGIN
    RAISE NOTICE 'Final robust trigger function handle_new_user has been applied.';
END $$;
