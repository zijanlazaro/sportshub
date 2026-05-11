-- ============================================================================
-- DRILLS TAB - DATABASE SCHEMA
-- Position-based drill tracking with performance scoring
-- ============================================================================

-- TABLE: player_drill_records
-- Stores individual drill training records for each player
CREATE TABLE IF NOT EXISTS player_drill_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  recorded_by UUID NOT NULL REFERENCES users(id),
  training_date DATE NOT NULL DEFAULT CURRENT_DATE,
  minutes_trained INT NOT NULL CHECK (minutes_trained > 0 AND minutes_trained <= 300),
  player_position TEXT NOT NULL,
  drills_completed JSONB NOT NULL DEFAULT '[]',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE: player_drill_performance
-- Computed performance scores and analytics for drills
CREATE TABLE IF NOT EXISTS player_drill_performance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL UNIQUE REFERENCES players(id) ON DELETE CASCADE,
  performance_score DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (performance_score >= 0 AND performance_score <= 100),
  drill_completion_rate DECIMAL(5,2) DEFAULT 0,
  attendance_rate DECIMAL(5,2) DEFAULT 0,
  training_minutes_total INT DEFAULT 0,
  position_specific_score DECIMAL(5,2) DEFAULT 0,
  performance_level TEXT CHECK (performance_level IN ('Beginner', 'Developing', 'Active', 'Competitive', 'Elite')) DEFAULT 'Beginner',
  total_training_days INT DEFAULT 0,
  total_drills_completed INT DEFAULT 0,
  training_frequency DECIMAL(5,2) DEFAULT 0,
  last_training_date DATE,
  weekly_progress DECIMAL(5,2) DEFAULT 0,
  monthly_progress DECIMAL(5,2) DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_drill_records_player_id ON player_drill_records(player_id);
CREATE INDEX IF NOT EXISTS idx_drill_records_date ON player_drill_records(training_date);
CREATE INDEX IF NOT EXISTS idx_drill_performance_player_id ON player_drill_performance(player_id);
CREATE INDEX IF NOT EXISTS idx_drill_performance_level ON player_drill_performance(performance_level);

-- Function to calculate drill performance score
CREATE OR REPLACE FUNCTION calculate_drill_performance_score(p_player_id UUID)
RETURNS DECIMAL(5,2) AS $$
DECLARE
  v_drill_score DECIMAL(5,2);
  v_attendance_score DECIMAL(5,2);
  v_minutes_score DECIMAL(5,2);
  v_position_score DECIMAL(5,2);
  v_total_score DECIMAL(5,2);
  v_total_drills INT;
  v_total_sessions INT;
  v_total_minutes INT;
  v_position_drills INT;
  v_attendance_count INT;
BEGIN
  -- Get total training sessions
  SELECT COUNT(*) INTO v_total_sessions
  FROM player_drill_records
  WHERE player_id = p_player_id;
  
  -- Get total drills completed (40% weight)
  SELECT COALESCE(SUM(jsonb_array_length(drills_completed)), 0) INTO v_total_drills
  FROM player_drill_records
  WHERE player_id = p_player_id;
  
  v_drill_score := CASE 
    WHEN v_total_sessions > 0 THEN 
      LEAST((v_total_drills::DECIMAL / (v_total_sessions * 3)) * 40, 40)
    ELSE 0
  END;
  
  -- Get attendance rate from training_attendance (20% weight)
  SELECT COUNT(*) INTO v_attendance_count
  FROM training_attendance ta
  JOIN training_sessions ts ON ta.training_session_id = ts.id
  WHERE ta.player_id = p_player_id
    AND ta.attendance_status = 'present'
    AND ts.session_date >= CURRENT_DATE - INTERVAL '30 days';
  
  v_attendance_score := LEAST((v_attendance_count::DECIMAL / 12) * 20, 20);
  
  -- Get training minutes (20% weight)
  SELECT COALESCE(SUM(minutes_trained), 0) INTO v_total_minutes
  FROM player_drill_records
  WHERE player_id = p_player_id;
  
  v_minutes_score := LEAST((v_total_minutes::DECIMAL / 600) * 20, 20);
  
  -- Position-specific training (20% weight)
  SELECT COUNT(*) INTO v_position_drills
  FROM player_drill_records
  WHERE player_id = p_player_id
    AND jsonb_array_length(drills_completed) >= 2;
  
  v_position_score := LEAST((v_position_drills::DECIMAL / 10) * 20, 20);
  
  -- Calculate total score
  v_total_score := v_drill_score + v_attendance_score + v_minutes_score + v_position_score;
  
  RETURN LEAST(v_total_score, 100);
