-- ===========================================================================
-- RECURRING SUBSCRIPTIONS SCHEMA
-- ===========================================================================

CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- 'active', 'trailing', 'past_due', 'canceled', 'expired'
    plan_id VARCHAR(50) NOT NULL,
    payment_provider VARCHAR(20) NOT NULL, -- 'paypal', 'razorpay'
    provider_subscription_id VARCHAR(100) UNIQUE,
    current_period_start TIMESTAMPTZ DEFAULT NOW(),
    current_period_end TIMESTAMPTZ NOT NULL,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Users can read their own subscription
CREATE POLICY "Users can view own subscription"
    ON public.subscriptions FOR SELECT
    USING (auth.uid() = user_id);

-- trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- ===========================================================================
-- AUTOMATIC EXPIRATION HANDLING
-- ===========================================================================

-- This function should be called by a CRON job or manually to clean up expired subs
CREATE OR REPLACE FUNCTION public.cleanup_expired_subscriptions()
RETURNS VOID AS $$
DECLARE
    expired_user RECORD;
BEGIN
    FOR expired_user IN 
        SELECT user_id FROM public.subscriptions 
        WHERE current_period_end < NOW() AND status != 'expired'
    LOOP
        -- 1. Update Profile is_pro = false
        UPDATE public.profiles SET is_pro = false WHERE id = expired_user.user_id;
        
        -- 2. Update Auth app_metadata (secure)
        UPDATE auth.users 
        SET raw_app_meta_data = raw_app_meta_data || '{"is_pro": false}'::jsonb
        WHERE id = expired_user.user_id;

        -- 3. Mark subscription as expired
        UPDATE public.subscriptions 
        SET status = 'expired' 
        WHERE user_id = expired_user.user_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================================================
-- TRIGGER TO SYNC PRO STATUS ON INSERT/UPDATE
-- ===========================================================================

CREATE OR REPLACE FUNCTION public.sync_pro_status_from_subscription()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'active' AND NEW.current_period_end > NOW() THEN
        UPDATE public.profiles SET is_pro = true WHERE id = NEW.user_id;
        
        UPDATE auth.users 
        SET raw_app_meta_data = raw_app_meta_data || '{"is_pro": true}'::jsonb
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_subscription_sync_pro
    AFTER INSERT OR UPDATE ON public.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_pro_status_from_subscription();
