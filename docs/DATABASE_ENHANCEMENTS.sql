-- ============================================================================
-- SPORTS HUB DATABASE ENHANCEMENTS
-- Add new tables and features for analytics and medical tracking
-- ============================================================================

-- Add new columns to existing tables (if they don't exist)
DO $$ 
BEGIN
    -- Add columns to teams table
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='teams' AND column_name='season') THEN
        ALTER TABLE teams ADD COLUMN season TEXT DEFAULT '2024';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='teams' AND column_name='active') THEN
        ALTER TABLE teams ADD COLUMN active BOOLEAN DEFAULT true;
    END IF;

    -- Add columns to users table
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='active') THEN
        ALTER TABLE users ADD COLUMN active BOOLEAN DEFAULT true;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='last_login') THEN
        ALTER TABLE users ADD COLUMN last_login TIMESTAMP WITH TIME ZONE;
    END IF;

    -- Add columns to medical_records table
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='medical_records' AND column_name='severity') THEN
        ALTER TABLE medical_records ADD COLUMN severity TEXT CHECK (severity IN ('minor', 'moderate', 'severe', 'critical'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='medical_records' AND column_name='expected_return_date') THEN
        ALTER TABLE medical_records ADD COLUMN expected_return_date DATE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='medical_records' AND column_name='actual_return_date') THEN
        ALTER TABLE medical_records ADD COLUMN actual_return_date DATE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='medical_records' AND column_name='restrictions') THEN
        ALTER TABLE medical_records ADD COLUMN restrictions TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='medical_records' AND column_name='follow_up_required') THEN
        ALTER TABLE medical_records ADD COLUMN follow_up_required BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='medical_records' AND column_name='follow_up_date') THEN
        ALTER TABLE medical_records ADD COLUMN follow_up_date DATE;
    END IF;
END $$;

-- Create new tables for analytics
CREATE TABLE IF NOT EXISTS player_analytics (
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

CREATE TABLE IF NOT EXISTS team_statistics (
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

CREATE TABLE IF NOT EXISTS medical_assessments (
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

-- Create indexes for new tables
CREATE INDEX IF NOT EXISTS idx_player_analytics_player_id ON player_analytics(player_id);
CREATE INDEX IF NOT EXISTS idx_player_analytics_date ON player_analytics(date);
CREATE INDEX IF NOT EXISTS idx_player_analytics_availability ON player_analytics(availability_status);
CREATE INDEX IF NOT EXISTS idx_team_statistics_team_id ON team_statistics(team_id);
CREATE INDEX IF NOT EXISTS idx_team_statistics_date ON team_statistics(date);
CREATE INDEX IF NOT EXISTS idx_medical_assessments_player_id ON medical_assessments(player_id);
CREATE INDEX IF NOT EXISTS idx_medical_assessments_date ON medical_assessments(assessment_date);

-- Create or replace views for analytics
CREATE OR REPLACE VIEW player_availability_status AS
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

CREATE OR REPLACE VIEW team_performance_dashboard AS
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

CREATE OR REPLACE VIEW medical_analytics AS
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

-- Enable RLS on new tables
ALTER TABLE player_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_assessments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for new tables
CREATE POLICY "Team members can view player analytics" ON player_analytics
FOR SELECT USING (
  player_id IN (SELECT id FROM players WHERE team_id IN (
    SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL
  ))
  OR auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

CREATE POLICY "Team members can view team statistics" ON team_statistics
FOR SELECT USING (
  team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL)
  OR auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

CREATE POLICY "Medical staff can view assessments" ON medical_assessments
FOR SELECT USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
  OR player_id IN (SELECT id FROM players WHERE user_id = auth.uid())
);

CREATE POLICY "Medical staff can insert assessments" ON medical_assessments
FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

-- Success message
SELECT 'Sports Hub database enhancements completed successfully!' as message;