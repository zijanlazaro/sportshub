-- ============================================================================
-- SPORTS HUB MANAGEMENT SYSTEM - COMPLETE DATABASE SCHEMA
-- Secure, Scalable Sports Management with Advanced Analytics
-- ============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- TABLE 1: Teams (Foundation table)
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  sport TEXT NOT NULL DEFAULT 'Soccer',
  coach_id UUID,
  team_manager_id UUID,
  season TEXT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::TEXT,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 2: Users (Authentication & Roles)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'coach', 'medical_staff', 'team_manager', 'game_master', 'player')),
  team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
  active BOOLEAN DEFAULT true,
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign key constraints after users table exists
ALTER TABLE teams ADD CONSTRAINT fk_teams_coach_id FOREIGN KEY (coach_id) REFERENCES users(id);
ALTER TABLE teams ADD CONSTRAINT fk_teams_manager_id FOREIGN KEY (team_manager_id) REFERENCES users(id);

-- TABLE 3: Players (Enhanced Profile System)
CREATE TABLE players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,

  -- Basic Information
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '13 years'),
  age INTEGER GENERATED ALWAYS AS (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM date_of_birth)) STORED,
  place_of_birth TEXT,
  profile_photo_url TEXT, -- Secure upload path

  -- Physical Attributes
  height_cm DECIMAL(5,2) CHECK (height_cm > 0 AND height_cm < 300),
  weight_kg DECIMAL(5,2) CHECK (weight_kg > 0 AND weight_kg < 500),

  -- Sports Information
  position TEXT NOT NULL CHECK (position IN ('Goalkeeper', 'Defender', 'Midfielder', 'Forward', 'Center Back', 'Full Back', 'Winger', 'Striker', 'Center Midfield')),
  jersey_number INTEGER NOT NULL CHECK (jersey_number > 0 AND jersey_number < 100),
  years_active INTEGER DEFAULT 0 CHECK (years_active >= 0),

  -- Status & Performance
  status TEXT NOT NULL DEFAULT 'TRYOUT' CHECK (status IN ('TRYOUT', 'OFFICIAL_PLAYER', 'INACTIVE', 'SUSPENDED')),
  performance_rating DECIMAL(3,1) DEFAULT 0.0 CHECK (performance_rating >= 0 AND performance_rating <= 10),
  attendance_streak INTEGER DEFAULT 0,

  -- Medical Clearance
  medical_clearance BOOLEAN DEFAULT false,
  fitness_status TEXT DEFAULT 'unknown' CHECK (fitness_status IN ('excellent', 'good', 'fair', 'poor', 'unknown')),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(team_id, jersey_number)
);

-- TABLE 4: Emergency Contacts
CREATE TABLE emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  relationship TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(player_id) -- One emergency contact per player
);

-- TABLE 5: Medical Records (Highly Sensitive - Encrypted Fields)
CREATE TABLE medical_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  recorded_by UUID NOT NULL REFERENCES users(id),

  -- Medical History
  medical_conditions TEXT, -- Encrypted
  medications TEXT, -- Encrypted
  seizure_history BOOLEAN DEFAULT false,
  recent_injury TEXT, -- Last 6-12 months
  surgery_history TEXT, -- Sports-related
  pain_during_activity BOOLEAN DEFAULT false,
  blood_type TEXT CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),

  -- Current Assessment
  injury_type TEXT,
  injury_date DATE,
  severity TEXT CHECK (severity IN ('minor', 'moderate', 'severe', 'critical')),
  description TEXT,
  treatment TEXT,
  recovery_status TEXT CHECK (recovery_status IN ('cleared', 'recovering', 'chronic', 'cleared_with_restrictions')),
  clearance_to_play BOOLEAN DEFAULT false,
  restrictions TEXT,

  -- Follow-up
  expected_return_date DATE,
  actual_return_date DATE,
  follow_up_required BOOLEAN DEFAULT false,
  follow_up_date DATE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 6: Medical Documents
