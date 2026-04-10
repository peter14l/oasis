-- Fix RLS: allow creators to select canvases and circles so that `insert().select()` doesn't throw a 403 Forbidden 
-- because they are not yet members of the respective member tables at creation time.

CREATE POLICY "Users can view canvases they created"
    ON canvases FOR SELECT
    USING (auth.uid() = created_by);

CREATE POLICY "Users can view circles they created"
    ON circles FOR SELECT
    USING (auth.uid() = created_by);
