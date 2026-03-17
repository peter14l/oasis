-- Alter the notifications table to drop the restrictive CHECK constraint on type
-- Since the frontend creates notifications with types like 'dm', 'post', 'reply',
-- the existing check constraint fails those inserts.

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
