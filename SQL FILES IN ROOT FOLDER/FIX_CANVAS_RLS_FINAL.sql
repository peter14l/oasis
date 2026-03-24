-- =====================================================
-- FIX CANVAS & CIRCLE RLS RECURSION AND PERMISSIONS
-- =====================================================

-- 1. Helper Functions (SECURITY DEFINER to bypass recursion)
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

CREATE OR REPLACE FUNCTION public.is_canvas_owner(c_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM canvas_members
    WHERE canvas_id = c_id AND user_id = auth.uid() AND role = 'owner'
  );
$$;

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

CREATE OR REPLACE FUNCTION public.is_circle_admin(c_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM circle_members
    WHERE circle_id = c_id AND user_id = auth.uid() AND role = 'admin'
  );
$$;

-- 2. Update Canvas Policies
DROP POLICY IF EXISTS "Users can view canvases they are members of" ON canvases;
DROP POLICY IF EXISTS "Canvas members can update canvases" ON canvases;

CREATE POLICY "Users can view canvases they are members of"
    ON canvases FOR SELECT
    USING ( public.is_canvas_member(id) OR created_by = auth.uid() );

CREATE POLICY "Canvas members can update canvases"
    ON canvases FOR UPDATE
    USING ( public.is_canvas_member(id) );

-- 3. Update Canvas Members Policies
DROP POLICY IF EXISTS "Users can view canvas members of their canvases" ON canvas_members;
DROP POLICY IF EXISTS "Users can add themselves or be added to canvases" ON canvas_members;

CREATE POLICY "Users can view canvas members of their canvases"
    ON canvas_members FOR SELECT
    USING ( public.is_canvas_member(canvas_id) );

CREATE POLICY "Users can add themselves or be added to canvases"
    ON canvas_members FOR INSERT
    WITH CHECK (
        -- User is adding themselves
        (user_id = auth.uid()) 
        OR 
        -- User is a member adding someone else (invite)
        public.is_canvas_member(canvas_id)
        OR
        -- Special case for canvas creation (creator adds themselves)
        EXISTS (SELECT 1 FROM canvases WHERE id = canvas_id AND created_by = auth.uid())
    );

-- 4. Update Canvas Items Policies
DROP POLICY IF EXISTS "Users can view items in their canvases" ON canvas_items;
DROP POLICY IF EXISTS "Users can add items to their canvases" ON canvas_items;
DROP POLICY IF EXISTS "Users can update items in their canvases" ON canvas_items;

CREATE POLICY "Users can view items in their canvases"
    ON canvas_items FOR SELECT
    USING ( public.is_canvas_member(canvas_id) );

CREATE POLICY "Users can add items to their canvases"
    ON canvas_items FOR INSERT
    WITH CHECK ( public.is_canvas_member(canvas_id) );

CREATE POLICY "Users can update items in their canvases"
    ON canvas_items FOR UPDATE
    USING ( public.is_canvas_member(canvas_id) );

-- 5. Update Circle Policies
DROP POLICY IF EXISTS "Users can view circles they are members of" ON circles;

CREATE POLICY "Users can view circles they are members of"
    ON circles FOR SELECT
    USING ( public.is_circle_member(id) OR created_by = auth.uid() );

-- 6. Update Circle Members Policies
DROP POLICY IF EXISTS "Users can view circle members of their circles" ON circle_members;
DROP POLICY IF EXISTS "Users can add members to circles" ON circle_members;

CREATE POLICY "Users can view circle members of their circles"
    ON circle_members FOR SELECT
    USING ( public.is_circle_member(circle_id) );

CREATE POLICY "Users can add members to circles"
    ON circle_members FOR INSERT
    WITH CHECK (
        (user_id = auth.uid())
        OR
        public.is_circle_member(circle_id)
        OR
        EXISTS (SELECT 1 FROM circles WHERE id = circle_id AND created_by = auth.uid())
    );

-- 7. Update Commitments Policies
DROP POLICY IF EXISTS "Users can view commitments in their circles" ON commitments;
DROP POLICY IF EXISTS "Circle members can add commitments" ON commitments;

CREATE POLICY "Users can view commitments in their circles"
    ON commitments FOR SELECT
    USING ( public.is_circle_member(circle_id) );

CREATE POLICY "Circle members can add commitments"
    ON commitments FOR INSERT
    WITH CHECK ( public.is_circle_member(circle_id) );

-- 8. Update Commitment Responses Policies
DROP POLICY IF EXISTS "Users can view commitment responses in their circles" ON commitment_responses;
DROP POLICY IF EXISTS "Users can respond to commitments in their circles" ON commitment_responses;

CREATE POLICY "Users can view commitment responses in their circles"
    ON commitment_responses FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM commitments c
            WHERE c.id = commitment_responses.commitment_id
            AND public.is_circle_member(c.circle_id)
        )
    );

CREATE POLICY "Users can respond to commitments in their circles"
    ON commitment_responses FOR INSERT
    WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM commitments c
            WHERE c.id = commitment_responses.commitment_id
            AND public.is_circle_member(c.circle_id)
        )
    );
