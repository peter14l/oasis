-- =====================================================
-- CANVAS & CIRCLE RLS - HYPER FIX (RECURSION-FREE)
-- =====================================================

-- 1. Helper Functions (SECURITY DEFINER to bypass recursion)
CREATE OR REPLACE FUNCTION public.is_canvas_member(c_id uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM canvas_members WHERE canvas_id = c_id AND user_id = auth.uid()
  ) OR EXISTS (
    SELECT 1 FROM canvases WHERE id = c_id AND created_by = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_canvas_owner(c_id uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM canvas_members WHERE canvas_id = c_id AND user_id = auth.uid() AND role = 'owner'
  ) OR EXISTS (
    SELECT 1 FROM canvases WHERE id = c_id AND created_by = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_circle_member(c_id uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM circle_members WHERE circle_id = c_id AND user_id = auth.uid()
  ) OR EXISTS (
    SELECT 1 FROM circles WHERE id = c_id AND created_by = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_circle_admin(c_id uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM circle_members WHERE circle_id = c_id AND user_id = auth.uid() AND role = 'admin'
  ) OR EXISTS (
    SELECT 1 FROM circles WHERE id = c_id AND created_by = auth.uid()
  );
$$;

-- 2. RESET POLICIES
DROP POLICY IF EXISTS "Select_Canvases" ON canvases;
DROP POLICY IF EXISTS "Insert_Canvases" ON canvases;
DROP POLICY IF EXISTS "Update_Canvases" ON canvases;
DROP POLICY IF EXISTS "Delete_Canvases" ON canvases;
DROP POLICY IF EXISTS "Users can view canvases they are members of" ON canvases;
DROP POLICY IF EXISTS "Users can insert canvases" ON canvases;
DROP POLICY IF EXISTS "Canvas members can update canvases" ON canvases;
DROP POLICY IF EXISTS "Owners can delete canvases" ON canvases;

DROP POLICY IF EXISTS "Select_Members" ON canvas_members;
DROP POLICY IF EXISTS "Insert_Members" ON canvas_members;
DROP POLICY IF EXISTS "Update_Members" ON canvas_members;
DROP POLICY IF EXISTS "Delete_Members" ON canvas_members;
DROP POLICY IF EXISTS "Users can view canvas members of their canvases" ON canvas_members;
DROP POLICY IF EXISTS "Users can add themselves or be added to canvases" ON canvas_members;
DROP POLICY IF EXISTS "Users can remove themselves from canvases" ON canvas_members;
DROP POLICY IF EXISTS "Members can be updated" ON canvas_members;

-- 3. APPLY ROBUST CANVAS POLICIES
CREATE POLICY "Hyper_Select_Canvases" ON canvases FOR SELECT USING ( public.is_canvas_member(id) );
CREATE POLICY "Hyper_Insert_Canvases" ON canvases FOR INSERT WITH CHECK ( auth.uid() = created_by );
CREATE POLICY "Hyper_Update_Canvases" ON canvases FOR UPDATE USING ( public.is_canvas_member(id) );
CREATE POLICY "Hyper_Delete_Canvases" ON canvases FOR DELETE USING ( public.is_canvas_owner(id) );

-- 4. APPLY ROBUST CANVAS_MEMBERS POLICIES
CREATE POLICY "Hyper_Select_Members" ON canvas_members FOR SELECT USING ( public.is_canvas_member(canvas_id) );
CREATE POLICY "Hyper_Insert_Members" ON canvas_members FOR INSERT WITH CHECK ( (user_id = auth.uid()) OR public.is_canvas_member(canvas_id) );
CREATE POLICY "Hyper_Update_Members" ON canvas_members FOR UPDATE USING ( public.is_canvas_member(canvas_id) );
CREATE POLICY "Hyper_Delete_Members" ON canvas_members FOR DELETE USING ( (user_id = auth.uid()) OR public.is_canvas_owner(canvas_id) );

-- 5. APPLY ROBUST CANVAS_ITEMS POLICIES
DROP POLICY IF EXISTS "Select_Items" ON canvas_items;
DROP POLICY IF EXISTS "Insert_Items" ON canvas_items;
DROP POLICY IF EXISTS "Update_Items" ON canvas_items;
DROP POLICY IF EXISTS "Delete_Items" ON canvas_items;
DROP POLICY IF EXISTS "Users can view items in their canvases" ON canvas_items;
DROP POLICY IF EXISTS "Users can add items to their canvases" ON canvas_items;
DROP POLICY IF EXISTS "Users can update items in their canvases" ON canvas_items;
DROP POLICY IF EXISTS "Users can delete their own items" ON canvas_items;

CREATE POLICY "Hyper_Select_Items" ON canvas_items FOR SELECT USING ( public.is_canvas_member(canvas_id) );
CREATE POLICY "Hyper_Insert_Items" ON canvas_items FOR INSERT WITH CHECK ( public.is_canvas_member(canvas_id) );
CREATE POLICY "Hyper_Update_Items" ON canvas_items FOR UPDATE USING ( public.is_canvas_member(canvas_id) );
CREATE POLICY "Hyper_Delete_Items" ON canvas_items FOR DELETE USING ( author_id = auth.uid() OR public.is_canvas_owner(canvas_id) );

-- 6. SYNC EXISTING DATA (Ensure creators are members with 'owner' role)
INSERT INTO canvas_members (canvas_id, user_id, role)
SELECT id, created_by, 'owner'
FROM canvases
ON CONFLICT (canvas_id, user_id) DO UPDATE SET role = 'owner';