CREATE TABLE medical_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medical_record_id UUID NOT NULL REFERENCES medical_records(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL, -- Supabase Storage path
  file_type TEXT,
  file_size INTEGER,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 7: Player Statistics
CREATE TABLE player_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  season TEXT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::TEXT,

  -- Game Statistics
  games_played INTEGER DEFAULT 0,
  games_started INTEGER DEFAULT 0,
  minutes_played INTEGER DEFAULT 0,
  goals_scored INTEGER DEFAULT 0,
  assists INTEGER DEFAULT 0,
  shots_on_target INTEGER DEFAULT 0,
  shots_off_target INTEGER DEFAULT 0,

  -- Defensive Stats
  tackles INTEGER DEFAULT 0,
  interceptions INTEGER DEFAULT 0,
  clearances INTEGER DEFAULT 0,
  blocks INTEGER DEFAULT 0,

  -- Disciplinary
  yellow_cards INTEGER DEFAULT 0,
  red_cards INTEGER DEFAULT 0,
  fouls_committed INTEGER DEFAULT 0,
  fouls_suffered INTEGER DEFAULT 0,

  -- Performance Metrics
  pass_accuracy DECIMAL(5,2) DEFAULT 0,
  rating DECIMAL(3,1) DEFAULT 0,

  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(player_id, season)
);

-- TABLE 8: Events (Games, Training, etc.)
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(id),
  event_type TEXT NOT NULL CHECK (event_type IN ('game', 'training', 'meeting', 'medical_checkup', 'tournament')),
  title TEXT NOT NULL,
  description TEXT,
  event_date DATE NOT NULL,
  event_time TIME,
  duration_minutes INTEGER,
  location TEXT,
  opponent_name TEXT, -- For games
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 9: Event Attendance
CREATE TABLE event_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  attendance_status TEXT NOT NULL CHECK (attendance_status IN ('present', 'absent', 'excused', 'late')),
  notes TEXT,
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(event_id, player_id)
);

-- TABLE 10: Game Results
CREATE TABLE game_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID UNIQUE NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  recorded_by UUID NOT NULL REFERENCES users(id),

  -- Score
  home_score INTEGER DEFAULT 0,
  away_score INTEGER DEFAULT 0,
  result TEXT GENERATED ALWAYS AS (
    CASE
      WHEN home_score > away_score THEN 'win'
      WHEN home_score < away_score THEN 'loss'
      ELSE 'draw'
    END
  ) STORED,

  -- Game Details
  weather_conditions TEXT,
  field_conditions TEXT,
  attendance_count INTEGER,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 11: Player Game Stats
CREATE TABLE player_game_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_result_id UUID NOT NULL REFERENCES game_results(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  minutes_played INTEGER DEFAULT 0,
  goals INTEGER DEFAULT 0,
  assists INTEGER DEFAULT 0,
  shots INTEGER DEFAULT 0,
  shots_on_target INTEGER DEFAULT 0,
  tackles INTEGER DEFAULT 0,
  passes INTEGER DEFAULT 0,
  pass_accuracy DECIMAL(5,2),
  rating DECIMAL(3,1),
  UNIQUE(game_result_id, player_id)
);

-- TABLE 12: Game Violations
CREATE TABLE game_violations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_result_id UUID NOT NULL REFERENCES game_results(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  recorded_by UUID NOT NULL REFERENCES users(id),

  violation_type TEXT NOT NULL CHECK (violation_type IN (
    'physical_contact', 'holding', 'obstruction', 'handball',
    'offside', 'dissent', 'unsporting_behavior', 'other'
  )),
  card_type TEXT CHECK (card_type IN ('yellow', 'red', 'none')),
  description TEXT,
  minute_occurred INTEGER CHECK (minute_occurred > 0 AND minute_occurred <= 120),
  incident_details TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 13: Performance Analytics
CREATE TABLE performance_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,

  -- Attendance & Training
  training_attendance_rate DECIMAL(5,2) DEFAULT 0,
  game_participation_rate DECIMAL(5,2) DEFAULT 0,

  -- Performance Trends
  current_rating DECIMAL(3,1) DEFAULT 0,
  rating_trend TEXT CHECK (rating_trend IN ('improving', 'stable', 'declining')),
  consistency_score DECIMAL(3,1) DEFAULT 0,

  -- Health & Fitness
  injury_days_lost INTEGER DEFAULT 0,
  fitness_score DECIMAL(3,1) DEFAULT 0,
  medical_clearance_status BOOLEAN DEFAULT false,

  -- Predictions
  predicted_rating DECIMAL(3,1),
  risk_level TEXT CHECK (risk_level IN ('low', 'medium', 'high')),
  recommendation TEXT CHECK (recommendation IN ('starter', 'bench', 'monitor', 'rest')),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(player_id, date)
);

