-- FOLLOW REQUESTS TABLE
CREATE TABLE IF NOT EXISTS public.follow_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

-- ENABLE RLS
ALTER TABLE public.follow_requests ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES
CREATE POLICY "Users can view their own follow requests" ON public.follow_requests
    FOR SELECT USING (auth.uid() = follower_id OR auth.uid() = following_id);

CREATE POLICY "Users can create follow requests" ON public.follow_requests
    FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Target user can update follow request status" ON public.follow_requests
    FOR UPDATE USING (auth.uid() = following_id);

CREATE POLICY "Users can delete their own follow requests" ON public.follow_requests
    FOR DELETE USING (auth.uid() = follower_id OR auth.uid() = following_id);

-- TRIGGER FOR NOTIFICATION
CREATE OR REPLACE FUNCTION public.handle_follow_request()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO public.notifications (user_id, actor_id, type, content)
        VALUES (NEW.following_id, NEW.follower_id, 'follow_request', 'sent you a follow request');
    ELSIF (TG_OP = 'UPDATE' AND NEW.status = 'accepted' AND OLD.status = 'pending') THEN
        -- Add to follows table
        INSERT INTO public.follows (follower_id, following_id)
        VALUES (NEW.follower_id, NEW.following_id)
        ON CONFLICT DO NOTHING;
        
        -- Create a notification for the follower
        INSERT INTO public.notifications (user_id, actor_id, type, content)
        VALUES (NEW.follower_id, NEW.following_id, 'follow', 'accepted your follow request');
        
        -- Delete the notification for the following user (sent you a follow request)
        DELETE FROM public.notifications 
        WHERE user_id = NEW.following_id AND actor_id = NEW.follower_id AND type = 'follow_request';
        
        -- Delete the follow request record since it's now a follow
        DELETE FROM public.follow_requests WHERE id = NEW.id;
    ELSIF (TG_OP = 'UPDATE' AND NEW.status = 'declined' AND OLD.status = 'pending') THEN
        -- Delete the notification
        DELETE FROM public.notifications 
        WHERE user_id = NEW.following_id AND actor_id = NEW.follower_id AND type = 'follow_request';
        
        -- Delete the follow request record
        DELETE FROM public.follow_requests WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- DROP TRIGGER IF EXISTS on_follow_request ON public.follow_requests;
CREATE TRIGGER on_follow_request
    AFTER INSERT OR UPDATE ON public.follow_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_follow_request();

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_follow_requests_follower ON public.follow_requests(follower_id);
CREATE INDEX IF NOT EXISTS idx_follow_requests_following ON public.follow_requests(following_id);
CREATE INDEX IF NOT EXISTS idx_follow_requests_status ON public.follow_requests(status);
