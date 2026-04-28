-- Add Home Base fields to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS home_theme TEXT DEFAULT 'default';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pinned_items JSONB DEFAULT '[]'::jsonb;

-- Create Guestbook entries table
CREATE TABLE IF NOT EXISTS public.guestbook_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    visitor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_guestbook_profile_id ON public.guestbook_entries(profile_id);

-- RLS
ALTER TABLE public.guestbook_entries ENABLE ROW LEVEL SECURITY;

-- Anyone can view guestbook entries for a profile
CREATE POLICY "Public can view guestbook entries" 
ON public.guestbook_entries FOR SELECT 
USING (TRUE);

-- Authenticated users can sign guestbooks
CREATE POLICY "Users can sign guestbooks" 
ON public.guestbook_entries FOR INSERT 
WITH CHECK (auth.uid() = visitor_id);

-- Only profile owner or entry author can delete
CREATE POLICY "Profile owner or author can delete entry" 
ON public.guestbook_entries FOR DELETE 
USING (auth.uid() = visitor_id OR auth.uid() = profile_id);
