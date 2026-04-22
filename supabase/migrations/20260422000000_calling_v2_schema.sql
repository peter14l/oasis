-- Phase 1: Clean Slate & Schema Overhaul
-- Migration: Calling V2 Schema
-- Description: Drops old calling tables and creates a simplified schema for V2 with ephemeral signaling.

-- 1. Database Cleanup
-- Remove foreign key from messages to prevent cascade issues
ALTER TABLE messages DROP COLUMN IF EXISTS call_id;

-- Drop old tables
DROP TABLE IF EXISTS call_signaling;
DROP TABLE IF EXISTS call_participants;
DROP TABLE IF EXISTS calls;

-- Drop old status type
DROP TYPE IF EXISTS call_status;

-- 2. Simplified Schema
-- Recreate call_status with new state machine
CREATE TYPE call_status AS ENUM ('ringing', 'active', 'ended', 'declined', 'missed');

-- Ensure call_type exists
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'call_type') THEN
        CREATE TYPE call_type AS ENUM ('voice', 'video');
    END IF;
END $$;

-- Recreate calls table
CREATE TABLE calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    caller_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    status call_status DEFAULT 'ringing',
    type call_type DEFAULT 'voice',
    offer JSONB,
    answer JSONB,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Everyone involved can see the call
CREATE POLICY "Users can see calls they are part of"
    ON calls FOR SELECT
    USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

-- Only caller can create the call
CREATE POLICY "Users can create calls"
    ON calls FOR INSERT
    WITH CHECK (auth.uid() = caller_id);

-- Both participants can update status, offer, answer, etc.
CREATE POLICY "Participants can update calls"
    ON calls FOR UPDATE
    USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

-- Performance Indexes
CREATE INDEX idx_calls_caller_id ON calls(caller_id);
CREATE INDEX idx_calls_receiver_id ON calls(receiver_id);
CREATE INDEX idx_calls_conversation_id ON calls(conversation_id);
CREATE INDEX idx_calls_status ON calls(status);

-- Enable Realtime for the calls table
ALTER PUBLICATION supabase_realtime ADD TABLE calls;
