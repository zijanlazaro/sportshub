-- Assign user to team to see dummy data
-- Replace 'your-user-id' with your actual user ID from auth.users

-- First, check your user ID by running this:
-- SELECT auth.uid() as your_user_id;

-- Then update your user to be part of the Lakers team:
UPDATE users 
SET team_id = '550e8400-e29b-41d4-a716-446655440001', 
    role = 'coach'
WHERE id = auth.uid();

-- Verify the update:
SELECT id, email, full_name, role, team_id FROM users WHERE id = auth.uid();

SELECT 'User assigned to Lakers team!' as message;