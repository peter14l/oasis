-- Coupons Table for Subscriptions
CREATE TABLE coupons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value FLOAT NOT NULL,
  max_uses INT,
  current_uses INT DEFAULT 0,
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS for coupons
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Coupons are viewable by everyone for validation" ON coupons FOR SELECT USING (true);

-- Insert some sample coupons
INSERT INTO coupons (code, discount_type, discount_value, expires_at)
VALUES 
('WELCOME20', 'percentage', 20, '2026-12-31T23:59:59Z'),
('MORROW5', 'fixed', 5, '2026-12-31T23:59:59Z'),
('PROLAUNCH', 'percentage', 50, '2026-06-01T00:00:00Z');
