-- =====================================================
-- OASIS - MASTER DATABASE SCHEMA (FINAL CONSOLIDATED)
-- =====================================================
-- This file contains the complete schema, functions, triggers, and migrations
-- for the Oasis project. Run this in a fresh Supabase SQL Editor.

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- PART 1: CORE INITIAL SCHEMA (001-010)
-- =====================================================

-- =====================================================
-- 001_initial_schema.sql
-- =====================================================
-- =====================================================
-- OASIS - INITIAL DATABASE SCHEMA
-- =====================================================
-- This migration creates the core database structure for the Oasis social media app
-- Run this in your Supabase SQL Editor

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- PROFILES TABLE (extends auth.users)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    location TEXT,
    website TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    is_private BOOLEAN DEFAULT FALSE,
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    posts_count INTEGER DEFAULT 0,
    is_pro BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 30),
    CONSTRAINT username_format CHECK (username ~ '^[a-z0-9_]+$')
);

-- Create a function to handle sync from auth.users metadata
-- This will automatically update the profiles table when metadata is updated
CREATE OR REPLACE FUNCTION public.handle_user_metadata_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.raw_user_meta_data->>'is_pro' IS NOT NULL THEN
    UPDATE public.profiles
    SET is_pro = (NEW.raw_user_meta_data->>'is_pro')::BOOLEAN
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger for metadata sync
DROP TRIGGER IF EXISTS on_auth_user_metadata_updated ON auth.users;
CREATE TRIGGER on_auth_user_metadata_updated
  AFTER UPDATE OF raw_user_meta_data ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_user_metadata_update();

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at DESC);

-- =====================================================
-- POSTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT,
    image_url TEXT,
    video_url TEXT,
    community_id UUID,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    views_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT post_has_content CHECK (
        content IS NOT NULL OR 
        image_url IS NOT NULL OR 
        video_url IS NOT NULL
    )
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_community_id ON public.posts(community_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_is_pinned ON public.posts(is_pinned) WHERE is_pinned = TRUE;

-- =====================================================
-- COMMUNITIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.communities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT,
    cover_url TEXT,
    theme TEXT DEFAULT 'General',
    rules TEXT,
    privacy_policy TEXT,
    is_private BOOLEAN DEFAULT FALSE,
    creator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    members_count INTEGER DEFAULT 0,
    posts_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT community_name_length CHECK (char_length(name) >= 3 AND char_length(name) <= 50),
    CONSTRAINT community_slug_format CHECK (slug ~ '^[a-z0-9-]+$')
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_communities_slug ON public.communities(slug);
CREATE INDEX IF NOT EXISTS idx_communities_creator_id ON public.communities(creator_id);
CREATE INDEX IF NOT EXISTS idx_communities_created_at ON public.communities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_communities_members_count ON public.communities(members_count DESC);

-- =====================================================
-- COMMUNITY MEMBERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.community_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('member', 'moderator', 'admin')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate memberships
    UNIQUE(community_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_community_members_community_id ON public.community_members(community_id);
CREATE INDEX IF NOT EXISTS idx_community_members_user_id ON public.community_members(user_id);
CREATE INDEX IF NOT EXISTS idx_community_members_role ON public.community_members(role);

-- =====================================================
-- FOLLOWS TABLE (User following relationships)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT no_self_follow CHECK (follower_id != following_id),
    UNIQUE(follower_id, following_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON public.follows(following_id);

-- =====================================================
-- LIKES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate likes
    UNIQUE(user_id, post_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON public.likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_post_id ON public.likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON public.likes(created_at DESC);

-- =====================================================
-- BOOKMARKS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate bookmarks
    UNIQUE(user_id, post_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_bookmarks_user_id ON public.bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_post_id ON public.bookmarks(post_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_created_at ON public.bookmarks(created_at DESC);

-- =====================================================
-- COMMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    likes_count INTEGER DEFAULT 0,
    replies_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT comment_content_length CHECK (char_length(content) > 0 AND char_length(content) <= 1000)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON public.comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent_comment_id ON public.comments(parent_comment_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON public.comments(created_at DESC);

-- =====================================================
-- COMMENT LIKES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.comment_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    comment_id UUID NOT NULL REFERENCES public.comments(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint
    UNIQUE(user_id, comment_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_comment_likes_user_id ON public.comment_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_comment_likes_comment_id ON public.comment_likes(comment_id);

-- =====================================================
-- NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('like', 'comment', 'follow', 'mention', 'community_invite', 'postShare')),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE,
    content TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);

-- Add foreign key for posts community_id (after communities table is created)
ALTER TABLE public.posts 
ADD CONSTRAINT fk_posts_community_id 
FOREIGN KEY (community_id) 
REFERENCES public.communities(id) 
ON DELETE SET NULL;

-- =====================================================
-- 002_messaging_schema.sql
-- =====================================================
-- =====================================================
-- OASIS - MESSAGING SCHEMA
-- =====================================================
-- This migration creates the messaging and real-time chat structure

-- =====================================================
-- CONVERSATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type TEXT DEFAULT 'direct' CHECK (type IN ('direct', 'group')),
    name TEXT, -- For group chats
    image_url TEXT, -- For group chats
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    last_message_id UUID,
    last_message_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_conversations_type ON public.conversations(type);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at ON public.conversations(last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON public.conversations(created_at DESC);

-- =====================================================
-- CONVERSATION PARTICIPANTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.conversation_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('member', 'admin')),
    last_read_at TIMESTAMPTZ,
    unread_count INTEGER DEFAULT 0,
    is_muted BOOLEAN DEFAULT FALSE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint
    UNIQUE(conversation_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation_id ON public.conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user_id ON public.conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_unread_count ON public.conversation_participants(unread_count) WHERE unread_count > 0;

-- =====================================================
-- MESSAGES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT,
    image_url TEXT,
    video_url TEXT,
    file_url TEXT,
    file_name TEXT,
    file_size INTEGER,
    reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT message_has_content CHECK (
        content IS NOT NULL OR 
        image_url IS NOT NULL OR 
        video_url IS NOT NULL OR
        file_url IS NOT NULL
    )
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_reply_to_id ON public.messages(reply_to_id);

-- =====================================================
-- MESSAGE READ RECEIPTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.message_read_receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint
    UNIQUE(message_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_message_read_receipts_message_id ON public.message_read_receipts(message_id);
CREATE INDEX IF NOT EXISTS idx_message_read_receipts_user_id ON public.message_read_receipts(user_id);

-- =====================================================
-- MESSAGE REACTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.message_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    emoji TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint
    UNIQUE(message_id, user_id, emoji)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON public.message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_user_id ON public.message_reactions(user_id);

-- =====================================================
-- TYPING INDICATORS TABLE (for real-time typing status)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.typing_indicators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint
    UNIQUE(conversation_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_typing_indicators_conversation_id ON public.typing_indicators(conversation_id);
CREATE INDEX IF NOT EXISTS idx_typing_indicators_user_id ON public.typing_indicators(user_id);

-- Add foreign key for last_message_id in conversations table
ALTER TABLE public.conversations 
ADD CONSTRAINT fk_conversations_last_message_id 
FOREIGN KEY (last_message_id) 
REFERENCES public.messages(id) 
ON DELETE SET NULL;

-- =====================================================
-- FUNCTIONS FOR MESSAGING
-- =====================================================

-- Function to update conversation's last message
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversations
    SET 
        last_message_id = NEW.id,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update conversation when new message is sent
DROP TRIGGER IF EXISTS trigger_update_conversation_last_message ON public.messages;
CREATE TRIGGER trigger_update_conversation_last_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_last_message();

-- Function to increment unread count for participants
CREATE OR REPLACE FUNCTION increment_unread_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversation_participants
    SET unread_count = unread_count + 1
    WHERE conversation_id = NEW.conversation_id
    AND user_id != NEW.sender_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to increment unread count when new message is sent
DROP TRIGGER IF EXISTS trigger_increment_unread_count ON public.messages;
CREATE TRIGGER trigger_increment_unread_count
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION increment_unread_count();

-- Function to reset unread count when user reads messages
CREATE OR REPLACE FUNCTION reset_unread_count(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.conversation_participants
    SET 
        unread_count = 0,
        last_read_at = NOW()
    WHERE conversation_id = p_conversation_id
    AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get or create direct conversation between two users
CREATE OR REPLACE FUNCTION get_or_create_direct_conversation(
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    -- Try to find existing conversation
    SELECT c.id INTO v_conversation_id
    FROM public.conversations c
    INNER JOIN public.conversation_participants cp1 ON c.id = cp1.conversation_id
    INNER JOIN public.conversation_participants cp2 ON c.id = cp2.conversation_id
    WHERE c.type = 'direct'
    AND cp1.user_id = p_user1_id
    AND cp2.user_id = p_user2_id
    LIMIT 1;
    
    -- If not found, create new conversation
    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (type, created_by)
        VALUES ('direct', p_user1_id)
        RETURNING id INTO v_conversation_id;
        
        -- Add both participants
        INSERT INTO public.conversation_participants (conversation_id, user_id)
        VALUES 
            (v_conversation_id, p_user1_id),
            (v_conversation_id, p_user2_id);
    END IF;
    
    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 003_rls_policies.sql
-- =====================================================
-- =====================================================
-- OASIS - ROW LEVEL SECURITY POLICIES
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

-- =====================================================
-- 004_messaging_rls_policies.sql
-- =====================================================
-- =====================================================
-- OASIS - MESSAGING RLS POLICIES
-- =====================================================

-- =====================================================
-- CONVERSATIONS POLICIES
-- =====================================================

-- Users can view conversations they are part of
CREATE POLICY "Users can view their conversations"
ON public.conversations FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_participants
        WHERE conversation_id = conversations.id
        AND user_id = auth.uid()
    )
);

-- Users can create conversations
CREATE POLICY "Users can create conversations"
ON public.conversations FOR INSERT
WITH CHECK (auth.uid() = created_by);

-- Conversation creators and admins can update conversations
CREATE POLICY "Conversation admins can update conversations"
ON public.conversations FOR UPDATE
USING (
    auth.uid() = created_by OR
    EXISTS (
        SELECT 1 FROM public.conversation_participants
        WHERE conversation_id = conversations.id
        AND user_id = auth.uid()
        AND role = 'admin'
    )
);

-- Conversation creators can delete conversations
CREATE POLICY "Conversation creators can delete conversations"
ON public.conversations FOR DELETE
USING (auth.uid() = created_by);

-- =====================================================
-- CONVERSATION PARTICIPANTS POLICIES
-- =====================================================

-- Users can view participants in their conversations
CREATE POLICY "Users can view participants in their conversations"
ON public.conversation_participants FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
        AND cp.user_id = auth.uid()
    )
);

-- Conversation admins can add participants
CREATE POLICY "Conversation admins can add participants"
ON public.conversation_participants FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
        AND cp.user_id = auth.uid()
        AND cp.role = 'admin'
    ) OR
    -- Allow users to add themselves to direct conversations
    (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = conversation_participants.conversation_id
            AND c.type = 'direct'
        )
    )
);

-- Users can update their own participant settings
CREATE POLICY "Users can update their own participant settings"
ON public.conversation_participants FOR UPDATE
USING (auth.uid() = user_id);

-- Users can leave conversations or admins can remove participants
CREATE POLICY "Users can leave or admins can remove participants"
ON public.conversation_participants FOR DELETE
USING (
    auth.uid() = user_id OR
    EXISTS (
        SELECT 1 FROM public.conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
        AND cp.user_id = auth.uid()
        AND cp.role = 'admin'
    )
);

-- =====================================================
-- MESSAGES POLICIES
-- =====================================================

-- Users can view messages in their conversations
CREATE POLICY "Users can view messages in their conversations"
ON public.messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_participants
        WHERE conversation_id = messages.conversation_id
        AND user_id = auth.uid()
    )
);

-- Users can send messages to their conversations
CREATE POLICY "Users can send messages to their conversations"
ON public.messages FOR INSERT
WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
        SELECT 1 FROM public.conversation_participants
        WHERE conversation_id = messages.conversation_id
        AND user_id = auth.uid()
    )
);

-- Users can update their own messages
CREATE POLICY "Users can update their own messages"
ON public.messages FOR UPDATE
USING (auth.uid() = sender_id);

-- Users can delete their own messages
CREATE POLICY "Users can delete their own messages"
ON public.messages FOR DELETE
USING (auth.uid() = sender_id);

-- =====================================================
-- MESSAGE READ RECEIPTS POLICIES
-- =====================================================

-- Users can view read receipts in their conversations
CREATE POLICY "Users can view read receipts in their conversations"
ON public.message_read_receipts FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.messages m
        INNER JOIN public.conversation_participants cp ON m.conversation_id = cp.conversation_id
        WHERE m.id = message_read_receipts.message_id
        AND cp.user_id = auth.uid()
    )
);

-- Users can create their own read receipts
CREATE POLICY "Users can create their own read receipts"
ON public.message_read_receipts FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own read receipts
CREATE POLICY "Users can update their own read receipts"
ON public.message_read_receipts FOR UPDATE
USING (auth.uid() = user_id);

-- =====================================================
-- MESSAGE REACTIONS POLICIES
-- =====================================================

-- Users can view reactions in their conversations
CREATE POLICY "Users can view reactions in their conversations"
ON public.message_reactions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.messages m
        INNER JOIN public.conversation_participants cp ON m.conversation_id = cp.conversation_id
        WHERE m.id = message_reactions.message_id
        AND cp.user_id = auth.uid()
    )
);

-- Users can add reactions
CREATE POLICY "Users can add reactions"
ON public.message_reactions FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can remove their own reactions
CREATE POLICY "Users can remove their own reactions"
ON public.message_reactions FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- TYPING INDICATORS POLICIES
-- =====================================================

-- Users can view typing indicators in their conversations
CREATE POLICY "Users can view typing indicators in their conversations"
ON public.typing_indicators FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_participants
        WHERE conversation_id = typing_indicators.conversation_id
        AND user_id = auth.uid()
    )
);

-- Users can create their own typing indicators
CREATE POLICY "Users can create their own typing indicators"
ON public.typing_indicators FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own typing indicators
CREATE POLICY "Users can update their own typing indicators"
ON public.typing_indicators FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own typing indicators
CREATE POLICY "Users can delete their own typing indicators"
ON public.typing_indicators FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- 005_triggers_and_functions.sql
-- =====================================================
-- =====================================================
-- OASIS - TRIGGERS AND FUNCTIONS
-- =====================================================
-- This migration creates triggers and functions for automatic updates

-- =====================================================
-- UPDATED_AT TRIGGER FUNCTION
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_posts_updated_at ON public.posts;
CREATE TRIGGER update_posts_updated_at
    BEFORE UPDATE ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_communities_updated_at ON public.communities;
CREATE TRIGGER update_communities_updated_at
    BEFORE UPDATE ON public.communities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_comments_updated_at ON public.comments;
CREATE TRIGGER update_comments_updated_at
    BEFORE UPDATE ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_conversations_updated_at ON public.conversations;
CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON public.conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_messages_updated_at ON public.messages;
CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- PROFILE CREATION TRIGGER
-- =====================================================
-- Automatically create profile when user signs up
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- LIKE COUNT TRIGGERS
-- =====================================================
-- Increment likes count when a like is added
CREATE OR REPLACE FUNCTION increment_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.posts
    SET likes_count = likes_count + 1
    WHERE id = NEW.post_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_post_likes_count ON public.likes;
CREATE TRIGGER trigger_increment_post_likes_count
    AFTER INSERT ON public.likes
    FOR EACH ROW
    EXECUTE FUNCTION increment_post_likes_count();

-- Decrement likes count when a like is removed
CREATE OR REPLACE FUNCTION decrement_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.posts
    SET likes_count = GREATEST(0, likes_count - 1)
    WHERE id = OLD.post_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_post_likes_count ON public.likes;
CREATE TRIGGER trigger_decrement_post_likes_count
    AFTER DELETE ON public.likes
    FOR EACH ROW
    EXECUTE FUNCTION decrement_post_likes_count();

-- =====================================================
-- COMMENT COUNT TRIGGERS
-- =====================================================
-- Increment comments count when a comment is added
CREATE OR REPLACE FUNCTION increment_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.posts
    SET comments_count = comments_count + 1
    WHERE id = NEW.post_id;
    
    -- If it's a reply, increment the parent comment's replies count
    IF NEW.parent_comment_id IS NOT NULL THEN
        UPDATE public.comments
        SET replies_count = replies_count + 1
        WHERE id = NEW.parent_comment_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_post_comments_count ON public.comments;
CREATE TRIGGER trigger_increment_post_comments_count
    AFTER INSERT ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION increment_post_comments_count();

-- Decrement comments count when a comment is deleted
CREATE OR REPLACE FUNCTION decrement_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.posts
    SET comments_count = GREATEST(0, comments_count - 1)
    WHERE id = OLD.post_id;
    
    -- If it's a reply, decrement the parent comment's replies count
    IF OLD.parent_comment_id IS NOT NULL THEN
        UPDATE public.comments
        SET replies_count = GREATEST(0, replies_count - 1)
        WHERE id = OLD.parent_comment_id;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_post_comments_count ON public.comments;
CREATE TRIGGER trigger_decrement_post_comments_count
    AFTER DELETE ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION decrement_post_comments_count();

-- =====================================================
-- COMMENT LIKES COUNT TRIGGERS
-- =====================================================
-- Increment comment likes count
CREATE OR REPLACE FUNCTION increment_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.comments
    SET likes_count = likes_count + 1
    WHERE id = NEW.comment_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_comment_likes_count ON public.comment_likes;
CREATE TRIGGER trigger_increment_comment_likes_count
    AFTER INSERT ON public.comment_likes
    FOR EACH ROW
    EXECUTE FUNCTION increment_comment_likes_count();

-- Decrement comment likes count
CREATE OR REPLACE FUNCTION decrement_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.comments
    SET likes_count = GREATEST(0, likes_count - 1)
    WHERE id = OLD.comment_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_comment_likes_count ON public.comment_likes;
CREATE TRIGGER trigger_decrement_comment_likes_count
    AFTER DELETE ON public.comment_likes
    FOR EACH ROW
    EXECUTE FUNCTION decrement_comment_likes_count();

-- =====================================================
-- FOLLOWER COUNT TRIGGERS
-- =====================================================
-- Increment follower/following counts
CREATE OR REPLACE FUNCTION increment_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
    -- Increment follower count for the user being followed
    UPDATE public.profiles
    SET followers_count = followers_count + 1
    WHERE id = NEW.following_id;
    
    -- Increment following count for the follower
    UPDATE public.profiles
    SET following_count = following_count + 1
    WHERE id = NEW.follower_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_follow_counts ON public.follows;
CREATE TRIGGER trigger_increment_follow_counts
    AFTER INSERT ON public.follows
    FOR EACH ROW
    EXECUTE FUNCTION increment_follow_counts();

-- Decrement follower/following counts
CREATE OR REPLACE FUNCTION decrement_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
    -- Decrement follower count for the user being unfollowed
    UPDATE public.profiles
    SET followers_count = GREATEST(0, followers_count - 1)
    WHERE id = OLD.following_id;
    
    -- Decrement following count for the unfollower
    UPDATE public.profiles
    SET following_count = GREATEST(0, following_count - 1)
    WHERE id = OLD.follower_id;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_follow_counts ON public.follows;
CREATE TRIGGER trigger_decrement_follow_counts
    AFTER DELETE ON public.follows
    FOR EACH ROW
    EXECUTE FUNCTION decrement_follow_counts();

-- =====================================================
-- POST COUNT TRIGGERS
-- =====================================================
-- Increment post count when a post is created
CREATE OR REPLACE FUNCTION increment_user_posts_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.profiles
    SET posts_count = posts_count + 1
    WHERE id = NEW.user_id;
    
    -- If post is in a community, increment community posts count
    IF NEW.community_id IS NOT NULL THEN
        UPDATE public.communities
        SET posts_count = posts_count + 1
        WHERE id = NEW.community_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_user_posts_count ON public.posts;
