-- ================================================================
-- Video & Daily Challenge Progress Tracking Tables
-- ================================================================
-- Run this in your Supabase SQL Editor
-- This creates the same pattern as user_progress table (which works)

-- 1. Create video_progress table
CREATE TABLE IF NOT EXISTS video_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    resource_id TEXT NOT NULL,
    watch_percentage NUMERIC(5,2) DEFAULT 0 CHECK (watch_percentage >= 0 AND watch_percentage <= 100),
    watch_duration_seconds INTEGER DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, resource_id)
);

-- 2. Create daily_challenge_progress table
CREATE TABLE IF NOT EXISTS daily_challenge_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    challenge_id UUID REFERENCES daily_challenges(id) ON DELETE CASCADE NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, challenge_id)
);

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_video_progress_user_resource ON video_progress(user_id, resource_id);
CREATE INDEX IF NOT EXISTS idx_video_progress_user ON video_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_challenge_progress_user ON daily_challenge_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_challenge_progress_date ON daily_challenge_progress(completed_at);

-- 4. Enable RLS (Row Level Security)
ALTER TABLE video_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_challenge_progress ENABLE ROW LEVEL SECURITY;

-- 5. Drop existing policies if they exist (to avoid errors on re-run)
DROP POLICY IF EXISTS "Users can view own video progress" ON video_progress;
DROP POLICY IF EXISTS "Users can insert own video progress" ON video_progress;
DROP POLICY IF EXISTS "Users can update own video progress" ON video_progress;
DROP POLICY IF EXISTS "Users can view own daily challenge progress" ON daily_challenge_progress;
DROP POLICY IF EXISTS "Users can insert own daily challenge progress" ON daily_challenge_progress;
DROP POLICY IF EXISTS "Users can update own daily challenge progress" ON daily_challenge_progress;

-- 6. Create RLS policies for video_progress
CREATE POLICY "Users can view own video progress" ON video_progress 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own video progress" ON video_progress 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own video progress" ON video_progress 
    FOR UPDATE USING (auth.uid() = user_id);

-- 7. Create RLS policies for daily_challenge_progress
CREATE POLICY "Users can view own daily challenge progress" ON daily_challenge_progress 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily challenge progress" ON daily_challenge_progress 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily challenge progress" ON daily_challenge_progress 
    FOR UPDATE USING (auth.uid() = user_id);

-- 8. Grant permissions
GRANT ALL ON video_progress TO authenticated;
GRANT ALL ON daily_challenge_progress TO authenticated;

-- ================================================================
-- VERIFY TABLES CREATED
-- ================================================================
-- Run these to verify:
-- SELECT * FROM video_progress LIMIT 1;
-- SELECT * FROM daily_challenge_progress LIMIT 1;
--
-- If you see "relation does not exist" error, the table wasn't created
-- ================================================================