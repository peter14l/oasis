-- SECURITY POLICIES FIX MIGRATION

-- 1. POSTS SELECT POLICY
-- Ensures posts are visible based on privacy settings, follow status, and blocking logic.
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

-- 2. TIME CAPSULES PRIVACY FIX
-- Replaces the overly permissive "Public can view capsules" policy.
DROP POLICY IF EXISTS "Public can view capsules" ON public.time_capsules;

-- New policy: Anyone can see a capsule ONLY IF it has been unlocked.
CREATE POLICY "Anyone can see unlocked capsules" ON public.time_capsules FOR SELECT 
USING (unlock_date <= NOW());
