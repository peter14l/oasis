-- Fix for infinite recursion in communities RLS policy
-- This migration fixes the circular dependency in the communities SELECT policy

-- Drop the problematic policy
DROP POLICY IF EXISTS "Public communities are viewable by everyone" ON public.communities;

-- Recreate the policy with a simpler, non-recursive approach
CREATE POLICY "Public communities are viewable by everyone"
ON public.communities FOR SELECT
USING (
    -- Public communities are always viewable
    is_private = FALSE 
    OR 
    -- Creator can always view their own community
    auth.uid() = creator_id 
    OR 
    -- Members can view private communities they belong to
    -- Use a direct lookup without recursion
    id IN (
        SELECT community_id 
        FROM public.community_members 
        WHERE user_id = auth.uid()
    )
);
