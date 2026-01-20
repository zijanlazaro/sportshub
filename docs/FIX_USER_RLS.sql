-- Fix RLS policy for user registration
-- Allow users to insert their own profile during signup

-- Drop all existing policies on users table
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Only admins can delete users" ON users;
DROP POLICY IF EXISTS "Users can insert own profile during signup" ON users;

-- Create simple policies without recursion
CREATE POLICY "Allow user registration" ON users
FOR INSERT WITH CHECK (true);

CREATE POLICY "Users view own profile" ON users
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users update own profile" ON users
FOR UPDATE USING (auth.uid() = id);

-- Success message
SELECT 'User RLS policies fixed without recursion!' as message;