-- TABLE 14: Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id),
  notification_type TEXT NOT NULL CHECK (notification_type IN (
    'injury_alert', 'suspension', 'promotion', 'training_reminder',
    'game_reminder', 'medical_checkup', 'performance_alert'
  )),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  read BOOLEAN DEFAULT false,
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  related_record_id UUID, -- Can reference various tables
  related_record_type TEXT, -- 'player', 'event', 'medical_record', etc.
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 15: Audit Logs
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  table_name TEXT NOT NULL,
  record_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- ============================================================================

-- Core entity indexes
CREATE INDEX idx_users_team_id ON users(team_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(active);
CREATE INDEX idx_users_email ON users(email);

CREATE INDEX idx_players_team_id ON players(team_id);
CREATE INDEX idx_players_user_id ON players(user_id);
CREATE INDEX idx_players_status ON players(status);
CREATE INDEX idx_players_position ON players(position);
CREATE INDEX idx_players_medical_clearance ON players(medical_clearance);

CREATE INDEX idx_events_team_id ON events(team_id);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_date ON events(event_date);
CREATE INDEX idx_events_status ON events(status);

CREATE INDEX idx_medical_records_player_id ON medical_records(player_id);
CREATE INDEX idx_medical_records_clearance ON medical_records(clearance_to_play);
CREATE INDEX idx_medical_records_severity ON medical_records(severity);

CREATE INDEX idx_player_stats_player_id ON player_stats(player_id);
CREATE INDEX idx_player_stats_season ON player_stats(season);

CREATE INDEX idx_game_results_event_id ON game_results(event_id);
CREATE INDEX idx_player_game_stats_game ON player_game_stats(game_result_id);
CREATE INDEX idx_player_game_stats_player ON player_game_stats(player_id);

CREATE INDEX idx_performance_analytics_player ON performance_analytics(player_id);
CREATE INDEX idx_performance_analytics_date ON performance_analytics(date);

CREATE INDEX idx_notifications_recipient ON notifications(recipient_id);
CREATE INDEX idx_notifications_read ON notifications(read);
CREATE INDEX idx_notifications_type ON notifications(notification_type);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_table ON audit_logs(table_name);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);

