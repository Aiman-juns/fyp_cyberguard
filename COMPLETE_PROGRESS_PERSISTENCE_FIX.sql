-- ============================================================================
-- CYBERGUARD PROGRESS PERSISTENCE FIX
-- ============================================================================
-- This SQL script creates all necessary tables and policies for persisting
-- user progress in video resources and daily challenges.
-- 
-- INSTRUCTIONS:
-- 1. Open Supabase Dashboard → SQL Editor
-- 2. Copy and paste this entire script
-- 3. Click "Run" to execute
-- 4. Verify success by checking the "Verification Queries" section at the end
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE DAILY CHALLENGES TABLE (If not exists)
-- ============================================================================
-- This table stores the daily challenge questions

CREATE TABLE IF NOT EXISTS public.daily_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question TEXT NOT NULL,
    is_true BOOLEAN NOT NULL,
    explanation TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- STEP 2: CREATE VIDEO PROGRESS TABLE
-- ============================================================================
-- This table tracks user progress on video resources
-- Uses composite unique constraint to prevent duplicate entries per user+resource

CREATE TABLE IF NOT EXISTS public.video_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    resource_id TEXT NOT NULL,
    watch_percentage NUMERIC(5,2) DEFAULT 0 CHECK (watch_percentage >= 0 AND watch_percentage <= 100),
    watch_duration_seconds INTEGER DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_resource UNIQUE(user_id, resource_id)
);

-- ============================================================================
-- STEP 3: CREATE DAILY CHALLENGE PROGRESS TABLE
-- ============================================================================
-- This table tracks which challenges each user has completed

CREATE TABLE IF NOT EXISTS public.daily_challenge_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    challenge_id UUID REFERENCES public.daily_challenges(id) ON DELETE CASCADE NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    is_correct BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_challenge UNIQUE(user_id, challenge_id)
);

-- ============================================================================
-- STEP 4: CREATE DAILY CHALLENGE STREAK TABLE
-- ============================================================================
-- This table stores user streak information for daily challenges

CREATE TABLE IF NOT EXISTS public.daily_challenge_streak (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    current_streak INTEGER DEFAULT 0,
    total_days INTEGER DEFAULT 0,
    last_completed_date DATE,
    week_answers TEXT, -- Comma-separated: "1,0,1,1,0" where 1=correct, 0=incorrect
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_streak UNIQUE(user_id)
);

-- ============================================================================
-- STEP 5: CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Video Progress Indexes
CREATE INDEX IF NOT EXISTS idx_video_progress_user_resource 
    ON public.video_progress(user_id, resource_id);

CREATE INDEX IF NOT EXISTS idx_video_progress_user 
    ON public.video_progress(user_id);

CREATE INDEX IF NOT EXISTS idx_video_progress_completed 
    ON public.video_progress(user_id, completed);

-- Daily Challenge Progress Indexes
CREATE INDEX IF NOT EXISTS idx_daily_challenge_progress_user 
    ON public.daily_challenge_progress(user_id);

CREATE INDEX IF NOT EXISTS idx_daily_challenge_progress_date 
    ON public.daily_challenge_progress(completed_at);

CREATE INDEX IF NOT EXISTS idx_daily_challenge_progress_user_date 
    ON public.daily_challenge_progress(user_id, completed_at);

-- Daily Challenge Streak Indexes
CREATE INDEX IF NOT EXISTS idx_daily_challenge_streak_user 
    ON public.daily_challenge_streak(user_id);

CREATE INDEX IF NOT EXISTS idx_daily_challenge_streak_last_completed 
    ON public.daily_challenge_streak(last_completed_date);

-- ============================================================================
-- STEP 6: CREATE TRIGGER FUNCTION FOR UPDATED_AT
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 7: ATTACH TRIGGERS TO TABLES
-- ============================================================================

-- Video Progress Trigger
DROP TRIGGER IF EXISTS update_video_progress_updated_at ON public.video_progress;
CREATE TRIGGER update_video_progress_updated_at
    BEFORE UPDATE ON public.video_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Daily Challenges Trigger
