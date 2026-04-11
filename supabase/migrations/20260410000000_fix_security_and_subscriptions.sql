-- ===========================================================================
-- SECURITY HARDENING & SUBSCRIPTION SYSTEM SYNC
-- Purpose: Remove metadata-based Pro exploits and ensure unified Subscriptions.
-- ===========================================================================

-- 1. REMOVE INSECURE METADATA SYNC (The "Metadata Ghost" Exploit)
-- This prevents users from forging Pro status via client-side metadata updates.
DROP TRIGGER IF EXISTS on_auth_user_metadata_updated ON auth.users;
DROP FUNCTION IF EXISTS public.handle_user_metadata_update();

-- 2. ENSURE SUBSCRIPTIONS TABLE EXISTS
-- Central table for all payment types (IAP, Razorpay, PayPal)
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- 'active', 'trailing', 'past_due', 'canceled', 'expired'
    plan_id VARCHAR(50) NOT NULL,
    payment_provider VARCHAR(20) NOT NULL, -- 'paypal', 'razorpay', 'google_play', 'apple_store'
    provider_subscription_id VARCHAR(100) UNIQUE,
    current_period_start TIMESTAMPTZ DEFAULT NOW(),
    current_period_end TIMESTAMPTZ NOT NULL,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on Subscriptions
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Users can read their own subscription
DROP POLICY IF EXISTS "Users can view own subscription" ON public.subscriptions;
CREATE POLICY "Users can view own subscription"
    ON public.subscriptions FOR SELECT
    USING (auth.uid() = user_id);

-- 3. SYNC PRO STATUS TO PROFILES & AUTH (SECURE)
-- This function runs as SECURITY DEFINER to update protected tables.
CREATE OR REPLACE FUNCTION public.sync_pro_status_from_subscription()
RETURNS TRIGGER AS $$
BEGIN
    -- If subscription is active and not expired, grant Pro status
    IF NEW.status = 'active' AND NEW.current_period_end > NOW() THEN
        -- Update Profile
        UPDATE public.profiles SET is_pro = true WHERE id = NEW.user_id;
        
        -- Update Auth app_metadata (Read-only for client, secure for Edge Functions)
        UPDATE auth.users 
        SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || '{"is_pro": true}'::jsonb
        WHERE id = NEW.user_id;
    ELSE
        -- Revoke Pro status
        UPDATE public.profiles SET is_pro = false WHERE id = NEW.user_id;
        
        UPDATE auth.users 
        SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || '{"is_pro": false}'::jsonb
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_subscription_sync_pro ON public.subscriptions;
CREATE TRIGGER on_subscription_sync_pro
    AFTER INSERT OR UPDATE ON public.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_pro_status_from_subscription();

-- 4. HARDEN PROFILES TABLE (is_pro protection)
-- Ensure the is_pro column cannot be updated directly by users via Supabase client.
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile except pro status" ON public.profiles;
CREATE POLICY "Users can update own profile except pro status"
ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
    auth.uid() = id 
    AND (
        -- Protect is_pro from being updated by the user directly.
        -- Since OLD/NEW are not available in RLS, we compare the new value with the current value in the database.
        is_pro = (SELECT p.is_pro FROM public.profiles p WHERE p.id = id)
    )
);

-- 5. XP INCREMENT SECURITY
-- Already exists but ensuring it remains SECURITY DEFINER
CREATE OR REPLACE FUNCTION increment_xp(user_id UUID, xp_amount INT)
RETURNS void AS $$
BEGIN
  UPDATE public.profiles
  SET xp = COALESCE(xp, 0) + xp_amount
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
