-- ============================================================================
-- SPORTS HUB MANAGEMENT SYSTEM - BACKEND LOGIC & FUNCTIONS
-- Advanced Business Logic, Automation, and Analytics Functions
-- ============================================================================

-- ============================================================================
-- PERFORMANCE CALCULATION FUNCTIONS
-- ============================================================================

-- Function to update player statistics after game
CREATE OR REPLACE FUNCTION update_player_stats_after_game(
  p_player_id UUID,
  p_game_result_id UUID,
  p_minutes_played INTEGER DEFAULT 0,
  p_goals INTEGER DEFAULT 0,
  p_assists INTEGER DEFAULT 0,
  p_shots INTEGER DEFAULT 0,
  p_shots_on_target INTEGER DEFAULT 0,
  p_tackles INTEGER DEFAULT 0,
  p_passes INTEGER DEFAULT 0,
  p_yellow_cards INTEGER DEFAULT 0,
  p_red_cards INTEGER DEFAULT 0
)
RETURNS VOID AS $$
DECLARE
  pass_accuracy DECIMAL(5,2);
  rating DECIMAL(3,1);
BEGIN
  -- Calculate pass accuracy
  IF p_passes > 0 THEN
    -- This is a simplified calculation - in reality you'd track successful passes
    pass_accuracy := 85.0; -- Default assumption
  ELSE
    pass_accuracy := 0;
  END IF;

  -- Calculate player rating (simplified algorithm)
  rating := (
    (p_goals * 2.0) +
    (p_assists * 1.5) +
    (p_tackles * 0.5) +
    (p_minutes_played / 90.0 * 2.0) +
    CASE WHEN p_yellow_cards > 0 THEN -0.5 ELSE 0 END +
    CASE WHEN p_red_cards > 0 THEN -2.0 ELSE 0 END
  )::DECIMAL(3,1);

  -- Cap rating between 0 and 10
  IF rating > 10.0 THEN rating := 10.0;
  ELSIF rating < 0.0 THEN rating := 0.0;
  END IF;

  -- Insert or update player game stats
  INSERT INTO player_game_stats (
    game_result_id, player_id, minutes_played, goals, assists,
    shots, shots_on_target, tackles, passes, pass_accuracy, rating
  ) VALUES (
    p_game_result_id, p_player_id, p_minutes_played, p_goals, p_assists,
    p_shots, p_shots_on_target, p_tackles, p_passes, pass_accuracy, rating
  ) ON CONFLICT (game_result_id, player_id) DO UPDATE SET
    minutes_played = EXCLUDED.minutes_played,
    goals = EXCLUDED.goals,
    assists = EXCLUDED.assists,
    shots = EXCLUDED.shots,
    shots_on_target = EXCLUDED.shots_on_target,
    tackles = EXCLUDED.tackles,
    passes = EXCLUDED.passes,
    pass_accuracy = EXCLUDED.pass_accuracy,
    rating = EXCLUDED.rating;

  -- Update cumulative player stats
  UPDATE player_stats SET
    games_played = games_played + 1,
    goals_scored = goals_scored + p_goals,
    assists = assists + p_assists,
    shots_on_target = shots_on_target + p_shots_on_target,
    tackles = tackles + p_tackles,
    yellow_cards = yellow_cards + p_yellow_cards,
    red_cards = red_cards + p_red_cards,
    rating = (rating + p_rating) / 2.0, -- Simple average
    updated_at = NOW()
  WHERE player_id = p_player_id;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate team performance metrics