-- ============================================================================
-- TRIGGERS FOR AUTOMATION
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON teams FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_players_updated_at BEFORE UPDATE ON players FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_game_results_updated_at BEFORE UPDATE ON game_results FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_performance_analytics_updated_at BEFORE UPDATE ON performance_analytics FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, table_name, record_id, old_values, new_values)
  VALUES (
    auth.uid(),
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    CASE WHEN TG_OP != 'INSERT' THEN to_jsonb(OLD) ELSE NULL END,
    CASE WHEN TG_OP != 'DELETE' THEN to_jsonb(NEW) ELSE NULL END
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply audit triggers to sensitive tables
CREATE TRIGGER audit_players AFTER INSERT OR UPDATE OR DELETE ON players FOR EACH ROW EXECUTE FUNCTION audit_trigger();
CREATE TRIGGER audit_medical_records AFTER INSERT OR UPDATE OR DELETE ON medical_records FOR EACH ROW EXECUTE FUNCTION audit_trigger();
CREATE TRIGGER audit_game_violations AFTER INSERT OR UPDATE OR DELETE ON game_violations FOR EACH ROW EXECUTE FUNCTION audit_trigger();

-- Function to auto-promote players based on attendance
CREATE OR REPLACE FUNCTION check_player_promotion()
RETURNS TRIGGER AS $$
BEGIN
  -- If attendance status is 'present' and player is TRYOUT
  IF NEW.attendance_status = 'present' AND
     EXISTS (SELECT 1 FROM players WHERE id = NEW.player_id AND status = 'TRYOUT') THEN

    -- Check if player has 3 consecutive present attendances
    WITH recent_attendance AS (
      SELECT ea.attendance_status,
             ROW_NUMBER() OVER (PARTITION BY ea.player_id ORDER BY e.event_date DESC) as rn
      FROM event_attendance ea
      JOIN events e ON ea.event_id = e.id
      WHERE ea.player_id = NEW.player_id
      AND e.event_type IN ('training', 'game')
      ORDER BY e.event_date DESC
      LIMIT 3
    )
    UPDATE players
    SET status = 'OFFICIAL_PLAYER',
        updated_at = NOW()
    WHERE id = NEW.player_id
    AND status = 'TRYOUT'
    AND (
      SELECT COUNT(*) FROM recent_attendance WHERE attendance_status = 'present'
    ) >= 3;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_player_promotion
AFTER INSERT OR UPDATE ON event_attendance
FOR EACH ROW EXECUTE FUNCTION check_player_promotion();

-- Function to update player attendance streak
CREATE OR REPLACE FUNCTION update_attendance_streak()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.attendance_status = 'present' THEN
    UPDATE players SET attendance_streak = attendance_streak + 1 WHERE id = NEW.player_id;
  ELSE
    UPDATE players SET attendance_streak = 0 WHERE id = NEW.player_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_streak
AFTER INSERT ON event_attendance
FOR EACH ROW EXECUTE FUNCTION update_attendance_streak();

-- ============================================================================
-- VIEWS FOR ANALYTICS AND DASHBOARDS
-- ============================================================================

-- Player availability and medical status view
CREATE VIEW player_availability_status AS
SELECT
  p.id,
  p.first_name,
  p.last_name,
  p.jersey_number,
  p.position,
  p.status,
  p.medical_clearance,
  p.fitness_status,
  p.attendance_streak,
  COALESCE(mr.clearance_to_play, true) as current_clearance,
  mr.recovery_status,
  mr.restrictions,
  mr.expected_return_date,
  CASE
    WHEN p.medical_clearance = false THEN 'Not Cleared'
    WHEN mr.clearance_to_play = false THEN 'Medical Restriction'
    WHEN p.status = 'SUSPENDED' THEN 'Suspended'
    WHEN p.attendance_streak >= 3 AND p.status = 'TRYOUT' THEN 'Eligible for Promotion'
    ELSE 'Available'
  END as availability_status
FROM players p
LEFT JOIN LATERAL (
  SELECT * FROM medical_records
  WHERE player_id = p.id
  ORDER BY created_at DESC
  LIMIT 1
) mr ON true;

-- Team performance dashboard
CREATE VIEW team_performance_dashboard AS
SELECT
  t.id as team_id,
  t.name as team_name,
  COUNT(p.id) as total_players,
  COUNT(CASE WHEN p.status = 'OFFICIAL_PLAYER' THEN 1 END) as official_players,
  COUNT(CASE WHEN p.status = 'TRYOUT' THEN 1 END) as tryout_players,
  COUNT(CASE WHEN pas.availability_status = 'Available' THEN 1 END) as available_players,
  ROUND(AVG(pa.current_rating), 2) as avg_team_rating,
  ROUND(AVG(pa.training_attendance_rate), 2) as avg_attendance_rate,
  COUNT(CASE WHEN pa.risk_level = 'high' THEN 1 END) as high_risk_players
FROM teams t
LEFT JOIN players p ON t.id = p.team_id
LEFT JOIN player_availability_status pas ON p.id = pas.id
LEFT JOIN performance_analytics pa ON p.id = pa.player_id AND pa.date = CURRENT_DATE
GROUP BY t.id, t.name;

-- Player ranking view
CREATE VIEW player_ranking AS
SELECT
  p.*,
  ps.games_played,
  ps.goals_scored,
  ps.assists,
  ps.rating,
  pa.predicted_rating,
  pa.risk_level,
  pa.recommendation,
  RANK() OVER (PARTITION BY p.team_id ORDER BY ps.rating DESC, ps.goals_scored DESC) as team_rank
FROM players p
LEFT JOIN player_stats ps ON p.id = ps.player_id
LEFT JOIN performance_analytics pa ON p.id = pa.player_id AND pa.date = CURRENT_DATE
ORDER BY p.team_id, team_rank;

-- Game violations summary
CREATE VIEW game_violations_summary AS
SELECT
  gv.game_result_id,
  e.title as game_title,
  e.event_date,
  p.first_name || ' ' || p.last_name as player_name,
  gv.violation_type,
  gv.card_type,
  gv.minute_occurred,
  gv.description,
  u.full_name as recorded_by
FROM game_violations gv
JOIN player_game_stats pgs ON gv.player_id = pgs.player_id AND gv.game_result_id = pgs.game_result_id
JOIN players p ON pgs.player_id = p.id
JOIN game_results gr ON gv.game_result_id = gr.id
JOIN events e ON gr.event_id = e.id
JOIN users u ON gv.recorded_by = u.id
ORDER BY e.event_date DESC, gv.minute_occurred;

-- Performance prediction view
CREATE VIEW performance_predictions AS
SELECT
  p.id,
  p.first_name || ' ' || p.last_name as player_name,
  p.position,
  pa.current_rating,
  pa.predicted_rating,
  pa.risk_level,
  pa.recommendation,
  pa.rating_trend,
  pa.consistency_score,
  CASE
    WHEN pa.predicted_rating > pa.current_rating THEN 'Expected Improvement'
    WHEN pa.predicted_rating < pa.current_rating THEN 'Potential Decline'
    ELSE 'Stable Performance'
  END as prediction_summary
FROM players p
JOIN performance_analytics pa ON p.id = pa.player_id AND pa.date = CURRENT_DATE
ORDER BY pa.predicted_rating DESC;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_game_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_violations ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- TEAMS POLICIES
CREATE POLICY "teams_select" ON teams FOR SELECT USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach', 'team_manager')) OR
  team_id IN (SELECT team_id FROM users WHERE id = auth.uid())
);

