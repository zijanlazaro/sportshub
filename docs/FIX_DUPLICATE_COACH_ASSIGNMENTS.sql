-- ============================================================================
-- FIX DUPLICATE COACH ASSIGNMENTS
-- Clean up duplicate coach assignments where one coach is assigned to multiple teams
-- ============================================================================

-- Step 1: Identify duplicate coach assignments
SELECT 
    coach_id,
    COUNT(*) as team_count,
    ARRAY_AGG(id) as team_ids,
    ARRAY_AGG(name) as team_names
FROM teams 
WHERE coach_id IS NOT NULL 
GROUP BY coach_id 
HAVING COUNT(*) > 1;

-- Step 2: For each duplicate, keep only the most recent team assignment
-- (based on updated_at timestamp) and clear the others
WITH duplicate_coaches AS (
    SELECT 
        coach_id,
        id as team_id,
        ROW_NUMBER() OVER (PARTITION BY coach_id ORDER BY updated_at DESC) as rn
    FROM teams 
    WHERE coach_id IS NOT NULL
),
teams_to_clear AS (
    SELECT team_id 
    FROM duplicate_coaches 
    WHERE rn > 1
)
UPDATE teams 
SET coach_id = NULL, 
    updated_at = NOW()
WHERE id IN (SELECT team_id FROM teams_to_clear);

-- Step 3: Verify the fix - this should return no rows
SELECT 
    coach_id,
    COUNT(*) as team_count
FROM teams 
WHERE coach_id IS NOT NULL 
GROUP BY coach_id 
HAVING COUNT(*) > 1;

-- Step 4: Update user team assignments to match their coaching assignments
-- Ensure users with role 'coach' have team_id matching the team they coach
UPDATE users 
SET team_id = (
    SELECT id 
    FROM teams 
    WHERE coach_id = users.id 
    LIMIT 1
),
updated_at = NOW()
WHERE role = 'coach' 
AND id IN (SELECT DISTINCT coach_id FROM teams WHERE coach_id IS NOT NULL);

-- Step 5: Add a unique constraint to prevent future duplicates (optional)
-- Note: This will prevent a coach from being assigned to multiple teams
-- ALTER TABLE teams ADD CONSTRAINT unique_coach_per_team UNIQUE (coach_id);

-- Step 6: Create a function to handle coach team changes properly
CREATE OR REPLACE FUNCTION handle_coach_team_change()
RETURNS TRIGGER AS $$
BEGIN
    -- If coach_id is being updated and it's not NULL
    IF NEW.coach_id IS NOT NULL AND (OLD.coach_id IS NULL OR OLD.coach_id != NEW.coach_id) THEN
        -- Clear this coach from any other teams
        UPDATE teams 
        SET coach_id = NULL, updated_at = NOW()
        WHERE coach_id = NEW.coach_id AND id != NEW.id;
        
        -- Update the user's team_id to match their coaching assignment
        UPDATE users 
        SET team_id = NEW.id, updated_at = NOW()
        WHERE id = NEW.coach_id AND role = 'coach';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 7: Create trigger to automatically handle coach assignments
DROP TRIGGER IF EXISTS trigger_coach_team_change ON teams;
CREATE TRIGGER trigger_coach_team_change
    BEFORE UPDATE ON teams
    FOR EACH ROW
    EXECUTE FUNCTION handle_coach_team_change();

-- Step 8: Verification queries
-- Check for any remaining duplicate coach assignments
SELECT 'Duplicate coach assignments:' as check_type, COUNT(*) as count
FROM (
    SELECT coach_id
    FROM teams 
    WHERE coach_id IS NOT NULL 
    GROUP BY coach_id 
    HAVING COUNT(*) > 1
) duplicates;

-- Check coach-user team alignment
SELECT 'Misaligned coach-user teams:' as check_type, COUNT(*) as count
FROM users u
JOIN teams t ON u.id = t.coach_id
WHERE u.role = 'coach' AND u.team_id != t.id;

-- Show current coach assignments
SELECT 
    t.name as team_name,
    u.full_name as coach_name,
    u.email as coach_email,
    t.updated_at as assignment_date
FROM teams t
LEFT JOIN users u ON t.coach_id = u.id
WHERE t.coach_id IS NOT NULL
ORDER BY t.name;