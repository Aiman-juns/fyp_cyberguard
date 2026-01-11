-- ============================================================================
-- VERIFICATION SCRIPT - Check if Progress Tables Exist
-- ============================================================================
-- Run this in Supabase SQL Editor to verify tables were created correctly
-- ============================================================================

-- 1. Check if tables exist
SELECT 
    table_name,
    'EXISTS' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('video_progress', 'daily_challenge_progress', 'daily_challenge_streak', 'daily_challenges')
ORDER BY table_name;

-- Expected to see 4 rows:
-- daily_challenge_progress
-- daily_challenge_streak  
-- daily_challenges
-- video_progress

-- ============================================================================

-- 2. Check video_progress table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'video_progress'
ORDER BY ordinal_position;

-- ============================================================================

-- 3. Check daily_challenge_streak table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'daily_challenge_streak'
ORDER BY ordinal_position;

-- ============================================================================

-- 4. Check RLS policies
SELECT tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('video_progress', 'daily_challenge_progress', 'daily_challenge_streak')
ORDER BY tablename, policyname;

-- ============================================================================

-- 5. Test insert (will only work if you're logged in as a user)
-- Uncomment and run these ONLY if tables exist

-- Test video_progress insert
-- INSERT INTO video_progress (user_id, resource_id, watch_percentage, completed)
-- VALUES (auth.uid(), 'test_resource', 50.0, false)
-- ON CONFLICT (user_id, resource_id) DO UPDATE SET watch_percentage = 50.0;

-- Check if insert worked
-- SELECT * FROM video_progress WHERE resource_id = 'test_resource';

-- Clean up test
-- DELETE FROM video_progress WHERE resource_id = 'test_resource';

-- ============================================================================
-- INSTRUCTIONS:
-- 1. Copy this entire script
-- 2. Paste into Supabase SQL Editor
-- 3. Click "Run"
-- 4. Check the results
-- 
-- If you see "0 rows" for step 1, it means tables don't exist yet!
-- You need to run COMPLETE_PROGRESS_PERSISTENCE_FIX.sql first.
-- ============================================================================