END;
$$ LANGUAGE plpgsql;

-- Function to update drill performance scores
CREATE OR REPLACE FUNCTION update_drill_performance_scores()
RETURNS TRIGGER AS $$
DECLARE
  v_score DECIMAL(5,2);
  v_level TEXT;
  v_total_days INT;
  v_total_drills INT;
  v_total_minutes INT;
  v_last_date DATE;
  v_drill_rate DECIMAL(5,2);
  v_attendance_rate DECIMAL(5,2);
  v_position_score DECIMAL(5,2);
  v_frequency DECIMAL(5,2);
  v_weekly_progress DECIMAL(5,2);
  v_monthly_progress DECIMAL(5,2);
  v_attendance_count INT;
BEGIN
  -- Calculate performance score
  v_score := calculate_drill_performance_score(NEW.player_id);
  
  -- Determine performance level
  v_level := CASE
    WHEN v_score >= 80 THEN 'Elite'
    WHEN v_score >= 65 THEN 'Competitive'
    WHEN v_score >= 50 THEN 'Active'
    WHEN v_score >= 35 THEN 'Developing'
    ELSE 'Beginner'
  END;
  
  -- Get statistics
  SELECT 
    COUNT(DISTINCT training_date),
    COALESCE(SUM(jsonb_array_length(drills_completed)), 0),
    COALESCE(SUM(minutes_trained), 0),
    MAX(training_date)
  INTO v_total_days, v_total_drills, v_total_minutes, v_last_date
  FROM player_drill_records
  WHERE player_id = NEW.player_id;
  
  -- Calculate drill completion rate
  v_drill_rate := CASE 
    WHEN v_total_days > 0 THEN 
      LEAST((v_total_drills::DECIMAL / (v_total_days * 3)) * 100, 100)
    ELSE 0
  END;
  
  -- Get attendance rate from training_attendance
  SELECT COUNT(*) INTO v_attendance_count
  FROM training_attendance ta
  JOIN training_sessions ts ON ta.training_session_id = ts.id
  WHERE ta.player_id = NEW.player_id
    AND ta.attendance_status = 'present'
    AND ts.session_date >= CURRENT_DATE - INTERVAL '30 days';
  
  v_attendance_rate := LEAST((v_attendance_count::DECIMAL / 12) * 100, 100);
  
  -- Calculate position-specific score
  v_position_score := (v_score * 0.2);
  
  -- Calculate training frequency (sessions per week)
  v_frequency := CASE
    WHEN v_total_days > 0 THEN
      (v_total_days::DECIMAL / GREATEST(EXTRACT(EPOCH FROM (CURRENT_DATE - (SELECT MIN(training_date) FROM player_drill_records WHERE player_id = NEW.player_id))) / 604800, 1))
    ELSE 0
  END;
  
  -- Calculate weekly progress (last 7 days vs previous 7 days)
  WITH weekly_scores AS (
    SELECT 
      CASE 
        WHEN training_date >= CURRENT_DATE - INTERVAL '7 days' THEN 'current'
        WHEN training_date >= CURRENT_DATE - INTERVAL '14 days' THEN 'previous'
      END as period,
      COUNT(*) as sessions
    FROM player_drill_records
    WHERE player_id = NEW.player_id
      AND training_date >= CURRENT_DATE - INTERVAL '14 days'
    GROUP BY period
  )
  SELECT 
    COALESCE(
      ((MAX(CASE WHEN period = 'current' THEN sessions ELSE 0 END) - 
        MAX(CASE WHEN period = 'previous' THEN sessions ELSE 0 END))::DECIMAL / 
       NULLIF(MAX(CASE WHEN period = 'previous' THEN sessions ELSE 1 END), 0)) * 100,
      0
    )
  INTO v_weekly_progress
  FROM weekly_scores;
  
  -- Calculate monthly progress (last 30 days vs previous 30 days)
  WITH monthly_scores AS (
    SELECT 
      CASE 
        WHEN training_date >= CURRENT_DATE - INTERVAL '30 days' THEN 'current'
        WHEN training_date >= CURRENT_DATE - INTERVAL '60 days' THEN 'previous'
      END as period,
      COUNT(*) as sessions
    FROM player_drill_records
    WHERE player_id = NEW.player_id
      AND training_date >= CURRENT_DATE - INTERVAL '60 days'
    GROUP BY period
  )
  SELECT 
    COALESCE(
      ((MAX(CASE WHEN period = 'current' THEN sessions ELSE 0 END) - 
        MAX(CASE WHEN period = 'previous' THEN sessions ELSE 0 END))::DECIMAL / 
       NULLIF(MAX(CASE WHEN period = 'previous' THEN sessions ELSE 1 END), 0)) * 100,
      0
    )
  INTO v_monthly_progress
  FROM monthly_scores;
  
  -- Upsert performance scores
  INSERT INTO player_drill_performance (
    player_id,
    performance_score,
    drill_completion_rate,
    attendance_rate,
    training_minutes_total,
    position_specific_score,
    performance_level,
    total_training_days,
    total_drills_completed,
    training_frequency,
    last_training_date,
    weekly_progress,
    monthly_progress,
    updated_at
  ) VALUES (
    NEW.player_id,
    v_score,
    v_drill_rate,
    v_attendance_rate,
    v_total_minutes,
    v_position_score,
    v_level,
    v_total_days,
    v_total_drills,
    ROUND(v_frequency, 2),
    v_last_date,
    ROUND(v_weekly_progress, 2),
    ROUND(v_monthly_progress, 2),
    NOW()
  )
  ON CONFLICT (player_id) DO UPDATE SET
    performance_score = EXCLUDED.performance_score,
    drill_completion_rate = EXCLUDED.drill_completion_rate,
    attendance_rate = EXCLUDED.attendance_rate,
    training_minutes_total = EXCLUDED.training_minutes_total,
    position_specific_score = EXCLUDED.position_specific_score,
    performance_level = EXCLUDED.performance_level,
    total_training_days = EXCLUDED.total_training_days,
    total_drills_completed = EXCLUDED.total_drills_completed,
    training_frequency = EXCLUDED.training_frequency,
    last_training_date = EXCLUDED.last_training_date,
    weekly_progress = EXCLUDED.weekly_progress,
    monthly_progress = EXCLUDED.monthly_progress,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update performance scores
