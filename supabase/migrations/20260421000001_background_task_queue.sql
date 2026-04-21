-- Background Task Queue Migration
-- Part of the Scalability Plan to move heavy tasks to async processing.

-- 1. Create the task_queue table
CREATE TABLE IF NOT EXISTS public.task_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_type TEXT NOT NULL, -- 'transcription', 'notification_burst', 'cleanup', etc.
    payload JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    priority INTEGER DEFAULT 0, -- Higher numbers processed first
    result JSONB,
    error TEXT,
    retries INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    processed_at TIMESTAMPTZ,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL -- User who initiated the task
);

-- 2. Add indexes for performance
CREATE INDEX idx_task_queue_status_priority ON public.task_queue(status, priority DESC, created_at ASC) WHERE status = 'pending';
CREATE INDEX idx_task_queue_user_id ON public.task_queue(user_id);

-- 3. Enable RLS
ALTER TABLE public.task_queue ENABLE ROW LEVEL SECURITY;

-- 4. Policies
-- Users can see their own tasks
CREATE POLICY "Users can view their own tasks" ON public.task_queue
    FOR SELECT USING (auth.uid() = user_id);

-- Only service_role can update tasks (for security)
-- But we allow users to INSERT tasks so they can trigger them from the client
CREATE POLICY "Users can insert tasks" ON public.task_queue
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 5. Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_task_queue_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_task_queue_updated_at
    BEFORE UPDATE ON public.task_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_task_queue_updated_at();

-- 6. Trigger to notify Edge Function (via HTTP Request if possible, or just use Realtime/Polling)
-- For now, we'll assume the Edge Function is triggered via a Database Webhook 
-- which is configured in the Supabase Dashboard, but we can also add a pg_net request if available.

-- 7. Add comments for documentation
COMMENT ON TABLE public.task_queue IS 'Queue for asynchronous background processing of heavy tasks.';
COMMENT ON COLUMN public.task_queue.task_type IS 'Type of background task (e.g., transcription).';
COMMENT ON COLUMN public.task_queue.payload IS 'JSON data required to execute the task.';