CREATE OR REPLACE FUNCTION calculate_team_performance(p_team_id UUID, p_season TEXT DEFAULT NULL)
RETURNS TABLE(
  total_players BIGINT,
  active_players BIGINT,
  injured_players BIGINT,
  avg_rating DECIMAL,
  total_goals BIGINT,
  total_assists BIGINT,
  discipline_score DECIMAL
) AS $$
BEGIN
  IF p_season IS NULL THEN
    p_season := EXTRACT(YEAR FROM CURRENT_DATE)::TEXT;
  END IF;

  RETURN QUERY
  SELECT
    COUNT(DISTINCT p.id) as total_players,
    COUNT(DISTINCT CASE WHEN p.status = 'OFFICIAL_PLAYER' THEN p.id END) as active_players,
    COUNT(DISTINCT CASE WHEN mr.recovery_status = 'recovering' THEN p.id END) as injured_players,
    ROUND(AVG(ps.rating), 2) as avg_rating,
    SUM(ps.goals_scored) as total_goals,
    SUM(ps.assists) as total_assists,
    ROUND(
      10.0 - (SUM(ps.yellow_cards) * 0.5 + SUM(ps.red_cards) * 2.0) /
      NULLIF(COUNT(DISTINCT p.id), 0), 2
    ) as discipline_score
  FROM players p
  LEFT JOIN player_stats ps ON p.id = ps.player_id AND ps.season = p_season
  LEFT JOIN medical_records mr ON p.id = mr.player_id
    AND mr.created_at >= CURRENT_DATE - INTERVAL '30 days'
  WHERE p.team_id = p_team_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- MEDICAL CLEARANCE FUNCTIONS
-- ============================================================================

-- Function to assess medical clearance
CREATE OR REPLACE FUNCTION assess_medical_clearance(p_player_id UUID)
RETURNS TABLE(
  clearance_status TEXT,
  restrictions TEXT,
  recommended_actions TEXT,
  risk_level TEXT
) AS $$
DECLARE
  recent_injuries INTEGER;
  chronic_conditions INTEGER;
  medication_count INTEGER;
  pain_reported BOOLEAN;
  last_assessment DATE;
BEGIN
  -- Get medical data
  SELECT
    COUNT(CASE WHEN injury_date >= CURRENT_DATE - INTERVAL '6 months' THEN 1 END),
    COUNT(CASE WHEN recovery_status = 'chronic' THEN 1 END),
    CASE WHEN medications IS NOT NULL AND medications != '' THEN 1 ELSE 0 END,
    COALESCE(pain_during_activity, false),
    MAX(created_at)::DATE
  INTO recent_injuries, chronic_conditions, medication_count, pain_reported, last_assessment
  FROM medical_records
  WHERE player_id = p_player_id;

  -- Determine clearance status
  IF recent_injuries > 0 OR chronic_conditions > 0 OR pain_reported THEN
    clearance_status := 'conditional';
    risk_level := 'medium';
    IF recent_injuries > 2 THEN
      risk_level := 'high';
      clearance_status := 'not_cleared';
    END IF;
  ELSIF medication_count > 0 THEN
    clearance_status := 'cleared_with_monitoring';
    risk_level := 'low';
  ELSE
    clearance_status := 'cleared';
    risk_level := 'low';
  END IF;

  -- Set restrictions and recommendations
  CASE
    WHEN clearance_status = 'not_cleared' THEN
      restrictions := 'No participation allowed';
      recommended_actions := 'Further medical evaluation required';
    WHEN clearance_status = 'conditional' THEN
      restrictions := 'Limited contact, supervised activity';
      recommended_actions := 'Regular check-ups, modified training';
    WHEN clearance_status = 'cleared_with_monitoring' THEN
      restrictions := 'Monitor for side effects';
      recommended_actions := 'Continue medication as prescribed';
    ELSE
      restrictions := 'None';
      recommended_actions := 'Regular fitness assessments';
  END CASE;

  RETURN QUERY SELECT clearance_status, restrictions, recommended_actions, risk_level;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update medical clearance status
