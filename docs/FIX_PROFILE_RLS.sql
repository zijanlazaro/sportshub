-- Fix RLS policies specifically for profile updates
-- This ensures users can update their own profiles without logout issues

-- Drop existing user policies that might be causing issues
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Allow user registration" ON users;

-- Create simplified, working policies for users table
CREATE POLICY "users_select_own" ON users 
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own" ON users 
FOR UPDATE USING (auth.uid() = id) 
WITH CHECK (auth.uid() = id);

CREATE POLICY "users_insert_registration" ON users 
FOR INSERT WITH CHECK (auth.uid() = id);

-- Ensure teams can be viewed by authenticated users
DROP POLICY IF EXISTS "Anyone can view teams" ON teams;
DROP POLICY IF EXISTS "Authenticated users can view teams" ON teams;

CREATE POLICY "teams_select_authenticated" ON teams 
FOR SELECT USING (auth.role() = 'authenticated');

SELECT 'Profile RLS policies fixed - users can now update profiles without logout!' as message;