-- Add missing SELECT policy for likes table
-- This allows users to read likes (needed to check if already liked)
-- Combined with existing INSERT/DELETE policies

-- Enable RLS if not already enabled
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

-- Drop existing SELECT policy if exists
DROP POLICY IF EXISTS "Users can view likes" ON public.likes;

-- Create SELECT policy - users can view likes on public posts
-- or their own posts
CREATE POLICY "Users can view likes" ON public.likes FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.posts
    WHERE posts.id = likes.post_id
    AND (
      -- Post is by a public profile
      NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = posts.user_id
        AND profiles.is_private = true
      )
      OR
      -- User is the post owner
      posts.user_id = (SELECT auth.uid())
      OR
      -- User follows the post owner
      EXISTS (
        SELECT 1 FROM public.follows
        WHERE follows.follower_id = (SELECT auth.uid())
        AND follows.following_id = posts.user_id
      )
    )
  )
);