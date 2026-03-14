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
