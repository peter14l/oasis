-- =============================================================================
-- SECURITY HARDENING MIGRATION
-- Fixes: C-3, H-1, H-2, H-3, M-1, M-2, L-2
-- =============================================================================

-- ===========================================================================
-- C-3: canvas_members / circle_members — fix DEFAULT-ALLOW INSERT
-- ===========================================================================

DROP POLICY IF EXISTS "Users can add themselves or be added to canvases" ON canvas_members;
CREATE POLICY "Canvas creator can add members, users can add themselves"
    ON canvas_members FOR INSERT
    WITH CHECK (
        user_id = (SELECT auth.uid())
        OR EXISTS (
            SELECT 1 FROM canvases
            WHERE id = canvas_id
            AND created_by = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can add members to circles" ON circle_members;
CREATE POLICY "Circle creator can add members, users can join circles"
    ON circle_members FOR INSERT
    WITH CHECK (
        user_id = (SELECT auth.uid())
        OR EXISTS (
            SELECT 1 FROM circles
            WHERE id = circle_id
            AND created_by = (SELECT auth.uid())
        )
    );


-- ===========================================================================
-- H-1: notifications INSERT — drop world-writable policy
-- Triggers run as SECURITY DEFINER and bypass RLS; no client INSERT needed.
-- ===========================================================================

DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;

-- Clients can only create notifications where THEY are the actor
-- (e.g. sending a reaction notification). Server triggers still bypass RLS.
CREATE POLICY "Users can insert notifications as actor"
    ON public.notifications FOR INSERT
    WITH CHECK (actor_id = (SELECT auth.uid()));


-- ===========================================================================
-- H-2: handle_new_user — add SET search_path to SECURITY DEFINER function
-- Prevents search_path injection against a superuser-privilege function.
-- ===========================================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, username, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL)
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;


-- ===========================================================================
-- H-3: signal_keys SELECT — restrict to authenticated users only
-- Prevents unauthenticated mass-harvesting of one-time prekeys.
-- ===========================================================================

DROP POLICY IF EXISTS "Anyone can read signal keys" ON signal_keys;

CREATE POLICY "Authenticated users can read signal key bundles"
    ON signal_keys FOR SELECT
    USING (auth.role() = 'authenticated');


-- ===========================================================================
-- M-1: Replace auth.uid() with (SELECT auth.uid()) in high-traffic policies
-- This makes the call an InitPlan (evaluated once per query, not per-row),
-- improving performance and preventing planner edge-cases on Postgres <15.
-- ===========================================================================

-- profiles
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can delete their own profile" ON public.profiles;
CREATE POLICY "Users can delete their own profile"
    ON public.profiles FOR DELETE
    USING ((SELECT auth.uid()) = id);

-- posts
DROP POLICY IF EXISTS "Users can insert their own posts" ON public.posts;
CREATE POLICY "Users can insert their own posts"
    ON public.posts FOR INSERT
    WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own posts" ON public.posts;
CREATE POLICY "Users can update their own posts"
    ON public.posts FOR UPDATE
    USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete their own posts" ON public.posts;
CREATE POLICY "Users can delete their own posts"
    ON public.posts FOR DELETE
    USING ((SELECT auth.uid()) = user_id);

-- notifications
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications"
    ON public.notifications FOR UPDATE
    USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
CREATE POLICY "Users can delete their own notifications"
    ON public.notifications FOR DELETE
    USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications"
    ON public.notifications FOR SELECT
    USING ((SELECT auth.uid()) = user_id);

-- bookmarks
DROP POLICY IF EXISTS "Users can view their own bookmarks" ON public.bookmarks;
CREATE POLICY "Users can view their own bookmarks"
    ON public.bookmarks FOR SELECT
    USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can bookmark posts" ON public.bookmarks;
CREATE POLICY "Users can bookmark posts"
    ON public.bookmarks FOR INSERT
    WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can remove bookmarks" ON public.bookmarks;
CREATE POLICY "Users can remove bookmarks"
    ON public.bookmarks FOR DELETE
    USING ((SELECT auth.uid()) = user_id);

-- likes
DROP POLICY IF EXISTS "Users can like posts" ON public.likes;
CREATE POLICY "Users can like posts"
    ON public.likes FOR INSERT
    WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can unlike posts" ON public.likes;
CREATE POLICY "Users can unlike posts"
    ON public.likes FOR DELETE
    USING ((SELECT auth.uid()) = user_id);

-- comments
DROP POLICY IF EXISTS "Users can create comments" ON public.comments;
CREATE POLICY "Users can create comments"
    ON public.comments FOR INSERT
    WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own comments" ON public.comments;
CREATE POLICY "Users can update their own comments"
    ON public.comments FOR UPDATE
    USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete their own comments" ON public.comments;
CREATE POLICY "Users can delete their own comments"
    ON public.comments FOR DELETE
    USING ((SELECT auth.uid()) = user_id);

-- follows
DROP POLICY IF EXISTS "Users can follow others" ON public.follows;
CREATE POLICY "Users can follow others"
    ON public.follows FOR INSERT
    WITH CHECK ((SELECT auth.uid()) = follower_id);

DROP POLICY IF EXISTS "Users can unfollow" ON public.follows;
CREATE POLICY "Users can unfollow"
    ON public.follows FOR DELETE
    USING ((SELECT auth.uid()) = follower_id);


-- ===========================================================================
-- M-2: comments SELECT — enforce post visibility (private profile check)
-- Previously, ANY authenticated user could read comments on private posts.
-- ===========================================================================

DROP POLICY IF EXISTS "Comments are viewable if post is viewable" ON public.comments;
CREATE POLICY "Comments are viewable if post is viewable"
    ON public.comments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.posts
            JOIN public.profiles ON profiles.id = posts.user_id
            WHERE posts.id = comments.post_id
            AND (
                profiles.is_private = FALSE
                OR profiles.id = (SELECT auth.uid())
                OR EXISTS (
                    SELECT 1 FROM public.follows
                    WHERE follower_id = (SELECT auth.uid())
                    AND following_id = profiles.id
                )
            )
        )
    );


-- ===========================================================================
-- L-2: follows SELECT — require authentication (prevent social graph scraping)
-- ===========================================================================

DROP POLICY IF EXISTS "Follows are viewable by everyone" ON public.follows;
CREATE POLICY "Authenticated users can view follows"
    ON public.follows FOR SELECT
    USING (auth.role() = 'authenticated');
