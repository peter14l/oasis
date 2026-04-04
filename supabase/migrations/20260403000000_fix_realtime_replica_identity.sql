-- Migration: Fix Realtime DELETE events missing message_id
-- Set REPLICA IDENTITY FULL for tables where we need non-PK columns on delete
-- Created: 2026-04-03

ALTER TABLE public.message_reactions REPLICA IDENTITY FULL;
ALTER TABLE public.message_read_receipts REPLICA IDENTITY FULL;
ALTER TABLE public.typing_indicators REPLICA IDENTITY FULL;
