-- Run this SQL in your Supabase SQL Editor to set up the tables

-- Beta testers table (limited to 15)
CREATE TABLE IF NOT EXISTS beta_testers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'waitlisted', 'removed')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Waitlist table (for when beta is full)
CREATE TABLE IF NOT EXISTS waitlist (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  joined_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE beta_testers ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist ENABLE RLS;

-- Allow public read for beta count
CREATE POLICY "Allow public read beta_testers" ON beta_testers
  FOR SELECT USING (true);

-- Allow public insert for waitlist
CREATE POLICY "Allow public insert beta_testers" ON beta_testers
  FOR INSERT WITH CHECK (true);

-- Allow public read for waitlist
CREATE POLICY "Allow public read waitlist" ON waitlist
  FOR SELECT USING (true);

-- Allow public insert for waitlist
CREATE POLICY "Allow public insert waitlist" ON waitlist
  FOR INSERT WITH CHECK (true);

-- Create function to count active beta testers
CREATE OR REPLACE FUNCTION get_active_beta_count()
RETURNS BIGINT AS $$
  SELECT COUNT(*)::BIGINT FROM beta_testers WHERE status = 'active';
$$ LANGUAGE SQL STABLE;
