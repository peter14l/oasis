-- Add message_id column to notifications table
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_notifications_message_id ON public.notifications(message_id);