CREATE POLICY "teams_insert" ON teams FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

CREATE POLICY "teams_update" ON teams FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin') OR
  coach_id = auth.uid() OR team_manager_id = auth.uid()
);

-- USERS POLICIES
CREATE POLICY "users_select_own" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "users_select_team" ON users FOR SELECT USING (
  team_id IN (SELECT team_id FROM users WHERE id = auth.uid()) OR
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

CREATE POLICY "users_update_own" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "users_insert_admin" ON users FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- PLAYERS POLICIES
CREATE POLICY "players_select_team" ON players FOR SELECT USING (
  team_id IN (SELECT team_id FROM users WHERE id = auth.uid()) OR
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

CREATE POLICY "players_insert_coach" ON players FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

CREATE POLICY "players_update_coach" ON players FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach')) OR
  team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND role = 'coach')
);

-- EMERGENCY CONTACTS POLICIES (Medical Staff + Admin Only)
CREATE POLICY "emergency_contacts_select" ON emergency_contacts FOR SELECT USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff')) OR
  player_id IN (SELECT id FROM players WHERE user_id = auth.uid())
);

CREATE POLICY "emergency_contacts_insert" ON emergency_contacts FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

CREATE POLICY "emergency_contacts_update" ON emergency_contacts FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

-- MEDICAL RECORDS POLICIES (Highly Restricted)
CREATE POLICY "medical_records_select" ON medical_records FOR SELECT USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff')) OR
  player_id IN (SELECT id FROM players WHERE user_id = auth.uid())
);

CREATE POLICY "medical_records_insert" ON medical_records FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

CREATE POLICY "medical_records_update" ON medical_records FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

