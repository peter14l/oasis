-- Migration: Privacy and Audit System
-- Date: 2026-04-12

-- 1. Add E2EE columns to time_capsules
ALTER TABLE public.time_capsules ADD COLUMN IF NOT EXISTS encrypted_keys JSONB;
ALTER TABLE public.time_capsules ADD COLUMN IF NOT EXISTS iv TEXT;

-- 2. Add E2EE columns to canvas_items
ALTER TABLE public.canvas_items ADD COLUMN IF NOT EXISTS encrypted_keys JSONB;
ALTER TABLE public.canvas_items ADD COLUMN IF NOT EXISTS iv TEXT;

-- 3. Create privacy_audit_logs table
CREATE TABLE IF NOT EXISTS public.privacy_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    resource_type TEXT NOT NULL, -- 'time_capsule', 'canvas_item', etc.
    action TEXT NOT NULL, -- 'READ', 'WRITE', 'DELETE'
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable RLS
ALTER TABLE public.time_capsules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.canvas_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.privacy_audit_logs ENABLE ROW LEVEL SECURITY;

-- 5. Policies for time_capsules
DROP POLICY IF EXISTS "Users can view their own capsules" ON public.time_capsules;
CREATE POLICY "Users can view their own capsules" 
    ON public.time_capsules FOR SELECT 
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own capsules" ON public.time_capsules;
CREATE POLICY "Users can insert their own capsules" 
    ON public.time_capsules FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own capsules" ON public.time_capsules;
CREATE POLICY "Users can update their own capsules" 
    ON public.time_capsules FOR UPDATE 
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own capsules" ON public.time_capsules;
CREATE POLICY "Users can delete their own capsules" 
    ON public.time_capsules FOR DELETE 
    USING (auth.uid() = user_id);

-- 6. Policies for canvas_items
-- Note: Canvas items are visible to all members of the canvas.
-- We need to check membership in canvas_members.
DROP POLICY IF EXISTS "Members can view canvas items" ON public.canvas_items;
CREATE POLICY "Members can view canvas items" 
    ON public.canvas_items FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM public.canvas_members 
            WHERE canvas_id = canvas_items.canvas_id 
            AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Members can insert canvas items" ON public.canvas_items;
CREATE POLICY "Members can insert canvas items" 
    ON public.canvas_items FOR INSERT 
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.canvas_members 
            WHERE canvas_id = canvas_items.canvas_id 
            AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Authors or owners can update/delete canvas items" ON public.canvas_items;
CREATE POLICY "Authors or owners can update/delete canvas items" 
    ON public.canvas_items FOR ALL 
    USING (
        auth.uid() = author_id OR 
        EXISTS (
            SELECT 1 FROM public.canvas_members 
            WHERE canvas_id = canvas_items.canvas_id 
            AND user_id = auth.uid() 
            AND role = 'owner'
        )
    );

-- 7. Policies for privacy_audit_logs
DROP POLICY IF EXISTS "Users can view their own audit logs" ON public.privacy_audit_logs;
CREATE POLICY "Users can view their own audit logs" 
    ON public.privacy_audit_logs FOR SELECT 
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert audit logs" ON public.privacy_audit_logs;
CREATE POLICY "System can insert audit logs" 
    ON public.privacy_audit_logs FOR INSERT 
    WITH CHECK (auth.uid() = user_id);
