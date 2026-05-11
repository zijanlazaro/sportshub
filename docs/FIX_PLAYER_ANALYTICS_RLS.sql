-- ============================================================================
-- FIX: RLS policies for player_analytics AND performance_analytics
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================================

-- ── player_analytics (DATABASE_SCHEMA.sql version) ──────────────────────────

ALTER TABLE player_analytics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Team members can view player analytics"          ON player_analytics;
DROP POLICY IF EXISTS "Coaches and admins can insert player analytics"  ON player_analytics;
DROP POLICY IF EXISTS "Coaches and admins can update player analytics"  ON player_analytics;
DROP POLICY IF EXISTS "Admins can delete player analytics"              ON player_analytics;

-- SELECT: any authenticated user on the same team, or admin
CREATE POLICY "player_analytics_select" ON player_analytics
FOR SELECT USING (
  player_id IN (
    SELECT p.id FROM players p
    JOIN users u ON u.id = auth.uid()
    WHERE p.team_id = u.team_id
  )
  OR auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- INSERT: any authenticated user (coach, admin, team_manager)
CREATE POLICY "player_analytics_insert" ON player_analytics
FOR INSERT WITH CHECK (
  auth.uid() IN (
    SELECT id FROM users WHERE role IN ('admin', 'coach', 'team_manager')
  )
);

-- UPDATE: same as insert
CREATE POLICY "player_analytics_update" ON player_analytics
FOR UPDATE USING (
  auth.uid() IN (
    SELECT id FROM users WHERE role IN ('admin', 'coach', 'team_manager')
  )
)
WITH CHECK (
  auth.uid() IN (
    SELECT id FROM users WHERE role IN ('admin', 'coach', 'team_manager')
  )
);

-- DELETE: admin only
CREATE POLICY "player_analytics_delete" ON player_analytics
FOR DELETE USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- ── performance_analytics (COMPLETE_SPORTS_HUB_SCHEMA.sql version) ──────────

ALTER TABLE performance_analytics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "performance_analytics_select" ON performance_analytics;
DROP POLICY IF EXISTS "performance_analytics_insert" ON performance_analytics;
DROP POLICY IF EXISTS "performance_analytics_update" ON performance_analytics;

CREATE POLICY "performance_analytics_select" ON performance_analytics
FOR SELECT USING (
  player_id IN (
    SELECT p.id FROM players p
    JOIN users u ON u.id = auth.uid()
    WHERE p.team_id = u.team_id
  )
  OR auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

CREATE POLICY "performance_analytics_insert" ON performance_analytics
FOR INSERT WITH CHECK (
  auth.uid() IN (
    SELECT id FROM users WHERE role IN ('admin', 'coach', 'team_manager')
  )
);

CREATE POLICY "performance_analytics_update" ON performance_analytics
FOR UPDATE USING (
  auth.uid() IN (
    SELECT id FROM users WHERE role IN ('admin', 'coach', 'team_manager', 'medical_staff')
  )
)
WITH CHECK (
  auth.uid() IN (
    SELECT id FROM users WHERE role IN ('admin', 'coach', 'team_manager', 'medical_staff')
  )
);

-- ── player_stats (also needs upsert access) ──────────────────────────────────

DROP POLICY IF EXISTS "Coaches and admins can insert player stats" ON player_stats;
DROP POLICY IF EXISTS "Coaches and admins can update player stats" ON player_stats;

CREATE POLICY "player_stats_insert" ON player_stats
FOR INSERT WITH CHECK (
  auth.uid() IN (
    SELECT id FROM users WHERE role IN ('admin', 'coach', 'team_manager')
  )
);

CREATE POLICY "player_stats_update" ON player_stats
FOR UPDATE USING (
  auth.uid() IN (
    SELECT id FROM users WHERE role IN ('admin', 'coach', 'team_manager')
  )
)
WITH CHECK (
  auth.uid() IN (
    SELECT id FROM users WHERE role IN ('admin', 'coach', 'team_manager')
  )
);

SELECT 'RLS policies fixed for player_analytics, performance_analytics, player_stats' AS status;