-- MEDICAL DOCUMENTS POLICIES
CREATE POLICY "medical_documents_select" ON medical_documents FOR SELECT USING (
  medical_record_id IN (
    SELECT id FROM medical_records WHERE
    recorded_by = auth.uid() OR
    auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff')) OR
    player_id IN (SELECT id FROM players WHERE user_id = auth.uid())
  )
);

CREATE POLICY "medical_documents_insert" ON medical_documents FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

-- EVENTS POLICIES
CREATE POLICY "events_select_team" ON events FOR SELECT USING (
  team_id IN (SELECT team_id FROM users WHERE id = auth.uid()) OR
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

CREATE POLICY "events_insert_coach" ON events FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

CREATE POLICY "events_update_coach" ON events FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach')) OR
  created_by = auth.uid()
);

-- GAME RESULTS POLICIES (Game Masters + Coaches)
CREATE POLICY "game_results_select" ON game_results FOR SELECT USING (
  event_id IN (SELECT id FROM events WHERE team_id IN (SELECT team_id FROM users WHERE id = auth.uid())) OR
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach', 'game_master'))
);

CREATE POLICY "game_results_insert" ON game_results FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'game_master'))
);

CREATE POLICY "game_results_update" ON game_results FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'game_master'))
);

-- GAME VIOLATIONS POLICIES
CREATE POLICY "game_violations_select" ON game_violations FOR SELECT USING (
  game_result_id IN (SELECT id FROM game_results WHERE event_id IN (
    SELECT id FROM events WHERE team_id IN (SELECT team_id FROM users WHERE id = auth.uid())
  )) OR auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach', 'game_master'))
);

CREATE POLICY "game_violations_insert" ON game_violations FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'game_master'))
);

-- PERFORMANCE ANALYTICS POLICIES
CREATE POLICY "performance_analytics_select" ON performance_analytics FOR SELECT USING (
  player_id IN (SELECT id FROM players WHERE team_id IN (SELECT team_id FROM users WHERE id = auth.uid())) OR
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

CREATE POLICY "performance_analytics_insert" ON performance_analytics FOR INSERT WITH CHECK (true); -- Allow system inserts

CREATE POLICY "performance_analytics_update" ON performance_analytics FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach', 'medical_staff'))
);

-- NOTIFICATIONS POLICIES
CREATE POLICY "notifications_select_own" ON notifications FOR SELECT USING (recipient_id = auth.uid());

CREATE POLICY "notifications_insert_system" ON notifications FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach', 'medical_staff'))
);

CREATE POLICY "notifications_update_own" ON notifications FOR UPDATE USING (recipient_id = auth.uid());

-- AUDIT LOGS POLICIES (Admin Only)
CREATE POLICY "audit_logs_select_admin" ON audit_logs FOR SELECT USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- ============================================================================
-- FUNCTIONS FOR BUSINESS LOGIC
-- ============================================================================

-- Function to calculate player performance rating
CREATE OR REPLACE FUNCTION calculate_player_rating(player_uuid UUID)
RETURNS DECIMAL(3,1) AS $$
DECLARE
  total_games INTEGER;
  avg_goals DECIMAL;
  avg_assists DECIMAL;
  attendance_rate DECIMAL;
  rating DECIMAL(3,1);
BEGIN
  SELECT
    COALESCE(ps.games_played, 0),
    COALESCE(ps.goals_scored::DECIMAL / NULLIF(ps.games_played, 0), 0),
    COALESCE(ps.assists::DECIMAL / NULLIF(ps.games_played, 0), 0),
    COALESCE(pa.training_attendance_rate, 0)
  INTO total_games, avg_goals, avg_assists, attendance_rate
  FROM players p
  LEFT JOIN player_stats ps ON p.id = ps.player_id
  LEFT JOIN performance_analytics pa ON p.id = pa.player_id AND pa.date = CURRENT_DATE
  WHERE p.id = player_uuid;

  -- Calculate rating based on performance metrics
  rating := (
    (avg_goals * 2) + (avg_assists * 1.5) + (attendance_rate / 10) + (total_games / 10)
  )::DECIMAL(3,1);

  -- Cap at 10.0
  IF rating > 10.0 THEN rating := 10.0; END IF;
  IF rating < 0.0 THEN rating := 0.0; END IF;

  RETURN rating;
