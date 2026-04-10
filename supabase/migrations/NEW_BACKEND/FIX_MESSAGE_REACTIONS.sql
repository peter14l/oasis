-- 1. Add the missing 'reaction' column
ALTER TABLE public.message_reactions ADD COLUMN IF NOT EXISTS reaction VARCHAR(10);

-- 2. Sync existing emoji data to the reaction column (optional but good for data integrity)
UPDATE public.message_reactions SET reaction = emoji WHERE reaction IS NULL;

-- 3. Ensure the 'username' column exists (as it's used in your Flutter provider)
ALTER TABLE public.message_reactions ADD COLUMN IF NOT EXISTS username TEXT DEFAULT 'Unknown';

-- 4. Fix constraints to match the app's expectations (one reaction per user per message)
-- Note: You might need to drop the old unique constraint if it was (message_id, user_id, emoji)
ALTER TABLE public.message_reactions DROP CONSTRAINT IF EXISTS message_reactions_message_id_user_id_emoji_key;
ALTER TABLE public.message_reactions DROP CONSTRAINT IF EXISTS unique_user_message_reaction;
ALTER TABLE public.message_reactions ADD CONSTRAINT unique_user_message_reaction UNIQUE (message_id, user_id);

-- 5. Notify PostgREST to refresh the schema cache
NOTIFY pgrst, 'reload schema';
