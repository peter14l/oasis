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

DROP TRIGGER IF EXISTS trigger_decrement_post_comments_count ON public.comments;
CREATE TRIGGER trigger_decrement_post_comments_count
    AFTER DELETE ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION public.decrement_post_comments_count();

-- -------------------------------------------------------
-- OPTIONAL: Fix stale comments_count values
-- This recalculates comments_count for all posts based on actual comment rows
-- -------------------------------------------------------
-- Uncomment below to run once:
-- UPDATE public.posts p
-- SET comments_count = sub.cnt
-- FROM (
--     SELECT post_id, COUNT(*)::INTEGER as cnt
--     FROM public.comments
--     WHERE parent_comment_id IS NULL
--     GROUP BY post_id
-- ) sub
-- WHERE p.id = sub.post_id
-- AND p.comments_count != sub.cnt;

-- Verify the fix (should show 0 rows if triggers are working correctly):
-- SELECT p.id, p.comments_count as stored, 
--        (SELECT COUNT(*)::INTEGER FROM public.comments c WHERE c.post_id = p.id AND c.parent_comment_id IS NULL) as actual
-- FROM public.posts p
-- WHERE p.comments_count != (SELECT COUNT(*)::INTEGER FROM public.comments c WHERE c.post_id = p.id AND c.parent_comment_id IS NULL)
-- LIMIT 10;