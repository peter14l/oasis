-- Fix infinite recursion in canvas_members and circle_members policies by using security definer functions

-- ==========================================
-- 1. FIX CANVAS MEMBERS POLICY
-- ==========================================

CREATE OR REPLACE FUNCTION public.is_canvas_member(c_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM canvas_members
    WHERE canvas_id = c_id AND user_id = auth.uid()
  );
$$;

DROP POLICY IF EXISTS "Users can view canvas members of their canvases" ON canvas_members;

CREATE POLICY "Users can view canvas members of their canvases"
    ON canvas_members FOR SELECT
    USING ( public.is_canvas_member(canvas_id) );

-- ==========================================
-- 2. FIX CIRCLE MEMBERS POLICY
-- ==========================================

CREATE OR REPLACE FUNCTION public.is_circle_member(c_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM circle_members
    WHERE circle_id = c_id AND user_id = auth.uid()
  );
$$;

DROP POLICY IF EXISTS "Users can view circle members of their circles" ON circle_members;

CREATE POLICY "Users can view circle members of their circles"
    ON circle_members FOR SELECT
    USING ( public.is_circle_member(circle_id) );
