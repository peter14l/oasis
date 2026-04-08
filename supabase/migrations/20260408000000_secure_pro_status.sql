-- Update the user metadata trigger to use app_metadata
CREATE OR REPLACE FUNCTION public.handle_user_metadata_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.raw_app_meta_data->>'is_pro' IS NOT NULL THEN
    UPDATE public.profiles
    SET is_pro = (NEW.raw_app_meta_data->>'is_pro')::BOOLEAN
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the old trigger that watched raw_user_meta_data
DROP TRIGGER IF EXISTS on_auth_user_metadata_updated ON auth.users;

-- Create the new trigger to watch raw_app_meta_data
CREATE TRIGGER on_auth_app_metadata_updated
  AFTER UPDATE OF raw_app_meta_data ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_user_metadata_update();

-- Sync existing data securely from app_metadata
UPDATE public.profiles p
SET is_pro = (u.raw_app_meta_data->>'is_pro')::BOOLEAN
FROM auth.users u
WHERE p.id = u.id AND u.raw_app_meta_data->>'is_pro' IS NOT NULL;

-- ===========================================================================
-- ENFORCE TIER LIMITS ON BACKEND
-- ===========================================================================

-- Vault items limit (10 for free users)
CREATE OR REPLACE FUNCTION public.check_vault_limit()
RETURNS TRIGGER AS $$
DECLARE
    pro_status BOOLEAN;
    item_count INT;
BEGIN
    SELECT is_pro INTO pro_status FROM public.profiles WHERE id = NEW.user_id;
    IF NOT COALESCE(pro_status, FALSE) THEN
        SELECT COUNT(*) INTO item_count FROM public.vault_items WHERE user_id = NEW.user_id;
        IF item_count >= 10 THEN
            RAISE EXCEPTION 'Free users can only have up to 10 vault items.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_vault_limit ON public.vault_items;
CREATE TRIGGER enforce_vault_limit
    BEFORE INSERT ON public.vault_items
    FOR EACH ROW
    EXECUTE FUNCTION public.check_vault_limit();

-- Time capsules limit (2 for free users)
CREATE OR REPLACE FUNCTION public.check_time_capsules_limit()
RETURNS TRIGGER AS $$
DECLARE
    pro_status BOOLEAN;
    item_count INT;
BEGIN
    SELECT is_pro INTO pro_status FROM public.profiles WHERE id = NEW.user_id;
    IF NOT COALESCE(pro_status, FALSE) THEN
        SELECT COUNT(*) INTO item_count FROM public.time_capsules WHERE user_id = NEW.user_id;
        IF item_count >= 2 THEN
            RAISE EXCEPTION 'Free users can only have up to 2 active time capsules.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_time_capsules_limit ON public.time_capsules;
CREATE TRIGGER enforce_time_capsules_limit
    BEFORE INSERT ON public.time_capsules
    FOR EACH ROW
    EXECUTE FUNCTION public.check_time_capsules_limit();

-- Canvases limit (2 for free users)
CREATE OR REPLACE FUNCTION public.check_canvases_limit()
RETURNS TRIGGER AS $$
DECLARE
    pro_status BOOLEAN;
    item_count INT;
BEGIN
    SELECT is_pro INTO pro_status FROM public.profiles WHERE id = NEW.created_by;
    IF NOT COALESCE(pro_status, FALSE) THEN
        SELECT COUNT(*) INTO item_count FROM public.canvases WHERE created_by = NEW.created_by;
        IF item_count >= 2 THEN
            RAISE EXCEPTION 'Free users can only create up to 2 canvases.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_canvases_limit ON public.canvases;
CREATE TRIGGER enforce_canvases_limit
    BEFORE INSERT ON public.canvases
    FOR EACH ROW
    EXECUTE FUNCTION public.check_canvases_limit();

-- Circles limit (2 for free users)
CREATE OR REPLACE FUNCTION public.check_circles_limit()
RETURNS TRIGGER AS $$
DECLARE
    pro_status BOOLEAN;
    item_count INT;
BEGIN
    SELECT is_pro INTO pro_status FROM public.profiles WHERE id = NEW.created_by;
    IF NOT COALESCE(pro_status, FALSE) THEN
        SELECT COUNT(*) INTO item_count FROM public.circles WHERE created_by = NEW.created_by;
        IF item_count >= 2 THEN
            RAISE EXCEPTION 'Free users can only create up to 2 circles.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_circles_limit ON public.circles;
CREATE TRIGGER enforce_circles_limit
    BEFORE INSERT ON public.circles
    FOR EACH ROW
    EXECUTE FUNCTION public.check_circles_limit();
