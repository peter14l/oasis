-- Add missing SELECT policy for posts to allow users to view them on the feed and profile
DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can view posts" ON public.posts;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

CREATE POLICY "Users can view posts" ON public.posts FOR SELECT
USING (
  (NOT EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = posts.user_id AND profiles.is_private = true)
   OR posts.user_id = (SELECT auth.uid())
   OR EXISTS (SELECT 1 FROM public.follows WHERE follows.follower_id = (SELECT auth.uid()) AND follows.following_id = posts.user_id)
  )
  AND NOT EXISTS (
    SELECT 1 FROM public.blocked_users
    WHERE (blocker_id = posts.user_id AND blocked_id = (SELECT auth.uid()))
    OR (blocker_id = (SELECT auth.uid()) AND blocked_id = posts.user_id)
  )
);
