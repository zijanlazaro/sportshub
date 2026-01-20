-- ============================================================================
-- SPORTS HUB DATABASE SCHEMA
-- Athlete Management & Analytics System
-- ============================================================================

-- TABLE 1: Teams (Created first - no dependencies)
-- Sports teams managed in the system
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  sport TEXT NOT NULL, -- e.g., "Football", "Basketball"
  coach_id UUID, -- Will be set after users table is created
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE 2: Users (Extended Auth)
-- Extends Supabase auth.users with role information
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'coach', 'medical_staff', 'player')),
  team_id UUID REFERENCES teams(id),
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

-- TABLE 5: Medical Records
-- Injury history and medical information
CREATE TABLE medical_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  recorded_by UUID NOT NULL REFERENCES users(id),
  injury_type TEXT,
  injury_date DATE,
  description TEXT,
  recovery_status TEXT CHECK (recovery_status IN ('recovering', 'cleared', 'cleared_with_restrictions')),
  clearance_to_play BOOLEAN DEFAULT FALSE,
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

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX idx_users_team_id ON users(team_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_players_team_id ON players(team_id);
CREATE INDEX idx_players_user_id ON players(user_id);
CREATE INDEX idx_player_stats_player_id ON player_stats(player_id);
CREATE INDEX idx_medical_records_player_id ON medical_records(player_id);
CREATE INDEX idx_training_sessions_team_id ON training_sessions(team_id);
CREATE INDEX idx_training_attendance_session_id ON training_attendance(training_session_id);
CREATE INDEX idx_games_team_id ON games(team_id);
CREATE INDEX idx_events_team_id ON events(team_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

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
-- VIEWS FOR CONVENIENCE
-- ============================================================================

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
  mr.recovery_status,
  mr.clearance_to_play
FROM players p
LEFT JOIN player_stats ps ON p.id = ps.player_id
LEFT JOIN medical_records mr ON p.id = mr.player_id;

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
