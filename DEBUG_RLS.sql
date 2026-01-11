-- ============================================================================
-- DEBUG SCRIPT - Check RLS and User Data Isolation
-- ============================================================================
-- Run this to verify RLS is working correctly
-- ============================================================================

-- 1. Check current user (logged in to Supabase)
SELECT auth.uid() as current_user_id;

-- 2. Check ALL video_progress records (to see if multiple users exist)
SELECT 
    user_id,
    resource_id,
    watch_percentage,
    completed
FROM video_progress
ORDER BY user_id, resource_id;

-- If you see multiple user_ids, that's GOOD - means different users have separate data
-- If you only see one user_id for all records, that's the PROBLEM

-- ============================================================================

-- 3. Check video_progress for current user only (what RLS should show)
SELECT 
    user_id,
    resource_id,
    watch_percentage,
    completed
FROM video_progress
WHERE user_id = auth.uid();

-- This should ONLY show YOUR data, not other users

-- ============================================================================

-- 4. Verify RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'video_progress';

-- rowsecurity should be TRUE

-- ============================================================================

-- 5. Check RLS policies exist
SELECT 
    tablename,
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'video_progress';

-- Should see policies for SELECT, INSERT, UPDATE

-- ============================================================================
-- INTERPRETATION:
-- 
-- If rowsecurity = FALSE:
--   → RLS is NOT enabled, all users see all data
--   → FIX: Run COMPLETE_PROGRESS_PERSISTENCE_FIX.sql
-- 
-- If you see NO policies:
--   → RLS policies not created
--   → FIX: Run COMPLETE_PROGRESS_PERSISTENCE_FIX.sql
--
-- If step 2 shows only ONE user_id for all records:
--   → All progress is being saved with the same user_id
--   → FIX: Check console logs for "user_id" value when saving
-- ============================================================================
