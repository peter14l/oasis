-- Migration to add a temporary testing plan and ensure subscriptions table is ready
-- This is for the Rs 5 Oasis Subscription testing

-- Ensure subscriptions table exists (based on common Supabase patterns)
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL, -- 'active', 'trialing', 'past_due', 'canceled', 'unpaid'
    plan_id TEXT NOT NULL,
    payment_provider TEXT, -- 'razorpay', 'paypal', 'payu'
    provider_subscription_id TEXT,
    current_period_start TIMESTAMPTZ DEFAULT now(),
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id)
);

-- Ensure RLS is enabled
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Policies for subscriptions
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscriptions' AND policyname = 'Users can view their own subscription') THEN
        CREATE POLICY "Users can view their own subscription" ON public.subscriptions
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;

-- Trigger to sync is_pro to profiles table
CREATE OR REPLACE FUNCTION public.sync_subscription_to_profile()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'active' THEN
        UPDATE public.profiles SET is_pro = true WHERE id = NEW.user_id;
        -- Also update app_metadata for JWT inclusion
        UPDATE auth.users 
        SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || '{"is_pro": true}'::jsonb
        WHERE id = NEW.user_id;
    ELSE
        UPDATE public.profiles SET is_pro = false WHERE id = NEW.user_id;
        UPDATE auth.users 
        SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || '{"is_pro": false}'::jsonb
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply trigger
DROP TRIGGER IF EXISTS on_subscription_change ON public.subscriptions;
CREATE TRIGGER on_subscription_change
    AFTER INSERT OR UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.sync_subscription_to_profile();

-- Add a comment about the testing plan
COMMENT ON TABLE public.subscriptions IS 'Handles user subscriptions. Pro plan temporarily Rs 5 for testing.';
