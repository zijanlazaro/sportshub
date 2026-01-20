-- Manual profile update for cleycley@gmail.com
-- Run this in your Supabase SQL editor

-- Update your user profile directly
UPDATE users 
SET 
  first_name = 'Cleycley',
  last_name = 'Coach', 
  role = 'coach',
  team_id = '550e8400-e29b-41d4-a716-446655440001', -- Lakers team ID
  updated_at = NOW()
WHERE email = 'cleycley@gmail.com';

-- Verify the update
SELECT id, email, first_name, last_name, role, team_id 
FROM users 
WHERE email = 'cleycley@gmail.com';

SELECT 'Profile updated for cleycley@gmail.com!' as message;