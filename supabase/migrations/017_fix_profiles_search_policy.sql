-- =====================================================
-- FIX PROFILES SELECT POLICY FOR USER SEARCH
-- =====================================================
-- This migration updates the profiles SELECT policy to allow
-- authenticated users to search for all users, not just public ones.
-- This is necessary for the user search functionality to work properly.

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;

-- Create a new policy that allows authenticated users to view all profiles
-- This enables search functionality while still protecting sensitive data
CREATE POLICY "Authenticated users can view all profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

-- Note: Sensitive profile data should be handled at the application level
-- or through additional column-level security if needed
