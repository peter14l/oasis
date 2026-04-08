-- =====================================================
-- AUTH INTEGRITY RESTORE & GOOGLE FIX
-- =====================================================
-- Use this script if you get "Internal Server Error" after
-- manually deleting users. It wipes all internal metadata
-- and re-applies the robust profile trigger.

BEGIN;

-- 1. Deep clean internal auth tables to restore integrity
TRUNCATE auth.users CASCADE;
TRUNCATE auth.identities CASCADE;
TRUNCATE auth.sessions CASCADE;
TRUNCATE auth.refresh_tokens CASCADE;

-- 2. Clean up existing trigger functions
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- 3. Re-create the ROBUST profile creator
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_username TEXT;
    v_base_username TEXT;
    v_count INTEGER := 0;
BEGIN
    v_base_username := COALESCE(
        NEW.raw_user_meta_data->>'username', 
        NEW.raw_user_meta_data->>'full_name',
        SPLIT_PART(NEW.email, '@', 1)
    );

    v_base_username := LOWER(REGEXP_REPLACE(v_base_username, '[^a-z0-9_]', '', 'g'));

    IF CHAR_LENGTH(v_base_username) < 3 THEN
        v_base_username := v_base_username || '_user';
    END IF;

    v_base_username := LEFT(v_base_username, 25);
    v_username := v_base_username;

    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username) LOOP
        v_count := v_count + 1;
        v_username := v_base_username || v_count::TEXT;
    END LOOP;

    INSERT INTO public.profiles (
        id, email, username, full_name, avatar_url, 
        xp, posts_count, followers_count, following_count,
        created_at, updated_at
    )
    VALUES (
        NEW.id, NEW.email, v_username, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', v_username),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL),
        0, 0, 0, 0, NOW(), NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Re-attach the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

COMMIT;

-- Print Success
DO $$ BEGIN
    RAISE NOTICE 'Auth integrity restored and Super Fix applied.';
END $$;
