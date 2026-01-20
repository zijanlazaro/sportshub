-- Update users table to have separate name fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS middle_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS suffix TEXT;

-- Update existing users to split full_name if it exists
UPDATE users 
SET first_name = SPLIT_PART(full_name, ' ', 1),
    last_name = SPLIT_PART(full_name, ' ', 2)
WHERE full_name IS NOT NULL AND first_name IS NULL;

SELECT 'User name fields updated!' as message;