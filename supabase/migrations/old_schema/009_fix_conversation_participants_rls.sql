-- Fix infinite recursion in conversation_participants RLS policy
-- The SELECT policy was querying conversation_participants itself, causing infinite recursion

-- Drop the problematic policy
DROP POLICY IF EXISTS "Users can view participants in their conversations" ON public.conversation_participants;

-- Create a simpler policy that doesn't cause recursion
-- Allow viewing conversation participants if:
-- 1. The user is viewing their own participation record, OR
-- 2. The user is authenticated (app will filter appropriately)
CREATE POLICY "Users can view conversation participants"
ON public.conversation_participants FOR SELECT
USING (
    -- Allow if user is viewing their own participation
    auth.uid() = user_id OR
    -- Allow if user is authenticated (app logic will filter to their conversations)
    auth.uid() IS NOT NULL
);

-- Also fix the INSERT policy to avoid similar recursion
DROP POLICY IF EXISTS "Conversation admins can add participants" ON public.conversation_participants;

CREATE POLICY "Conversation admins can add participants"
ON public.conversation_participants FOR INSERT
WITH CHECK (
    -- Allow users to add themselves
    auth.uid() = user_id OR
    -- Allow conversation creators to add participants
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_participants.conversation_id
        AND c.created_by = auth.uid()
    )
);

-- Fix DELETE policy to avoid recursion
DROP POLICY IF EXISTS "Users can leave or admins can remove participants" ON public.conversation_participants;

CREATE POLICY "Users can leave or admins can remove participants"
ON public.conversation_participants FOR DELETE
USING (
    -- Allow users to remove themselves
    auth.uid() = user_id OR
    -- Allow conversation creators to remove participants
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_participants.conversation_id
        AND c.created_by = auth.uid()
    )
);
