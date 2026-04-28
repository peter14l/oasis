-- Add is_trust_circle to circles table
-- Ensures each user can only have ONE trust circle

ALTER TABLE public.circles ADD COLUMN IF NOT EXISTS is_trust_circle BOOLEAN DEFAULT FALSE;

-- Create a unique constraint to ensure only one trust circle per user
-- We use a partial index to allow multiple FALSE values but only one TRUE per created_by
CREATE UNIQUE INDEX IF NOT EXISTS unique_trust_circle_per_user 
ON public.circles (created_by) 
WHERE (is_trust_circle = TRUE);

-- Helper function to set trust circle and unset others
CREATE OR REPLACE FUNCTION public.set_trust_circle(p_community_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Unset all other trust circles for this user
    UPDATE public.circles 
    SET is_trust_circle = FALSE 
    WHERE created_by = auth.uid() 
    AND id != p_community_id;

    -- Set the new trust circle
    UPDATE public.circles 
    SET is_trust_circle = TRUE 
    WHERE id = p_community_id 
    AND created_by = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
