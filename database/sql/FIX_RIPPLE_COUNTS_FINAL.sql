-- Fix: Add SECURITY DEFINER to ripple count triggers and sync existing counts
-- This allows the trigger to update the ripples table even when RLS is enabled

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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-sync all counts from actual data to fix any existing discrepancies
UPDATE ripples r
SET 
  likes_count = (SELECT count(*) FROM ripple_likes WHERE ripple_id = r.id),
  comments_count = (SELECT count(*) FROM ripple_comments WHERE ripple_id = r.id),
  saves_count = (SELECT count(*) FROM ripple_saves WHERE ripple_id = r.id);
