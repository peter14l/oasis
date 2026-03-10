-- =====================================================
-- FIX GET_OR_CREATE_DIRECT_CONVERSATION FUNCTION
-- =====================================================
-- This migration fixes the function to use the current user
-- as created_by to satisfy the RLS policy

-- Drop and recreate the function with proper security
CREATE OR REPLACE FUNCTION get_or_create_direct_conversation(
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID 
LANGUAGE plpgsql
SECURITY DEFINER  -- Run with elevated privileges to bypass RLS
SET search_path = public
AS $$
DECLARE
    v_conversation_id UUID;
    v_current_user_id UUID;
BEGIN
    -- Get the current authenticated user
    v_current_user_id := auth.uid();
    
    -- Validate that the caller is one of the participants
    IF v_current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    IF v_current_user_id != p_user1_id AND v_current_user_id != p_user2_id THEN
        RAISE EXCEPTION 'User can only create conversations they are part of';
    END IF;
    
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
        -- Ensure we're not trying to create a conversation with the same user twice
        IF p_user1_id = p_user2_id THEN
            RAISE EXCEPTION 'Cannot create a conversation with yourself';
        END IF;
        
        -- Use current user as created_by to satisfy RLS policy
        INSERT INTO public.conversations (type, created_by)
        VALUES ('direct', v_current_user_id)
        RETURNING id INTO v_conversation_id;
        
        -- Add both participants (using ON CONFLICT to handle any race conditions)
        INSERT INTO public.conversation_participants (conversation_id, user_id)
        VALUES 
            (v_conversation_id, p_user1_id),
            (v_conversation_id, p_user2_id)
        ON CONFLICT (conversation_id, user_id) DO NOTHING;
    END IF;
    
    RETURN v_conversation_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_or_create_direct_conversation(UUID, UUID) TO authenticated;