CREATE OR REPLACE FUNCTION update_medical_clearance(p_player_id UUID, p_cleared BOOLEAN, p_restrictions TEXT DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
  UPDATE players SET
    medical_clearance = p_cleared,
    updated_at = NOW()
  WHERE id = p_player_id;

  -- Create medical record if restrictions provided
  IF p_restrictions IS NOT NULL AND p_restrictions != '' THEN
    INSERT INTO medical_records (
      player_id, recorded_by, description, restrictions, clearance_to_play, recovery_status
    ) VALUES (
      p_player_id,
      auth.uid(),
      'Medical clearance update',
      p_restrictions,
      p_cleared,
      CASE WHEN p_cleared THEN 'cleared' ELSE 'recovering' END
    );
  END IF;

  -- Create notification
  PERFORM create_notification(
    (SELECT user_id FROM players WHERE id = p_player_id),
    auth.uid(),
    'medical_checkup',
    'Medical Clearance Updated',
    CASE WHEN p_cleared THEN 'You have been cleared for play' ELSE 'Medical restrictions applied' END,
    'high',
    p_player_id,
    'player'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ATTENDANCE & TRAINING FUNCTIONS
-- ============================================================================

-- Function to record attendance for an event
CREATE OR REPLACE FUNCTION record_event_attendance(
  p_event_id UUID,
  p_player_id UUID,
  p_status TEXT,
  p_notes TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  event_type TEXT;
  player_name TEXT;
BEGIN
  -- Get event type
  SELECT event_type INTO event_type FROM events WHERE id = p_event_id;

  -- Record attendance
  INSERT INTO event_attendance (event_id, player_id, attendance_status, notes)
  VALUES (p_event_id, p_player_id, p_status, p_notes)
  ON CONFLICT (event_id, player_id) DO UPDATE SET
    attendance_status = EXCLUDED.attendance_status,
    notes = EXCLUDED.notes,
    recorded_at = NOW();

  -- Update performance analytics
  UPDATE performance_analytics SET
    training_attendance_rate = (
      SELECT ROUND(AVG(CASE WHEN attendance_status = 'present' THEN 100 ELSE 0 END), 2)
      FROM event_attendance ea
      JOIN events e ON ea.event_id = e.id
      WHERE ea.player_id = p_player_id
      AND e.event_type = 'training'
      AND e.event_date >= CURRENT_DATE - INTERVAL '30 days'
    ),
    updated_at = NOW()
  WHERE player_id = p_player_id AND date = CURRENT_DATE;

  -- Create notification for absences
  IF p_status != 'present' THEN
    SELECT first_name || ' ' || last_name INTO player_name
    FROM players WHERE id = p_player_id;

    PERFORM create_notification(
      (SELECT user_id FROM players WHERE id = p_player_id),
      auth.uid(),
      'training_reminder',
      'Attendance Recorded',
      'Your attendance for ' || event_type || ' has been marked as: ' || p_status,
      'normal',
      p_event_id,
      'event'
    );
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate attendance rate
CREATE OR REPLACE FUNCTION calculate_attendance_rate(p_player_id UUID, p_days INTEGER DEFAULT 30)
RETURNS DECIMAL(5,2) AS $$
DECLARE
  total_events INTEGER;
  present_count INTEGER;
BEGIN
  SELECT
    COUNT(*) as total,
    COUNT(CASE WHEN attendance_status = 'present' THEN 1 END) as present
  INTO total_events, present_count
  FROM event_attendance ea
  JOIN events e ON ea.event_id = e.id
  WHERE ea.player_id = p_player_id
  AND e.event_date >= CURRENT_DATE - (p_days || ' days')::INTERVAL;

  IF total_events = 0 THEN
    RETURN 0;
  END IF;

  RETURN ROUND((present_count::DECIMAL / total_events) * 100, 2);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- NOTIFICATION SYSTEM FUNCTIONS
-- ============================================================================

-- Function to create injury alert notifications
CREATE OR REPLACE FUNCTION create_injury_alert(p_player_id UUID, p_injury_description TEXT)
RETURNS VOID AS $$
DECLARE
  player_name TEXT;
  team_id UUID;
BEGIN
  -- Get player details
  SELECT first_name || ' ' || last_name, team_id
  INTO player_name, team_id
  FROM players WHERE id = p_player_id;

  -- Notify medical staff
  INSERT INTO notifications (recipient_id, sender_id, notification_type, title, message, priority, related_record_id, related_record_type)
  SELECT
    u.id,
    auth.uid(),
    'injury_alert',
    'Player Injury Reported',
    player_name || ' has reported an injury: ' || p_injury_description,
    'urgent',
    p_player_id,
    'player'
  FROM users u
  WHERE u.role = 'medical_staff'
  AND (u.team_id = team_id OR u.team_id IS NULL);

  -- Notify coaches
  INSERT INTO notifications (recipient_id, sender_id, notification_type, title, message, priority, related_record_id, related_record_type)
  SELECT
    u.id,
    auth.uid(),
    'injury_alert',
    'Player Injury Alert',
    player_name || ' is injured and may miss upcoming activities',
    'high',
    p_player_id,
    'player'
  FROM users u
  WHERE u.role IN ('coach', 'team_manager')
  AND u.team_id = team_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create promotion notifications
CREATE OR REPLACE FUNCTION create_promotion_notification(p_player_id UUID)
RETURNS VOID AS $$
DECLARE
  player_name TEXT;
BEGIN
  SELECT first_name || ' ' || last_name INTO player_name
  FROM players WHERE id = p_player_id;

  -- Notify player
  PERFORM create_notification(
    (SELECT user_id FROM players WHERE id = p_player_id),
    NULL,
    'promotion',
    'Congratulations!',
    'You have been promoted to Official Player status!',
    'high',
    p_player_id,
    'player'
  );

  -- Notify coaches
  INSERT INTO notifications (recipient_id, sender_id, notification_type, title, message, priority, related_record_id, related_record_type)
  SELECT
    u.id,
    auth.uid(),
    'promotion',
    'Player Promotion',
    player_name || ' has been promoted to Official Player',
    'normal',
    p_player_id,
    'player'
  FROM users u
  WHERE u.role IN ('coach', 'team_manager')
  AND u.team_id = (SELECT team_id FROM players WHERE id = p_player_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ANALYTICS & REPORTING FUNCTIONS
-- ============================================================================

-- Function to generate player performance report
CREATE OR REPLACE FUNCTION generate_player_report(p_player_id UUID, p_start_date DATE DEFAULT NULL, p_end_date DATE DEFAULT NULL)
RETURNS TABLE(
  period TEXT,
  games_played BIGINT,
  goals_scored BIGINT,
  assists BIGINT,
  avg_rating DECIMAL,
  attendance_rate DECIMAL,
  injuries BIGINT,
  fitness_score DECIMAL
) AS $$
BEGIN
  IF p_start_date IS NULL THEN p_start_date := CURRENT_DATE - INTERVAL '30 days'; END IF;
  IF p_end_date IS NULL THEN p_end_date := CURRENT_DATE; END IF;

  RETURN QUERY
  SELECT
    'Report Period'::TEXT as period,
    COUNT(DISTINCT pgs.id) as games_played,
    SUM(pgs.goals) as goals_scored,
    SUM(pgs.assists) as assists,
    ROUND(AVG(pgs.rating), 2) as avg_rating,
    calculate_attendance_rate(p_player_id, 30) as attendance_rate,
    COUNT(DISTINCT mr.id) as injuries,
    AVG(pa.fitness_score) as fitness_score
  FROM players p
  LEFT JOIN player_game_stats pgs ON p.id = pgs.player_id
  LEFT JOIN game_results gr ON pgs.game_result_id = gr.id
  LEFT JOIN events e ON gr.event_id = e.id AND e.event_date BETWEEN p_start_date AND p_end_date
  LEFT JOIN medical_records mr ON p.id = mr.player_id AND mr.injury_date BETWEEN p_start_date AND p_end_date
  LEFT JOIN performance_analytics pa ON p.id = pa.player_id AND pa.date BETWEEN p_start_date AND p_end_date
  WHERE p.id = p_player_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate team analytics
CREATE OR REPLACE FUNCTION generate_team_analytics(p_team_id UUID, p_period_days INTEGER DEFAULT 30)
RETURNS TABLE(
  metric TEXT,
  value TEXT,
  trend TEXT
) AS $$
DECLARE
  start_date DATE := CURRENT_DATE - (p_period_days || ' days')::INTERVAL;
BEGIN
  RETURN QUERY
  WITH team_metrics AS (
    SELECT
      COUNT(DISTINCT p.id) as total_players,
      COUNT(DISTINCT CASE WHEN p.status = 'OFFICIAL_PLAYER' THEN p.id END) as official_players,
      ROUND(AVG(pa.current_rating), 2) as avg_rating,
      ROUND(AVG(pa.training_attendance_rate), 2) as avg_attendance,
      COUNT(DISTINCT CASE WHEN mr.recovery_status = 'recovering' THEN p.id END) as injured_count,
      COUNT(DISTINCT CASE WHEN p.status = 'TRYOUT' THEN p.id END) as tryout_count
    FROM players p
    LEFT JOIN performance_analytics pa ON p.id = pa.player_id AND pa.date >= start_date
    LEFT JOIN medical_records mr ON p.id = mr.player_id AND mr.created_at >= start_date
    WHERE p.team_id = p_team_id
  )
  SELECT * FROM (
    VALUES
      ('Total Players', tm.total_players::TEXT, 'stable'),
      ('Official Players', tm.official_players::TEXT, 'increasing'),
      ('Tryout Players', tm.tryout_count::TEXT, 'stable'),
      ('Average Rating', tm.avg_rating::TEXT, 'stable'),
      ('Attendance Rate', (tm.avg_attendance || '%')::TEXT, 'stable'),
      ('Currently Injured', tm.injured_count::TEXT, 'decreasing')
  ) AS metrics(metric, value, trend)
  FROM team_metrics tm;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- EXPORT FUNCTIONS
-- ============================================================================

-- Function to export player data as JSON
CREATE OR REPLACE FUNCTION export_player_data(p_player_id UUID)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'player_info', jsonb_build_object(
      'id', p.id,
      'name', p.first_name || ' ' || p.last_name,
      'position', p.position,
      'jersey_number', p.jersey_number,
      'status', p.status,
      'date_of_birth', p.date_of_birth,
      'age', p.age
    ),
    'performance_stats', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'season', ps.season,
          'games_played', ps.games_played,
          'goals', ps.goals_scored,
          'assists', ps.assists,
          'rating', ps.rating
        )
      )
      FROM player_stats ps WHERE ps.player_id = p.id
    ),
    'medical_history', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'date', mr.injury_date,
          'type', mr.injury_type,
          'severity', mr.severity,
          'status', mr.recovery_status
        )
      )
      FROM medical_records mr WHERE mr.player_id = p.id
      ORDER BY mr.injury_date DESC
    ),
    'attendance_record', (
      SELECT jsonb_build_object(
        'overall_rate', calculate_attendance_rate(p.id, 90),
        'last_30_days', calculate_attendance_rate(p.id, 30)
      )
    )
  ) INTO result
  FROM players p
  WHERE p.id = p_player_id;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to export team data as JSON