CREATE TRIGGER trigger_increment_user_posts_count
    AFTER INSERT ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION increment_user_posts_count();

-- Decrement post count when a post is deleted
CREATE OR REPLACE FUNCTION decrement_user_posts_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.profiles
    SET posts_count = GREATEST(0, posts_count - 1)
    WHERE id = OLD.user_id;
    
    -- If post was in a community, decrement community posts count
    IF OLD.community_id IS NOT NULL THEN
        UPDATE public.communities
        SET posts_count = GREATEST(0, posts_count - 1)
        WHERE id = OLD.community_id;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_user_posts_count ON public.posts;
CREATE TRIGGER trigger_decrement_user_posts_count
    AFTER DELETE ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION decrement_user_posts_count();

-- =====================================================
-- 006_notification_triggers.sql
-- =====================================================
-- =====================================================
-- OASIS - NOTIFICATION TRIGGERS
-- =====================================================
-- This migration creates triggers for automatic notification creation

-- =====================================================
-- NOTIFICATION CREATION FUNCTIONS
-- =====================================================

-- Create notification for new like
CREATE OR REPLACE FUNCTION create_like_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_post_user_id UUID;
BEGIN
    -- Get the post owner's user_id
    SELECT user_id INTO v_post_user_id
    FROM public.posts
    WHERE id = NEW.post_id;
    
    -- Don't create notification if user likes their own post
    IF v_post_user_id != NEW.user_id THEN
        INSERT INTO public.notifications (user_id, actor_id, type, post_id)
        VALUES (v_post_user_id, NEW.user_id, 'like', NEW.post_id)
        ON CONFLICT DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_create_like_notification ON public.likes;
CREATE TRIGGER trigger_create_like_notification
    AFTER INSERT ON public.likes
    FOR EACH ROW
    EXECUTE FUNCTION create_like_notification();

-- Create notification for new comment
CREATE OR REPLACE FUNCTION create_comment_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_post_user_id UUID;
    v_parent_comment_user_id UUID;
BEGIN
    -- Get the post owner's user_id
    SELECT user_id INTO v_post_user_id
    FROM public.posts
    WHERE id = NEW.post_id;
    
    -- Create notification for post owner
    IF v_post_user_id != NEW.user_id THEN
        INSERT INTO public.notifications (user_id, actor_id, type, post_id, comment_id, content)
        VALUES (v_post_user_id, NEW.user_id, 'comment', NEW.post_id, NEW.id, NEW.content)
        ON CONFLICT DO NOTHING;
    END IF;
    
    -- If it's a reply to another comment, notify the parent comment author
    IF NEW.parent_comment_id IS NOT NULL THEN
        SELECT user_id INTO v_parent_comment_user_id
        FROM public.comments
        WHERE id = NEW.parent_comment_id;
        
        IF v_parent_comment_user_id != NEW.user_id AND v_parent_comment_user_id != v_post_user_id THEN
            INSERT INTO public.notifications (user_id, actor_id, type, post_id, comment_id, content)
            VALUES (v_parent_comment_user_id, NEW.user_id, 'comment', NEW.post_id, NEW.id, NEW.content)
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_create_comment_notification ON public.comments;
CREATE TRIGGER trigger_create_comment_notification
    AFTER INSERT ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION create_comment_notification();

-- Create notification for new follower
CREATE OR REPLACE FUNCTION create_follow_notification()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (user_id, actor_id, type)
    VALUES (NEW.following_id, NEW.follower_id, 'follow')
    ON CONFLICT DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_create_follow_notification ON public.follows;
CREATE TRIGGER trigger_create_follow_notification
    AFTER INSERT ON public.follows
    FOR EACH ROW
    EXECUTE FUNCTION create_follow_notification();

-- =====================================================
-- COMMUNITY MEMBER COUNT TRIGGERS
-- =====================================================

-- Increment community members count
CREATE OR REPLACE FUNCTION increment_community_members_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.communities
    SET members_count = members_count + 1
    WHERE id = NEW.community_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_community_members_count ON public.community_members;
CREATE TRIGGER trigger_increment_community_members_count
    AFTER INSERT ON public.community_members
    FOR EACH ROW
    EXECUTE FUNCTION increment_community_members_count();

-- Decrement community members count
CREATE OR REPLACE FUNCTION decrement_community_members_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.communities
    SET members_count = GREATEST(0, members_count - 1)
    WHERE id = OLD.community_id;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_community_members_count ON public.community_members;
CREATE TRIGGER trigger_decrement_community_members_count
    AFTER DELETE ON public.community_members
    FOR EACH ROW
    EXECUTE FUNCTION decrement_community_members_count();

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Function to delete user account and all related data
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS VOID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Delete all user data (cascading deletes will handle related records)
    DELETE FROM public.profiles WHERE id = v_user_id;
    
    -- Delete auth user
    DELETE FROM auth.users WHERE id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get feed posts (for you)
CREATE OR REPLACE FUNCTION get_feed_posts(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    username TEXT,
    full_name TEXT,
    avatar_url TEXT,
    content TEXT,
    image_url TEXT,
    video_url TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    shares_count INTEGER,
    created_at TIMESTAMPTZ,
    is_liked BOOLEAN,
    is_bookmarked BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        pr.username,
        pr.full_name,
        pr.avatar_url,
        p.content,
        p.image_url,
        p.video_url,
        p.likes_count,
        p.comments_count,
        p.shares_count,
        p.created_at,
        EXISTS(SELECT 1 FROM public.likes l WHERE l.post_id = p.id AND l.user_id = p_user_id) as is_liked,
        EXISTS(SELECT 1 FROM public.bookmarks b WHERE b.post_id = p.id AND b.user_id = p_user_id) as is_bookmarked
    FROM public.posts p
    INNER JOIN public.profiles pr ON p.user_id = pr.id
    WHERE 
        -- Show posts from public profiles or followed users
        (pr.is_private = FALSE OR pr.id = p_user_id OR EXISTS (
            SELECT 1 FROM public.follows f 
            WHERE f.follower_id = p_user_id AND f.following_id = pr.id
        ))
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Function to get following feed posts
CREATE OR REPLACE FUNCTION get_following_feed_posts(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    username TEXT,
    full_name TEXT,
    avatar_url TEXT,
    content TEXT,
    image_url TEXT,
    video_url TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    shares_count INTEGER,
    created_at TIMESTAMPTZ,
    is_liked BOOLEAN,
    is_bookmarked BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        pr.username,
        pr.full_name,
        pr.avatar_url,
        p.content,
        p.image_url,
        p.video_url,
        p.likes_count,
        p.comments_count,
        p.shares_count,
        p.created_at,
        EXISTS(SELECT 1 FROM public.likes l WHERE l.post_id = p.id AND l.user_id = p_user_id) as is_liked,
        EXISTS(SELECT 1 FROM public.bookmarks b WHERE b.post_id = p.id AND b.user_id = p_user_id) as is_bookmarked
    FROM public.posts p
    INNER JOIN public.profiles pr ON p.user_id = pr.id
    WHERE EXISTS (
        SELECT 1 FROM public.follows f 
        WHERE f.follower_id = p_user_id AND f.following_id = p.user_id
    )
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Function to get user's conversations with last message
CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id UUID)
RETURNS TABLE (
    conversation_id UUID,
    conversation_type TEXT,
    conversation_name TEXT,
    conversation_image_url TEXT,
    other_user_id UUID,
    other_user_username TEXT,
    other_user_full_name TEXT,
    other_user_avatar_url TEXT,
    last_message_content TEXT,
    last_message_at TIMESTAMPTZ,
    unread_count INTEGER,
    is_muted BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as conversation_id,
        c.type as conversation_type,
        c.name as conversation_name,
        c.image_url as conversation_image_url,
        CASE 
            WHEN c.type = 'direct' THEN (
                SELECT cp2.user_id 
                FROM public.conversation_participants cp2 
                WHERE cp2.conversation_id = c.id AND cp2.user_id != p_user_id 
                LIMIT 1
            )
            ELSE NULL
        END as other_user_id,
        CASE 
            WHEN c.type = 'direct' THEN (
                SELECT pr.username 
                FROM public.conversation_participants cp2 
                INNER JOIN public.profiles pr ON cp2.user_id = pr.id
                WHERE cp2.conversation_id = c.id AND cp2.user_id != p_user_id 
                LIMIT 1
            )
            ELSE NULL
        END as other_user_username,
        CASE 
            WHEN c.type = 'direct' THEN (
                SELECT pr.full_name 
                FROM public.conversation_participants cp2 
                INNER JOIN public.profiles pr ON cp2.user_id = pr.id
                WHERE cp2.conversation_id = c.id AND cp2.user_id != p_user_id 
                LIMIT 1
            )
            ELSE NULL
        END as other_user_full_name,
        CASE 
            WHEN c.type = 'direct' THEN (
                SELECT pr.avatar_url 
                FROM public.conversation_participants cp2 
                INNER JOIN public.profiles pr ON cp2.user_id = pr.id
                WHERE cp2.conversation_id = c.id AND cp2.user_id != p_user_id 
                LIMIT 1
            )
            ELSE NULL
        END as other_user_avatar_url,
        m.content as last_message_content,
        c.last_message_at,
        cp.unread_count,
        cp.is_muted
    FROM public.conversations c
    INNER JOIN public.conversation_participants cp ON c.id = cp.conversation_id
    LEFT JOIN public.messages m ON c.last_message_id = m.id
    WHERE cp.user_id = p_user_id
    ORDER BY c.last_message_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 007_storage_setup.sql
-- =====================================================
-- =====================================================
-- OASIS - STORAGE BUCKETS SETUP
-- =====================================================
-- This migration creates storage buckets and policies for file uploads

-- =====================================================
-- CREATE STORAGE BUCKETS
-- =====================================================

-- Profile pictures bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-pictures', 'profile-pictures', true)
ON CONFLICT (id) DO NOTHING;

-- Post images bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('post-images', 'post-images', true)
ON CONFLICT (id) DO NOTHING;

-- Post videos bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('post-videos', 'post-videos', true)
ON CONFLICT (id) DO NOTHING;

-- Community images bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('community-images', 'community-images', true)
ON CONFLICT (id) DO NOTHING;

-- Message attachments bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('message-attachments', 'message-attachments', false)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STORAGE POLICIES - PROFILE PICTURES
-- =====================================================

-- Anyone can view profile pictures
CREATE POLICY "Profile pictures are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-pictures');

-- Users can upload their own profile pictures
CREATE POLICY "Users can upload their own profile pictures"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'profile-pictures' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can update their own profile pictures
CREATE POLICY "Users can update their own profile pictures"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'profile-pictures' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own profile pictures
CREATE POLICY "Users can delete their own profile pictures"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'profile-pictures' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- STORAGE POLICIES - POST IMAGES
-- =====================================================

-- Anyone can view post images
CREATE POLICY "Post images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'post-images');

-- Authenticated users can upload post images
CREATE POLICY "Authenticated users can upload post images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'post-images' AND
    auth.role() = 'authenticated'
);

-- Users can update their own post images
CREATE POLICY "Users can update their own post images"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'post-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own post images
CREATE POLICY "Users can delete their own post images"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'post-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- STORAGE POLICIES - POST VIDEOS
-- =====================================================

-- Anyone can view post videos
CREATE POLICY "Post videos are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'post-videos');

-- Authenticated users can upload post videos
CREATE POLICY "Authenticated users can upload post videos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'post-videos' AND
    auth.role() = 'authenticated'
);

-- Users can update their own post videos
CREATE POLICY "Users can update their own post videos"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'post-videos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own post videos
CREATE POLICY "Users can delete their own post videos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'post-videos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- STORAGE POLICIES - COMMUNITY IMAGES
-- =====================================================

-- Anyone can view community images
CREATE POLICY "Community images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'community-images');

-- Authenticated users can upload community images
CREATE POLICY "Authenticated users can upload community images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'community-images' AND
    auth.role() = 'authenticated'
);

-- Community admins can update community images
CREATE POLICY "Community admins can update community images"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'community-images' AND
    auth.role() = 'authenticated'
);

-- Community admins can delete community images
CREATE POLICY "Community admins can delete community images"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'community-images' AND
    auth.role() = 'authenticated'
);

-- =====================================================
-- STORAGE POLICIES - MESSAGE ATTACHMENTS
-- =====================================================

-- Only conversation participants can view message attachments
CREATE POLICY "Conversation participants can view message attachments"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'message-attachments' AND
    auth.role() = 'authenticated'
);

-- Authenticated users can upload message attachments
CREATE POLICY "Authenticated users can upload message attachments"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'message-attachments' AND
    auth.role() = 'authenticated'
);

-- Users can delete their own message attachments
CREATE POLICY "Users can delete their own message attachments"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'message-attachments' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- 008_fix_community_members_rls.sql
-- =====================================================
-- Fix infinite recursion in community_members RLS policy
-- The SELECT policy was querying community_members itself, causing infinite recursion

-- Drop the problematic policy
DROP POLICY IF EXISTS "Community members are viewable by community members" ON public.community_members;

-- Create a simpler policy that doesn't cause recursion
-- Allow viewing community members if:
-- 1. The community is public, OR
-- 2. The user is authenticated (they can see members of communities they're in via app logic)
CREATE POLICY "Community members are viewable"
ON public.community_members FOR SELECT
USING (
    -- Allow if community is public
    EXISTS (
        SELECT 1 FROM public.communities c
        WHERE c.id = community_members.community_id
        AND c.is_private = FALSE
    ) OR
    -- Allow if user is viewing their own membership
    auth.uid() = user_id OR
    -- Allow if user is authenticated (app will filter appropriately)
    auth.uid() IS NOT NULL
);

-- =====================================================
-- 009_fix_conversation_participants_rls.sql
-- =====================================================
-- Fix infinite recursion in conversation_participants RLS policy
-- The SELECT policy was querying conversation_participants itself, causing infinite recursion

-- Drop the problematic policy
DROP POLICY IF EXISTS "Users can view participants in their conversations" ON public.conversation_participants;

-- Create a simpler policy that doesn't cause recursion
-- Allow viewing conversation participants if:
-- 1. The user is viewing their own participation record, OR
-- 2. The user is authenticated (app will filter appropriately)
CREATE POLICY "Users can view conversation participants"
ON public.conversation_participants FOR SELECT
USING (
    -- Allow if user is viewing their own participation
    auth.uid() = user_id OR
    -- Allow if user is authenticated (app logic will filter to their conversations)
    auth.uid() IS NOT NULL
);

-- Also fix the INSERT policy to avoid similar recursion
DROP POLICY IF EXISTS "Conversation admins can add participants" ON public.conversation_participants;

CREATE POLICY "Conversation admins can add participants"
ON public.conversation_participants FOR INSERT
WITH CHECK (
    -- Allow users to add themselves
    auth.uid() = user_id OR
    -- Allow conversation creators to add participants
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_participants.conversation_id
        AND c.created_by = auth.uid()
    )
);

-- Fix DELETE policy to avoid recursion
DROP POLICY IF EXISTS "Users can leave or admins can remove participants" ON public.conversation_participants;

CREATE POLICY "Users can leave or admins can remove participants"
ON public.conversation_participants FOR DELETE
USING (
    -- Allow users to remove themselves
    auth.uid() = user_id OR
    -- Allow conversation creators to remove participants
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_participants.conversation_id
        AND c.created_by = auth.uid()
    )
);

-- =====================================================
-- 010_stories_schema.sql
-- =====================================================
-- =====================================================
-- OASIS - STORIES FEATURE - DATABASE SCHEMA
-- =====================================================
-- This migration creates tables for Instagram-style stories feature
-- Stories expire after 24 hours

-- =====================================================
-- STORIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
    thumbnail_url TEXT,
    caption TEXT,
    duration INTEGER DEFAULT 5, -- seconds to display (for images)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours',
    view_count INTEGER DEFAULT 0,
    
    -- Constraints
    CONSTRAINT caption_length CHECK (caption IS NULL OR char_length(caption) <= 200)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_stories_user_id ON public.stories(user_id);
