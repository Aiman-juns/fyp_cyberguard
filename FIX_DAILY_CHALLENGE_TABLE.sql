-- ============================================================================
-- FIX DAILY CHALLENGE TABLE - Add Missing Columns
-- ============================================================================
-- This script adds the missing is_correct column to daily_challenge_progress
-- ============================================================================

-- Add the is_correct column if it doesn't exist
ALTER TABLE daily_challenge_progress 
ADD COLUMN IF NOT EXISTS is_correct BOOLEAN NOT NULL DEFAULT true;

-- Add user_answer column if missing (to track what user answered)
ALTER TABLE daily_challenge_progress 
ADD COLUMN IF NOT EXISTS user_answer BOOLEAN;

-- Verify the columns were added
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'daily_challenge_progress'
ORDER BY ordinal_position;

-- ============================================================================
-- Expected columns after running this script:
-- 
-- - id (uuid)
-- - user_id (uuid)
-- - challenge_id (uuid)
-- - completed_at (timestamp)
-- - is_correct (boolean) ← NEWLY ADDED
-- - user_answer (boolean) ← NEWLY ADDED
-- - created_at (timestamp)
-- - updated_at (timestamp)
-- ============================================================================
