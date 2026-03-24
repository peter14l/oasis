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
