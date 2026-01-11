-- Check daily challenge streak data for debugging
-- Run this query in Supabase SQL Editor to see what's in the streak table

SELECT 
    user_id,
    current_streak,
    total_days,
    week_answers,
    last_completed_date,
    updated_at
FROM daily_challenge_streak
ORDER BY updated_at DESC;

-- Also check completed challenges
SELECT 
    user_id,
    challenge_id,
    is_correct,
    completed_at
FROM daily_challenge_progress
ORDER BY completed_at DESC
LIMIT 10;
