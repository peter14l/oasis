-- =====================================================
-- ENABLE REALTIME REPLICATION FOR CORE TABLES
-- =====================================================

-- This script ensures that Supabase Realtime broadcasts changes
-- for tables that are used by the Flutter app via .stream() or .onPostgresChanges().

-- 1. Ensure the supabase_realtime publication exists
-- (This should usually exist by default in a Supabase project)

-- 2. Add core feature tables to the publication
-- We use DO blocks to avoid errors if the table is already in the publication

DO $$
BEGIN
    -- messages
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
    END IF;

    -- posts
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'posts'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.posts;
    END IF;

    -- calls
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'calls'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.calls;
    END IF;

    -- call_participants
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'call_participants'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.call_participants;
    END IF;

    -- call_signaling
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'call_signaling'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.call_signaling;
    END IF;

    -- typing_indicators
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'typing_indicators'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.typing_indicators;
    END IF;

    -- conversation_participants
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'conversation_participants'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.conversation_participants;
    END IF;
END $$;

-- 3. Verify Publication Status
-- You can run: SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