DROP TRIGGER IF EXISTS update_daily_challenges_updated_at ON public.daily_challenges;
CREATE TRIGGER update_daily_challenges_updated_at
    BEFORE UPDATE ON public.daily_challenges
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Daily Challenge Streak Trigger
DROP TRIGGER IF EXISTS update_daily_challenge_streak_updated_at ON public.daily_challenge_streak;
CREATE TRIGGER update_daily_challenge_streak_updated_at
    BEFORE UPDATE ON public.daily_challenge_streak
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STEP 8: ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.daily_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_challenge_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_challenge_streak ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 9: DROP EXISTING POLICIES (To avoid conflicts on re-run)
-- ============================================================================

-- Daily Challenges Policies
DROP POLICY IF EXISTS "Everyone can read challenges" ON public.daily_challenges;
DROP POLICY IF EXISTS "Admins can manage challenges" ON public.daily_challenges;

-- Video Progress Policies
DROP POLICY IF EXISTS "Users can view own video progress" ON public.video_progress;
DROP POLICY IF EXISTS "Users can insert own video progress" ON public.video_progress;
DROP POLICY IF EXISTS "Users can update own video progress" ON public.video_progress;
DROP POLICY IF EXISTS "Users can delete own video progress" ON public.video_progress;

-- Daily Challenge Progress Policies
DROP POLICY IF EXISTS "Users can view own daily challenge progress" ON public.daily_challenge_progress;
DROP POLICY IF EXISTS "Users can insert own daily challenge progress" ON public.daily_challenge_progress;
DROP POLICY IF EXISTS "Users can update own daily challenge progress" ON public.daily_challenge_progress;
DROP POLICY IF EXISTS "Users can delete own daily challenge progress" ON public.daily_challenge_progress;

-- Daily Challenge Streak Policies
DROP POLICY IF EXISTS "Users can view own streak" ON public.daily_challenge_streak;
DROP POLICY IF EXISTS "Users can insert own streak" ON public.daily_challenge_streak;
DROP POLICY IF EXISTS "Users can update own streak" ON public.daily_challenge_streak;

-- ============================================================================
-- STEP 10: CREATE RLS POLICIES
-- ============================================================================

-- DAILY CHALLENGES POLICIES
-- Everyone can read challenges
CREATE POLICY "Everyone can read challenges" 
    ON public.daily_challenges 
    FOR SELECT 
    USING (true);

-- Only admins can manage challenges
CREATE POLICY "Admins can manage challenges" 
    ON public.daily_challenges 
    FOR ALL 
    USING (auth.jwt() ->> 'role' = 'admin');

-- VIDEO PROGRESS POLICIES
-- Users can only see their own progress
CREATE POLICY "Users can view own video progress" 
    ON public.video_progress 
    FOR SELECT 
    USING (auth.uid() = user_id);

-- Users can insert their own progress
CREATE POLICY "Users can insert own video progress" 
    ON public.video_progress 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own progress
CREATE POLICY "Users can update own video progress" 
    ON public.video_progress 
    FOR UPDATE 
    USING (auth.uid() = user_id);

-- Users can delete their own progress
CREATE POLICY "Users can delete own video progress" 
    ON public.video_progress 
    FOR DELETE 
    USING (auth.uid() = user_id);

-- DAILY CHALLENGE PROGRESS POLICIES
-- Users can view their own challenge progress
CREATE POLICY "Users can view own daily challenge progress" 
    ON public.daily_challenge_progress 
    FOR SELECT 
    USING (auth.uid() = user_id);

-- Users can insert their own challenge progress
CREATE POLICY "Users can insert own daily challenge progress" 
    ON public.daily_challenge_progress 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own challenge progress
CREATE POLICY "Users can update own daily challenge progress" 
    ON public.daily_challenge_progress 
    FOR UPDATE 
    USING (auth.uid() = user_id);

-- Users can delete their own challenge progress
CREATE POLICY "Users can delete own daily challenge progress" 
    ON public.daily_challenge_progress 
    FOR DELETE 
    USING (auth.uid() = user_id);