CREATE INDEX IF NOT EXISTS idx_stories_created_at ON public.stories(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stories_expires_at ON public.stories(expires_at);

-- =====================================================
-- STORY VIEWS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.story_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
    viewer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    viewed_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint to track unique views
    UNIQUE(story_id, viewer_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_story_views_story_id ON public.story_views(story_id);
CREATE INDEX IF NOT EXISTS idx_story_views_viewer_id ON public.story_views(viewer_id);
CREATE INDEX IF NOT EXISTS idx_story_views_viewed_at ON public.story_views(viewed_at DESC);

-- =====================================================
-- STORY REACTIONS TABLE (optional - for future)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.story_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    emoji TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint
    UNIQUE(story_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_story_reactions_story_id ON public.story_reactions(story_id);
CREATE INDEX IF NOT EXISTS idx_story_reactions_user_id ON public.story_reactions(user_id);

-- =====================================================
-- FUNCTION: Auto-delete expired stories
-- =====================================================
CREATE OR REPLACE FUNCTION delete_expired_stories()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.stories
    WHERE expires_at < NOW();
END;
$$;

-- =====================================================
-- FUNCTION: Increment story view count
-- =====================================================
CREATE OR REPLACE FUNCTION increment_story_view_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.stories
    SET view_count = view_count + 1
    WHERE id = NEW.story_id;
    
    RETURN NEW;
END;
$$;

-- Create trigger for view count
DROP TRIGGER IF EXISTS trigger_increment_story_view_count ON public.story_views;
CREATE TRIGGER trigger_increment_story_view_count
    AFTER INSERT ON public.story_views
    FOR EACH ROW
    EXECUTE FUNCTION increment_story_view_count();

-- =====================================================
-- FUNCTION: Get active stories for a user
-- =====================================================
DROP FUNCTION IF EXISTS get_active_stories(uuid);
CREATE OR REPLACE FUNCTION get_active_stories(target_user_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    media_url TEXT,
    media_type TEXT,
    thumbnail_url TEXT,
    caption TEXT,
    duration INTEGER,
    created_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    view_count INTEGER,
    has_viewed BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.user_id,
        s.media_url,
        s.media_type,
        s.thumbnail_url,
        s.caption,
        s.duration,
        s.created_at,
        s.expires_at,
        s.view_count,
        EXISTS(
            SELECT 1 FROM public.story_views sv
            WHERE sv.story_id = s.id AND sv.viewer_id = auth.uid()
        ) as has_viewed
    FROM public.stories s
    WHERE s.user_id = target_user_id
    AND s.expires_at > NOW()
    ORDER BY s.created_at ASC;
END;
$$;

-- =====================================================
-- FUNCTION: Get stories from following users
-- =====================================================
DROP FUNCTION IF EXISTS get_following_stories(uuid);
CREATE OR REPLACE FUNCTION get_following_stories(requesting_user_id UUID)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    story_count BIGINT,
    has_unviewed BOOLEAN,
    latest_story_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as user_id,
        p.username,
        p.avatar_url,
        COUNT(s.id) as story_count,
        BOOL_OR(NOT EXISTS(
            SELECT 1 FROM public.story_views sv
            WHERE sv.story_id = s.id AND sv.viewer_id = requesting_user_id
        )) as has_unviewed,
        MAX(s.created_at) as latest_story_at
    FROM public.profiles p
    INNER JOIN public.follows f ON f.following_id = p.id
    INNER JOIN public.stories s ON s.user_id = p.id
    WHERE f.follower_id = requesting_user_id
    AND s.expires_at > NOW()
    GROUP BY p.id, p.username, p.avatar_url
    ORDER BY has_unviewed DESC, latest_story_at DESC;
END;
$$;

-- =====================================================
-- PART 2: ADVANCED FEATURES (011-020)
-- =====================================================

-- =====================================================
-- 011_mentions_hashtags_schema.sql
-- =====================================================
-- =====================================================
-- MENTIONS & HASHTAGS FEATURE - DATABASE SCHEMA
-- =====================================================
-- This migration creates tables for user mentions and hashtags

-- =====================================================
-- HASHTAGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.hashtags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tag TEXT UNIQUE NOT NULL,
    normalized_tag TEXT UNIQUE NOT NULL, -- lowercase version for matching
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT tag_format CHECK (tag ~ '^[a-zA-Z0-9_]+$'),
    CONSTRAINT tag_length CHECK (char_length(tag) >= 2 AND char_length(tag) <= 50)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_hashtags_tag ON public.hashtags(tag);
CREATE INDEX IF NOT EXISTS idx_hashtags_normalized_tag ON public.hashtags(normalized_tag);
CREATE INDEX IF NOT EXISTS idx_hashtags_usage_count ON public.hashtags(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_hashtags_last_used_at ON public.hashtags(last_used_at DESC);

-- =====================================================
-- POST HASHTAGS TABLE (junction table)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.post_hashtags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    hashtag_id UUID NOT NULL REFERENCES public.hashtags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint
    UNIQUE(post_id, hashtag_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_post_hashtags_post_id ON public.post_hashtags(post_id);
CREATE INDEX IF NOT EXISTS idx_post_hashtags_hashtag_id ON public.post_hashtags(hashtag_id);

-- =====================================================
-- MENTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.mentions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    mentioned_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    mentioned_by_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure mention is in either post or comment
    CONSTRAINT mention_source CHECK (
        (post_id IS NOT NULL AND comment_id IS NULL) OR
        (post_id IS NULL AND comment_id IS NOT NULL)
    )
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_mentions_post_id ON public.mentions(post_id);
CREATE INDEX IF NOT EXISTS idx_mentions_comment_id ON public.mentions(comment_id);
CREATE INDEX IF NOT EXISTS idx_mentions_mentioned_user_id ON public.mentions(mentioned_user_id);
CREATE INDEX IF NOT EXISTS idx_mentions_mentioned_by_user_id ON public.mentions(mentioned_by_user_id);

-- =====================================================
-- FUNCTION: Extract and save hashtags from post
-- =====================================================
CREATE OR REPLACE FUNCTION extract_hashtags_from_post()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    hashtag_text TEXT;
    hashtag_record RECORD;
    hashtag_matches TEXT[];
BEGIN
    -- Extract hashtags from content (matches #word)
    IF NEW.content IS NOT NULL THEN
        hashtag_matches := regexp_matches(NEW.content, '#([a-zA-Z0-9_]+)', 'g');
        
        -- Process each hashtag
        FOREACH hashtag_text IN ARRAY hashtag_matches
        LOOP
            -- Insert or update hashtag
            INSERT INTO public.hashtags (tag, normalized_tag, usage_count, last_used_at)
            VALUES (hashtag_text, LOWER(hashtag_text), 1, NOW())
            ON CONFLICT (normalized_tag) 
            DO UPDATE SET 
                usage_count = public.hashtags.usage_count + 1,
                last_used_at = NOW()
            RETURNING * INTO hashtag_record;
            
            -- Link hashtag to post
            INSERT INTO public.post_hashtags (post_id, hashtag_id)
            VALUES (NEW.id, hashtag_record.id)
            ON CONFLICT (post_id, hashtag_id) DO NOTHING;
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for hashtag extraction
DROP TRIGGER IF EXISTS trigger_extract_hashtags_from_post ON public.posts;
CREATE TRIGGER trigger_extract_hashtags_from_post
    AFTER INSERT OR UPDATE OF content ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION extract_hashtags_from_post();

-- =====================================================
-- FUNCTION: Extract and save mentions from post
-- =====================================================
CREATE OR REPLACE FUNCTION extract_mentions_from_post()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    mention_username TEXT;
    mentioned_user_record RECORD;
    mention_matches TEXT[];
BEGIN
    -- Extract mentions from content (matches @username)
    IF NEW.content IS NOT NULL THEN
        mention_matches := regexp_matches(NEW.content, '@([a-z0-9_]+)', 'g');
        
        -- Process each mention
        FOREACH mention_username IN ARRAY mention_matches
        LOOP
            -- Find the mentioned user
            SELECT * INTO mentioned_user_record
            FROM public.profiles
            WHERE username = mention_username;
            
            -- If user exists, create mention
            IF FOUND THEN
                INSERT INTO public.mentions (
                    post_id, 
                    mentioned_user_id, 
                    mentioned_by_user_id
                )
                VALUES (
                    NEW.id, 
                    mentioned_user_record.id, 
                    NEW.user_id
                )
                ON CONFLICT DO NOTHING;
                
                -- Create notification for mentioned user
                INSERT INTO public.notifications (
                    user_id,
                    actor_id,
                    type,
                    post_id,
                    content
                )
                VALUES (
                    mentioned_user_record.id,
                    NEW.user_id,
                    'mention',
                    NEW.id,
                    'mentioned you in a post'
                );
            END IF;
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for mention extraction
DROP TRIGGER IF EXISTS trigger_extract_mentions_from_post ON public.posts;
CREATE TRIGGER trigger_extract_mentions_from_post
    AFTER INSERT OR UPDATE OF content ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION extract_mentions_from_post();

-- =====================================================
-- FUNCTION: Extract mentions from comments
-- =====================================================
CREATE OR REPLACE FUNCTION extract_mentions_from_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    mention_username TEXT;
    mentioned_user_record RECORD;
    mention_matches TEXT[];
BEGIN
    -- Extract mentions from content (matches @username)
    IF NEW.content IS NOT NULL THEN
        mention_matches := regexp_matches(NEW.content, '@([a-z0-9_]+)', 'g');
        
        -- Process each mention
        FOREACH mention_username IN ARRAY mention_matches
        LOOP
            -- Find the mentioned user
            SELECT * INTO mentioned_user_record
            FROM public.profiles
            WHERE username = mention_username;
            
            -- If user exists, create mention
            IF FOUND THEN
                INSERT INTO public.mentions (
                    comment_id, 
                    mentioned_user_id, 
                    mentioned_by_user_id
                )
                VALUES (
                    NEW.id, 
                    mentioned_user_record.id, 
                    NEW.user_id
                )
                ON CONFLICT DO NOTHING;
                
                -- Create notification for mentioned user
                INSERT INTO public.notifications (
                    user_id,
                    actor_id,
                    type,
                    comment_id,
                    content
                )
                VALUES (
                    mentioned_user_record.id,
                    NEW.user_id,
                    'mention',
                    NEW.id,
                    'mentioned you in a comment'
                );
            END IF;
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for comment mentions
DROP TRIGGER IF EXISTS trigger_extract_mentions_from_comment ON public.comments;
CREATE TRIGGER trigger_extract_mentions_from_comment
    AFTER INSERT OR UPDATE OF content ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION extract_mentions_from_comment();

-- =====================================================
-- FUNCTION: Get trending hashtags
-- =====================================================
CREATE OR REPLACE FUNCTION get_trending_hashtags(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    tag TEXT,
    usage_count INTEGER,
    recent_usage_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.id,
        h.tag,
        h.usage_count,
        COUNT(ph.id) as recent_usage_count
    FROM public.hashtags h
    LEFT JOIN public.post_hashtags ph ON ph.hashtag_id = h.id
    LEFT JOIN public.posts p ON p.id = ph.post_id
    WHERE p.created_at > NOW() - INTERVAL '7 days' OR p.created_at IS NULL
    GROUP BY h.id, h.tag, h.usage_count
    ORDER BY recent_usage_count DESC, h.usage_count DESC
    LIMIT limit_count;
END;
$$;

-- =====================================================
-- FUNCTION: Search hashtags
-- =====================================================
CREATE OR REPLACE FUNCTION search_hashtags(search_query TEXT, limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    tag TEXT,
    usage_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.id,
        h.tag,
        h.usage_count
    FROM public.hashtags h
    WHERE h.normalized_tag LIKE LOWER(search_query) || '%'
    ORDER BY h.usage_count DESC
    LIMIT limit_count;
END;
$$;

-- =====================================================
-- 012_collections_schema.sql
-- =====================================================
-- =====================================================
-- SAVED COLLECTIONS FEATURE - DATABASE SCHEMA
-- =====================================================
-- This migration creates tables for organizing bookmarked posts into collections

-- =====================================================
-- COLLECTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    is_private BOOLEAN DEFAULT TRUE,
    items_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT collection_name_length CHECK (char_length(name) >= 1 AND char_length(name) <= 50),
    CONSTRAINT collection_description_length CHECK (description IS NULL OR char_length(description) <= 200)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_collections_user_id ON public.collections(user_id);
CREATE INDEX IF NOT EXISTS idx_collections_created_at ON public.collections(created_at DESC);

-- =====================================================
-- COLLECTION ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.collection_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    collection_id UUID NOT NULL REFERENCES public.collections(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate items
    UNIQUE(collection_id, post_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_collection_items_collection_id ON public.collection_items(collection_id);
CREATE INDEX IF NOT EXISTS idx_collection_items_post_id ON public.collection_items(post_id);
CREATE INDEX IF NOT EXISTS idx_collection_items_added_at ON public.collection_items(added_at DESC);

-- =====================================================
-- FUNCTION: Update collection items count
-- =====================================================
CREATE OR REPLACE FUNCTION update_collection_items_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.collections
        SET items_count = items_count + 1,
            updated_at = NOW()
        WHERE id = NEW.collection_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.collections
        SET items_count = items_count - 1,
            updated_at = NOW()
        WHERE id = OLD.collection_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

-- Create trigger for items count
DROP TRIGGER IF EXISTS trigger_update_collection_items_count ON public.collection_items;
CREATE TRIGGER trigger_update_collection_items_count
    AFTER INSERT OR DELETE ON public.collection_items
    FOR EACH ROW
    EXECUTE FUNCTION update_collection_items_count();

-- =====================================================
-- FUNCTION: Get user collections with preview
-- =====================================================
CREATE OR REPLACE FUNCTION get_user_collections(target_user_id UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    is_private BOOLEAN,
    items_count INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    preview_images TEXT[]
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.description,
        c.is_private,
        c.items_count,
        c.created_at,
        c.updated_at,
        ARRAY(
            SELECT p.image_url
            FROM public.collection_items ci
            INNER JOIN public.posts p ON p.id = ci.post_id
            WHERE ci.collection_id = c.id
            AND p.image_url IS NOT NULL
            ORDER BY ci.added_at DESC
            LIMIT 4
        ) as preview_images
    FROM public.collections c
    WHERE c.user_id = target_user_id
    ORDER BY c.updated_at DESC;
END;
$$;

-- =====================================================
-- FUNCTION: Get collection items with post details
-- =====================================================
CREATE OR REPLACE FUNCTION get_collection_items(target_collection_id UUID, requesting_user_id UUID)
RETURNS TABLE (
    item_id UUID,
    post_id UUID,
    post_content TEXT,
    post_image_url TEXT,
    post_video_url TEXT,
    post_created_at TIMESTAMPTZ,
    post_likes_count INTEGER,
    post_comments_count INTEGER,
    author_id UUID,
    author_username TEXT,
    author_avatar_url TEXT,
    added_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if user has access to this collection
    IF NOT EXISTS (
        SELECT 1 FROM public.collections c
        WHERE c.id = target_collection_id
        AND (c.user_id = requesting_user_id OR c.is_private = FALSE)
    ) THEN
        RAISE EXCEPTION 'Access denied to this collection';
    END IF;

    RETURN QUERY
    SELECT 
        ci.id as item_id,
        p.id as post_id,
        p.content as post_content,
        p.image_url as post_image_url,
        p.video_url as post_video_url,
        p.created_at as post_created_at,
        p.likes_count as post_likes_count,
        p.comments_count as post_comments_count,
        pr.id as author_id,
        pr.username as author_username,
        pr.avatar_url as author_avatar_url,
        ci.added_at
    FROM public.collection_items ci
    INNER JOIN public.posts p ON p.id = ci.post_id
    INNER JOIN public.profiles pr ON pr.id = p.user_id
    WHERE ci.collection_id = target_collection_id
    ORDER BY ci.added_at DESC;
END;
$$;

-- =====================================================
-- FUNCTION: Add post to collection (also bookmarks it)
-- =====================================================
CREATE OR REPLACE FUNCTION add_to_collection(
    target_collection_id UUID,
    target_post_id UUID,
    requesting_user_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_item_id UUID;
BEGIN
    -- Verify collection belongs to user
    IF NOT EXISTS (
        SELECT 1 FROM public.collections
        WHERE id = target_collection_id AND user_id = requesting_user_id
    ) THEN
        RAISE EXCEPTION 'Collection not found or access denied';
    END IF;

    -- Add to bookmarks if not already bookmarked
    INSERT INTO public.bookmarks (user_id, post_id)
    VALUES (requesting_user_id, target_post_id)
    ON CONFLICT (user_id, post_id) DO NOTHING;

    -- Add to collection
    INSERT INTO public.collection_items (collection_id, post_id)
    VALUES (target_collection_id, target_post_id)
    ON CONFLICT (collection_id, post_id) DO NOTHING
    RETURNING id INTO new_item_id;

    RETURN new_item_id;
END;
$$;

-- =====================================================
-- 013_moderation_schema.sql
-- =====================================================
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

-- =====================================================
-- 014_phase1_rls_policies.sql
-- =====================================================
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

-- =====================================================
-- 015_fix_extraction_functions.sql
-- =====================================================
-- =====================================================
-- FIX EXTRACTION FUNCTIONS
-- =====================================================
-- This migration fixes the extraction functions to handle cases where
-- no matches are found, preventing "FOREACH expression must not be null" errors.

-- =====================================================
-- FUNCTION: Extract and save hashtags from post
-- =====================================================
CREATE OR REPLACE FUNCTION extract_hashtags_from_post()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    hashtag_text TEXT;
    hashtag_record RECORD;
    hashtag_matches TEXT[];
BEGIN
    -- Extract hashtags from content (matches #word)
    IF NEW.content IS NOT NULL THEN
        -- Use ARRAY(SELECT ...) to ensure we get an empty array instead of NULL if no matches
        SELECT ARRAY(
            SELECT (regexp_matches(NEW.content, '#([a-zA-Z0-9_]+)', 'g'))[1]
        ) INTO hashtag_matches;
        
        -- Process each hashtag
        IF hashtag_matches IS NOT NULL THEN
            FOREACH hashtag_text IN ARRAY hashtag_matches
            LOOP
                -- Insert or update hashtag
                INSERT INTO public.hashtags (tag, normalized_tag, usage_count, last_used_at)
                VALUES (hashtag_text, LOWER(hashtag_text), 1, NOW())
                ON CONFLICT (normalized_tag) 
                DO UPDATE SET 
                    usage_count = public.hashtags.usage_count + 1,
                    last_used_at = NOW()
                RETURNING * INTO hashtag_record;
                
                -- Link hashtag to post
                INSERT INTO public.post_hashtags (post_id, hashtag_id)
                VALUES (NEW.id, hashtag_record.id)
                ON CONFLICT (post_id, hashtag_id) DO NOTHING;
            END LOOP;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- =====================================================
-- FUNCTION: Extract and save mentions from post
-- =====================================================
CREATE OR REPLACE FUNCTION extract_mentions_from_post()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    mention_username TEXT;
    mentioned_user_record RECORD;
    mention_matches TEXT[];
BEGIN
    -- Extract mentions from content (matches @username)
    IF NEW.content IS NOT NULL THEN
        -- Use ARRAY(SELECT ...) to ensure we get an empty array instead of NULL if no matches
        SELECT ARRAY(
            SELECT (regexp_matches(NEW.content, '@([a-z0-9_]+)', 'g'))[1]
        ) INTO mention_matches;
        
        -- Process each mention
        IF mention_matches IS NOT NULL THEN
            FOREACH mention_username IN ARRAY mention_matches
            LOOP
                -- Find the mentioned user
                SELECT * INTO mentioned_user_record
                FROM public.profiles
                WHERE username = mention_username;
                
                -- If user exists, create mention
                IF FOUND THEN
                    INSERT INTO public.mentions (
                        post_id, 
                        mentioned_user_id, 
                        mentioned_by_user_id
                    )
                    VALUES (
                        NEW.id, 
                        mentioned_user_record.id, 
                        NEW.user_id
                    )
                    ON CONFLICT DO NOTHING;
                    
                    -- Create notification for mentioned user
                    INSERT INTO public.notifications (
                        user_id,
                        actor_id,
                        type,
                        post_id,
                        content
                    )
                    VALUES (
                        mentioned_user_record.id,
                        NEW.user_id,
                        'mention',
                        NEW.id,
                        'mentioned you in a post'
                    );
                END IF;
            END LOOP;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- =====================================================
-- FUNCTION: Extract mentions from comments
-- =====================================================
CREATE OR REPLACE FUNCTION extract_mentions_from_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    mention_username TEXT;
    mentioned_user_record RECORD;
    mention_matches TEXT[];
BEGIN
    -- Extract mentions from content (matches @username)
    IF NEW.content IS NOT NULL THEN
        -- Use ARRAY(SELECT ...) to ensure we get an empty array instead of NULL if no matches
        SELECT ARRAY(
            SELECT (regexp_matches(NEW.content, '@([a-z0-9_]+)', 'g'))[1]
        ) INTO mention_matches;
        
        -- Process each mention
        IF mention_matches IS NOT NULL THEN
            FOREACH mention_username IN ARRAY mention_matches
            LOOP
                -- Find the mentioned user
                SELECT * INTO mentioned_user_record
                FROM public.profiles
                WHERE username = mention_username;
                
                -- If user exists, create mention
                IF FOUND THEN
                    INSERT INTO public.mentions (
                        comment_id, 
                        mentioned_user_id, 
                        mentioned_by_user_id
                    )
                    VALUES (
                        NEW.id, 
                        mentioned_user_record.id, 
                        NEW.user_id
                    )
                    ON CONFLICT DO NOTHING;
                    
                    -- Create notification for mentioned user
                    INSERT INTO public.notifications (
                        user_id,
                        actor_id,
                        type,
                        comment_id,
                        content
                    )
                    VALUES (
                        mentioned_user_record.id,
                        NEW.user_id,
                        'mention',
                        NEW.id,
                        'mentioned you in a comment'
                    );
                END IF;
            END LOOP;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- =====================================================
-- 016_fix_conversations_insert_policy.sql
-- =====================================================
-- =====================================================
-- FIX GET_OR_CREATE_DIRECT_CONVERSATION FUNCTION
-- =====================================================
-- This migration fixes the function to use the current user
-- as created_by to satisfy the RLS policy

-- Drop and recreate the function with proper security
CREATE OR REPLACE FUNCTION get_or_create_direct_conversation(
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID 
LANGUAGE plpgsql
SECURITY DEFINER  -- Run with elevated privileges to bypass RLS
SET search_path = public
AS $$
DECLARE
    v_conversation_id UUID;
    v_current_user_id UUID;
BEGIN
    -- Get the current authenticated user
    v_current_user_id := auth.uid();
    
    -- Validate that the caller is one of the participants
    IF v_current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    IF v_current_user_id != p_user1_id AND v_current_user_id != p_user2_id THEN
        RAISE EXCEPTION 'User can only create conversations they are part of';
    END IF;
    
    -- Try to find existing conversation
    SELECT c.id INTO v_conversation_id
    FROM public.conversations c
    INNER JOIN public.conversation_participants cp1 ON c.id = cp1.conversation_id
    INNER JOIN public.conversation_participants cp2 ON c.id = cp2.conversation_id
    WHERE c.type = 'direct'
    AND cp1.user_id = p_user1_id
    AND cp2.user_id = p_user2_id
    LIMIT 1;
    
    -- If not found, create new conversation
    IF v_conversation_id IS NULL THEN
        -- Ensure we're not trying to create a conversation with the same user twice
        IF p_user1_id = p_user2_id THEN
            RAISE EXCEPTION 'Cannot create a conversation with yourself';
        END IF;
        
        -- Use current user as created_by to satisfy RLS policy
        INSERT INTO public.conversations (type, created_by)
        VALUES ('direct', v_current_user_id)
        RETURNING id INTO v_conversation_id;
        
        -- Add both participants (using ON CONFLICT to handle any race conditions)
        INSERT INTO public.conversation_participants (conversation_id, user_id)
        VALUES 
            (v_conversation_id, p_user1_id),
            (v_conversation_id, p_user2_id)
        ON CONFLICT (conversation_id, user_id) DO NOTHING;
    END IF;
    
    RETURN v_conversation_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_or_create_direct_conversation(UUID, UUID) TO authenticated;

-- =====================================================
-- 017_fix_profiles_search_policy.sql
-- =====================================================
-- =====================================================
-- FIX PROFILES SELECT POLICY FOR USER SEARCH
-- =====================================================
-- This migration updates the profiles SELECT policy to allow
-- authenticated users to search for all users, not just public ones.
-- This is necessary for the user search functionality to work properly.

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;

-- Create a new policy that allows authenticated users to view all profiles
-- This enables search functionality while still protecting sensitive data
CREATE POLICY "Authenticated users can view all profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

-- Note: Sensitive profile data should be handled at the application level
-- or through additional column-level security if needed

-- =====================================================
-- 018_fix_message_attachments_access.sql
-- =====================================================
-- =====================================================
-- FIX MESSAGE ATTACHMENTS STORAGE ACCESS
-- =====================================================
-- This migration fixes the message-attachments bucket to allow
-- public read access so images can load in the chat UI

-- Update bucket to be public
UPDATE storage.buckets
SET public = true
WHERE id = 'message-attachments';

-- Drop the existing restrictive SELECT policy
DROP POLICY IF EXISTS "Conversation participants can view message attachments" ON storage.objects;

-- Create new public SELECT policy
CREATE POLICY "Message attachments are publicly accessible"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'message-attachments');

-- Note: Upload and delete policies remain authenticated-only for security

-- =====================================================
-- 019_fix_following_feed_function.sql
-- =====================================================
-- =====================================================
-- FIX GET_FOLLOWING_FEED_POSTS FUNCTION
-- =====================================================
-- This migration fixes a bug in the get_following_feed_posts function
-- where it was checking if the user follows themselves instead of
-- checking if the user follows the post author.

CREATE OR REPLACE FUNCTION get_following_feed_posts(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    username TEXT,
    full_name TEXT,
    avatar_url TEXT,
    content TEXT,
    image_url TEXT,
    video_url TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    shares_count INTEGER,
    created_at TIMESTAMPTZ,
    is_liked BOOLEAN,
    is_bookmarked BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        pr.username,
        pr.full_name,
        pr.avatar_url,
        p.content,
        p.image_url,
        p.video_url,
        p.likes_count,
        p.comments_count,
        p.shares_count,
        p.created_at,
        EXISTS(SELECT 1 FROM public.likes l WHERE l.post_id = p.id AND l.user_id = p_user_id) as is_liked,
        EXISTS(SELECT 1 FROM public.bookmarks b WHERE b.post_id = p.id AND b.user_id = p_user_id) as is_bookmarked
    FROM public.posts p
    INNER JOIN public.profiles pr ON p.user_id = pr.id
    WHERE 
        -- Show posts from users you follow
        (EXISTS (
            SELECT 1 FROM public.follows f 
            WHERE f.follower_id = p_user_id AND f.following_id = pr.id
        ))
        -- Also show your own posts
        OR p.user_id = p_user_id
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 020_fix_stories_query.sql
-- =====================================================
-- =====================================================
-- FIX GET_FOLLOWING_STORIES FUNCTION
-- =====================================================
-- This migration updates the get_following_stories function to include
-- the current user's own stories in the list, not just followed users.

DROP FUNCTION IF EXISTS get_following_stories(uuid);

CREATE OR REPLACE FUNCTION get_following_stories(requesting_user_id UUID)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    story_count BIGINT,
    has_unviewed BOOLEAN,
    latest_story_at TIMESTAMPTZ,
    stories jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as user_id,
        p.username,
        p.avatar_url,
        COUNT(s.id) as story_count,
        BOOL_OR(NOT EXISTS(
            SELECT 1 FROM public.story_views sv
            WHERE sv.story_id = s.id AND sv.viewer_id = requesting_user_id
        )) as has_unviewed,
        MAX(s.created_at) as latest_story_at,
        jsonb_agg(
            jsonb_build_object(
                'id', s.id,
                'user_id', s.user_id,
                'media_url', s.media_url,
                'media_type', s.media_type,
                'thumbnail_url', s.thumbnail_url,
                'caption', s.caption,
                'duration', s.duration,
                'created_at', s.created_at,
                'expires_at', s.expires_at,
                'view_count', s.view_count,
                'has_viewed', EXISTS(
                    SELECT 1 FROM public.story_views sv
                    WHERE sv.story_id = s.id AND sv.viewer_id = requesting_user_id
                )
            ) ORDER BY s.created_at ASC
        ) as stories
    FROM public.profiles p
    INNER JOIN public.stories s ON s.user_id = p.id
    WHERE 
        -- Include followed users OR the current user
        (p.id = requesting_user_id OR EXISTS (
            SELECT 1 FROM public.follows f 
            WHERE f.follower_id = requesting_user_id AND f.following_id = p.id
        ))
        AND s.expires_at > NOW()
    GROUP BY p.id, p.username, p.avatar_url
    ORDER BY 
        -- Put current user first
        (p.id = requesting_user_id) DESC,
        -- Then unviewed stories
        has_unviewed DESC, 
        -- Then latest
        latest_story_at DESC;
END;
$$;

-- =====================================================
-- 021_add_whisper_mode_and_e2e.sql
-- =====================================================
-- Add Whisper Mode and E2E Encryption Support
-- Migration: 021_add_whisper_mode_and_e2e.sql

-- Add Whisper Mode to conversations
ALTER TABLE conversations
ADD COLUMN IF NOT EXISTS is_whisper_mode BOOLEAN DEFAULT FALSE;

-- Add E2E encryption fields to profiles
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS public_key TEXT,
ADD COLUMN IF NOT EXISTS encrypted_private_key TEXT;

-- Add ephemeral and encryption fields to messages
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS is_ephemeral BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS encrypted_keys JSONB,
ADD COLUMN IF NOT EXISTS iv TEXT;

-- Create trigger function to mark messages as ephemeral in whisper mode
CREATE OR REPLACE FUNCTION handle_new_message_in_whisper_mode()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if the conversation is in whisper mode
  IF EXISTS (
    SELECT 1 FROM conversations 
    WHERE id = NEW.conversation_id 
    AND is_whisper_mode = TRUE
  ) THEN
    NEW.is_ephemeral := TRUE;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new messages
DROP TRIGGER IF EXISTS trigger_whisper_mode_messages ON messages;
CREATE TRIGGER trigger_whisper_mode_messages
  BEFORE INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_message_in_whisper_mode();

-- Create trigger function to set expiration when message is read
CREATE OR REPLACE FUNCTION set_message_expiration()
RETURNS TRIGGER AS $$
DECLARE
  v_is_ephemeral BOOLEAN;
  v_expires_at TIMESTAMPTZ;
BEGIN
  -- Get message details
  SELECT is_ephemeral, expires_at INTO v_is_ephemeral, v_expires_at
  FROM messages
  WHERE id = NEW.message_id;

  -- If message is ephemeral and has no expiration set, set it now
  IF v_is_ephemeral = TRUE AND v_expires_at IS NULL THEN
    UPDATE messages
    SET expires_at = NOW() + INTERVAL '24 hours'
    WHERE id = NEW.message_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for message reads
DROP TRIGGER IF EXISTS trigger_message_expiration ON message_read_receipts;
CREATE TRIGGER trigger_message_expiration
  AFTER INSERT ON message_read_receipts
  FOR EACH ROW
  EXECUTE FUNCTION set_message_expiration();

-- Create index for efficient expired message queries
CREATE INDEX IF NOT EXISTS idx_messages_expires_at 
ON messages(expires_at) 
WHERE expires_at IS NOT NULL;

-- Create index for whisper mode conversations
CREATE INDEX IF NOT EXISTS idx_conversations_whisper_mode 
ON conversations(is_whisper_mode) 
WHERE is_whisper_mode = TRUE;

-- Add RLS policies for encryption keys
-- Allow users to read their own public keys
CREATE POLICY "Users can read public keys"
ON profiles FOR SELECT
USING (true);

-- Allow users to update their own encryption keys
CREATE POLICY "Users can update own encryption keys"
ON profiles FOR UPDATE
USING (auth.uid() = id);


-- =====================================================
-- 022_fix_communities_recursion.sql
-- =====================================================
-- Fix for infinite recursion in communities RLS policy
-- This migration fixes the circular dependency in the communities SELECT policy

-- Drop the problematic policy
DROP POLICY IF EXISTS "Public communities are viewable by everyone" ON public.communities;

-- Recreate the policy with a simpler, non-recursive approach
CREATE POLICY "Public communities are viewable by everyone"
ON public.communities FOR SELECT
USING (
    -- Public communities are always viewable
    is_private = FALSE 
    OR 
    -- Creator can always view their own community
    auth.uid() = creator_id 
    OR 
    -- Members can view private communities they belong to
    -- Use a direct lookup without recursion
    id IN (
        SELECT community_id 
        FROM public.community_members 
        WHERE user_id = auth.uid()
    )
);


-- =====================================================
-- 022_fix_whisper_mode_durations.sql
-- =====================================================
-- =====================================================
-- FIX: WHISPER MODE / VANISHING MESSAGES LOGIC
-- Migration: 022_fix_whisper_mode_durations.sql
-- =====================================================

-- 1. Ensure ephemeral_duration column exists in messages table
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS ephemeral_duration INTEGER DEFAULT 86400;

-- 2. Update the trigger function to handle different durations and instant vanish
CREATE OR REPLACE FUNCTION set_message_expiration()
RETURNS TRIGGER AS $$
DECLARE
  v_is_ephemeral BOOLEAN;
  v_ephemeral_duration INTEGER;
  v_expires_at TIMESTAMPTZ;
  v_sender_id UUID;
BEGIN
  -- Get message details
  SELECT is_ephemeral, ephemeral_duration, expires_at, sender_id 
  INTO v_is_ephemeral, v_ephemeral_duration, v_expires_at, v_sender_id
  FROM public.messages
  WHERE id = NEW.message_id;

  -- If message is ephemeral and has no expiration set, set it now
  -- We only set expiration if the reader is NOT the sender
  IF v_is_ephemeral = TRUE AND v_expires_at IS NULL AND NEW.user_id != v_sender_id THEN
    
    -- If duration is 0 (Vanish instantly), we delete it immediately
    IF v_ephemeral_duration = 0 THEN
      DELETE FROM public.messages WHERE id = NEW.message_id;
    ELSE
      -- Otherwise, set expires_at based on the duration (in seconds)
      UPDATE public.messages
      SET expires_at = NOW() + (v_ephemeral_duration || ' seconds')::INTERVAL
      WHERE id = NEW.message_id;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Re-create the trigger for message reads
DROP TRIGGER IF EXISTS trigger_message_expiration ON public.message_read_receipts;
CREATE TRIGGER trigger_message_expiration
  AFTER INSERT ON public.message_read_receipts
  FOR EACH ROW
  EXECUTE FUNCTION set_message_expiration();

-- 4. Create a background worker (simulated with a cron-like query) 
-- to periodically clean up expired messages that weren't deleted instantly
CREATE INDEX IF NOT EXISTS idx_messages_expires_at_cleanup 
ON public.messages(expires_at) 
WHERE expires_at IS NOT NULL;


-- =====================================================
-- 023_fix_community_members_circular_dependency.sql
-- =====================================================
-- Fix circular dependency between communities and community_members RLS policies
-- This migration breaks the recursion loop

-- Drop the problematic community_members policy
DROP POLICY IF EXISTS "Community members are viewable" ON public.community_members;

-- Recreate without checking communities table (which would cause recursion)
CREATE POLICY "Community members are viewable"
ON public.community_members FOR SELECT
USING (
    -- Allow if user is viewing their own membership
    auth.uid() = user_id 
    OR
    -- Allow if user is authenticated (app-level filtering will handle privacy)
    auth.uid() IS NOT NULL
);


-- =====================================================
-- 023_vanish_mode_reopen_logic.sql
-- =====================================================
-- =====================================================
-- FIX: INSTAGRAM-STYLE VANISH MODE (REOPEN LOGIC)
-- Migration: 023_vanish_mode_reopen_logic.sql
-- =====================================================

-- 1. Update the trigger function to NOT delete immediately.
-- Instead, it sets a generous expires_at (e.g., 24h) even for "instant" messages,
-- allowing the app to handle the "vanish on reopen" logic via session timestamps.
CREATE OR REPLACE FUNCTION set_message_expiration()
RETURNS TRIGGER AS $$
DECLARE
  v_is_ephemeral BOOLEAN;
  v_ephemeral_duration INTEGER;
  v_expires_at TIMESTAMPTZ;
  v_sender_id UUID;
BEGIN
  -- Get message details
  SELECT is_ephemeral, ephemeral_duration, expires_at, sender_id 
  INTO v_is_ephemeral, v_ephemeral_duration, v_expires_at, v_sender_id
  FROM public.messages
  WHERE id = NEW.message_id;

  -- If message is ephemeral and has no expiration set, set it now
  -- We only set expiration if the reader is NOT the sender
  IF v_is_ephemeral = TRUE AND v_expires_at IS NULL AND NEW.user_id != v_sender_id THEN
    
    -- For Vanish Mode (duration 0), we set a 24h safety expiry in the DB,
    -- but the app will hide it as soon as the session ends.
    IF v_ephemeral_duration = 0 THEN
      UPDATE public.messages
      SET expires_at = NOW() + INTERVAL '24 hours'
      WHERE id = NEW.message_id;
    ELSE
      -- Otherwise, set expires_at based on the duration (in seconds)
      UPDATE public.messages
      SET expires_at = NOW() + (v_ephemeral_duration || ' seconds')::INTERVAL
      WHERE id = NEW.message_id;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- 024_complete_communities_rls_fix.sql
-- =====================================================
-- Complete fix for communities RLS policies
-- This removes all circular dependencies and simplifies the policies

-- Drop all existing community-related policies
DROP POLICY IF EXISTS "Public communities are viewable by everyone" ON public.communities;
DROP POLICY IF EXISTS "Authenticated users can create communities" ON public.communities;
DROP POLICY IF EXISTS "Community creators and admins can update communities" ON public.communities;
DROP POLICY IF EXISTS "Community creators can delete communities" ON public.communities;
DROP POLICY IF EXISTS "Community members are viewable" ON public.community_members;
DROP POLICY IF EXISTS "Community members are viewable by community members" ON public.community_members;
DROP POLICY IF EXISTS "Users can join communities" ON public.community_members;
DROP POLICY IF EXISTS "Users can leave or admins can remove members" ON public.community_members;
DROP POLICY IF EXISTS "Admins can update member roles" ON public.community_members;

-- =====================================================
-- COMMUNITIES POLICIES (Simplified, no recursion)
-- =====================================================

-- Allow all authenticated users to view all communities
-- Privacy filtering will be handled at application level
CREATE POLICY "Authenticated users can view communities"
ON public.communities FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Authenticated users can create communities
CREATE POLICY "Authenticated users can create communities"
ON public.communities FOR INSERT
WITH CHECK (auth.uid() = creator_id);

-- Community creators can update their communities
CREATE POLICY "Community creators can update communities"
ON public.communities FOR UPDATE
USING (auth.uid() = creator_id);

-- Community creators can delete their communities
CREATE POLICY "Community creators can delete communities"
ON public.communities FOR DELETE
USING (auth.uid() = creator_id);

-- =====================================================
-- COMMUNITY MEMBERS POLICIES (Simplified, no recursion)
-- =====================================================

-- Authenticated users can view all community memberships
-- Privacy filtering will be handled at application level
CREATE POLICY "Authenticated users can view memberships"
ON public.community_members FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Users can join communities
CREATE POLICY "Users can join communities"
ON public.community_members FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can leave communities
CREATE POLICY "Users can leave communities"
ON public.community_members FOR DELETE
USING (auth.uid() = user_id);

-- Admins can update member roles (simplified)
CREATE POLICY "Admins can update member roles"
ON public.community_members FOR UPDATE
USING (auth.uid() = user_id OR auth.uid() IS NOT NULL);


-- Add chat themes table
CREATE TABLE IF NOT EXISTS public.chat_themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    theme_name VARCHAR(50) DEFAULT 'default',
    background_color VARCHAR(20),
    background_image_url TEXT,
    bubble_color VARCHAR(20),
    text_color VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_user_conversation_theme UNIQUE (conversation_id, user_id)
);

-- Enable RLS for chat themes
ALTER TABLE public.chat_themes ENABLE ROW LEVEL SECURITY;

-- Drop existing policy first
DROP POLICY IF EXISTS "Users can manage own chat themes" ON public.chat_themes;

-- Users can manage their own chat themes
CREATE POLICY "Users can manage own chat themes"
    ON public.chat_themes FOR ALL
    USING (auth.uid() = user_id);


-- =====================================================
-- 026_sync_chat_themes.sql
-- =====================================================
-- Allow participants to manage chat themes for all users in the same conversation
DROP POLICY IF EXISTS "Users can manage own chat themes" ON public.chat_themes;

CREATE POLICY "Users can manage chat themes for their conversations"
    ON public.chat_themes FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants
            WHERE conversation_id = chat_themes.conversation_id
            AND user_id = auth.uid()
        )
    );


-- =====================================================
-- 027_calls_schema.sql
-- =====================================================
-- Calls Schema for Real-time Voice and Video Calling

-- Call status enum
CREATE TYPE call_status AS ENUM ('pinging', 'active', 'ended', 'missed', 'rejected');

-- Call type enum
CREATE TYPE call_type AS ENUM ('voice', 'video');

-- Calls table
CREATE TABLE calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    host_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    channel_name TEXT NOT NULL, -- Agora channel name
    status call_status DEFAULT 'pinging',
    type call_type DEFAULT 'voice',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    agora_token TEXT, -- Optional: store token if generated by backend
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Call participants table (for group calls and tracking status)
CREATE TABLE call_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_id UUID REFERENCES calls(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ,
    left_at TIMESTAMPTZ,
    is_muted BOOLEAN DEFAULT FALSE,
    is_video_on BOOLEAN DEFAULT TRUE,
    is_screen_sharing BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'invited', -- invited, joined, left, declined
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(call_id, user_id)
);

-- Add call_id to messages to link call history in chat
ALTER TABLE messages ADD COLUMN call_id UUID REFERENCES calls(id) ON DELETE SET NULL;

-- Enable RLS
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_participants ENABLE ROW LEVEL SECURITY;

-- RLS Policies for calls
CREATE POLICY "Users can see calls they are part of"
    ON calls FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversation_participants
            WHERE conversation_id = calls.conversation_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can initiate calls in conversations they are part of"
    ON calls FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM conversation_participants
            WHERE conversation_id = conversation_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Host can update their call"
    ON calls FOR UPDATE
    USING (host_id = auth.uid());

-- RLS Policies for call_participants
CREATE POLICY "Users can see participants of calls they are part of"
    ON call_participants FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversation_participants cp
            JOIN calls c ON c.conversation_id = cp.conversation_id
            WHERE c.id = call_participants.call_id
            AND cp.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own participant status"
    ON call_participants FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can join calls they are invited to"
    ON call_participants FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Index for performance
CREATE INDEX idx_calls_conversation_id ON calls(conversation_id);
CREATE INDEX idx_calls_status ON calls(status);
CREATE INDEX idx_call_participants_call_id ON call_participants(call_id);
CREATE INDEX idx_call_participants_user_id ON call_participants(user_id);


-- =====================================================
-- 028_study_sessions_xp.sql
-- =====================================================
-- Add XP and Level system to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS xp INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS level INTEGER DEFAULT 1;

-- Study Sessions Table
CREATE TABLE IF NOT EXISTS study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ DEFAULT NOW(),
    duration_minutes INTEGER NOT NULL,
    status TEXT DEFAULT 'active', -- active, completed, cancelled
    is_locked_in BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Study Session Participants
CREATE TABLE IF NOT EXISTS study_session_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES study_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    exit_status TEXT DEFAULT 'joined', -- joined, completed, left_early
    xp_earned INTEGER DEFAULT 0,
    UNIQUE(session_id, user_id)
);

-- RLS for Study Sessions
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_session_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can see active study sessions"
    ON study_sessions FOR SELECT
    USING (status = 'active');

CREATE POLICY "Users can create study sessions"
    ON study_sessions FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Participants can see their sessions"
    ON study_session_participants FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can join sessions"
    ON study_session_participants FOR INSERT
    WITH CHECK (auth.uid() = user_id);


-- =====================================================
-- 20240314000000_fix_calling_and_capsules.sql
-- =====================================================
-- 20260202100000_create_time_capsules.sql
-- =====================================================
-- Create time_capsules table
create table if not exists public.time_capsules (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) not null,
  content text not null,
  media_url text,
  media_type text default 'none',
  unlock_date timestamp with time zone not null,
  created_at timestamp with time zone default now(),
  is_locked boolean default true
);

-- Enable RLS
alter table public.time_capsules enable row level security;

-- Policies
create policy "Users can view their own capsules" on public.time_capsules
  for select using (auth.uid() = user_id);

create policy "Users can insert their own capsules" on public.time_capsules
  for insert with check (auth.uid() = user_id);

create policy "Public can view capsules" on public.time_capsules
  for select using (true);


-- =====================================================
-- Migration to fix call schema and capsule relationships
-- Date: 2024-03-14

-- 1. Fix 'calls' table missing columns
ALTER TABLE calls ADD COLUMN IF NOT EXISTS sdp TEXT;
ALTER TABLE calls ADD COLUMN IF NOT EXISTS sdp_type TEXT;

-- 2. Enhance 'time_capsules' table with collaborative features
ALTER TABLE time_capsules ADD COLUMN IF NOT EXISTS is_collaborative BOOLEAN DEFAULT FALSE;
ALTER TABLE time_capsules ADD COLUMN IF NOT EXISTS contributor_ids UUID[] DEFAULT '{}';
ALTER TABLE time_capsules ADD COLUMN IF NOT EXISTS location_trigger TEXT;
ALTER TABLE time_capsules ADD COLUMN IF NOT EXISTS location_radius DOUBLE PRECISION;
ALTER TABLE time_capsules ADD COLUMN IF NOT EXISTS music_url TEXT;
ALTER TABLE time_capsules ADD COLUMN IF NOT EXISTS music_title TEXT;

-- 3. Create 'capsule_contributions' table if missing
CREATE TABLE IF NOT EXISTS capsule_contributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    capsule_id UUID REFERENCES time_capsules(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_urls TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable RLS and add policies for capsule_contributions
ALTER TABLE capsule_contributions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = 'Users can contribute to capsules they are invited to'
    ) THEN
        CREATE POLICY "Users can contribute to capsules they are invited to"
            ON capsule_contributions FOR INSERT
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM time_capsules
                    WHERE id = capsule_id
                    AND (user_id = auth.uid() OR contributor_ids @> ARRAY[auth.uid()])
                )
            );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = 'Users can view contributions for capsules they can see'
    ) THEN
        CREATE POLICY "Users can view contributions for capsules they can see"
            ON capsule_contributions FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM time_capsules
                    WHERE id = capsule_id
                )
            );
    END IF;
END $$;


-- =====================================================
-- 20240320_beta_readiness.sql
-- =====================================================
-- 1. E2EE Recovery & Profiles Upgrade
-- This enables users who upgraded to PIN security but missed the recovery key generation 
-- to complete their backup setup.
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS encrypted_private_key_recovery TEXT,
ADD COLUMN IF NOT EXISTS key_salt TEXT,
ADD COLUMN IF NOT EXISTS has_upgraded_security BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS xp INT DEFAULT 0;

-- 2. Multilingual Transcription Table
-- Stores multilingual transcriptions of voice messages.
CREATE TABLE IF NOT EXISTS message_transcripts (
  message_id UUID PRIMARY KEY REFERENCES messages(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  language TEXT NOT NULL,
  confidence DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Enable RLS on Transcripts
ALTER TABLE message_transcripts ENABLE ROW LEVEL SECURITY;

-- Policy: Only participants of the conversation can view the transcript.
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'message_transcripts' AND policyname = 'transcripts_visibility_policy'
    ) THEN
        CREATE POLICY "transcripts_visibility_policy" 
        ON message_transcripts FOR SELECT 
        USING (
          EXISTS (
            SELECT 1 FROM messages m
            JOIN conversation_participants cp ON m.conversation_id = cp.conversation_id
            WHERE m.id = message_transcripts.message_id 
            AND cp.user_id = auth.uid()
          )
        );
    END IF;
END $$;

-- 4. Create the XP increment function (used by Wellness Service)
-- This is a SECURITY DEFINER function to ensure users can't manually call 
-- UPDATE profiles to boost their own XP.
CREATE OR REPLACE FUNCTION increment_xp(user_id UUID, xp_amount INT)
RETURNS void AS $$
BEGIN
  UPDATE profiles
  SET xp = COALESCE(xp, 0) + xp_amount
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Secure Pro Status (RLS)
-- Disallow ANY user (even the owner) from manually updating their is_pro status.
-- This column can now ONLY be updated by Edge Functions using the service_role key.

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile except pro status" ON profiles;

CREATE POLICY "Users can update own profile restricted" 
ON profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id 
  AND (
    -- Force is_pro to remain identical to its current database value
    is_pro = (SELECT is_pro FROM profiles WHERE id = auth.uid())
  )
);


-- =====================================================
-- 20260204100000_app_improvements.sql
-- =====================================================
-- Migration: Add message reactions table
-- Created: 2026-02-04

-- Create message_reactions table
CREATE TABLE IF NOT EXISTS public.message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reaction VARCHAR(10) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure one reaction per user per message
    CONSTRAINT unique_user_message_reaction UNIQUE (message_id, user_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON public.message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_user_id ON public.message_reactions(user_id);

-- Enable RLS
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies (drop existing first to make migration idempotent)
DROP POLICY IF EXISTS "Users can view reactions in their conversations" ON public.message_reactions;
DROP POLICY IF EXISTS "Users can add reactions in their conversations" ON public.message_reactions;
DROP POLICY IF EXISTS "Users can remove their own reactions" ON public.message_reactions;

-- Users can view reactions on messages in conversations they're part of
CREATE POLICY "Users can view reactions in their conversations"
    ON public.message_reactions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.messages m
            JOIN public.conversation_participants cp ON cp.conversation_id = m.conversation_id
            WHERE m.id = message_reactions.message_id
            AND cp.user_id = auth.uid()
        )
    );

-- Users can add reactions to messages in their conversations
CREATE POLICY "Users can add reactions in their conversations"
    ON public.message_reactions FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (
            SELECT 1 FROM public.messages m
            JOIN public.conversation_participants cp ON cp.conversation_id = m.conversation_id
            WHERE m.id = message_reactions.message_id
            AND cp.user_id = auth.uid()
        )
    );

-- Users can remove their own reactions
CREATE POLICY "Users can remove their own reactions"
    ON public.message_reactions FOR DELETE
    USING (auth.uid() = user_id);

-- Add mood column to posts table
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS mood VARCHAR(50);

-- Add mood index for filtering
CREATE INDEX IF NOT EXISTS idx_posts_mood ON public.posts(mood) WHERE mood IS NOT NULL;

-- Add wellness tracking table
CREATE TABLE IF NOT EXISTS public.wellness_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_type VARCHAR(50) NOT NULL,
    achievement_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_user_achievement UNIQUE (user_id, achievement_type, achievement_name)
);

-- Create index for user achievements
CREATE INDEX IF NOT EXISTS idx_wellness_achievements_user ON public.wellness_achievements(user_id);

-- Enable RLS for achievements
ALTER TABLE public.wellness_achievements ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view own achievements" ON public.wellness_achievements;
DROP POLICY IF EXISTS "System can insert achievements" ON public.wellness_achievements;

-- Users can view their own achievements
CREATE POLICY "Users can view own achievements"
    ON public.wellness_achievements FOR SELECT
    USING (auth.uid() = user_id);

-- System can insert achievements (via service role)
CREATE POLICY "System can insert achievements"
    ON public.wellness_achievements FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Add focus mode settings to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS focus_mode_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS focus_mode_schedule JSONB;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS wind_down_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS wind_down_time TIME;

-- Add vault mode table for protected content
CREATE TABLE IF NOT EXISTS public.vault_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    item_type VARCHAR(20) NOT NULL, -- 'post', 'conversation', 'collection'
    item_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for vault items
ALTER TABLE public.vault_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policy first
DROP POLICY IF EXISTS "Users can manage own vault items" ON public.vault_items;

-- Users can manage their own vault items
CREATE POLICY "Users can manage own vault items"
    ON public.vault_items FOR ALL
    USING (auth.uid() = user_id);

-- Add poll tables
CREATE TABLE IF NOT EXISTS public.polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    poll_type VARCHAR(20) DEFAULT 'single', -- 'single', 'multiple', 'this_or_that', 'quiz'
    is_anonymous BOOLEAN DEFAULT FALSE,
    ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.poll_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    option_order INT DEFAULT 0,
    is_correct BOOLEAN DEFAULT FALSE -- For quiz type
);

CREATE TABLE IF NOT EXISTS public.poll_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES public.poll_options(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_poll_vote UNIQUE (poll_id, user_id, option_id)
);

-- Enable RLS for polls
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

-- Poll policies (drop existing first)
DROP POLICY IF EXISTS "Anyone can view polls" ON public.polls;
DROP POLICY IF EXISTS "Anyone can view poll options" ON public.poll_options;
DROP POLICY IF EXISTS "Users can vote" ON public.poll_votes;
DROP POLICY IF EXISTS "Users can view votes" ON public.poll_votes;

CREATE POLICY "Anyone can view polls"
    ON public.polls FOR SELECT USING (true);

CREATE POLICY "Anyone can view poll options"
    ON public.poll_options FOR SELECT USING (true);

CREATE POLICY "Users can vote"
    ON public.poll_votes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view votes"
    ON public.poll_votes FOR SELECT USING (true);


-- =====================================================
-- 20260314000001_create_call_signaling.sql
-- =====================================================
-- Create call_signaling table for WebRTC signaling (Initial Version)
CREATE TABLE IF NOT EXISTS call_signaling (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_id UUID REFERENCES calls(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL, 
    data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE call_signaling ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can see signaling for calls they are part of"
    ON call_signaling FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM calls
            WHERE id = call_signaling.call_id
            AND (
                host_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM call_participants
                    WHERE call_id = call_signaling.call_id
                    AND user_id = auth.uid()
                )
            )
        )
    );

CREATE POLICY "Participants can insert signaling"
    ON call_signaling FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM calls
            WHERE id = call_signaling.call_id
            AND (
                host_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM call_participants
                    WHERE call_id = call_signaling.call_id
                    AND user_id = auth.uid()
                )
            )
        )
    );