END;
$$ LANGUAGE plpgsql;

-- Function to predict player performance
CREATE OR REPLACE FUNCTION predict_player_performance(player_uuid UUID)
RETURNS TABLE(predicted_rating DECIMAL, risk_level TEXT, recommendation TEXT) AS $$
DECLARE
  current_rating DECIMAL;
  attendance_trend DECIMAL;
  injury_history INTEGER;
  consistency DECIMAL;
BEGIN
  -- Get current metrics
  SELECT
    COALESCE(pa.current_rating, 0),
    COALESCE(pa.training_attendance_rate, 0),
    COALESCE(pa.injury_days_lost, 0),
    COALESCE(pa.consistency_score, 5.0)
  INTO current_rating, attendance_trend, injury_history, consistency
  FROM performance_analytics pa
  WHERE pa.player_id = player_uuid AND pa.date = CURRENT_DATE;

  -- Calculate predicted rating
  predicted_rating := current_rating + (attendance_trend - 50) / 20.0 - (injury_history / 30.0) + (consistency - 5.0) / 2.0;

  -- Determine risk level
  IF injury_history > 30 OR consistency < 3.0 THEN
    risk_level := 'high';
  ELSIF injury_history > 15 OR consistency < 5.0 THEN
    risk_level := 'medium';
  ELSE
    risk_level := 'low';
  END IF;

  -- Determine recommendation
  IF predicted_rating >= 7.0 AND risk_level = 'low' THEN
    recommendation := 'starter';
  ELSIF predicted_rating >= 5.0 AND risk_level != 'high' THEN
    recommendation := 'bench';
  ELSE
    recommendation := 'monitor';
  END IF;

  RETURN QUERY SELECT predicted_rating::DECIMAL(3,1), risk_level, recommendation;
END;
$$ LANGUAGE plpgsql;

-- Function to create notification
CREATE OR REPLACE FUNCTION create_notification(
  recipient_uuid UUID,
  sender_uuid UUID DEFAULT NULL,
  notif_type TEXT,
  notif_title TEXT,
  notif_message TEXT,
  notif_priority TEXT DEFAULT 'normal',
  related_id UUID DEFAULT NULL,
  related_type TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  notif_id UUID;
BEGIN
  INSERT INTO notifications (
    recipient_id, sender_id, notification_type, title, message,
    priority, related_record_id, related_record_type
  ) VALUES (
    recipient_uuid, sender_uuid, notif_type, notif_title, notif_message,
    notif_priority, related_id, related_type
  ) RETURNING id INTO notif_id;

  RETURN notif_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- DATA VALIDATION CONSTRAINTS
-- ============================================================================

-- Ensure jersey numbers are unique per team
ALTER TABLE players ADD CONSTRAINT unique_jersey_per_team UNIQUE(team_id, jersey_number);

-- Ensure one emergency contact per player
ALTER TABLE emergency_contacts ADD CONSTRAINT one_contact_per_player UNIQUE(player_id);

-- Ensure game results are unique per event
ALTER TABLE game_results ADD CONSTRAINT one_result_per_event UNIQUE(event_id);

-- Ensure player game stats are unique per game
ALTER TABLE player_game_stats ADD CONSTRAINT one_stat_per_player_game UNIQUE(game_result_id, player_id);

-- ============================================================================
-- INITIAL DATA SEEDING (Optional Examples)
-- ============================================================================

-- Insert sample roles check
INSERT INTO users (id, email, full_name, first_name, last_name, role, active)
SELECT
  gen_random_uuid(),
  'admin@sportshub.com',
  'System Administrator',
  'System',
  'Administrator',
  'admin',
  true
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@sportshub.com');

-- Success message
SELECT 'Sports Hub Management System schema created successfully!' as status;</content>
<parameter name="filePath">c:\Users\ACER\Downloads\sportshub\sportshub\sportshub\docs\COMPLETE_SPORTS_HUB_SCHEMA.sql