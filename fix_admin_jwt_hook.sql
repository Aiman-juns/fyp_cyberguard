-- Add user role to JWT token
-- This function will automatically set the user's role in the JWT
-- Execute this in your Supabase SQL Editor

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  claims jsonb;
  user_role text;
BEGIN
  -- Fetch the user role from the users table
  SELECT role INTO user_role 
  FROM public.users 
  WHERE id = (event->>'user_id')::uuid;
  
  -- Set the claims
  claims := event->'claims';
  
  if user_role is not null then
    -- Set the role in the JWT
    claims := jsonb_set(claims, '{role}', to_jsonb(user_role));
  else
    -- Default to 'user' if no role found
    claims := jsonb_set(claims, '{role}', to_jsonb('user'::text));
  end if;
  
  -- Update the event object
  event := jsonb_set(event, '{claims}', claims);
  
  return event;
END;
$$;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT ALL ON ALL TABLES IN SCHEMA public TO supabase_auth_admin;

-- Note: You'll need to configure this hook in your Supabase dashboard:
-- 1. Go to Database > Webhooks
-- 2. Create a new webhook with trigger "Custom Access Token Hook"  
-- 3. Set the function to "public.custom_access_token_hook"