-- Index
CREATE INDEX IF NOT EXISTS idx_call_signaling_call_id ON call_signaling(call_id);


-- =====================================================
-- 20260314000002_fix_call_signaling_schema.sql
-- =====================================================
-- Alter call_signaling table to match WebRTC ICE candidate structure expected by CallService
ALTER TABLE call_signaling DROP COLUMN IF EXISTS type;
ALTER TABLE call_signaling DROP COLUMN IF EXISTS data;

ALTER TABLE call_signaling ADD COLUMN IF NOT EXISTS candidate TEXT NOT NULL;
ALTER TABLE call_signaling ADD COLUMN IF NOT EXISTS "sdpMid" TEXT;
ALTER TABLE call_signaling ADD COLUMN IF NOT EXISTS "sdpMLineIndex" INTEGER;


-- =====================================================
-- 20260315000000_create_canvas_and_circles.sql
-- =====================================================
-- Migration for "The Canvas" and "The Circle of Commitments" Features

-- ==========================================
-- 1. THE CANVAS FEATURE
-- ==========================================

-- Canvases Table
CREATE TABLE IF NOT EXISTS canvases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT DEFAULT 'Our Canvas',
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
    cover_color TEXT DEFAULT '#3B82F6',
    is_encrypted BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Canvas Members Table
