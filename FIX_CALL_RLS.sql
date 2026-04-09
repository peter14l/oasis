-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "Users can join calls they are invited to" ON call_participants;

-- Create a new policy that allows:
-- 1. Users to insert themselves (joining/accepting)
-- 2. Call hosts to insert others (inviting)
CREATE POLICY "Users can insert participants if they are the host or the user themselves"
ON call_participants FOR INSERT
WITH CHECK (
    user_id = auth.uid() 
    OR EXISTS (
        SELECT 1 FROM calls 
        WHERE id = call_participants.call_id 
        AND host_id = auth.uid()
    )
);
