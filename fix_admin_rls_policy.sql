-- SOLUTION: Fix daily_challenges RLS policy for admin access
-- Execute this step-by-step in your Supabase SQL Editor

-- STEP 1: Check current admin users
SELECT id, email, full_name, role FROM public.users WHERE role = 'admin';

-- STEP 2: If no admin users exist, create one (replace with your admin email)
-- UPDATE public.users SET role = 'admin' WHERE email = 'your-admin@email.com';

-- STEP 3: Drop the existing problematic policy
DROP POLICY IF EXISTS "Admins can manage challenges" ON daily_challenges;

-- STEP 4: Create new policy that works with direct database lookup
CREATE POLICY "Admins can manage challenges" ON daily_challenges
    FOR ALL 
    TO authenticated
    USING (
        (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
    );

-- STEP 5: Verify the policy is working
-- Test this query (should return results if you're logged in as admin):
-- SELECT * FROM daily_challenges LIMIT 1;

-- STEP 6: Alternative policy if Step 4 doesn't work
-- Uncomment and run this instead:
/*
DROP POLICY IF EXISTS "Admins can manage challenges" ON daily_challenges;

CREATE POLICY "Admins can manage challenges" ON daily_challenges
    FOR ALL 
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );
*/

-- STEP 7: For debugging - check what auth.uid() returns
-- SELECT auth.uid() as current_user_id, 
--        (SELECT role FROM public.users WHERE id = auth.uid()) as current_role;

-- STEP 8: If still not working, temporarily disable RLS for testing
-- ALTER TABLE daily_challenges DISABLE ROW LEVEL SECURITY;
-- (Remember to re-enable it later: ALTER TABLE daily_challenges ENABLE ROW LEVEL SECURITY;)