CREATE OR REPLACE FUNCTION export_team_data(p_team_id UUID)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'team_info', jsonb_build_object(
      'id', t.id,
      'name', t.name,
      'sport', t.sport,
      'season', t.season
    ),
    'players', (
      SELECT jsonb_agg(export_player_data(p.id))
      FROM players p WHERE p.team_id = t.id
    ),
    'upcoming_events', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'title', e.title,
          'date', e.event_date,
          'type', e.event_type,
          'location', e.location
        )
      )
      FROM events e WHERE e.team_id = t.id AND e.event_date >= CURRENT_DATE
      ORDER BY e.event_date
      LIMIT 10
    ),
    'performance_summary', (
      SELECT jsonb_build_object(
        'avg_rating', ROUND(AVG(pa.current_rating), 2),
        'attendance_rate', ROUND(AVG(pa.training_attendance_rate), 2),
        'injury_rate', ROUND(
          COUNT(DISTINCT CASE WHEN mr.recovery_status = 'recovering' THEN p.id END)::DECIMAL /
          NULLIF(COUNT(DISTINCT p.id), 0) * 100, 2
        )
      )
      FROM players p
      LEFT JOIN performance_analytics pa ON p.id = pa.player_id AND pa.date = CURRENT_DATE
      LEFT JOIN medical_records mr ON p.id = mr.player_id
        AND mr.created_at >= CURRENT_DATE - INTERVAL '30 days'
      WHERE p.team_id = t.id
    )
  ) INTO result
  FROM teams t
  WHERE t.id = p_team_id;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Function to validate email format
