-- =====================================================
-- MORROW V2 - ROW LEVEL SECURITY POLICIES
-- =====================================================
-- This migration sets up RLS policies for all tables

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_read_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.typing_indicators ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PROFILES POLICIES
-- =====================================================

-- Anyone can view public profiles
CREATE POLICY "Public profiles are viewable by everyone"
ON public.profiles FOR SELECT
USING (
    is_private = FALSE OR
    auth.uid() = id OR
    EXISTS (
        SELECT 1 FROM public.follows
        WHERE follower_id = auth.uid() AND following_id = id
    )
);

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

-- Users can delete their own profile
CREATE POLICY "Users can delete their own profile"
ON public.profiles FOR DELETE
USING (auth.uid() = id);

-- =====================================================
-- POSTS POLICIES
-- =====================================================

-- Anyone can view posts from public profiles or followed users
CREATE POLICY "Posts are viewable by everyone or followers"
ON public.posts FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = posts.user_id
        AND (
            profiles.is_private = FALSE OR
            profiles.id = auth.uid() OR
            EXISTS (
                SELECT 1 FROM public.follows
                WHERE follower_id = auth.uid() AND following_id = profiles.id
            )
        )
    )
);

-- Users can insert their own posts
CREATE POLICY "Users can insert their own posts"
ON public.posts FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own posts
CREATE POLICY "Users can update their own posts"
ON public.posts FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own posts
CREATE POLICY "Users can delete their own posts"
ON public.posts FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- COMMUNITIES POLICIES
-- =====================================================

-- Public communities are viewable by everyone
CREATE POLICY "Public communities are viewable by everyone"
ON public.communities FOR SELECT
USING (
    is_private = FALSE OR
    auth.uid() = creator_id OR
    EXISTS (
        SELECT 1 FROM public.community_members
        WHERE community_id = communities.id AND user_id = auth.uid()
    )
);

-- Authenticated users can create communities
CREATE POLICY "Authenticated users can create communities"
ON public.communities FOR INSERT
WITH CHECK (auth.uid() = creator_id);

-- Community creators and admins can update communities
CREATE POLICY "Community creators and admins can update communities"
ON public.communities FOR UPDATE
USING (
    auth.uid() = creator_id OR
    EXISTS (
        SELECT 1 FROM public.community_members
        WHERE community_id = communities.id 
        AND user_id = auth.uid() 
        AND role IN ('admin', 'moderator')
    )
);

-- Community creators can delete communities
CREATE POLICY "Community creators can delete communities"
ON public.communities FOR DELETE
USING (auth.uid() = creator_id);

-- =====================================================
-- COMMUNITY MEMBERS POLICIES
-- =====================================================

-- Members can view other members in their communities
CREATE POLICY "Community members are viewable by community members"
ON public.community_members FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.community_members cm
        WHERE cm.community_id = community_members.community_id
        AND cm.user_id = auth.uid()
    ) OR
    EXISTS (
        SELECT 1 FROM public.communities c
        WHERE c.id = community_members.community_id
        AND c.is_private = FALSE
    )
);

-- Users can join communities
CREATE POLICY "Users can join communities"
ON public.community_members FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can leave communities or admins can remove members
CREATE POLICY "Users can leave or admins can remove members"
ON public.community_members FOR DELETE
USING (
    auth.uid() = user_id OR
    EXISTS (
        SELECT 1 FROM public.community_members cm
        WHERE cm.community_id = community_members.community_id
        AND cm.user_id = auth.uid()
        AND cm.role IN ('admin', 'moderator')
    )
);

-- Admins can update member roles
CREATE POLICY "Admins can update member roles"
ON public.community_members FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.community_members cm
        WHERE cm.community_id = community_members.community_id
        AND cm.user_id = auth.uid()
        AND cm.role = 'admin'
    )
);

-- =====================================================
-- FOLLOWS POLICIES
-- =====================================================

-- Users can view follows
CREATE POLICY "Follows are viewable by everyone"
ON public.follows FOR SELECT
USING (true);

-- Users can follow others
CREATE POLICY "Users can follow others"
ON public.follows FOR INSERT
WITH CHECK (auth.uid() = follower_id);

-- Users can unfollow
CREATE POLICY "Users can unfollow"
ON public.follows FOR DELETE
USING (auth.uid() = follower_id);

-- =====================================================
-- LIKES POLICIES
-- =====================================================

-- Likes are viewable by everyone
CREATE POLICY "Likes are viewable by everyone"
ON public.likes FOR SELECT
USING (true);

-- Users can like posts
CREATE POLICY "Users can like posts"
ON public.likes FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can unlike posts
CREATE POLICY "Users can unlike posts"
ON public.likes FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- BOOKMARKS POLICIES
-- =====================================================

-- Users can only view their own bookmarks
CREATE POLICY "Users can view their own bookmarks"
ON public.bookmarks FOR SELECT
USING (auth.uid() = user_id);

-- Users can bookmark posts
CREATE POLICY "Users can bookmark posts"
ON public.bookmarks FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can remove bookmarks
CREATE POLICY "Users can remove bookmarks"
ON public.bookmarks FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- COMMENTS POLICIES
-- =====================================================

-- Comments are viewable if the post is viewable
CREATE POLICY "Comments are viewable if post is viewable"
ON public.comments FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.posts
        WHERE posts.id = comments.post_id
    )
);

-- Users can create comments
CREATE POLICY "Users can create comments"
ON public.comments FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own comments
CREATE POLICY "Users can update their own comments"
ON public.comments FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own comments
CREATE POLICY "Users can delete their own comments"
ON public.comments FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- COMMENT LIKES POLICIES
-- =====================================================

-- Comment likes are viewable by everyone
CREATE POLICY "Comment likes are viewable by everyone"
ON public.comment_likes FOR SELECT
USING (true);

-- Users can like comments
CREATE POLICY "Users can like comments"
ON public.comment_likes FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can unlike comments
CREATE POLICY "Users can unlike comments"
ON public.comment_likes FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- NOTIFICATIONS POLICIES
-- =====================================================

-- Users can only view their own notifications
CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
USING (auth.uid() = user_id);

-- System can create notifications (handled by triggers)
CREATE POLICY "System can create notifications"
ON public.notifications FOR INSERT
WITH CHECK (true);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update their own notifications"
ON public.notifications FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications"
ON public.notifications FOR DELETE
USING (auth.uid() = user_id);

