-- =====================================================
-- LIVE LOCATION & MEDIA VIEW COUNT SUPPORT
-- =====================================================

-- 1. Update Messages Table
-- location_data: Stores coordinates, timestamp, and isLive status
-- media_view_mode: 'unlimited', 'once', 'twice'
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS location_data JSONB,
ADD COLUMN IF NOT EXISTS media_view_mode TEXT DEFAULT 'unlimited';

-- 2. Create Media Views Tracking Table
-- tracks how many times a user has viewed a specific media message
CREATE TABLE IF NOT EXISTS public.message_media_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    view_count INTEGER DEFAULT 0,
    last_viewed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(message_id, user_id)
);

-- 3. Enable RLS
ALTER TABLE public.message_media_views ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Users can only see view counts for messages in conversations they belong to
DROP POLICY IF EXISTS "Users can view counts for messages they can see" ON public.message_media_views;
CREATE POLICY "Users can view counts for messages they can see"
ON public.message_media_views FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.messages m
        JOIN public.conversation_participants cp ON m.conversation_id = cp.conversation_id
        WHERE m.id = message_media_views.message_id
        AND cp.user_id = auth.uid()
    )
);

-- Users can only record/increment their own view counts
DROP POLICY IF EXISTS "Users can insert/update their own view counts" ON public.message_media_views;
CREATE POLICY "Users can insert/update their own view counts"
ON public.message_media_views FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 5. Atomic Increment Function
-- Provides thread-safe incrementing of view counts via RPC
CREATE OR REPLACE FUNCTION public.increment_media_view_count(p_message_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.message_media_views (message_id, user_id, view_count, last_viewed_at)
    VALUES (p_message_id, auth.uid(), 1, NOW())
    ON CONFLICT (message_id, user_id)
    DO UPDATE SET 
        view_count = message_media_views.view_count + 1,
        last_viewed_at = NOW();
END;
$$;

-- 6. Add policy for updating location_data if it doesn't exist
-- Allows the sender to update the location_data column in their own messages
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'messages' 
        AND policyname = 'Users can update location_data of their own messages'
    ) THEN
        CREATE POLICY "Users can update location_data of their own messages"
        ON public.messages FOR UPDATE
        TO authenticated
        USING (auth.uid() = sender_id)
        WITH CHECK (auth.uid() = sender_id);
    END IF;
END
$$;

