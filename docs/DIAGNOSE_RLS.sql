-- ============================================================================
-- DIAGNOSTIC: Run this FIRST to see what's blocking the save
-- ============================================================================

-- 1. Check your current user's role
SELECT id, email, role, team_id
FROM users
WHERE id = auth.uid();

-- 2. Check which analytics tables actually exist in your database
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('player_analytics', 'performance_analytics');

-- 3. Check existing RLS policies on both tables
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE tablename IN ('player_analytics', 'performance_analytics', 'player_stats')
ORDER BY tablename, cmd;
