-- Compliance and Privacy-First Cleanup Migration
-- Enhances the delete_user_account function to ensure full GDPR compliance.

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS VOID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 1. Explicitly clean up task_queue (Privacy/GDPR)
    DELETE FROM public.task_queue WHERE user_id = v_user_id;

    -- 2. Explicitly clean up any Signal sessions where user was a participant
    -- (Though cascading handles keys, this ensures no orphaned metadata)
    -- This is handled by the ON DELETE CASCADE on signal_keys.user_id

    -- 3. Delete all user data via profile (cascading deletes handle messages, conversations, etc.)
    DELETE FROM public.profiles WHERE id = v_user_id;

    -- 4. Delete auth user
    DELETE FROM auth.users WHERE id = v_user_id;

    -- 5. Logic for storage cleanup can be triggered here via an Edge Function
    -- by inserting a 'cleanup' task into the task_queue for the system
    INSERT INTO public.task_queue (task_type, payload, status, priority)
    VALUES ('cleanup_storage', jsonb_build_object('user_id', v_user_id), 'pending', 10);

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.delete_user_account IS 'Safely deletes a user account and all associated data, including task queues and triggers a storage cleanup task.';
