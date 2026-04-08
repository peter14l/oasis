-- Migration: Ripples & Messaging Enhancements

-- 1. Create Ripples Table
CREATE TABLE ripples (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  video_url TEXT NOT NULL,
  thumbnail_url TEXT,
  caption TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  saves_count INT DEFAULT 0,
  is_private BOOLEAN DEFAULT false
);

-- RLS for ripples
ALTER TABLE ripples ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public ripples are viewable by everyone" ON ripples FOR SELECT USING (true);
CREATE POLICY "Users can create their own ripples" ON ripples FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own ripples" ON ripples FOR DELETE USING (auth.uid() = user_id);

-- 2. Create Interaction Tables
CREATE TABLE ripple_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ripple_id UUID REFERENCES ripples(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(ripple_id, user_id)
);

CREATE TABLE ripple_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ripple_id UUID REFERENCES ripples(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE ripple_saves (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ripple_id UUID REFERENCES ripples(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(ripple_id, user_id)
);

-- RLS for interactions
ALTER TABLE ripple_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE ripple_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ripple_saves ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view ripple likes" ON ripple_likes FOR SELECT USING (true);
CREATE POLICY "Users can like ripples" ON ripple_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike ripples" ON ripple_likes FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view ripple comments" ON ripple_comments FOR SELECT USING (true);
CREATE POLICY "Users can comment on ripples" ON ripple_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own ripple comments" ON ripple_comments FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own ripple saves" ON ripple_saves FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can save ripples" ON ripple_saves FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unsave ripples" ON ripple_saves FOR DELETE USING (auth.uid() = user_id);

-- 3. Update messages table
ALTER TABLE messages 
ADD COLUMN ripple_id UUID REFERENCES ripples(id) ON DELETE SET NULL,
ADD COLUMN story_id UUID REFERENCES stories(id) ON DELETE SET NULL;

-- 4. Update profiles for adaptive lockout
ALTER TABLE profiles 
ADD COLUMN ripples_lockout_multiplier FLOAT DEFAULT 1.0,
ADD COLUMN ripples_last_session_end TIMESTAMPTZ,
ADD COLUMN ripples_remaining_duration_ms BIGINT DEFAULT 0;

-- 5. Triggers for counts
CREATE OR REPLACE FUNCTION update_ripple_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    IF (TG_TABLE_NAME = 'ripple_likes') THEN
      UPDATE ripples SET likes_count = likes_count + 1 WHERE id = NEW.ripple_id;
    ELSIF (TG_TABLE_NAME = 'ripple_comments') THEN
      UPDATE ripples SET comments_count = comments_count + 1 WHERE id = NEW.ripple_id;
    ELSIF (TG_TABLE_NAME = 'ripple_saves') THEN
      UPDATE ripples SET saves_count = saves_count + 1 WHERE id = NEW.ripple_id;
    END IF;
  ELSIF (TG_OP = 'DELETE') THEN
    IF (TG_TABLE_NAME = 'ripple_likes') THEN
      UPDATE ripples SET likes_count = likes_count - 1 WHERE id = OLD.ripple_id;
    ELSIF (TG_TABLE_NAME = 'ripple_comments') THEN
      UPDATE ripples SET comments_count = comments_count - 1 WHERE id = OLD.ripple_id;
    ELSIF (TG_TABLE_NAME = 'ripple_saves') THEN
      UPDATE ripples SET saves_count = saves_count - 1 WHERE id = OLD.ripple_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_ripple_likes_count AFTER INSERT OR DELETE ON ripple_likes FOR EACH ROW EXECUTE FUNCTION update_ripple_counts();
CREATE TRIGGER tr_ripple_comments_count AFTER INSERT OR DELETE ON ripple_comments FOR EACH ROW EXECUTE FUNCTION update_ripple_counts();
CREATE TRIGGER tr_ripple_saves_count AFTER INSERT OR DELETE ON ripple_saves FOR EACH ROW EXECUTE FUNCTION update_ripple_counts();