DROP TRIGGER IF EXISTS trigger_update_drill_performance ON player_drill_records;
CREATE TRIGGER trigger_update_drill_performance
AFTER INSERT OR UPDATE ON player_drill_records
FOR EACH ROW
EXECUTE FUNCTION update_drill_performance_scores();

-- View for drill progress dashboard
CREATE OR REPLACE VIEW player_drill_dashboard AS
SELECT 
  p.id,
  p.first_name,
  p.last_name,
  p.position,
  p.jersey_number,
  p.photo_url,
  t.name as team_name,
  pdp.performance_score,
  pdp.drill_completion_rate,
  pdp.attendance_rate,
  pdp.training_minutes_total,
  pdp.position_specific_score,
  pdp.performance_level,
  pdp.total_training_days,
  pdp.total_drills_completed,
  pdp.training_frequency,
  pdp.last_training_date,
  pdp.weekly_progress,
  pdp.monthly_progress
FROM players p
LEFT JOIN teams t ON p.team_id = t.id
LEFT JOIN player_drill_performance pdp ON p.id = pdp.player_id
ORDER BY pdp.performance_score DESC NULLS LAST;

-- RLS Policies for player_drill_records
ALTER TABLE player_drill_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Coaches and admins can manage drill records" ON player_drill_records;
CREATE POLICY "Coaches and admins can manage drill records"
ON player_drill_records FOR ALL
USING (
  auth.uid() IN (
    SELECT id FROM users 
    WHERE role IN ('admin', 'coach', 'team_manager')
  )
);

DROP POLICY IF EXISTS "Players can view own drill records" ON player_drill_records;
CREATE POLICY "Players can view own drill records"
ON player_drill_records FOR SELECT
USING (
  player_id IN (
    SELECT id FROM players WHERE user_id = auth.uid()
  )
);

-- RLS Policies for player_drill_performance
ALTER TABLE player_drill_performance ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Everyone can view drill performance scores" ON player_drill_performance;
CREATE POLICY "Everyone can view drill performance scores"
ON player_drill_performance FOR SELECT
USING (true);

DROP POLICY IF EXISTS "System can update drill performance scores" ON player_drill_performance;
CREATE POLICY "System can update drill performance scores"
ON player_drill_performance FOR ALL
USING (true);