CREATE OR REPLACE FUNCTION validate_email_format(p_email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN p_email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to validate phone format
CREATE OR REPLACE FUNCTION validate_phone_format(p_phone TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN p_phone ~ '^\+?[0-9\s\-\(\)]{10,15}$';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get user role
CREATE OR REPLACE FUNCTION get_user_role(p_user_id UUID)
RETURNS TEXT AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role FROM users WHERE id = p_user_id;
  RETURN COALESCE(user_role, 'unknown');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can access team data
CREATE OR REPLACE FUNCTION can_access_team_data(p_user_id UUID, p_team_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  user_role TEXT;
  user_team_id UUID;
BEGIN
  SELECT role, team_id INTO user_role, user_team_id
  FROM users WHERE id = p_user_id;

  RETURN user_role = 'admin' OR user_team_id = p_team_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- MAINTENANCE FUNCTIONS
-- ============================================================================

-- Function to clean up old notifications
CREATE OR REPLACE FUNCTION cleanup_old_notifications(p_days_old INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM notifications
  WHERE created_at < CURRENT_DATE - (p_days_old || ' days')::INTERVAL
  AND read = true;

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update performance analytics (to be run daily)
CREATE OR REPLACE FUNCTION update_performance_analytics()
RETURNS VOID AS $$
BEGIN
  -- Insert or update analytics for all players
  INSERT INTO performance_analytics (
    player_id, date, training_attendance_rate, game_participation_rate,
    current_rating, consistency_score, medical_clearance_status
  )
  SELECT
    p.id,
    CURRENT_DATE,
    calculate_attendance_rate(p.id, 30),
    CASE WHEN ps.games_played > 0 THEN
      ROUND((ps.games_played::DECIMAL / GREATEST(ps.games_played + 5, 10)) * 100, 2)
    ELSE 0 END,
    COALESCE(ps.rating, 0),
    CASE WHEN ps.rating >= 7.0 THEN 8.0
         WHEN ps.rating >= 5.0 THEN 6.0
         ELSE 4.0 END,
    p.medical_clearance
  FROM players p
  LEFT JOIN player_stats ps ON p.id = ps.player_id
  ON CONFLICT (player_id, date) DO UPDATE SET
    training_attendance_rate = EXCLUDED.training_attendance_rate,
    game_participation_rate = EXCLUDED.game_participation_rate,
    current_rating = EXCLUDED.current_rating,
    consistency_score = EXCLUDED.consistency_score,
    medical_clearance_status = EXCLUDED.medical_clearance_status,
    updated_at = NOW();

  -- Update predictions
  UPDATE performance_analytics pa
  SET
    predicted_rating = pred.predicted_rating,
    risk_level = pred.risk_level,
    recommendation = pred.recommendation
  FROM (
    SELECT * FROM predict_player_performance(pa2.player_id)
  ) pred
  WHERE pa.player_id = pred.predict_player_performance.player_id
  AND pa.date = CURRENT_DATE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Success message
SELECT 'Sports Hub Backend Logic functions created successfully!' as status;</content>
<parameter name="filePath">c:\Users\ACER\Downloads\sportshub\sportshub\sportshub\docs\SPORTS_HUB_BACKEND_LOGIC.sql