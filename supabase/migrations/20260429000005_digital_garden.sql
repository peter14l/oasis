-- Create garden_plots table
CREATE TABLE IF NOT EXISTS public.garden_plots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    seed_text TEXT NOT NULL,
    stage INT DEFAULT 0, -- 0: seed, 1: sprout, 2: young plant, 3: blooming
    x_pos FLOAT NOT NULL,
    y_pos FLOAT NOT NULL,
    planted_at TIMESTAMPTZ DEFAULT NOW(),
    last_tended_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast querying
CREATE INDEX IF NOT EXISTS idx_garden_plots_user_id ON public.garden_plots(user_id);

-- RLS Policies
ALTER TABLE public.garden_plots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own garden" 
ON public.garden_plots FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert into their own garden" 
ON public.garden_plots FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own garden" 
ON public.garden_plots FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete from their own garden" 
ON public.garden_plots FOR DELETE 
USING (auth.uid() = user_id);
