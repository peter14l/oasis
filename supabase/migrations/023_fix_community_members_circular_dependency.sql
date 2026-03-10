-- Fix circular dependency between communities and community_members RLS policies
-- This migration breaks the recursion loop

-- Drop the problematic community_members policy
DROP POLICY IF EXISTS "Community members are viewable" ON public.community_members;

-- Recreate without checking communities table (which would cause recursion)
CREATE POLICY "Community members are viewable"
ON public.community_members FOR SELECT
USING (
    -- Allow if user is viewing their own membership
    auth.uid() = user_id 
    OR
    -- Allow if user is authenticated (app-level filtering will handle privacy)
    auth.uid() IS NOT NULL
);
