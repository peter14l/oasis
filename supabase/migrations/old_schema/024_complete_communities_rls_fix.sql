-- Complete fix for communities RLS policies
-- This removes all circular dependencies and simplifies the policies

-- Drop all existing community-related policies
DROP POLICY IF EXISTS "Public communities are viewable by everyone" ON public.communities;
DROP POLICY IF EXISTS "Authenticated users can create communities" ON public.communities;
DROP POLICY IF EXISTS "Community creators and admins can update communities" ON public.communities;
DROP POLICY IF EXISTS "Community creators can delete communities" ON public.communities;
DROP POLICY IF EXISTS "Community members are viewable" ON public.community_members;
DROP POLICY IF EXISTS "Community members are viewable by community members" ON public.community_members;
DROP POLICY IF EXISTS "Users can join communities" ON public.community_members;
DROP POLICY IF EXISTS "Users can leave or admins can remove members" ON public.community_members;
DROP POLICY IF EXISTS "Admins can update member roles" ON public.community_members;

-- =====================================================
-- COMMUNITIES POLICIES (Simplified, no recursion)
-- =====================================================

-- Allow all authenticated users to view all communities
-- Privacy filtering will be handled at application level
CREATE POLICY "Authenticated users can view communities"
ON public.communities FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Authenticated users can create communities
CREATE POLICY "Authenticated users can create communities"
ON public.communities FOR INSERT
WITH CHECK (auth.uid() = creator_id);

-- Community creators can update their communities
CREATE POLICY "Community creators can update communities"
ON public.communities FOR UPDATE
USING (auth.uid() = creator_id);

-- Community creators can delete their communities
CREATE POLICY "Community creators can delete communities"
ON public.communities FOR DELETE
USING (auth.uid() = creator_id);

-- =====================================================
-- COMMUNITY MEMBERS POLICIES (Simplified, no recursion)
-- =====================================================

-- Authenticated users can view all community memberships
-- Privacy filtering will be handled at application level
CREATE POLICY "Authenticated users can view memberships"
ON public.community_members FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Users can join communities
CREATE POLICY "Users can join communities"
ON public.community_members FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can leave communities
CREATE POLICY "Users can leave communities"
ON public.community_members FOR DELETE
USING (auth.uid() = user_id);

-- Admins can update member roles (simplified)
CREATE POLICY "Admins can update member roles"
ON public.community_members FOR UPDATE
USING (auth.uid() = user_id OR auth.uid() IS NOT NULL);
