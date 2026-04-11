-- Migration: House Ads System
-- Date: 2026-04-13

CREATE TABLE IF NOT EXISTS public.house_ads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    image_url TEXT,
    action_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- Enable RLS
ALTER TABLE public.house_ads ENABLE ROW LEVEL SECURITY;

-- Everyone can read active ads
DROP POLICY IF EXISTS "Everyone can view active house ads" ON public.house_ads;
CREATE POLICY "Everyone can view active house ads"
    ON public.house_ads FOR SELECT
    USING (is_active = TRUE);

-- Only service role or admins can manage ads
DROP POLICY IF EXISTS "Admins can manage house ads" ON public.house_ads;
CREATE POLICY "Admins can manage house ads"
    ON public.house_ads FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Insert some initial data
INSERT INTO public.house_ads (title, body, image_url, action_url)
VALUES 
('Upgrade to Oasis Pro', 'Get an ad-free experience, exclusive badges, and premium features.', 'https://oasis.app/pro-promo.png', 'https://oasis.app/pro'),
('Join the Alpha Community', 'Help shape the future of Oasis by joining our alpha testers group.', 'https://oasis.app/alpha-promo.png', 'https://oasis.app/community/alpha');
