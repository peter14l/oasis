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

