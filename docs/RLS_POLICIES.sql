-- ============================================================================
-- SPORTS HUB - ROW LEVEL SECURITY (RLS) POLICIES
-- Implements role-based access control using Supabase RLS
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

-- Admins can see all users; others see only their own
CREATE POLICY "Users can view own profile" ON users
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON users
FOR SELECT USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON users
FOR UPDATE USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Only admins can delete users
CREATE POLICY "Only admins can delete users" ON users
FOR DELETE USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- ============================================================================
-- TEAMS TABLE POLICIES
-- ============================================================================

-- All authenticated users can view teams
CREATE POLICY "Authenticated users can view teams" ON teams
FOR SELECT USING (auth.role() = 'authenticated');

-- Only admins and coaches can create teams
CREATE POLICY "Admins and coaches can create teams" ON teams
FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

-- Coaches can update their own team; admins can update all
CREATE POLICY "Coaches update own team; admins update all teams" ON teams
FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  OR coach_id = auth.uid()
)
WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  OR coach_id = auth.uid()
);

-- Only admins can delete teams
CREATE POLICY "Only admins can delete teams" ON teams
FOR DELETE USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- ============================================================================
-- PLAYERS TABLE POLICIES
-- ============================================================================

-- All team members can view players in their team
CREATE POLICY "Team members can view team players" ON players
FOR SELECT USING (
  team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL)
  OR auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- Coaches and admins can insert players
CREATE POLICY "Coaches and admins can insert players" ON players
FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

-- Coaches can update players in their team; admins can update all
CREATE POLICY "Coaches update own team players; admins update all" ON players
FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  OR team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND role = 'coach')
)
WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  OR team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND role = 'coach')
);

-- Only admins and coaches can delete players
CREATE POLICY "Admins and coaches can delete players" ON players
FOR DELETE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

-- ============================================================================
-- PLAYER STATS TABLE POLICIES
-- ============================================================================

-- All team members can view player stats
CREATE POLICY "Team members can view player stats" ON player_stats
FOR SELECT USING (
  player_id IN (SELECT id FROM players WHERE team_id IN (
    SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL
  ))
  OR auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- Coaches and admins can insert stats
CREATE POLICY "Coaches and admins can insert player stats" ON player_stats
FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

-- Coaches and admins can update stats
CREATE POLICY "Coaches and admins can update player stats" ON player_stats
FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
)
WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

-- ============================================================================
-- MEDICAL RECORDS TABLE POLICIES
-- ============================================================================

-- Medical staff and admins can view all medical records
CREATE POLICY "Medical staff and admins can view medical records" ON medical_records
FOR SELECT USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

-- Players can view their own medical records
CREATE POLICY "Players can view own medical records" ON medical_records
FOR SELECT USING (
  player_id IN (SELECT id FROM players WHERE user_id = auth.uid())
);

-- Medical staff and admins can insert medical records
CREATE POLICY "Medical staff and admins can insert medical records" ON medical_records
FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

-- Only medical staff and admins can update medical records
CREATE POLICY "Medical staff and admins can update medical records" ON medical_records
FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
)
WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

-- ============================================================================
-- MEDICAL DOCUMENTS TABLE POLICIES
-- ============================================================================

-- Same as medical records - medical staff/admins and players (own data)
CREATE POLICY "Medical staff and admins can view medical documents" ON medical_documents
FOR SELECT USING (
  medical_record_id IN (
    SELECT id FROM medical_records WHERE 
    (recorded_by = auth.uid() OR auth.uid() IN (
      SELECT id FROM users WHERE role IN ('admin', 'medical_staff')
    ))
  )
);

CREATE POLICY "Players can view own medical documents" ON medical_documents
FOR SELECT USING (
  medical_record_id IN (
    SELECT id FROM medical_records WHERE player_id IN (
      SELECT id FROM players WHERE user_id = auth.uid()
    )
  )
);

CREATE POLICY "Medical staff and admins can insert medical documents" ON medical_documents
FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

-- ============================================================================
-- TRAINING SESSIONS TABLE POLICIES
-- ============================================================================

-- Team members can view training sessions for their team
CREATE POLICY "Team members can view team training sessions" ON training_sessions
FOR SELECT USING (
  team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL)
  OR auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- Only coaches and admins can create training sessions
CREATE POLICY "Coaches and admins can create training sessions" ON training_sessions
FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

-- Coaches can update their own team's sessions; admins update all
CREATE POLICY "Coaches update own team sessions; admins update all" ON training_sessions
FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  OR created_by = auth.uid()
)
WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  OR created_by = auth.uid()
);

-- ============================================================================
-- TRAINING ATTENDANCE TABLE POLICIES
-- ============================================================================

-- Team members can view attendance records for their team
CREATE POLICY "Team members can view training attendance" ON training_attendance
FOR SELECT USING (
  training_session_id IN (
    SELECT id FROM training_sessions WHERE team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL
    )
  )
  OR auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- Coaches and admins can insert attendance records
CREATE POLICY "Coaches and admins can insert attendance" ON training_attendance
FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

-- Coaches and admins can update attendance records
CREATE POLICY "Coaches and admins can update attendance" ON training_attendance
FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
)
WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

-- ============================================================================
-- GAMES TABLE POLICIES
-- ============================================================================

-- Team members can view games for their team
CREATE POLICY "Team members can view games" ON games
FOR SELECT USING (
  team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL)
  OR auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- Coaches and admins can create games
CREATE POLICY "Coaches and admins can create games" ON games
FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

-- Coaches can update their team's games; admins update all
CREATE POLICY "Coaches update own team games; admins update all" ON games
FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  OR team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND role = 'coach')
)
WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  OR team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND role = 'coach')
);

-- ============================================================================
-- EVENTS TABLE POLICIES
-- ============================================================================

-- Team members can view events for their team
CREATE POLICY "Team members can view events" ON events
FOR SELECT USING (
  team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL)
  OR auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- Coaches and admins can create events
CREATE POLICY "Coaches and admins can create events" ON events
FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

-- Coaches can update their team's events; admins update all
CREATE POLICY "Coaches update own team events; admins update all" ON events
FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  OR team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND role = 'coach')
)
WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  OR team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND role = 'coach')
);

-- ============================================================================
-- AUDIT LOGS TABLE POLICIES
-- ============================================================================

-- Only admins can view audit logs
CREATE POLICY "Only admins can view audit logs" ON audit_logs
FOR SELECT USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- No direct insertion allowed - managed by triggers only
-- Admins can read audit_logs for accountability
