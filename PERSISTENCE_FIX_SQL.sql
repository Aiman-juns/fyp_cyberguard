-- ==================================================
-- PERSISTENCE FIX: Video Progress & Daily Challenge
-- ==================================================
-- Run this in your Supabase SQL Editor to ensure all tables exist
-- with proper Row Level Security (RLS) policies

-- ==================================================
-- 1. CREATE TABLES (IF NOT EXISTS)
-- ==================================================

-- Video Progress Table
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

-- Daily Challenge Progress Table
CREATE TABLE IF NOT EXISTS daily_challenge_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    challenge_id UUID REFERENCES daily_challenges(id) ON DELETE CASCADE NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, challenge_id)
);

-- ==================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ==================================================

CREATE INDEX IF NOT EXISTS idx_video_progress_user_resource 
    ON video_progress(user_id, resource_id);

CREATE INDEX IF NOT EXISTS idx_video_progress_user 
    ON video_progress(user_id);

CREATE INDEX IF NOT EXISTS idx_video_progress_completed 
    ON video_progress(user_id, completed);

CREATE INDEX IF NOT EXISTS idx_daily_challenge_progress_user 
    ON daily_challenge_progress(user_id);

CREATE INDEX IF NOT EXISTS idx_daily_challenge_progress_date 
    ON daily_challenge_progress(completed_at);

CREATE INDEX IF NOT EXISTS idx_daily_challenge_progress_user_date 
    ON daily_challenge_progress(user_id, completed_at);

-- ==================================================
-- 3. ENABLE ROW LEVEL SECURITY
-- ==================================================

ALTER TABLE video_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_challenge_progress ENABLE ROW LEVEL SECURITY;

-- ==================================================
-- 4. DROP EXISTING POLICIES (TO AVOID CONFLICTS)
-- ==================================================

DROP POLICY IF EXISTS "Users can view own video progress" ON video_progress;
DROP POLICY IF EXISTS "Users can insert own video progress" ON video_progress;
DROP POLICY IF EXISTS "Users can update own video progress" ON video_progress;
DROP POLICY IF EXISTS "Users can delete own video progress" ON video_progress;

DROP POLICY IF EXISTS "Users can view own daily challenge progress" ON daily_challenge_progress;
DROP POLICY IF EXISTS "Users can insert own daily challenge progress" ON daily_challenge_progress;
DROP POLICY IF EXISTS "Users can update own daily challenge progress" ON daily_challenge_progress;
DROP POLICY IF EXISTS "Users can delete own daily challenge progress" ON daily_challenge_progress;

-- ==================================================
-- 5. CREATE RLS POLICIES FOR VIDEO_PROGRESS
-- ==================================================

CREATE POLICY "Users can view own video progress" 
    ON video_progress 
    FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own video progress" 
    ON video_progress 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own video progress" 
    ON video_progress 
    FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own video progress" 
    ON video_progress 
    FOR DELETE 
    USING (auth.uid() = user_id);

-- ==================================================
-- 6. CREATE RLS POLICIES FOR DAILY_CHALLENGE_PROGRESS
-- ==================================================

CREATE POLICY "Users can view own daily challenge progress" 
    ON daily_challenge_progress 
    FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily challenge progress" 
    ON daily_challenge_progress 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily challenge progress" 
    ON daily_challenge_progress 
    FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own daily challenge progress" 
    ON daily_challenge_progress 
    FOR DELETE 
    USING (auth.uid() = user_id);

-- ==================================================
-- 7. GRANT PERMISSIONS
-- ==================================================

GRANT ALL ON video_progress TO authenticated;
GRANT ALL ON daily_challenge_progress TO authenticated;

-- ==================================================
-- 8. CREATE OR REPLACE UPDATED_AT TRIGGER
-- ==================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_video_progress_updated_at ON video_progress;

CREATE TRIGGER update_video_progress_updated_at
    BEFORE UPDATE ON video_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==================================================
-- 9. VERIFICATION QUERIES
-- ==================================================

-- Run these to verify tables exist and are accessible:

-- Check video_progress table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'video_progress';

-- Check daily_challenge_progress table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'daily_challenge_progress';

-- Check RLS policies
SELECT tablename, policyname, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('video_progress', 'daily_challenge_progress');

-- Test queries (should return empty results for new users)
SELECT * FROM video_progress WHERE user_id = auth.uid() LIMIT 1;
SELECT * FROM daily_challenge_progress WHERE user_id = auth.uid() LIMIT 1;

-- ==================================================
-- NOTES:
-- ==================================================
-- - Both tables use dual storage: Supabase + SharedPreferences
-- - FutureProvider automatically reloads data from database on app restart
-- - SharedPreferences acts as local backup if database is unavailable
-- - Debug logs will show where data is loaded from (check Flutter console)
-- ==================================================
