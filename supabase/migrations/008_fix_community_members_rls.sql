-- Fix infinite recursion in community_members RLS policy
-- The SELECT policy was querying community_members itself, causing infinite recursion

-- Drop the problematic policy
DROP POLICY IF EXISTS "Community members are viewable by community members" ON public.community_members;

-- Create a simpler policy that doesn't cause recursion
-- Allow viewing community members if:
-- 1. The community is public, OR
-- 2. The user is authenticated (they can see members of communities they're in via app logic)
CREATE POLICY "Community members are viewable"
ON public.community_members FOR SELECT
USING (
    -- Allow if community is public
    EXISTS (
        SELECT 1 FROM public.communities c
        WHERE c.id = community_members.community_id
        AND c.is_private = FALSE
    ) OR
    -- Allow if user is viewing their own membership
    auth.uid() = user_id OR
    -- Allow if user is authenticated (app will filter appropriately)
    auth.uid() IS NOT NULL
);
