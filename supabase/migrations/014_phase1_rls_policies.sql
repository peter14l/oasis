-- =====================================================
-- ROW LEVEL SECURITY POLICIES - PHASE 1 FEATURES
-- =====================================================
-- This migration enables RLS and creates policies for:
-- - Stories
-- - Hashtags & Mentions
-- - Collections
-- - Moderation

-- =====================================================
-- STORIES RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_reactions ENABLE ROW LEVEL SECURITY;

-- Stories: Anyone can view non-expired stories from public profiles or followed users
CREATE POLICY "Stories are viewable by everyone for public profiles"
    ON public.stories FOR SELECT
    USING (
        expires_at > NOW() AND (
            -- Public profile
            EXISTS (
                SELECT 1 FROM public.profiles
                WHERE id = stories.user_id AND is_private = FALSE
            )
            OR
            -- Followed user
            EXISTS (
                SELECT 1 FROM public.follows
                WHERE following_id = stories.user_id AND follower_id = auth.uid()
            )
            OR
            -- Own story
            user_id = auth.uid()
        )
    );

-- Users can create their own stories
CREATE POLICY "Users can create their own stories"
    ON public.stories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own stories
CREATE POLICY "Users can delete their own stories"
    ON public.stories FOR DELETE
    USING (auth.uid() = user_id);

-- Story Views: Users can view their own story views
CREATE POLICY "Users can view their own story views"
    ON public.story_views FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.stories
            WHERE id = story_views.story_id AND user_id = auth.uid()
        )
    );

-- Users can create story views
CREATE POLICY "Users can create story views"
    ON public.story_views FOR INSERT
    WITH CHECK (auth.uid() = viewer_id);

-- Story Reactions: Users can view reactions on stories they can see
CREATE POLICY "Users can view story reactions"
    ON public.story_reactions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.stories
            WHERE id = story_reactions.story_id
            AND (user_id = auth.uid() OR expires_at > NOW())
        )
    );

-- Users can create reactions
CREATE POLICY "Users can create story reactions"
    ON public.story_reactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own reactions
CREATE POLICY "Users can delete their own story reactions"
    ON public.story_reactions FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- HASHTAGS & MENTIONS RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.hashtags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_hashtags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentions ENABLE ROW LEVEL SECURITY;

-- Hashtags: Anyone can view hashtags
CREATE POLICY "Hashtags are viewable by everyone"
    ON public.hashtags FOR SELECT
    USING (true);

-- Hashtags are created by triggers, but allow authenticated users to query
CREATE POLICY "Authenticated users can create hashtags"
    ON public.hashtags FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Post Hashtags: Anyone can view
CREATE POLICY "Post hashtags are viewable by everyone"
    ON public.post_hashtags FOR SELECT
    USING (true);

-- Post hashtags are created by triggers
CREATE POLICY "Authenticated users can create post hashtags"
    ON public.post_hashtags FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Mentions: Users can view mentions they're involved in
CREATE POLICY "Users can view their mentions"
    ON public.mentions FOR SELECT
    USING (
        auth.uid() = mentioned_user_id OR
        auth.uid() = mentioned_by_user_id OR
        EXISTS (
            SELECT 1 FROM public.posts
            WHERE id = mentions.post_id AND user_id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM public.comments
            WHERE id = mentions.comment_id AND user_id = auth.uid()
        )
    );

-- Mentions are created by triggers
CREATE POLICY "Authenticated users can create mentions"
    ON public.mentions FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- =====================================================
-- COLLECTIONS RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collection_items ENABLE ROW LEVEL SECURITY;

-- Collections: Users can view their own collections and public collections
CREATE POLICY "Users can view their own collections"
    ON public.collections FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can view public collections"
    ON public.collections FOR SELECT
    USING (is_private = FALSE);

-- Users can create their own collections
CREATE POLICY "Users can create their own collections"
    ON public.collections FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own collections
CREATE POLICY "Users can update their own collections"
    ON public.collections FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own collections
CREATE POLICY "Users can delete their own collections"
    ON public.collections FOR DELETE
    USING (auth.uid() = user_id);

-- Collection Items: Users can view items in collections they can access
CREATE POLICY "Users can view collection items"
    ON public.collection_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.collections
            WHERE id = collection_items.collection_id
            AND (user_id = auth.uid() OR is_private = FALSE)
        )
    );

-- Users can add items to their own collections
CREATE POLICY "Users can add items to their own collections"
    ON public.collection_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.collections
            WHERE id = collection_id AND user_id = auth.uid()
        )
    );

-- Users can remove items from their own collections
CREATE POLICY "Users can remove items from their own collections"
    ON public.collection_items FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.collections
            WHERE id = collection_id AND user_id = auth.uid()
        )
    );

-- =====================================================
-- MODERATION RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.muted_users ENABLE ROW LEVEL SECURITY;

-- Reports: Users can view their own reports
CREATE POLICY "Users can view their own reports"
    ON public.reports FOR SELECT
    USING (auth.uid() = reporter_id);

-- Users can create reports
CREATE POLICY "Users can create reports"
    ON public.reports FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);

-- Moderators/admins can view all reports (future: add role check)
-- For now, only users can see their own reports

-- Blocked Users: Users can view their own blocks
CREATE POLICY "Users can view their own blocks"
    ON public.blocked_users FOR SELECT
    USING (auth.uid() = blocker_id);

-- Users can create blocks
CREATE POLICY "Users can create blocks"
    ON public.blocked_users FOR INSERT
    WITH CHECK (auth.uid() = blocker_id);

-- Users can remove their own blocks
CREATE POLICY "Users can remove their own blocks"
    ON public.blocked_users FOR DELETE
    USING (auth.uid() = blocker_id);

-- Muted Users: Users can view their own mutes
CREATE POLICY "Users can view their own mutes"
    ON public.muted_users FOR SELECT
    USING (auth.uid() = muter_id);

-- Users can create mutes
CREATE POLICY "Users can create mutes"
    ON public.muted_users FOR INSERT
    WITH CHECK (auth.uid() = muter_id);

-- Users can update their own mutes
CREATE POLICY "Users can update their own mutes"
    ON public.muted_users FOR UPDATE
    USING (auth.uid() = muter_id)
    WITH CHECK (auth.uid() = muter_id);

-- Users can remove their own mutes
CREATE POLICY "Users can remove their own mutes"
    ON public.muted_users FOR DELETE
    USING (auth.uid() = muter_id);

-- =====================================================
-- ADDITIONAL POLICIES FOR EXISTING TABLES
-- =====================================================

-- Update posts policies to filter blocked/muted users
DROP POLICY IF EXISTS "Posts are viewable by everyone" ON public.posts;
CREATE POLICY "Posts are viewable by everyone except blocked users"
    ON public.posts FOR SELECT
    USING (
        -- Not blocked by the post author
        NOT EXISTS (
            SELECT 1 FROM public.blocked_users
            WHERE (blocker_id = posts.user_id AND blocked_id = auth.uid())
            OR (blocker_id = auth.uid() AND blocked_id = posts.user_id)
        )
    );

-- Update comments policies to filter blocked users
DROP POLICY IF EXISTS "Comments are viewable by everyone" ON public.comments;
CREATE POLICY "Comments are viewable by everyone except blocked users"
    ON public.comments FOR SELECT
    USING (
        -- Not blocked by the comment author
        NOT EXISTS (
            SELECT 1 FROM public.blocked_users
            WHERE (blocker_id = comments.user_id AND blocked_id = auth.uid())
            OR (blocker_id = auth.uid() AND blocked_id = comments.user_id)
        )
    );
