-- Add unique constraint to user_id to allow upserts
-- This ensures each user has only one primary subscription record in this table.
ALTER TABLE public.subscriptions ADD CONSTRAINT subscriptions_user_id_unique UNIQUE (user_id);