-- DAILY CHALLENGE STREAK POLICIES
-- Users can view their own streak
CREATE POLICY "Users can view own streak" 
    ON public.daily_challenge_streak 
    FOR SELECT 
    USING (auth.uid() = user_id);

-- Users can insert their own streak
CREATE POLICY "Users can insert own streak" 
    ON public.daily_challenge_streak 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own streak
CREATE POLICY "Users can update own streak" 
    ON public.daily_challenge_streak 
    FOR UPDATE 
    USING (auth.uid() = user_id);

-- ============================================================================
-- STEP 11: GRANT PERMISSIONS
-- ============================================================================

GRANT ALL ON public.daily_challenges TO authenticated;
GRANT ALL ON public.video_progress TO authenticated;
GRANT ALL ON public.daily_challenge_progress TO authenticated;
GRANT ALL ON public.daily_challenge_streak TO authenticated;

-- ============================================================================
-- STEP 12: INSERT SAMPLE DAILY CHALLENGES (If table is empty)
-- ============================================================================

INSERT INTO public.daily_challenges (question, is_true, explanation) 
SELECT * FROM (VALUES
    ('Public Wi-Fi is safe for online banking if it requires a password.', FALSE, 'Public Wi-Fi can be intercepted by hackers. Always use a VPN or mobile data for sensitive transactions like banking.'),
    ('You should use the same password for all your social media accounts.', FALSE, 'If one site is breached, hackers get access to all your accounts. Use unique passwords for each service!'),
    ('Enabling 2FA (Two-Factor Authentication) makes your account harder to hack.', TRUE, '2FA adds a second layer of security beyond just a password, making it much harder for attackers to access your account.'),
    ('It is safe to click on links in emails from unknown senders.', FALSE, 'Unknown sender links could be phishing attempts designed to steal your information. Always verify the sender before clicking.'),
    ('Antivirus software protects you from all cyber threats.', FALSE, 'Antivirus helps but cannot protect against all threats like social engineering. Practice safe browsing habits too.'),
    ('HTTPS in a website URL means the site is 100% safe and legitimate.', FALSE, 'HTTPS only means the connection is encrypted, not that the site itself is trustworthy. Phishing sites can also use HTTPS.'),
    ('Using a password manager is safer than remembering all your passwords.', TRUE, 'Password managers generate and store strong, unique passwords securely, reducing the risk of password reuse and weak passwords.'),
    ('It is safe to charge your phone at public USB charging stations.', FALSE, 'Public USB ports can be compromised with malware (juice jacking). Use your own charger with a wall outlet instead.'),
    ('Logging out of accounts on shared computers is not necessary if you trust the people using it.', FALSE, 'Always log out on shared computers. Others may intentionally or accidentally access your accounts or private information.'),
    ('Regular software updates are important for security.', TRUE, 'Updates often include security patches that fix vulnerabilities hackers could exploit. Keep your software up to date!')
) AS v(question, is_true, explanation)
WHERE NOT EXISTS (SELECT 1 FROM public.daily_challenges LIMIT 1);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these queries to verify everything is set up correctly

-- 1. Check if all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('video_progress', 'daily_challenge_progress', 'daily_challenge_streak', 'daily_challenges')
ORDER BY table_name;

-- 2. Check video_progress table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'video_progress'
ORDER BY ordinal_position;

-- 3. Check daily_challenge_progress table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'daily_challenge_progress'
ORDER BY ordinal_position;

-- 4. Check daily_challenge_streak table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'daily_challenge_streak'
ORDER BY ordinal_position;

-- 5. Check RLS policies
SELECT tablename, policyname, cmd, permissive
FROM pg_policies 
WHERE tablename IN ('video_progress', 'daily_challenge_progress', 'daily_challenge_streak', 'daily_challenges')
ORDER BY tablename, policyname;

-- 6. Check daily challenges count
SELECT COUNT(*) as total_challenges FROM public.daily_challenges;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
-- If all verification queries return results without errors, your database
-- is ready! You can now proceed to update your Flutter app code.
-- ============================================================================
