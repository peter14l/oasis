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
