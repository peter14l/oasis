-- =====================================================
-- OASIS - COZY AUTO-REPLIES (Part 4)
-- =====================================================
-- Table to track auto-replies for rate limiting (max 1 per hour per pair)

CREATE TABLE IF NOT EXISTS public.cozy_auto_replies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for rate limit checks
CREATE INDEX IF NOT EXISTS idx_cozy_auto_replies_lookup 
ON public.cozy_auto_replies(sender_id, recipient_id, created_at);

-- =====================================================
-- RLS POLICIES
-- =====================================================
ALTER TABLE public.cozy_auto_replies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own auto-reply history"
ON public.cozy_auto_replies FOR SELECT
USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

CREATE POLICY "System can insert auto-replies"
ON public.cozy_auto_replies FOR INSERT
WITH CHECK (auth.uid() = sender_id);