CREATE TABLE IF NOT EXISTS canvas_members (
    canvas_id UUID REFERENCES canvases(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (canvas_id, user_id)
);

-- Canvas Items Table
CREATE TABLE IF NOT EXISTS canvas_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    canvas_id UUID REFERENCES canvases(id) ON DELETE CASCADE,
    author_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    content TEXT,
    x_pos DOUBLE PRECISION NOT NULL,
    y_pos DOUBLE PRECISION NOT NULL,
    rotation DOUBLE PRECISION DEFAULT 0.0,
    scale DOUBLE PRECISION DEFAULT 1.0,
    color TEXT DEFAULT '#252930',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 2. THE CIRCLE OF COMMITMENTS FEATURE
-- ==========================================

-- Circles Table
CREATE TABLE IF NOT EXISTS circles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT DEFAULT 'My Circle',
    emoji TEXT DEFAULT 'ðŸŒŠ',
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
    streak_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Circle Members Table
CREATE TABLE IF NOT EXISTS circle_members (
    circle_id UUID REFERENCES circles(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member', -- 'admin' or 'member'
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (circle_id, user_id)
);

-- Commitments Table
CREATE TABLE IF NOT EXISTS commitments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    circle_id UUID REFERENCES circles(id) ON DELETE CASCADE,
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    due_date DATE NOT NULL,
    status TEXT DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Commitment Responses Table
CREATE TABLE IF NOT EXISTS commitment_responses (
    commitment_id UUID REFERENCES commitments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    intent TEXT NOT NULL,
    completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    note TEXT,
    PRIMARY KEY (commitment_id, user_id)
);


-- ==========================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

ALTER TABLE canvases ENABLE ROW LEVEL SECURITY;
ALTER TABLE canvas_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE canvas_items ENABLE ROW LEVEL SECURITY;

ALTER TABLE circles ENABLE ROW LEVEL SECURITY;
ALTER TABLE circle_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE commitments ENABLE ROW LEVEL SECURITY;
ALTER TABLE commitment_responses ENABLE ROW LEVEL SECURITY;


-- Canvases Policies
CREATE POLICY "Users can view canvases they are members of"
    ON canvases FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM canvas_members
            WHERE canvas_id = canvases.id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert canvases"
    ON canvases FOR INSERT
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Canvas members can update canvases"
    ON canvases FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM canvas_members
            WHERE canvas_id = canvases.id
            AND user_id = auth.uid()
        )
    );

-- Canvas Members Policies
CREATE POLICY "Users can view canvas members of their canvases"
    ON canvas_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM canvas_members AS cm
            WHERE cm.canvas_id = canvas_members.canvas_id
            AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can add themselves or be added to canvases"
    ON canvas_members FOR INSERT
    WITH CHECK (true); -- Ideally restrict to creators, but open for now to let creator add members

CREATE POLICY "Users can remove themselves from canvases"
    ON canvas_members FOR DELETE
    USING (user_id = auth.uid());


-- Canvas Items Policies
CREATE POLICY "Users can view items in their canvases"
    ON canvas_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM canvas_members
            WHERE canvas_id = canvas_items.canvas_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can add items to their canvases"
    ON canvas_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM canvas_members
            WHERE canvas_id = canvas_items.canvas_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update items in their canvases"
    ON canvas_items FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM canvas_members
            WHERE canvas_id = canvas_items.canvas_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own items"
    ON canvas_items FOR DELETE
    USING (author_id = auth.uid());


-- Circles Policies
CREATE POLICY "Users can view circles they are members of"
    ON circles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM circle_members
            WHERE circle_id = circles.id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create circles"
    ON circles FOR INSERT
    WITH CHECK (auth.uid() = created_by);

-- Circle Members Policies
CREATE POLICY "Users can view circle members of their circles"
    ON circle_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM circle_members AS cm
            WHERE cm.circle_id = circle_members.circle_id
            AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can add members to circles"
    ON circle_members FOR INSERT
    WITH CHECK (true); 

CREATE POLICY "Users can leave circles"
    ON circle_members FOR DELETE
    USING (user_id = auth.uid());


-- Commitments Policies
CREATE POLICY "Users can view commitments in their circles"
    ON commitments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM circle_members
            WHERE circle_id = commitments.circle_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Circle members can add commitments"
    ON commitments FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM circle_members
            WHERE circle_id = commitments.circle_id
            AND user_id = auth.uid()
        )
    );

-- Commitment Responses Policies
CREATE POLICY "Users can view commitment responses in their circles"
    ON commitment_responses FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM commitments c
            JOIN circle_members cm ON cm.circle_id = c.circle_id
            WHERE c.id = commitment_responses.commitment_id
            AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can respond to commitments in their circles"
    ON commitment_responses FOR INSERT
    WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM commitments c
            JOIN circle_members cm ON cm.circle_id = c.circle_id
            WHERE c.id = commitment_responses.commitment_id
            AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own commitment responses"
    ON commitment_responses FOR UPDATE
    USING (user_id = auth.uid());


-- ==========================================
-- 4. REALTIME SETUP
-- ==========================================
-- Enable realtime for the tables that are subscribed to in the app
ALTER PUBLICATION supabase_realtime ADD TABLE canvas_items;
ALTER PUBLICATION supabase_realtime ADD TABLE commitments;
ALTER PUBLICATION supabase_realtime ADD TABLE commitment_responses;


-- =====================================================
-- 20260315133030_fix_rls_recursion_v2.sql
-- =====================================================
-- Fix infinite recursion in canvas_members and circle_members policies by using security definer functions

-- ==========================================
-- 1. FIX CANVAS MEMBERS POLICY
-- ==========================================

CREATE OR REPLACE FUNCTION public.is_canvas_member(c_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM canvas_members
    WHERE canvas_id = c_id AND user_id = auth.uid()
  );
$$;

DROP POLICY IF EXISTS "Users can view canvas members of their canvases" ON canvas_members;

CREATE POLICY "Users can view canvas members of their canvases"
    ON canvas_members FOR SELECT
    USING ( public.is_canvas_member(canvas_id) );

-- ==========================================
-- 2. FIX CIRCLE MEMBERS POLICY
-- ==========================================

CREATE OR REPLACE FUNCTION public.is_circle_member(c_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM circle_members
    WHERE circle_id = c_id AND user_id = auth.uid()
  );
$$;

DROP POLICY IF EXISTS "Users can view circle members of their circles" ON circle_members;

CREATE POLICY "Users can view circle members of their circles"
    ON circle_members FOR SELECT
    USING ( public.is_circle_member(circle_id) );


-- =====================================================
-- 20260315134000_fix_canvases_and_circles_select_rls.sql
-- =====================================================
-- Fix RLS: allow creators to select canvases and circles so that `insert().select()` doesn't throw a 403 Forbidden 
-- because they are not yet members of the respective member tables at creation time.

CREATE POLICY "Users can view canvases they created"
    ON canvases FOR SELECT
    USING (auth.uid() = created_by);

CREATE POLICY "Users can view circles they created"
    ON circles FOR SELECT
    USING (auth.uid() = created_by);


-- =====================================================
-- 20260316000000_enable_realtime_features.sql
-- =====================================================
-- Enable realtime for notifications and chat_themes
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_themes;


