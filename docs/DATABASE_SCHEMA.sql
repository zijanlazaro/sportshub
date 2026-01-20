-- ============================================================================
-- SPORTS HUB DATABASE SCHEMA - REVAMPED
-- Athlete Management & Analytics System with Medical Availability Tracking
-- ============================================================================

-- TABLE 1: Teams (Created first - no dependencies)
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  sport TEXT NOT NULL,
  coach_id UUID,
  season TEXT DEFAULT '2024',
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 2: Users (Extended Auth) - NO EMAIL CONFIRMATION REQUIRED
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'coach', 'medical_staff', 'player')),
  team_id UUID REFERENCES teams(id),
  active BOOLEAN DEFAULT true,
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add the foreign key constraint to teams.coach_id after users table exists
ALTER TABLE teams ADD CONSTRAINT fk_teams_coach_id FOREIGN KEY (coach_id) REFERENCES users(id);

-- TABLE 3: Players
-- Player profiles and basic information
CREATE TABLE players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  age INT CHECK (age >= 13 AND age <= 100),
  position TEXT NOT NULL, -- "Forward", "Guard", etc.
  jersey_number INT NOT NULL,
  height_cm DECIMAL(5, 2),
  weight_kg DECIMAL(6, 2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(team_id, jersey_number)
);

-- TABLE 4: Player Statistics
-- Performance metrics for each player
CREATE TABLE player_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  games_played INT DEFAULT 0,
  points_scored INT DEFAULT 0,
  assists INT DEFAULT 0,
  fouls_committed INT DEFAULT 0,
  injuries_count INT DEFAULT 0,
  avg_performance_rating DECIMAL(3, 1) DEFAULT 0.0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 5: Medical Records - Enhanced for Availability Tracking
CREATE TABLE medical_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  recorded_by UUID NOT NULL REFERENCES users(id),
  injury_type TEXT,
  injury_date DATE,
  description TEXT,
  severity TEXT CHECK (severity IN ('minor', 'moderate', 'severe', 'critical')),
  recovery_status TEXT CHECK (recovery_status IN ('recovering', 'cleared', 'cleared_with_restrictions')),
  clearance_to_play BOOLEAN DEFAULT FALSE,
  expected_return_date DATE,
  actual_return_date DATE,
  restrictions TEXT,
  follow_up_required BOOLEAN DEFAULT FALSE,
  follow_up_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 6: Medical Documents
-- Uploaded medical files (e.g., X-rays, reports)
CREATE TABLE medical_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medical_record_id UUID NOT NULL REFERENCES medical_records(id) ON DELETE CASCADE,
  file_path TEXT NOT NULL, -- Path in Supabase Storage
  file_name TEXT NOT NULL,
  file_type TEXT, -- MIME type
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 7: Training Sessions
-- Coach-created training events
CREATE TABLE training_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(id),
  session_date DATE NOT NULL,
  session_time TIME,
  location TEXT,
  topic TEXT, -- e.g., "Defensive drills"
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 8: Training Attendance
-- Attendance records for each training session
CREATE TABLE training_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  training_session_id UUID NOT NULL REFERENCES training_sessions(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  attendance_status TEXT NOT NULL CHECK (attendance_status IN ('present', 'absent', 'excused')),
  notes TEXT,
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(training_session_id, player_id)
);

