-- =====================================================
-- MORROW V2 - MESSAGING SCHEMA
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