-- =====================================================
-- 20260316000000_update_feed_rpcs.sql
-- =====================================================
-- Update get_feed_posts and get_following_feed_posts to include is_verified

-- Drop existing functions first
DROP FUNCTION IF EXISTS get_feed_posts(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_following_feed_posts(UUID, INTEGER, INTEGER);

-- Re-create get_feed_posts with is_verified
CREATE OR REPLACE FUNCTION get_feed_posts(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    username TEXT,
    full_name TEXT,
    avatar_url TEXT,
    is_verified BOOLEAN,
    content TEXT,
    image_url TEXT,
    video_url TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    shares_count INTEGER,
    created_at TIMESTAMPTZ,
    is_liked BOOLEAN,
    is_bookmarked BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        pr.username,
        pr.full_name,
        pr.avatar_url,
        pr.is_verified,
        p.content,
        p.image_url,
        p.video_url,
        p.likes_count,
        p.comments_count,
        p.shares_count,
        p.created_at,
        EXISTS(SELECT 1 FROM public.likes l WHERE l.post_id = p.id AND l.user_id = p_user_id) as is_liked,
        EXISTS(SELECT 1 FROM public.bookmarks b WHERE b.post_id = p.id AND b.user_id = p_user_id) as is_bookmarked
    FROM public.posts p
    INNER JOIN public.profiles pr ON p.user_id = pr.id
    WHERE 
        -- Show posts from public profiles or followed users
        (pr.is_private = FALSE OR pr.id = p_user_id OR EXISTS (
            SELECT 1 FROM public.follows f 
            WHERE f.follower_id = p_user_id AND f.following_id = pr.id
        ))
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Re-create get_following_feed_posts with is_verified
CREATE OR REPLACE FUNCTION get_following_feed_posts(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    username TEXT,
    full_name TEXT,
    avatar_url TEXT,
    is_verified BOOLEAN,
    content TEXT,
    image_url TEXT,
    video_url TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    shares_count INTEGER,
    created_at TIMESTAMPTZ,
    is_liked BOOLEAN,
    is_bookmarked BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        pr.username,
        pr.full_name,
        pr.avatar_url,
        pr.is_verified,
        p.content,
        p.image_url,
        p.video_url,
        p.likes_count,
        p.comments_count,
        p.shares_count,
        p.created_at,
        EXISTS(SELECT 1 FROM public.likes l WHERE l.post_id = p.id AND l.user_id = p_user_id) as is_liked,
        EXISTS(SELECT 1 FROM public.bookmarks b WHERE b.post_id = p.id AND b.user_id = p_user_id) as is_bookmarked
    FROM public.posts p
    INNER JOIN public.profiles pr ON p.user_id = pr.id
    WHERE EXISTS (
        SELECT 1 FROM public.follows f 
        WHERE f.follower_id = p_user_id AND f.following_id = p.user_id
    )
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- 20260317000000_signal_protocol_keys.sql
-- =====================================================
-- Signal Protocol Key Distribution Schema
-- Migration: 20260317000000_signal_protocol_keys.sql

-- Create table to store Signal Protocol users' key bundles
CREATE TABLE IF NOT EXISTS signal_keys (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  identity_key TEXT NOT NULL,
  registration_id INT NOT NULL,
  signed_prekey JSONB NOT NULL,    -- { "keyId": int, "publicKey": string, "signature": string }
  onetime_prekeys JSONB NOT NULL,  -- { "1": "publicKeyPem1", "2": "publicKeyPem2", ... }
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE signal_keys ENABLE ROW LEVEL SECURITY;

-- Everyone can read key bundles
CREATE POLICY "Anyone can read signal keys"
ON signal_keys FOR SELECT
USING (true);

-- Users can insert their own keys
CREATE POLICY "Users can insert their own signal keys"
ON signal_keys FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own keys
CREATE POLICY "Users can update their own signal keys"
ON signal_keys FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_signal_keys_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_signal_keys_updated_at ON signal_keys;
CREATE TRIGGER trigger_signal_keys_updated_at
BEFORE UPDATE ON signal_keys
FOR EACH ROW
EXECUTE FUNCTION update_signal_keys_updated_at();


-- =====================================================
-- 20260317000001_fix_notification_types.sql
-- =====================================================
-- Alter the notifications table to drop the restrictive CHECK constraint on type
-- Since the frontend creates notifications with types like 'dm', 'post', 'reply',
-- the existing check constraint fails those inserts.

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;


-- =====================================================
-- 20260318000000_add_role_to_canvas_members.sql
-- =====================================================
-- Add role column to canvas_members table
ALTER TABLE canvas_members ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'member';


-- =====================================================
-- 20260319000000_fix_message_reactions_username.sql
-- =====================================================
-- Migration: Add username to message_reactions table for denormalization
-- Created: 2026-03-19

-- Add username column to message_reactions
ALTER TABLE public.message_reactions ADD COLUMN IF NOT EXISTS username TEXT;

-- Update existing reactions with username if possible (optional, but good for data integrity)
UPDATE public.message_reactions mr
SET username = p.username
FROM public.profiles p
WHERE mr.user_id = p.id AND mr.username IS NULL;

-- Set default for future rows if needed, or just let the app handle it
ALTER TABLE public.message_reactions ALTER COLUMN username SET DEFAULT 'Unknown';


-- =====================================================
-- 20260319000000_notification_silencing.sql
-- =====================================================
-- =====================================================
-- OASIS - NOTIFICATION SILENCING LOGIC
-- =====================================================
-- This migration ensures that muted or blocked interactions do not trigger notifications.

-- 1. FUNCTION: Filter Notifications
-- =====================================================
CREATE OR REPLACE FUNCTION public.filter_notification_insert()
RETURNS TRIGGER AS $$
DECLARE
    v_is_blocked BOOLEAN;
    v_is_muted_user BOOLEAN;
    v_is_muted_conversation BOOLEAN;
    v_conversation_id UUID;
BEGIN
    -- A. CHECK BLOCKS (Recipient blocked Actor)
    SELECT EXISTS (
        SELECT 1 FROM public.blocked_users
        WHERE blocker_id = NEW.user_id AND blocked_id = NEW.actor_id
    ) INTO v_is_blocked;

    IF v_is_blocked THEN
        -- Recipient has blocked the sender. Silently discard the notification.
        RETURN NULL;
    END IF;

    -- B. CHECK MUTED USERS (Recipient muted Actor)
    SELECT EXISTS (
        SELECT 1 FROM public.muted_users
        WHERE muter_id = NEW.user_id AND muted_id = NEW.actor_id
        AND (expires_at IS NULL OR expires_at > NOW())
    ) INTO v_is_muted_user;

    IF v_is_muted_user THEN
        -- Recipient has muted the user globally. Silently discard.
        RETURN NULL;
    END IF;

    -- C. CHECK MUTED CONVERSATIONS (Specific to DMs)
    IF NEW.type = 'dm' AND NEW.message_id IS NOT NULL THEN
        -- Get conversation_id from the message
        SELECT conversation_id INTO v_conversation_id
        FROM public.messages
        WHERE id = NEW.message_id;

        IF v_conversation_id IS NOT NULL THEN
            SELECT is_muted INTO v_is_muted_conversation
            FROM public.conversation_participants
            WHERE conversation_id = v_conversation_id AND user_id = NEW.user_id;

            IF v_is_muted_conversation THEN
                -- Recipient has muted this specific conversation. Silently discard.
                RETURN NULL;
            END IF;
        END IF;
    END IF;

    -- If we reach here, the notification is allowed.
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. TRIGGER: Apply Filter Before Insert
-- =====================================================
DROP TRIGGER IF EXISTS trigger_filter_notification_insert ON public.notifications;
CREATE TRIGGER trigger_filter_notification_insert
    BEFORE INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION public.filter_notification_insert();

-- 3. RLS POLICY: Prevent messages from blocked users
-- =====================================================
-- This policy prevents inserting into the messages table if the recipient has blocked the sender.
-- Note: This requires checking conversation_participants to find the recipient.

CREATE OR REPLACE FUNCTION public.is_blocked_in_conversation(p_conversation_id UUID, p_sender_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.conversation_participants cp
        JOIN public.blocked_users bu ON cp.user_id = bu.blocker_id
        WHERE cp.conversation_id = p_conversation_id
        AND bu.blocked_id = p_sender_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply the policy to the messages table
-- We use a policy that checks BEFORE insert
-- DROP POLICY IF EXISTS "Prevent messages from blocked users" ON public.messages;
-- CREATE POLICY "Prevent messages from blocked users" ON public.messages
--     FOR INSERT
--     WITH CHECK (
--         NOT public.is_blocked_in_conversation(conversation_id, auth.uid())
--     );

-- 4. FUNCTION: Cleanup Existing Silenced Notifications
-- =====================================================
-- Clean up any notifications that might have slipped through before the block
DELETE FROM public.notifications n
USING public.blocked_users b
WHERE n.user_id = b.blocker_id AND n.actor_id = b.blocked_id;


-- =====================================================
-- 20260319000001_add_signal_message_type.sql
-- =====================================================
-- Add signal_message_type to messages table for Signal E2E Encryption
ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS signal_message_type INTEGER;




-- =====================================================

-- 20260320000000_add_signal_identity_backup.sql

-- =====================================================

-- Migration: Add Signal Identity backup to profiles

-- Description: Adds a column to store securely encrypted Signal Protocol identity keys.



ALTER TABLE public.profiles

ADD COLUMN IF NOT EXISTS encrypted_signal_identity TEXT;



COMMENT ON COLUMN public.profiles.encrypted_signal_identity IS 'Securely encrypted Signal IdentityKeyPair and RegistrationId for cross-device restoration.';



-- =====================================================

-- 20260321000000_add_signal_sender_content.sql

-- =====================================================

-- Add columns to store the sender's encrypted copy of the message for Signal

ALTER TABLE messages

ADD COLUMN IF NOT EXISTS signal_sender_content TEXT,

ADD COLUMN IF NOT EXISTS signal_sender_message_type INTEGER;



-- =====================================================
-- 20260322000001_add_message_id_to_notifications.sql

-- =====================================================

-- Add message_id column to notifications table

ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE;



-- Add index for faster lookups

CREATE INDEX IF NOT EXISTS idx_notifications_message_id ON public.notifications(message_id);



-- =====================================================

-- 20260322000002_increase_bucket_limits.sql

-- =====================================================

-- Increase file size limit for storage buckets to 150MB (157286400 bytes)

UPDATE storage.buckets 

SET file_size_limit = 157286400 

WHERE id IN (

  'message-attachments',

  'post-images',

  'post-videos',

  'community-images'

);



-- Also ensure profile pictures have a reasonable limit if they didn't have one

UPDATE storage.buckets

SET file_size_limit = 10485760 -- 10MB

WHERE id = 'profile-pictures' AND file_size_limit IS NULL;



-- =====================================================

-- 20260322000003_add_voice_columns_to_messages.sql

-- =====================================================

-- Add voice message columns to messages table

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_url TEXT;

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_duration INTEGER;



-- Update the constraint to include voice_url

ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS message_has_content;

ALTER TABLE public.messages ADD CONSTRAINT message_has_content CHECK (

    content IS NOT NULL OR 

    image_url IS NOT NULL OR 

    video_url IS NOT NULL OR

    file_url IS NOT NULL OR

    voice_url IS NOT NULL

);



-- =====================================================

-- 20260322000004_add_reply_to_messages.sql

-- =====================================================

-- Add reply_to_id column to messages table for threaded replies

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL;



-- Add index for faster lookup of replies

CREATE INDEX IF NOT EXISTS idx_messages_reply_to_id ON public.messages(reply_to_id);



-- =====================================================

-- 20260322000005_add_media_view_modes.sql

-- =====================================================

-- Migration: 20260322000005_add_media_view_modes.sql

-- Description: Add support for View Once, View Twice, and Unlimited media modes



-- 1. Add media_view_mode to messages table

ALTER TABLE public.messages 

ADD COLUMN IF NOT EXISTS media_view_mode TEXT DEFAULT 'unlimited' 

CHECK (media_view_mode IN ('unlimited', 'once', 'twice'));



-- 2. Create message_media_views table for tracking per-user views

CREATE TABLE IF NOT EXISTS public.message_media_views (

    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,

    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

    view_count INTEGER DEFAULT 0,

    last_viewed_at TIMESTAMPTZ DEFAULT NOW(),

    

    -- Unique constraint: one entry per user per message

    UNIQUE(message_id, user_id)

);



-- 3. Create indexes

CREATE INDEX IF NOT EXISTS idx_message_media_views_message_id ON public.message_media_views(message_id);

CREATE INDEX IF NOT EXISTS idx_message_media_views_user_id ON public.message_media_views(user_id);



-- 4. Enable RLS

ALTER TABLE public.message_media_views ENABLE ROW LEVEL SECURITY;



-- 5. RLS Policies

-- Users can see their own view counts

CREATE POLICY "Users can see their own media view counts"

    ON public.message_media_views FOR SELECT

    USING (auth.uid() = user_id);



-- Senders can see view counts for messages they sent (to show 'Opened' status)

CREATE POLICY "Senders can see media view counts for their messages"

    ON public.message_media_views FOR SELECT

    USING (

        EXISTS (

            SELECT 1 FROM public.messages

            WHERE messages.id = message_media_views.message_id

            AND messages.sender_id = auth.uid()

        )

    );



-- Users can insert/update their own view counts

CREATE POLICY "Users can insert their own media view counts"

    ON public.message_media_views FOR INSERT

    WITH CHECK (auth.uid() = user_id);



CREATE POLICY "Users can update their own media view counts"

    ON public.message_media_views FOR UPDATE

    USING (auth.uid() = user_id);



-- 6. Add to SupabaseConfig (optional documentation/reference)

-- message_media_views table added



-- =====================================================

-- 20260324000000_add_ttl_cleanup.sql

-- =====================================================

-- Function to delete expired ephemeral messages

CREATE OR REPLACE FUNCTION delete_expired_messages()

RETURNS void AS $$

BEGIN

    DELETE FROM public.messages 

    WHERE expires_at IS NOT NULL AND expires_at < NOW();

END;

$$ LANGUAGE plpgsql;

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS share_data JSONB;



-- =====================================================

-- 20260325000000_remake_vanish_mode.sql

-- =====================================================

-- 1. Drop old triggers and functions

DROP TRIGGER IF EXISTS trigger_message_expiration ON public.message_read_receipts;

DROP FUNCTION IF EXISTS set_message_expiration();

DROP FUNCTION IF EXISTS delete_expired_messages();



-- 2. Create the Instagram-style cleanup function

CREATE OR REPLACE FUNCTION cleanup_vanish_mode_messages(p_conversation_id UUID)

RETURNS void AS $$

BEGIN

    -- Delete messages that are ephemeral and have been read by ANY recipient

    DELETE FROM public.messages m

    WHERE m.conversation_id = p_conversation_id

      AND m.is_ephemeral = true

      AND EXISTS (

          SELECT 1 FROM public.message_read_receipts r 

          WHERE r.message_id = m.id 

          AND r.user_id != m.sender_id

      );

END;

$$ LANGUAGE plpgsql;



-- =====================================================

-- 20260325000001_fix_metadata_relation_error.sql

-- =====================================================

-- =====================================================

-- FIX: relation "metadata" does not exist

-- =====================================================

-- CONTEXT:

--   The error "relation 'metadata' does not exist" (code: 42P01)

--   is thrown when liking a post. This means there is a DB trigger

--   or function on the 'likes' table that references a table called

--   'metadata' (or the 'metadata' schema) which no longer exists.

--

-- This migration:

--   1. Diagnoses any function bodies that reference 'metadata' (informational)

--   2. Drops any stale triggers on public.likes that could be calling a bad function

--   3. Re-creates clean, safe triggers for the likes table

-- =====================================================





-- -------------------------------------------------------

-- STEP 1: Drop any unknown/stale triggers on likes table

-- -------------------------------------------------------

-- This will capture any triggers created outside migrations

-- (e.g. via the Supabase dashboard) that may be calling a

-- function which references the missing 'metadata' table/schema.



DO $$

DECLARE

    r RECORD;

BEGIN

    FOR r IN

        SELECT tgname

        FROM pg_trigger

        WHERE tgrelid = 'public.likes'::regclass

          AND tgisinternal = FALSE           -- skip system/FK constraint triggers

          AND tgname NOT LIKE 'RI_ConstraintTrigger%'  -- extra safety guard

          AND tgname NOT IN (

            'trigger_increment_post_likes_count',

            'trigger_decrement_post_likes_count',

            'trigger_create_like_notification'

          )

    LOOP

        RAISE NOTICE 'Dropping unknown trigger: %', r.tgname;

        EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.likes', r.tgname);

    END LOOP;

END;

$$;





-- -------------------------------------------------------

-- STEP 2: Re-create the three known safe triggers cleanly

-- -------------------------------------------------------



-- 2a. Increment likes_count on posts

CREATE OR REPLACE FUNCTION public.increment_post_likes_count()

RETURNS TRIGGER AS $$

BEGIN

    UPDATE public.posts

    SET likes_count = likes_count + 1

    WHERE id = NEW.post_id;

    RETURN NEW;

END;

$$ LANGUAGE plpgsql SECURITY DEFINER;



DROP TRIGGER IF EXISTS trigger_increment_post_likes_count ON public.likes;

CREATE TRIGGER trigger_increment_post_likes_count

    AFTER INSERT ON public.likes

    FOR EACH ROW

    EXECUTE FUNCTION public.increment_post_likes_count();





-- 2b. Decrement likes_count on posts

CREATE OR REPLACE FUNCTION public.decrement_post_likes_count()

RETURNS TRIGGER AS $$

BEGIN

    UPDATE public.posts

    SET likes_count = GREATEST(0, likes_count - 1)

    WHERE id = OLD.post_id;

    RETURN OLD;

END;

$$ LANGUAGE plpgsql SECURITY DEFINER;



DROP TRIGGER IF EXISTS trigger_decrement_post_likes_count ON public.likes;

CREATE TRIGGER trigger_decrement_post_likes_count

    AFTER DELETE ON public.likes

    FOR EACH ROW

    EXECUTE FUNCTION public.decrement_post_likes_count();





-- 2c. Create a notification for the post owner when liked

CREATE OR REPLACE FUNCTION public.create_like_notification()

RETURNS TRIGGER AS $$

DECLARE

    v_post_user_id UUID;

BEGIN

    SELECT user_id INTO v_post_user_id

    FROM public.posts

    WHERE id = NEW.post_id;



    -- Don't notify if user likes their own post

    IF v_post_user_id IS NOT NULL AND v_post_user_id != NEW.user_id THEN

        INSERT INTO public.notifications (user_id, actor_id, type, post_id)

        VALUES (v_post_user_id, NEW.user_id, 'like', NEW.post_id)

        ON CONFLICT DO NOTHING;

    END IF;



    RETURN NEW;

END;

$$ LANGUAGE plpgsql SECURITY DEFINER;



DROP TRIGGER IF EXISTS trigger_create_like_notification ON public.likes;

CREATE TRIGGER trigger_create_like_notification

    AFTER INSERT ON public.likes

    FOR EACH ROW

    EXECUTE FUNCTION public.create_like_notification();





-- -------------------------------------------------------

-- STEP 3: Verify all triggers now on likes (informational)

-- -------------------------------------------------------

SELECT

    tgname AS trigger_name,

    proname AS function_name

FROM pg_trigger t

JOIN pg_proc p ON t.tgfoid = p.oid

WHERE tgrelid = 'public.likes'::regclass

ORDER BY tgname;



-- =====================================================

-- 20260326000000_fix_realtime_and_whisper_persistence.sql

-- =====================================================

-- Ensure messages table sends full records on delete for Realtime filtering

ALTER TABLE public.messages REPLICA IDENTITY FULL;



-- Ensure is_whisper_mode exists on conversations

ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS is_whisper_mode BOOLEAN DEFAULT FALSE;



-- =====================================================

-- 20260326000001_security_hardening.sql

-- =====================================================

-- =============================================================================

-- SECURITY HARDENING MIGRATION

-- Fixes: C-3, H-1, H-2, H-3, M-1, M-2, L-2

-- =============================================================================



-- ===========================================================================

-- C-3: canvas_members / circle_members ï¿½ï¿½   fix DEFAULT-ALLOW INSERT

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

-- H-1: notifications INSERT ï¿½ï¿½   drop world-writable policy

-- Triggers run as SECURITY DEFINER and bypass RLS; no client INSERT needed.

-- ===========================================================================



DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;



-- Clients can only create notifications where THEY are the actor

-- (e.g. sending a reaction notification). Server triggers still bypass RLS.

CREATE POLICY "Users can insert notifications as actor"

    ON public.notifications FOR INSERT

    WITH CHECK (actor_id = (SELECT auth.uid()));





-- ===========================================================================

-- H-2: handle_new_user ï¿½ï¿½   add SET search_path to SECURITY DEFINER function

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

-- H-3: signal_keys SELECT ï¿½ï¿½   restrict to authenticated users only

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

-- M-2: comments SELECT ï¿½ï¿½   enforce post visibility (private profile check)

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

-- L-2: follows SELECT ï¿½ï¿½   require authentication (prevent social graph scraping)

-- ===========================================================================



DROP POLICY IF EXISTS "Follows are viewable by everyone" ON public.follows;

CREATE POLICY "Authenticated users can view follows"

    ON public.follows FOR SELECT

    USING (auth.role() = 'authenticated');



-- =====================================================

-- 20260326000002_fresh_whisper_mode.sql

-- =====================================================

-- =====================================================
-- FRESH WHISPER MODE IMPLEMENTATION
-- Centralized server-side logic for Vanish Mode
-- =====================================================

-- 1. Clean up ALL old whisper-related triggers and functions


DROP TRIGGER IF EXISTS trigger_whisper_mode_messages ON public.messages;

DROP TRIGGER IF EXISTS trigger_message_expiration ON public.message_read_receipts;

DROP FUNCTION IF EXISTS public.handle_new_message_in_whisper_mode();

DROP FUNCTION IF EXISTS public.set_message_expiration();

DROP FUNCTION IF EXISTS public.cleanup_vanish_mode_messages(UUID);



-- 2. Update conversations table to use a proper mode column

-- Mode: 0 = Off, 1 = Instant, 2 = 24 Hours

ALTER TABLE public.conversations 

ADD COLUMN IF NOT EXISTS whisper_mode INTEGER DEFAULT 0;



-- 3. Trigger to automatically mark new messages as ephemeral

CREATE OR REPLACE FUNCTION public.handle_message_whisper_settings()

RETURNS TRIGGER AS $$

DECLARE

    v_whisper_mode INTEGER;

BEGIN

    -- Get current conversation whisper mode

    SELECT whisper_mode INTO v_whisper_mode

    FROM public.conversations

    WHERE id = NEW.conversation_id;



    -- If whisper mode is enabled (1 or 2)

    IF v_whisper_mode > 0 THEN

        NEW.is_ephemeral := TRUE;

        -- Set duration: 0 for Instant, 86400 for 24h

        NEW.ephemeral_duration := CASE 

            WHEN v_whisper_mode = 1 THEN 0 

            WHEN v_whisper_mode = 2 THEN 86400 

            ELSE 86400 

        END;

    ELSE

        NEW.is_ephemeral := FALSE;

        NEW.ephemeral_duration := 86400; -- default

    END IF;



    RETURN NEW;

END;

$$ LANGUAGE plpgsql;



CREATE TRIGGER trigger_message_whisper_settings

    BEFORE INSERT ON public.messages

    FOR EACH ROW

    EXECUTE FUNCTION public.handle_message_whisper_settings();



-- 4. Trigger to set expires_at when a message is read

CREATE OR REPLACE FUNCTION public.apply_message_expiration()

RETURNS TRIGGER AS $$

DECLARE

    v_is_ephemeral BOOLEAN;

    v_duration INTEGER;

    v_sender_id UUID;

BEGIN

    -- Get message metadata

    SELECT is_ephemeral, ephemeral_duration, sender_id 

    INTO v_is_ephemeral, v_duration, v_sender_id

    FROM public.messages

    WHERE id = NEW.message_id;



    -- Only apply if it's ephemeral, hasn't expired yet, and the reader is NOT the sender

    IF v_is_ephemeral = TRUE AND NEW.user_id != v_sender_id THEN

        -- Check if expires_at is already set (by another recipient)

        -- We only set it once (the first time it's seen by a recipient)

        UPDATE public.messages

        SET expires_at = CASE 

            WHEN v_duration = 0 THEN NOW() -- Instant vanish

            ELSE NOW() + (v_duration || ' seconds')::INTERVAL -- 24h vanish

        END

        WHERE id = NEW.message_id AND expires_at IS NULL;

    END IF;



    RETURN NEW;

END;

$$ LANGUAGE plpgsql;



CREATE TRIGGER trigger_apply_expiration

    AFTER INSERT ON public.message_read_receipts

    FOR EACH ROW

    EXECUTE FUNCTION public.apply_message_expiration();



-- 5. Helper function for manual/lazy cleanup

CREATE OR REPLACE FUNCTION public.cleanup_expired_messages(p_conversation_id UUID)

RETURNS void AS $$

BEGIN

    DELETE FROM public.messages

    WHERE conversation_id = p_conversation_id

      AND is_ephemeral = TRUE

      AND expires_at <= NOW();

END;

$$ LANGUAGE plpgsql;



-- =====================================================

-- 20260401000000_add_likes_select_policy.sql

-- =====================================================

-- Add missing SELECT policy for likes table

-- This allows users to read likes (needed to check if already liked)

-- Combined with existing INSERT/DELETE policies



-- Enable RLS if not already enabled

ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;



-- Drop existing SELECT policy if exists

DROP POLICY IF EXISTS "Users can view likes" ON public.likes;



-- Create SELECT policy - users can view likes on public posts

-- or their own posts

CREATE POLICY "Users can view likes" ON public.likes FOR SELECT

USING (

  EXISTS (

    SELECT 1 FROM public.posts

    WHERE posts.id = likes.post_id

    AND (

      -- Post is by a public profile

      NOT EXISTS (

        SELECT 1 FROM public.profiles

        WHERE profiles.id = posts.user_id

        AND profiles.is_private = true

      )

      OR

      -- User is the post owner

      posts.user_id = (SELECT auth.uid())

      OR

      -- User follows the post owner

      EXISTS (

        SELECT 1 FROM public.follows

        WHERE follows.follower_id = (SELECT auth.uid())

        AND follows.following_id = posts.user_id

      )

    )

  )

);



-- =====================================================

-- 20260403000000_fix_realtime_replica_identity.sql

-- =====================================================

-- Migration: Fix Realtime DELETE events missing message_id

-- Set REPLICA IDENTITY FULL for tables where we need non-PK columns on delete

-- Created: 2026-04-03



ALTER TABLE public.message_reactions REPLICA IDENTITY FULL;

ALTER TABLE public.message_read_receipts REPLICA IDENTITY FULL;

ALTER TABLE public.typing_indicators REPLICA IDENTITY FULL;



-- =====================================================

-- 20260404000000_update_stories_interactive.sql

-- =====================================================

-- =====================================================

-- STORIES FEATURE - INTERACTIVE METADATA & SPOTIFY

-- =====================================================



-- Add music and interactive columns to stories table

ALTER TABLE public.stories 

ADD COLUMN IF NOT EXISTS music_id TEXT,

ADD COLUMN IF NOT EXISTS music_metadata JSONB,

ADD COLUMN IF NOT EXISTS interactive_metadata JSONB;



-- =====================================================

-- UPDATE GET_ACTIVE_STORIES

-- =====================================================

DROP FUNCTION IF EXISTS get_active_stories(uuid);

CREATE OR REPLACE FUNCTION get_active_stories(target_user_id UUID)

RETURNS TABLE (

    id UUID,

    user_id UUID,

    media_url TEXT,

    media_type TEXT,

    thumbnail_url TEXT,

    caption TEXT,

    duration INTEGER,

    created_at TIMESTAMPTZ,

    expires_at TIMESTAMPTZ,

    view_count INTEGER,

    has_viewed BOOLEAN,

    music_id TEXT,

    music_metadata JSONB,

    interactive_metadata JSONB

)

LANGUAGE plpgsql

SECURITY DEFINER

AS $$

BEGIN

    RETURN QUERY

    SELECT 

        s.id,

        s.user_id,

        s.media_url,

        s.media_type,

        s.thumbnail_url,

        s.caption,

        s.duration,

        s.created_at,

        s.expires_at,

        s.view_count,

        EXISTS(

            SELECT 1 FROM public.story_views sv

            WHERE sv.story_id = s.id AND sv.viewer_id = auth.uid()

        ) as has_viewed,

        s.music_id,

        s.music_metadata,

        s.interactive_metadata

    FROM public.stories s

    WHERE s.user_id = target_user_id

    AND s.expires_at > NOW()

    ORDER BY s.created_at ASC;

END;

$$;



-- =====================================================

-- UPDATE GET_FOLLOWING_STORIES

-- =====================================================

DROP FUNCTION IF EXISTS get_following_stories(uuid);



CREATE OR REPLACE FUNCTION get_following_stories(requesting_user_id UUID)

RETURNS TABLE (

    user_id UUID,

    username TEXT,

    avatar_url TEXT,

    story_count BIGINT,

    has_unviewed BOOLEAN,

    latest_story_at TIMESTAMPTZ,

    stories jsonb

)

LANGUAGE plpgsql

SECURITY DEFINER

AS $$

BEGIN

    RETURN QUERY

    SELECT 

        p.id as user_id,

        p.username,

        p.avatar_url,

        COUNT(s.id) as story_count,

        BOOL_OR(NOT EXISTS(

            SELECT 1 FROM public.story_views sv

            WHERE sv.story_id = s.id AND sv.viewer_id = requesting_user_id

        )) as has_unviewed,

        MAX(s.created_at) as latest_story_at,

        jsonb_agg(

            jsonb_build_object(

                'id', s.id,

                'user_id', s.user_id,

                'media_url', s.media_url,

                'media_type', s.media_type,

                'thumbnail_url', s.thumbnail_url,

                'caption', s.caption,

                'duration', s.duration,

                'created_at', s.created_at,

                'expires_at', s.expires_at,

                'view_count', s.view_count,

                'has_viewed', EXISTS(

                    SELECT 1 FROM public.story_views sv

                    WHERE sv.story_id = s.id AND sv.viewer_id = requesting_user_id

                ),

                'music_id', s.music_id,

                'music_metadata', s.music_metadata,

                'interactive_metadata', s.interactive_metadata

            ) ORDER BY s.created_at ASC

        ) as stories

    FROM public.profiles p

    INNER JOIN public.stories s ON s.user_id = p.id

    WHERE 

        -- Include followed users OR the current user

        (p.id = requesting_user_id OR EXISTS (

            SELECT 1 FROM public.follows f 

            WHERE f.follower_id = requesting_user_id AND f.following_id = p.id

        ))

        AND s.expires_at > NOW()

    GROUP BY p.id, p.username, p.avatar_url

    ORDER BY 

        -- Put current user first

        (p.id = requesting_user_id) DESC,

        -- Then unviewed stories

        has_unviewed DESC, 

        -- Then latest

        latest_story_at DESC;

END;

$$;



-- =====================================================

-- 20260405000000_update_feed_rpcs_media.sql

-- =====================================================

-- Update get_feed_posts and get_following_feed_posts to include all post columns

-- Specifically media_urls, media_types, community_id, mood, etc.



-- Drop existing functions

DROP FUNCTION IF EXISTS get_feed_posts(UUID, INTEGER, INTEGER);

DROP FUNCTION IF EXISTS get_following_feed_posts(UUID, INTEGER, INTEGER);



-- Re-create get_feed_posts with all columns

CREATE OR REPLACE FUNCTION get_feed_posts(

    p_user_id UUID,

    p_limit INTEGER DEFAULT 20,

    p_offset INTEGER DEFAULT 0

)

RETURNS TABLE (

    id UUID,

    user_id UUID,

    username TEXT,

    full_name TEXT,

    avatar_url TEXT,

    is_verified BOOLEAN,

    content TEXT,

    image_url TEXT,

    media_urls TEXT[],

    media_types TEXT[],

    community_id UUID,

    community_name TEXT,

    mood TEXT,

    thumbnail_url TEXT,

    dominant_color TEXT,

    likes_count INTEGER,

    comments_count INTEGER,

    shares_count INTEGER,

    created_at TIMESTAMPTZ,

    is_liked BOOLEAN,

    is_bookmarked BOOLEAN

) AS $$

BEGIN

    RETURN QUERY

    SELECT 

        p.id,

        p.user_id,

        pr.username::TEXT,

        pr.full_name::TEXT,

        pr.avatar_url::TEXT,

        pr.is_verified,

        p.content::TEXT,

        p.image_url::TEXT,

        p.media_urls,

        NULL::TEXT[] as media_types,

        p.community_id,

        c.name::TEXT as community_name,

        p.mood::TEXT,

        NULL::TEXT as thumbnail_url,

        NULL::TEXT as dominant_color,

        p.likes_count,

        p.comments_count,

        p.shares_count,

        p.created_at,

        EXISTS(SELECT 1 FROM public.likes l WHERE l.post_id = p.id AND l.user_id = p_user_id) as is_liked,

        EXISTS(SELECT 1 FROM public.bookmarks b WHERE b.post_id = p.id AND b.user_id = p_user_id) as is_bookmarked

    FROM public.posts p

    INNER JOIN public.profiles pr ON p.user_id = pr.id

    LEFT JOIN public.communities c ON p.community_id = c.id

    WHERE 

        -- Show posts from public profiles or followed users

        (pr.is_private = FALSE OR pr.id = p_user_id OR EXISTS (

            SELECT 1 FROM public.follows f 

            WHERE f.follower_id = p_user_id AND f.following_id = pr.id

        ))

    ORDER BY p.created_at DESC

    LIMIT p_limit

    OFFSET p_offset;

END;

$$ LANGUAGE plpgsql;



-- Re-create get_following_feed_posts with all columns

CREATE OR REPLACE FUNCTION get_following_feed_posts(

    p_user_id UUID,

    p_limit INTEGER DEFAULT 20,

    p_offset INTEGER DEFAULT 0

)

RETURNS TABLE (

    id UUID,

    user_id UUID,

    username TEXT,

    full_name TEXT,

    avatar_url TEXT,

    is_verified BOOLEAN,

    content TEXT,

    image_url TEXT,

    media_urls TEXT[],

    media_types TEXT[],

    community_id UUID,

    community_name TEXT,

    mood TEXT,

    thumbnail_url TEXT,

    dominant_color TEXT,

    likes_count INTEGER,

    comments_count INTEGER,

    shares_count INTEGER,

    created_at TIMESTAMPTZ,

    is_liked BOOLEAN,

    is_bookmarked BOOLEAN

) AS $$

BEGIN

    RETURN QUERY

    SELECT 

        p.id,

        p.user_id,

        pr.username::TEXT,

        pr.full_name::TEXT,

        pr.avatar_url::TEXT,

        pr.is_verified,

        p.content::TEXT,

        p.image_url::TEXT,

        p.media_urls,

        NULL::TEXT[] as media_types,

        p.community_id,

        c.name::TEXT as community_name,

        p.mood::TEXT,

        NULL::TEXT as thumbnail_url,

        NULL::TEXT as dominant_color,

        p.likes_count,

        p.comments_count,

        p.shares_count,

        p.created_at,

        EXISTS(SELECT 1 FROM public.likes l WHERE l.post_id = p.id AND l.user_id = p_user_id) as is_liked,

        EXISTS(SELECT 1 FROM public.bookmarks b WHERE b.post_id = p.id AND b.user_id = p_user_id) as is_bookmarked

    FROM public.posts p

    INNER JOIN public.profiles pr ON p.user_id = pr.id

    LEFT JOIN public.communities c ON p.community_id = c.id

    WHERE EXISTS (

        SELECT 1 FROM public.follows f 

        WHERE f.follower_id = p_user_id AND f.following_id = p.user_id

    )

    ORDER BY p.created_at DESC

    LIMIT p_limit

    OFFSET p_offset;

END;

$$ LANGUAGE plpgsql;



-- =====================================================

-- 20260406000000_add_encryption_recovery_key.sql

-- =====================================================

-- Adds a recovery key backup for end-to-end encryption private keys



ALTER TABLE public.profiles 

ADD COLUMN IF NOT EXISTS encrypted_private_key_recovery TEXT;



COMMENT ON COLUMN public.profiles.encrypted_private_key_recovery IS 'RSA Private Key encrypted with a Recovery Key-derived key (redundant backup for PIN recovery)';



-- =====================================================

-- 20260407000000_fix_comment_count_triggers.sql

-- =====================================================

-- =====================================================

-- FIX: Re-create comment count triggers that may have been lost

-- =====================================================



-- Check if triggers exist (informational)

-- SELECT tgname FROM pg_trigger WHERE tgrelid = 'public.comments'::regclass;



-- -------------------------------------------------------

-- Increment comments count when a comment is added

-- -------------------------------------------------------

CREATE OR REPLACE FUNCTION public.increment_post_comments_count()

RETURNS TRIGGER AS $$

BEGIN

    UPDATE public.posts

    SET comments_count = comments_count + 1

    WHERE id = NEW.post_id;

    

    -- If it's a reply, increment the parent comment's replies count

    IF NEW.parent_comment_id IS NOT NULL THEN

        UPDATE public.comments

        SET replies_count = replies_count + 1

        WHERE id = NEW.parent_comment_id;

    END IF;

    

    RETURN NEW;

END;

$$ LANGUAGE plpgsql SECURITY DEFINER;



DROP TRIGGER IF EXISTS trigger_increment_post_comments_count ON public.comments;

CREATE TRIGGER trigger_increment_post_comments_count

    AFTER INSERT ON public.comments

    FOR EACH ROW

    EXECUTE FUNCTION public.increment_post_comments_count();



-- -------------------------------------------------------

-- Decrement comments count when a comment is deleted

-- -------------------------------------------------------

CREATE OR REPLACE FUNCTION public.decrement_post_comments_count()

RETURNS TRIGGER AS $$

BEGIN

    UPDATE public.posts

    SET comments_count = GREATEST(0, comments_count - 1)

    WHERE id = OLD.post_id;

    

    -- If it's a reply, decrement the parent comment's replies count

    IF OLD.parent_comment_id IS NOT NULL THEN

        UPDATE public.comments

        SET replies_count = GREATEST(0, replies_count - 1)

        WHERE id = OLD.parent_comment_id;

    END IF;

    

    RETURN OLD;

END;

$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SYSTEM METADATA TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.metadata (
    key TEXT PRIMARY KEY,
    value TEXT,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- COUPONS SETUP
-- =====================================================
-- Coupons Table for Subscriptions
CREATE TABLE coupons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value FLOAT NOT NULL,
  max_uses INT,
  current_uses INT DEFAULT 0,
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS for coupons
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Coupons are viewable by everyone for validation" ON coupons FOR SELECT USING (true);

-- Insert some sample coupons
INSERT INTO coupons (code, discount_type, discount_value, expires_at)
VALUES 
('WELCOME20', 'percentage', 20, '2026-12-31T23:59:59Z'),
('MORROW5', 'fixed', 5, '2026-12-31T23:59:59Z'),
('PROLAUNCH', 'percentage', 50, '2026-06-01T00:00:00Z');


-- =====================================================
-- PUSH NOTIFICATIONS TRIGGER
-- =====================================================
-- =====================================================
-- TRIGGER FOR PUSH NOTIFICATIONS
-- =====================================================

-- 1. Enable pg_net extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Create the function that calls the Edge Function
CREATE OR REPLACE FUNCTION public.notify_push_service()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Call the push-notifications Edge Function
  -- The payload includes the new notification record
  PERFORM
    net.http_post(
      url := 'https://' || (SELECT value FROM metadata WHERE key = 'supabase_project_ref') || '.supabase.co/functions/v1/push-notifications',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (SELECT value FROM metadata WHERE key = 'supabase_anon_key')
      ),
      body := jsonb_build_object('record', row_to_json(NEW))
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Create the trigger
DROP TRIGGER IF EXISTS trigger_notify_push_service ON public.notifications;
CREATE TRIGGER trigger_notify_push_service
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION notify_push_service();

-- Note: Ensure 'metadata' table exists or use hardcoded values/environment variables if preferred.
-- For now, I'll assume you have a way to inject these or I will provide a version using standard Supabase variables.


-- =====================================================
-- RPC TYPE FIX
-- =====================================================
-- FIX: RPC Type Mismatch
-- Change VARCHAR to TEXT in the RETURNS TABLE clause to match the underlying table schema.
-- We must DROP the function first because PostgreSQL doesn't allow changing the return type via CREATE OR REPLACE.

DROP FUNCTION IF EXISTS get_user_conversations_v2(uuid);

CREATE OR REPLACE FUNCTION get_user_conversations_v2(p_user_id UUID)
RETURNS TABLE (
    id UUID,
    type TEXT,
    name TEXT,
    image_url TEXT,
    is_whisper_mode BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    unread_count INTEGER,
    cleared_at TIMESTAMPTZ,
    all_participants JSONB,
    last_message_data JSONB,
    sort_time TIMESTAMPTZ
) 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH user_convs AS (
        -- Get all conversations where the user is a participant
        SELECT 
            c.id,
            c.type,
            c.name,
            c.image_url,
            c.is_whisper_mode,
            c.created_at,
            c.updated_at,
            cp.unread_count as my_unread,
            cp.cleared_at as my_cleared
        FROM conversations c
        JOIN conversation_participants cp ON c.id = cp.conversation_id
        WHERE cp.user_id = p_user_id
    ),
    latest_msgs AS (
        -- Find the TRUE latest message for each conversation
        -- that was sent AFTER the user cleared the chat
        SELECT DISTINCT ON (m.conversation_id)
            m.conversation_id,
            m.id as msg_id,
            m.content as msg_content,
            m.sender_id as msg_sender_id,
            m.created_at as msg_created_at,
            m.image_url as msg_image_url,
            m.video_url as msg_video_url,
            m.file_url as msg_file_url,
            m.voice_url as msg_voice_url,
            m.iv as msg_iv,
            m.encrypted_keys as msg_encrypted_keys,
            m.signal_message_type as msg_signal_type,
            m.signal_sender_content as msg_signal_sender_content
        FROM messages m
        JOIN user_convs uc ON m.conversation_id = uc.id
        WHERE uc.my_cleared IS NULL OR m.created_at > uc.my_cleared
        ORDER BY m.conversation_id, m.created_at DESC
    )
    SELECT 
        uc.id,
        uc.type,
        uc.name,
        uc.image_url,
        uc.is_whisper_mode,
        uc.created_at,
        uc.updated_at,
        uc.my_unread as unread_count,
        uc.my_cleared as cleared_at,
        (
            SELECT jsonb_agg(jsonb_build_object(
                'user_id', cp2.user_id,
                'profile', jsonb_build_object(
                    'username', p.username,
                    'full_name', p.full_name,
                    'avatar_url', p.avatar_url
                )
            ))
            FROM conversation_participants cp2
            JOIN profiles p ON cp2.user_id = p.id
            WHERE cp2.conversation_id = uc.id
        ) as all_participants,
        CASE 
            WHEN lm.msg_id IS NOT NULL THEN
                jsonb_build_object(
                    'id', lm.msg_id,
                    'content', lm.msg_content,
                    'sender_id', lm.msg_sender_id,
                    'created_at', lm.msg_created_at,
                    'image_url', lm.msg_image_url,
                    'video_url', lm.msg_video_url,
                    'file_url', lm.msg_file_url,
                    'voice_url', lm.msg_voice_url,
                    'iv', lm.msg_iv,
                    'encrypted_keys', lm.msg_encrypted_keys,
                    'signal_message_type', lm.msg_signal_type,
                    'signal_sender_content', lm.msg_signal_sender_content
                )
            ELSE NULL
        END as last_message_data,
        COALESCE(lm.msg_created_at, uc.created_at) as sort_time
    FROM user_convs uc
    LEFT JOIN latest_msgs lm ON uc.id = lm.conversation_id
    ORDER BY sort_time DESC;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- SCHEMA CONSISTENCY ADDITIONS
-- =====================================================

-- ADD CLEARED_AT COLUMN
-- =====================================================
-- ADD CLEARED_AT COLUMN FOR "CLEAR FOR ME" FEATURE
-- =====================================================
-- This script adds a cleared_at timestamp to the conversation_participants table.
-- Messages created before this timestamp will be hidden for the specific user.

ALTER TABLE public.conversation_participants 
ADD COLUMN IF NOT EXISTS cleared_at TIMESTAMPTZ;

-- Reset unread count logic can also use this if needed in the future


-- ADD POST_ID TO MESSAGES
-- Add post_id column to messages table
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_messages_post_id ON public.messages(post_id);


-- ADD REPLY_TO TO MESSAGES
-- Add reply_to_id column to messages table for threaded replies
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL;

-- Add index for faster lookup of replies
CREATE INDEX IF NOT EXISTS idx_messages_reply_to_id ON public.messages(reply_to_id);


-- ADD UNLOCK_AT TO CANVAS
-- Migration: Update canvas_items table for new features (Time Capsule, Spatial Map, Grouping)
ALTER TABLE canvas_items 
ADD COLUMN IF NOT EXISTS unlock_at TIMESTAMPTZ DEFAULT NULL,
ADD COLUMN IF NOT EXISTS rotation FLOAT DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS scale FLOAT DEFAULT 1.0,
ADD COLUMN IF NOT EXISTS group_id UUID DEFAULT NULL,
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_canvas_items_group_id ON canvas_items(group_id);
CREATE INDEX IF NOT EXISTS idx_canvas_items_unlock_at ON canvas_items(unlock_at);

-- Comments for documentation
COMMENT ON COLUMN canvas_items.unlock_at IS 'Date and time when this item becomes visible.';
COMMENT ON COLUMN canvas_items.rotation IS 'Rotation angle in degrees.';
COMMENT ON COLUMN canvas_items.scale IS 'Scale factor for the item UI.';
COMMENT ON COLUMN canvas_items.group_id IS 'Used to group multiple items (e.g. photo stacks).';
COMMENT ON COLUMN canvas_items.metadata IS 'Flexible storage for extra feature data.';


-- ADD UPDATED_AT TO PARTICIPANTS
-- Add updated_at to conversation_participants to track any change (for realtime sorting)
ALTER TABLE public.conversation_participants 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Consolidate all message post-processing into ONE function to ensure order and consistency
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Update the conversation's last message info FIRST
    UPDATE public.conversations
    SET 
        last_message_id = NEW.id,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;

    -- 2. Update participants (unread count and updated_at timestamp)
    -- Recipients get unread_count incremented
    UPDATE public.conversation_participants
    SET 
        unread_count = unread_count + 1,
        updated_at = NOW()
    WHERE conversation_id = NEW.conversation_id
    AND user_id != NEW.sender_id;
    
    -- Sender only gets updated_at timestamp (to trigger rearrangement)
    UPDATE public.conversation_participants
    SET updated_at = NOW()
    WHERE conversation_id = NEW.conversation_id
    AND user_id = NEW.sender_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Replace old triggers with the new consolidated one
DROP TRIGGER IF EXISTS trigger_update_conversation_last_message ON public.messages;
DROP TRIGGER IF EXISTS trigger_increment_unread_count ON public.messages;

CREATE TRIGGER trigger_handle_new_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_message();


-- ADD V2 ENCRYPTION COLUMNS
-- 1. Add columns for Version 2 (Secure) Encryption
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS encrypted_private_key_v2 TEXT,
ADD COLUMN IF NOT EXISTS key_salt TEXT,
ADD COLUMN IF NOT EXISTS has_upgraded_security BOOLEAN DEFAULT FALSE;

-- 2. Add an index to help the app quickly identify users needing upgrades
CREATE INDEX IF NOT EXISTS idx_profiles_security_upgrade 
ON profiles(has_upgraded_security) 
WHERE has_upgraded_security = FALSE;

-- 3. (Optional) Commentary for documentation
COMMENT ON COLUMN profiles.encrypted_private_key_v2 IS 'RSA Private Key encrypted with a PIN-derived Argon2id key (v2)';
COMMENT ON COLUMN profiles.key_salt IS 'Unique salt used for Argon2id key derivation from user PIN';


-- ADD VOICE MESSAGE COLUMNS
-- Add voice message columns to messages table
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_url TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_duration INTEGER;

-- Update the constraint to include voice_url
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS message_has_content;
ALTER TABLE public.messages ADD CONSTRAINT message_has_content CHECK (
    content IS NOT NULL OR 
    image_url IS NOT NULL OR 
    video_url IS NOT NULL OR
    file_url IS NOT NULL OR
    voice_url IS NOT NULL
);
-- =====================================================
-- HYPER CANVAS RLS (RECURSION-FREE)
-- =====================================================
-- 1. Helper Functions (SECURITY DEFINER to bypass recursion)
CREATE OR REPLACE FUNCTION public.is_canvas_member(c_id uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM canvas_members WHERE canvas_id = c_id AND user_id = auth.uid()
  ) OR EXISTS (
    SELECT 1 FROM canvases WHERE id = c_id AND created_by = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_canvas_owner(c_id uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM canvas_members WHERE canvas_id = c_id AND user_id = auth.uid() AND role = 'owner'
  ) OR EXISTS (
    SELECT 1 FROM canvases WHERE id = c_id AND created_by = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_circle_member(c_id uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM circle_members WHERE circle_id = c_id AND user_id = auth.uid()
  ) OR EXISTS (
    SELECT 1 FROM circles WHERE id = c_id AND created_by = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_circle_admin(c_id uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM circle_members WHERE circle_id = c_id AND user_id = auth.uid() AND role = 'admin'
  ) OR EXISTS (
    SELECT 1 FROM circles WHERE id = c_id AND created_by = auth.uid()
  );
$$;

-- 2. RESET POLICIES
DROP POLICY IF EXISTS "Select_Canvases" ON canvases;
DROP POLICY IF EXISTS "Insert_Canvases" ON canvases;
DROP POLICY IF EXISTS "Update_Canvases" ON canvases;
DROP POLICY IF EXISTS "Delete_Canvases" ON canvases;
DROP POLICY IF EXISTS "Users can view canvases they are members of" ON canvases;
DROP POLICY IF EXISTS "Users can insert canvases" ON canvases;
DROP POLICY IF EXISTS "Canvas members can update canvases" ON canvases;
DROP POLICY IF EXISTS "Owners can delete canvases" ON canvases;

DROP POLICY IF EXISTS "Select_Members" ON canvas_members;
DROP POLICY IF EXISTS "Insert_Members" ON canvas_members;
DROP POLICY IF EXISTS "Update_Members" ON canvas_members;
DROP POLICY IF EXISTS "Delete_Members" ON canvas_members;
DROP POLICY IF EXISTS "Users can view canvas members of their canvases" ON canvas_members;
DROP POLICY IF EXISTS "Users can add themselves or be added to canvases" ON canvas_members;
DROP POLICY IF EXISTS "Users can remove themselves from canvases" ON canvas_members;
DROP POLICY IF EXISTS "Members can be updated" ON canvas_members;

-- 3. APPLY ROBUST CANVAS POLICIES
CREATE POLICY "Hyper_Select_Canvases" ON canvases FOR SELECT USING ( public.is_canvas_member(id) );
CREATE POLICY "Hyper_Insert_Canvases" ON canvases FOR INSERT WITH CHECK ( auth.uid() = created_by );
CREATE POLICY "Hyper_Update_Canvases" ON canvases FOR UPDATE USING ( public.is_canvas_member(id) );
CREATE POLICY "Hyper_Delete_Canvases" ON canvases FOR DELETE USING ( public.is_canvas_owner(id) );

-- 4. APPLY ROBUST CANVAS_MEMBERS POLICIES
CREATE POLICY "Hyper_Select_Members" ON canvas_members FOR SELECT USING ( public.is_canvas_member(canvas_id) );
CREATE POLICY "Hyper_Insert_Members" ON canvas_members FOR INSERT WITH CHECK ( (user_id = auth.uid()) OR public.is_canvas_member(canvas_id) );
CREATE POLICY "Hyper_Update_Members" ON canvas_members FOR UPDATE USING ( public.is_canvas_member(canvas_id) );
CREATE POLICY "Hyper_Delete_Members" ON canvas_members FOR DELETE USING ( (user_id = auth.uid()) OR public.is_canvas_owner(canvas_id) );

-- 5. APPLY ROBUST CANVAS_ITEMS POLICIES
DROP POLICY IF EXISTS "Select_Items" ON canvas_items;
DROP POLICY IF EXISTS "Insert_Items" ON canvas_items;
DROP POLICY IF EXISTS "Update_Items" ON canvas_items;
DROP POLICY IF EXISTS "Delete_Items" ON canvas_items;
DROP POLICY IF EXISTS "Users can view items in their canvases" ON canvas_items;
DROP POLICY IF EXISTS "Users can add items to their canvases" ON canvas_items;
DROP POLICY IF EXISTS "Users can update items in their canvases" ON canvas_items;
DROP POLICY IF EXISTS "Users can delete their own items" ON canvas_items;

CREATE POLICY "Hyper_Select_Items" ON canvas_items FOR SELECT USING ( public.is_canvas_member(canvas_id) );
CREATE POLICY "Hyper_Insert_Items" ON canvas_items FOR INSERT WITH CHECK ( public.is_canvas_member(canvas_id) );
CREATE POLICY "Hyper_Update_Items" ON canvas_items FOR UPDATE USING ( public.is_canvas_member(canvas_id) );
CREATE POLICY "Hyper_Delete_Items" ON canvas_items FOR DELETE USING ( author_id = auth.uid() OR public.is_canvas_owner(canvas_id) );

-- 6. SYNC EXISTING DATA (Ensure creators are members with 'owner' role)
INSERT INTO canvas_members (canvas_id, user_id, role)
SELECT id, created_by, 'owner'
FROM canvases
ON CONFLICT (canvas_id, user_id) DO UPDATE SET role = 'owner';

-- =====================================================
-- REDUNDANT TRIGGER CLEANUP & SYNC
-- =====================================================
-- CLEANUP: Remove redundant and potentially conflicting triggers on messages table
DROP TRIGGER IF EXISTS trigger_update_conversation_last_message ON public.messages;
DROP TRIGGER IF EXISTS trigger_increment_unread_count ON public.messages;

-- Consolidated handle_new_message with improved sorting logic
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Update the conversation's last message info ONLY IF the new message is newer or equal
    -- This prevents out-of-order messages (clock skew or lag) from breaking the preview/sorting.
    UPDATE public.conversations
    SET 
        last_message_id = NEW.id,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id
    AND (last_message_at IS NULL OR NEW.created_at >= last_message_at);

    -- 2. Update participants (unread count and updated_at timestamp)
    -- Recipients get unread_count incremented
    UPDATE public.conversation_participants
    SET 
        unread_count = unread_count + 1,
        updated_at = NOW()
    WHERE conversation_id = NEW.conversation_id
    AND user_id != NEW.sender_id;
    
    -- Sender only gets updated_at timestamp (to trigger rearrangement)
    UPDATE public.conversation_participants
    SET updated_at = NOW()
    WHERE conversation_id = NEW.conversation_id
    AND user_id = NEW.sender_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Final re-sync of last_message_at to fix any out-of-order corruption
DO $$
DECLARE
    conv_record RECORD;
    latest_msg_id UUID;
    latest_msg_at TIMESTAMPTZ;
BEGIN
    FOR conv_record IN SELECT id FROM public.conversations LOOP
        -- Find the latest message for this conversation based on created_at
        SELECT id, created_at INTO latest_msg_id, latest_msg_at
        FROM public.messages
        WHERE conversation_id = conv_record.id
        ORDER BY created_at DESC
        LIMIT 1;

        -- Update the conversation if a message exists
        IF latest_msg_id IS NOT NULL THEN
            UPDATE public.conversations
            SET 
                last_message_id = latest_msg_id,
                last_message_at = latest_msg_at,
                updated_at = NOW()
            WHERE id = conv_record.id;
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- RIPPLE COUNT SAFETY (PREVENT NEGATIVE COUNTS)
-- =====================================================
CREATE OR REPLACE FUNCTION update_ripple_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    IF (TG_TABLE_NAME = 'ripple_likes') THEN
      UPDATE ripples SET likes_count = likes_count + 1 WHERE id = NEW.ripple_id;
    ELSIF (TG_TABLE_NAME = 'ripple_comments') THEN
      UPDATE ripples SET comments_count = comments_count + 1 WHERE id = NEW.ripple_id;
    ELSIF (TG_TABLE_NAME = 'ripple_saves') THEN
      UPDATE ripples SET saves_count = saves_count + 1 WHERE id = NEW.ripple_id;
    END IF;
  ELSIF (TG_OP = 'DELETE') THEN
    IF (TG_TABLE_NAME = 'ripple_likes') THEN
      UPDATE ripples SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.ripple_id;
    ELSIF (TG_TABLE_NAME = 'ripple_comments') THEN
      UPDATE ripples SET comments_count = GREATEST(0, comments_count - 1) WHERE id = OLD.ripple_id;
    ELSIF (TG_TABLE_NAME = 'ripple_saves') THEN
      UPDATE ripples SET saves_count = GREATEST(0, saves_count - 1) WHERE id = OLD.ripple_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ROBUST PUSH NOTIFICATION FIX
-- =====================================================
-- 1. Create the 'metadata' table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Insert placeholder values to prevent NULL results in the trigger
INSERT INTO public.metadata (key, value) 
VALUES 
    ('supabase_project_ref', 'placeholder-ref'),
    ('supabase_anon_key', 'placeholder-key')
ON CONFLICT (key) DO NOTHING;

-- 3. Robust version of the notify_push_service function
CREATE OR REPLACE FUNCTION public.notify_push_service()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_project_ref TEXT;
    v_anon_key TEXT;
BEGIN
    -- Try to get config from metadata table
    SELECT value INTO v_project_ref FROM public.metadata WHERE key = 'supabase_project_ref';
    SELECT value INTO v_anon_key FROM public.metadata WHERE key = 'supabase_anon_key';

    -- Only attempt to call the edge function if we have the configuration
    IF v_project_ref IS NOT NULL AND v_anon_key IS NOT NULL AND v_project_ref != 'placeholder-ref' THEN
        PERFORM
            net.http_post(
                url := 'https://' || v_project_ref || '.supabase.co/functions/v1/push-notifications',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || v_anon_key
                ),
                body := jsonb_build_object('record', row_to_json(NEW))
            );
    END IF;
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Push notification trigger failed: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Re-apply the trigger
DROP TRIGGER IF EXISTS trigger_notify_push_service ON public.notifications;
CREATE TRIGGER trigger_notify_push_service
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION notify_push_service();

-- 5. Cleanup stale triggers on likes table
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT tgname
        FROM pg_trigger
        WHERE tgrelid = 'public.likes'::regclass
          AND tgisinternal = FALSE
          AND tgname NOT IN (
            'trigger_increment_post_likes_count',
            'trigger_decrement_post_likes_count',
            'trigger_create_like_notification'
          )
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.likes', r.tgname);
    END LOOP;
END;
$$;
