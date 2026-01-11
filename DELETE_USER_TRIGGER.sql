-- ============================================================================
-- ADMIN USER DELETION - Complete Solution
-- ============================================================================
-- This script sets up automatic auth user deletion when admin deletes a user
-- ============================================================================

-- Step 1: Enable the necessary extensions if not already enabled
-- (This allows us to call auth functions from SQL)
CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";

-- Step 2: Create a function to delete from auth.users
-- This function will be called by a trigger
CREATE OR REPLACE FUNCTION public.delete_user_from_auth()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER -- Run with elevated permissions
AS $$
BEGIN
  -- Delete the user from auth.users
  -- This will CASCADE delete from auth.identities and other auth tables
  DELETE FROM auth.users WHERE id = OLD.id;
  
  RETURN OLD;
END;
$$;

-- Step 3: Create a trigger that fires AFTER a user is deleted from public.users
DROP TRIGGER IF EXISTS on_user_deleted ON public.users;

CREATE TRIGGER on_user_deleted
  AFTER DELETE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.delete_user_from_auth();

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check if trigger was created successfully
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_user_deleted';

-- ============================================================================
-- TESTING INSTRUCTIONS
-- ============================================================================
-- 
-- 1. Run this script in Supabase SQL Editor
-- 2. Go to your Flutter app → Admin → Users
-- 3. Delete a user
-- 4. Check Supabase Dashboard → Authentication → Users
--    The user should be automatically removed from auth!
-- 5. Try to register with the same email → Should work! ✅
-- 
-- ============================================================================

-- Note: If you get permission errors, you may need to run this as a superuser
-- or use Supabase Dashboard → SQL Editor which runs with proper permissions