-- TABLE 9: Games (Matches)
-- Scheduled games and match information
CREATE TABLE games (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  opponent_name TEXT NOT NULL,
  game_date DATE NOT NULL,
  game_time TIME,
  location TEXT,
  status TEXT NOT NULL CHECK (status IN ('upcoming', 'completed', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 10: Events
-- General events (drills, meetings, etc.)
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(id),
  event_title TEXT NOT NULL,
  event_description TEXT,
  event_date DATE NOT NULL,
  event_time TIME,
  event_type TEXT, -- "training", "game", "meeting", "medical_checkup"
  location TEXT,
  status TEXT CHECK (status IN ('upcoming', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 11: Audit Logs
-- Track all changes for audit purposes
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  action TEXT NOT NULL, -- "create", "update", "delete"
  table_name TEXT NOT NULL,
  record_id UUID,
  old_values JSONB,
  new_values JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 12: Player Analytics
-- Comprehensive analytics and performance metrics
CREATE TABLE player_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  training_attendance_rate DECIMAL(5,2) DEFAULT 0,
  game_participation_rate DECIMAL(5,2) DEFAULT 0,
  injury_days_lost INT DEFAULT 0,
  fitness_score DECIMAL(3,1) DEFAULT 0,
  availability_status TEXT CHECK (availability_status IN ('available', 'injured', 'restricted', 'suspended')) DEFAULT 'available',
  performance_trend TEXT CHECK (performance_trend IN ('improving', 'stable', 'declining')) DEFAULT 'stable',
  medical_clearance_date DATE,
  next_medical_checkup DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(player_id, date)
);

-- TABLE 13: Team Statistics
-- Team-level performance and analytics
CREATE TABLE team_statistics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_players INT DEFAULT 0,
  available_players INT DEFAULT 0,
  injured_players INT DEFAULT 0,
  restricted_players INT DEFAULT 0,
  avg_team_fitness DECIMAL(3,1) DEFAULT 0,
  injury_rate DECIMAL(5,2) DEFAULT 0,
  training_attendance_avg DECIMAL(5,2) DEFAULT 0,
  games_won INT DEFAULT 0,
  games_lost INT DEFAULT 0,
  games_drawn INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(team_id, date)
);

-- TABLE 14: Medical Assessments
-- Regular medical checkups and fitness assessments
CREATE TABLE medical_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  assessed_by UUID NOT NULL REFERENCES users(id),
  assessment_date DATE NOT NULL,
  assessment_type TEXT CHECK (assessment_type IN ('routine', 'pre_season', 'post_injury', 'fitness_test')),
  overall_fitness DECIMAL(3,1) CHECK (overall_fitness >= 0 AND overall_fitness <= 10),
  cardiovascular_score DECIMAL(3,1) CHECK (cardiovascular_score >= 0 AND cardiovascular_score <= 10),
  strength_score DECIMAL(3,1) CHECK (strength_score >= 0 AND strength_score <= 10),
  flexibility_score DECIMAL(3,1) CHECK (flexibility_score >= 0 AND flexibility_score <= 10),
  injury_risk_level TEXT CHECK (injury_risk_level IN ('low', 'medium', 'high')),
  recommendations TEXT,
  cleared_for_full_activity BOOLEAN DEFAULT FALSE,
  restrictions TEXT,
  next_assessment_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX idx_users_team_id ON users(team_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(active);
CREATE INDEX idx_players_team_id ON players(team_id);
CREATE INDEX idx_players_user_id ON players(user_id);
CREATE INDEX idx_player_stats_player_id ON player_stats(player_id);
CREATE INDEX idx_medical_records_player_id ON medical_records(player_id);
CREATE INDEX idx_medical_records_clearance ON medical_records(clearance_to_play);
CREATE INDEX idx_training_sessions_team_id ON training_sessions(team_id);
CREATE INDEX idx_training_attendance_session_id ON training_attendance(training_session_id);
CREATE INDEX idx_games_team_id ON games(team_id);
CREATE INDEX idx_events_team_id ON events(team_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_player_analytics_player_id ON player_analytics(player_id);
CREATE INDEX idx_player_analytics_date ON player_analytics(date);
CREATE INDEX idx_player_analytics_availability ON player_analytics(availability_status);
CREATE INDEX idx_team_statistics_team_id ON team_statistics(team_id);
CREATE INDEX idx_team_statistics_date ON team_statistics(date);
CREATE INDEX idx_medical_assessments_player_id ON medical_assessments(player_id);
CREATE INDEX idx_medical_assessments_date ON medical_assessments(assessment_date);

-- ============================================================================
-- TRIGGERS FOR AUDIT LOGGING
-- ============================================================================

CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, table_name, record_id, old_values, new_values)
  VALUES (
    auth.uid(),
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    to_jsonb(OLD),
    to_jsonb(NEW)
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Audit trigger for players
CREATE TRIGGER audit_players AFTER INSERT OR UPDATE OR DELETE ON players
FOR EACH ROW EXECUTE FUNCTION audit_trigger();

-- Audit trigger for medical records
CREATE TRIGGER audit_medical_records AFTER INSERT OR UPDATE OR DELETE ON medical_records
FOR EACH ROW EXECUTE FUNCTION audit_trigger();

-- ============================================================================
-- VIEWS FOR CONVENIENCE AND ANALYTICS
-- ============================================================================

-- Player availability and medical status view
CREATE VIEW player_availability_status AS
SELECT 
  p.id,
  p.first_name,
  p.last_name,
  p.jersey_number,
  p.position,
  pa.availability_status,
  pa.fitness_score,
  pa.medical_clearance_date,
  pa.next_medical_checkup,
  CASE 
    WHEN mr.clearance_to_play = true AND pa.availability_status = 'available' THEN 'Ready to Play'
    WHEN mr.clearance_to_play = false OR pa.availability_status = 'injured' THEN 'Not Available'
    WHEN pa.availability_status = 'restricted' THEN 'Limited Availability'
    ELSE 'Status Unknown'
  END as work_readiness,
  mr.recovery_status,
  mr.restrictions,
  mr.expected_return_date
FROM players p
LEFT JOIN player_analytics pa ON p.id = pa.player_id AND pa.date = CURRENT_DATE
LEFT JOIN LATERAL (
  SELECT * FROM medical_records 
  WHERE player_id = p.id 
  ORDER BY created_at DESC 
  LIMIT 1
) mr ON true;

-- Team performance dashboard view
CREATE VIEW team_performance_dashboard AS
SELECT 
  t.id as team_id,
  t.name as team_name,
  ts.total_players,
  ts.available_players,
  ts.injured_players,
  ts.restricted_players,
  ROUND((ts.available_players::NUMERIC / NULLIF(ts.total_players, 0)) * 100, 1) as availability_percentage,
  ts.avg_team_fitness,
  ts.injury_rate,
  ts.training_attendance_avg,
  ts.games_won,
  ts.games_lost,
  ts.games_drawn,
  CASE 
    WHEN (ts.games_won + ts.games_lost + ts.games_drawn) > 0 
    THEN ROUND((ts.games_won::NUMERIC / (ts.games_won + ts.games_lost + ts.games_drawn)) * 100, 1)
    ELSE 0
  END as win_percentage
FROM teams t
LEFT JOIN team_statistics ts ON t.id = ts.team_id AND ts.date = CURRENT_DATE;

-- Player performance summary view
CREATE VIEW player_performance_summary AS
SELECT 
  p.id,
  p.first_name,
  p.last_name,
  p.jersey_number,
  ps.games_played,
  ps.points_scored,
  ps.assists,
  ROUND((ps.points_scored::NUMERIC / NULLIF(ps.games_played, 0)), 2) as avg_points_per_game,
  ROUND((ps.assists::NUMERIC / NULLIF(ps.games_played, 0)), 2) as avg_assists_per_game,
  ps.avg_performance_rating,
  pa.training_attendance_rate,
  pa.game_participation_rate,
  pa.injury_days_lost,
  pa.fitness_score,
  pa.availability_status
FROM players p
LEFT JOIN player_stats ps ON p.id = ps.player_id
LEFT JOIN player_analytics pa ON p.id = pa.player_id AND pa.date = CURRENT_DATE;

-- Medical analytics view
CREATE VIEW medical_analytics AS
SELECT 
  p.team_id,
  COUNT(DISTINCT p.id) as total_players,
  COUNT(DISTINCT CASE WHEN mr.recovery_status = 'recovering' THEN p.id END) as currently_injured,
  COUNT(DISTINCT CASE WHEN mr.clearance_to_play = false THEN p.id END) as not_cleared,
  AVG(ma.overall_fitness) as avg_fitness_score,
  COUNT(DISTINCT CASE WHEN ma.injury_risk_level = 'high' THEN p.id END) as high_risk_players,
  AVG(pa.injury_days_lost) as avg_injury_days_lost
FROM players p
LEFT JOIN medical_records mr ON p.id = mr.player_id
LEFT JOIN medical_assessments ma ON p.id = ma.player_id
LEFT JOIN player_analytics pa ON p.id = pa.player_id AND pa.date = CURRENT_DATE
GROUP BY p.team_id;

-- Training attendance summary
CREATE VIEW training_attendance_summary AS
SELECT 
  ts.id,
  ts.session_date,
  t.name as team_name,
  COUNT(ta.id) as total_attendees,
  SUM(CASE WHEN ta.attendance_status = 'present' THEN 1 ELSE 0 END) as present_count,
  SUM(CASE WHEN ta.attendance_status = 'absent' THEN 1 ELSE 0 END) as absent_count,
  SUM(CASE WHEN ta.attendance_status = 'excused' THEN 1 ELSE 0 END) as excused_count,
  ROUND(100.0 * SUM(CASE WHEN ta.attendance_status = 'present' THEN 1 ELSE 0 END) / NULLIF(COUNT(ta.id), 0), 1) as attendance_rate
FROM training_sessions ts
JOIN teams t ON ts.team_id = t.id
LEFT JOIN training_attendance ta ON ts.id = ta.training_session_id
GROUP BY ts.id, ts.session_date, t.name;
