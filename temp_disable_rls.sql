-- Temporary solution: Disable RLS for daily_challenges table
-- WARNING: This removes security. Only use for testing!
-- Execute this in your Supabase SQL Editor

-- Disable RLS (NOT recommended for production)
ALTER TABLE daily_challenges DISABLE ROW LEVEL SECURITY;

-- Or, create a more permissive policy for testing:
-- DROP POLICY IF EXISTS "Admins can manage challenges" ON daily_challenges;
-- CREATE POLICY "Allow all for testing" ON daily_challenges FOR ALL USING (true);