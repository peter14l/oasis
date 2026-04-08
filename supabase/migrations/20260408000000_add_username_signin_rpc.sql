-- Migration: Add username-to-email lookup RPC for sign-in
-- This RPC is SECURITY DEFINER to allow unauthenticated users to resolve usernames for sign-in

CREATE OR REPLACE FUNCTION public.get_email_by_username(p_username TEXT)
RETURNS TEXT AS $$
DECLARE
    v_email TEXT;
BEGIN
    SELECT email INTO v_email FROM public.profiles WHERE username = p_username;
    RETURN v_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant access to anon and authenticated roles
GRANT EXECUTE ON FUNCTION public.get_email_by_username(TEXT) TO anon, authenticated;
