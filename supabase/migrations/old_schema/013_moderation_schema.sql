-- =====================================================
-- CONTENT MODERATION FEATURE - DATABASE SCHEMA
-- =====================================================
-- This migration creates tables for content reporting and user blocking/muting

-- =====================================================
-- REPORTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL,
    comment_id UUID REFERENCES public.comments(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending',
    reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    resolution_note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT report_category_check CHECK (category IN (
        'spam',
        'harassment',
        'hate_speech',
        'violence',
        'nudity',
        'misinformation',
        'copyright',
        'other'
    )),
    CONSTRAINT report_status_check CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
    CONSTRAINT report_has_target CHECK (
        reported_user_id IS NOT NULL OR
        post_id IS NOT NULL OR
        comment_id IS NOT NULL
    )
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON public.reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported_user_id ON public.reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_reports_post_id ON public.reports(post_id);
CREATE INDEX IF NOT EXISTS idx_reports_comment_id ON public.reports(comment_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_category ON public.reports(category);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at DESC);

-- =====================================================
-- BLOCKED USERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.blocked_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT no_self_block CHECK (blocker_id != blocked_id),
    UNIQUE(blocker_id, blocked_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker_id ON public.blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked_id ON public.blocked_users(blocked_id);

-- =====================================================
-- MUTED USERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.muted_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    muter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    muted_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    CONSTRAINT no_self_mute CHECK (muter_id != muted_id),
    UNIQUE(muter_id, muted_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_muted_users_muter_id ON public.muted_users(muter_id);
CREATE INDEX IF NOT EXISTS idx_muted_users_muted_id ON public.muted_users(muted_id);
CREATE INDEX IF NOT EXISTS idx_muted_users_expires_at ON public.muted_users(expires_at);

-- =====================================================
-- FUNCTION: Check if user is blocked
-- =====================================================
CREATE OR REPLACE FUNCTION is_user_blocked(user_a UUID, user_b UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.blocked_users
        WHERE (blocker_id = user_a AND blocked_id = user_b)
        OR (blocker_id = user_b AND blocked_id = user_a)
    );
END;
$$;

-- =====================================================
-- FUNCTION: Check if user is muted
-- =====================================================
CREATE OR REPLACE FUNCTION is_user_muted(muter UUID, muted UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.muted_users
        WHERE muter_id = muter 
        AND muted_id = muted
        AND (expires_at IS NULL OR expires_at > NOW())
    );
END;
$$;

-- =====================================================
-- FUNCTION: Get blocked users list
-- =====================================================
CREATE OR REPLACE FUNCTION get_blocked_users(requesting_user_id UUID)
RETURNS TABLE (
    id UUID,
    blocked_user_id UUID,
    username TEXT,
    full_name TEXT,
    avatar_url TEXT,
    blocked_at TIMESTAMPTZ,
    reason TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bu.id,
        p.id as blocked_user_id,
        p.username,
        p.full_name,
        p.avatar_url,
        bu.created_at as blocked_at,
        bu.reason
    FROM public.blocked_users bu
    INNER JOIN public.profiles p ON p.id = bu.blocked_id
    WHERE bu.blocker_id = requesting_user_id
    ORDER BY bu.created_at DESC;
END;
$$;

-- =====================================================
-- FUNCTION: Get muted users list
-- =====================================================
CREATE OR REPLACE FUNCTION get_muted_users(requesting_user_id UUID)
RETURNS TABLE (
    id UUID,
    muted_user_id UUID,
    username TEXT,
    full_name TEXT,
    avatar_url TEXT,
    muted_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    reason TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mu.id,
        p.id as muted_user_id,
        p.username,
        p.full_name,
        p.avatar_url,
        mu.created_at as muted_at,
        mu.expires_at,
        mu.reason
    FROM public.muted_users mu
    INNER JOIN public.profiles p ON p.id = mu.muted_id
    WHERE mu.muter_id = requesting_user_id
    AND (mu.expires_at IS NULL OR mu.expires_at > NOW())
    ORDER BY mu.created_at DESC;
END;
$$;

-- =====================================================
-- FUNCTION: Clean up expired mutes
-- =====================================================
CREATE OR REPLACE FUNCTION cleanup_expired_mutes()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.muted_users
    WHERE expires_at IS NOT NULL AND expires_at < NOW();
END;
$$;

-- =====================================================
-- FUNCTION: Get user's reports
-- =====================================================
CREATE OR REPLACE FUNCTION get_user_reports(requesting_user_id UUID)
RETURNS TABLE (
    id UUID,
    category TEXT,
    reason TEXT,
    description TEXT,
    status TEXT,
    created_at TIMESTAMPTZ,
    reported_user_username TEXT,
    post_content TEXT,
    comment_content TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        r.category,
        r.reason,
        r.description,
        r.status,
        r.created_at,
        p.username as reported_user_username,
        po.content as post_content,
        c.content as comment_content
    FROM public.reports r
    LEFT JOIN public.profiles p ON p.id = r.reported_user_id
    LEFT JOIN public.posts po ON po.id = r.post_id
    LEFT JOIN public.comments c ON c.id = r.comment_id
    WHERE r.reporter_id = requesting_user_id
    ORDER BY r.created_at DESC;
END;
$$;

-- =====================================================
-- FUNCTION: Submit report
-- =====================================================
CREATE OR REPLACE FUNCTION submit_report(
    reporter UUID,
    report_category TEXT,
    report_reason TEXT,
    reported_user UUID DEFAULT NULL,
    reported_post UUID DEFAULT NULL,
    reported_comment UUID DEFAULT NULL,
    report_description TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_report_id UUID;
BEGIN
    IF reported_user IS NULL AND reported_post IS NULL AND reported_comment IS NULL THEN
        RAISE EXCEPTION 'Must specify at least one target to report';
    END IF;

    INSERT INTO public.reports (
        reporter_id,
        reported_user_id,
        post_id,
        comment_id,
        category,
        reason,
        description
    )
    VALUES (
        reporter,
        reported_user,
        reported_post,
        reported_comment,
        report_category,
        report_reason,
        report_description
    )
    RETURNING id INTO new_report_id;

    RETURN new_report_id;
END;
$$;
