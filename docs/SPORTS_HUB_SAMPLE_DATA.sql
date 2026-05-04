-- ============================================================================
-- SPORTS HUB MANAGEMENT SYSTEM - SAMPLE DATA
-- Test data for demonstration and development
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- SAMPLE TEAMS
-- ============================================================================

INSERT INTO teams (name, sport, coach_id, season, active) VALUES
('Thunderbolts FC', 'Soccer', NULL, '2024', true),
('Eagles United', 'Soccer', NULL, '2024', true),
('Titans Academy', 'Soccer', NULL, '2024', true);

-- ============================================================================
-- SAMPLE USERS (AUTH ACCOUNTS WOULD BE CREATED SEPARATELY)
-- ============================================================================

-- Admin User
INSERT INTO users (id, email, full_name, first_name, last_name, role, team_id, active) VALUES
(gen_random_uuid(), 'admin@sportshub.com', 'System Administrator', 'System', 'Administrator', 'admin', NULL, true);

-- Coaches
INSERT INTO users (id, email, full_name, first_name, last_name, role, team_id, active) VALUES
(gen_random_uuid(), 'coach.thunderbolts@sportshub.com', 'Marcus Johnson', 'Marcus', 'Johnson', 'coach', (SELECT id FROM teams WHERE name = 'Thunderbolts FC'), true),
(gen_random_uuid(), 'coach.eagles@sportshub.com', 'Sarah Williams', 'Sarah', 'Williams', 'coach', (SELECT id FROM teams WHERE name = 'Eagles United'), true),
(gen_random_uuid(), 'coach.titans@sportshub.com', 'David Chen', 'David', 'Chen', 'coach', (SELECT id FROM teams WHERE name = 'Titans Academy'), true);

-- Medical Staff
INSERT INTO users (id, email, full_name, first_name, last_name, role, team_id, active) VALUES
(gen_random_uuid(), 'medical.thunderbolts@sportshub.com', 'Dr. Emily Rodriguez', 'Emily', 'Rodriguez', 'medical_staff', (SELECT id FROM teams WHERE name = 'Thunderbolts FC'), true),
(gen_random_uuid(), 'medical.eagles@sportshub.com', 'Dr. Michael Brown', 'Michael', 'Brown', 'medical_staff', (SELECT id FROM teams WHERE name = 'Eagles United'), true);

-- Game Masters
INSERT INTO users (id, email, full_name, first_name, last_name, role, team_id, active) VALUES
(gen_random_uuid(), 'gamemaster.thunderbolts@sportshub.com', 'James Wilson', 'James', 'Wilson', 'game_master', (SELECT id FROM teams WHERE name = 'Thunderbolts FC'), true),
(gen_random_uuid(), 'gamemaster.eagles@sportshub.com', 'Lisa Garcia', 'Lisa', 'Garcia', 'game_master', (SELECT id FROM teams WHERE name = 'Eagles United'), true);

-- Update team coach_ids
UPDATE teams SET coach_id = (SELECT id FROM users WHERE email = 'coach.thunderbolts@sportshub.com') WHERE name = 'Thunderbolts FC';
UPDATE teams SET coach_id = (SELECT id FROM users WHERE email = 'coach.eagles@sportshub.com') WHERE name = 'Eagles United';
UPDATE teams SET coach_id = (SELECT id FROM users WHERE email = 'coach.titans@sportshub.com') WHERE name = 'Titans Academy';

-- ============================================================================
-- SAMPLE PLAYERS
-- ============================================================================

-- Thunderbolts FC Players
INSERT INTO players (user_id, team_id, first_name, last_name, date_of_birth, height_cm, weight_kg, position, jersey_number, status, performance_rating, medical_clearance, fitness_status) VALUES
-- Official Players
((SELECT gen_random_uuid()), (SELECT id FROM teams WHERE name = 'Thunderbolts FC'), 'Alex', 'Thompson', '2005-03-15', 175, 70, 'Goalkeeper', 1, 'OFFICIAL_PLAYER', 8.5, true, 'excellent'),
((SELECT gen_random_uuid()), (SELECT id FROM teams WHERE name = 'Thunderbolts FC'), 'Jordan', 'Martinez', '2004-07-22', 180, 75, 'Defender', 4, 'OFFICIAL_PLAYER', 7.8, true, 'good'),
((SELECT gen_random_uuid()), (SELECT id FROM teams WHERE name = 'Thunderbolts FC'), 'Ryan', 'Davis', '2005-01-10', 178, 72, 'Midfielder', 8, 'OFFICIAL_PLAYER', 8.2, true, 'excellent'),
((SELECT gen_random_uuid()), (SELECT id FROM teams WHERE name = 'Thunderbolts FC'), 'Tyler', 'Anderson', '2004-11-05', 182, 78, 'Forward', 9, 'OFFICIAL_PLAYER', 8.7, true, 'excellent'),
-- Tryout Players
((SELECT gen_random_uuid()), (SELECT id FROM teams WHERE name = 'Thunderbolts FC'), 'Chris', 'Wilson', '2006-04-18', 176, 68, 'Defender', 15, 'TRYOUT', 6.5, true, 'good'),
((SELECT gen_random_uuid()), (SELECT id FROM teams WHERE name = 'Thunderbolts FC'), 'Morgan', 'Taylor', '2005-09-30', 174, 66, 'Midfielder', 20, 'TRYOUT', 7.0, true, 'fair');

-- Eagles United Players
INSERT INTO players (user_id, team_id, first_name, last_name, date_of_birth, height_cm, weight_kg, position, jersey_number, status, performance_rating, medical_clearance, fitness_status) VALUES
((SELECT gen_random_uuid()), (SELECT id FROM teams WHERE name = 'Eagles United'), 'Sam', 'Johnson', '2004-06-12', 185, 80, 'Goalkeeper', 1, 'OFFICIAL_PLAYER', 8.0, true, 'excellent'),
((SELECT gen_random_uuid()), (SELECT id FROM teams WHERE name = 'Eagles United'), 'Casey', 'Brown', '2005-02-28', 177, 71, 'Defender', 3, 'OFFICIAL_PLAYER', 7.5, true, 'good'),
((SELECT gen_random_uuid()), (SELECT id FROM teams WHERE name = 'Eagles United'), 'Jamie', 'Lee', '2004-08-14', 179, 73, 'Midfielder', 7, 'OFFICIAL_PLAYER', 8.3, true, 'excellent'),
((SELECT gen_random_uuid()), (SELECT id FROM teams WHERE name = 'Eagles United'), 'Taylor', 'White', '2005-12-03', 181, 76, 'Forward', 10, 'OFFICIAL_PLAYER', 8.1, true, 'good');

-- ============================================================================
-- SAMPLE EMERGENCY CONTACTS
-- ============================================================================

INSERT INTO emergency_contacts (player_id, name, relationship, phone, email) VALUES
((SELECT id FROM players WHERE first_name = 'Alex' AND last_name = 'Thompson'), 'Robert Thompson', 'Father', '+1-555-0101', 'robert.thompson@email.com'),
((SELECT id FROM players WHERE first_name = 'Jordan' AND last_name = 'Martinez'), 'Maria Martinez', 'Mother', '+1-555-0102', 'maria.martinez@email.com'),
((SELECT id FROM players WHERE first_name = 'Ryan' AND last_name = 'Davis'), 'Jennifer Davis', 'Mother', '+1-555-0103', 'jennifer.davis@email.com'),
((SELECT id FROM players WHERE first_name = 'Tyler' AND last_name = 'Anderson'), 'Mark Anderson', 'Father', '+1-555-0104', 'mark.anderson@email.com');

-- ============================================================================
-- SAMPLE MEDICAL RECORDS
-- ============================================================================

INSERT INTO medical_records (player_id, recorded_by, medical_conditions, medications, seizure_history, recent_injury, surgery_history, pain_during_activity, blood_type, injury_type, injury_date, severity, description, recovery_status, clearance_to_play, restrictions) VALUES
((SELECT id FROM players WHERE first_name = 'Alex' AND last_name = 'Thompson'), (SELECT id FROM users WHERE email = 'medical.thunderbolts@sportshub.com'), NULL, NULL, false, NULL, NULL, false, 'O+', NULL, NULL, NULL, 'Annual checkup - no issues', 'cleared', true, NULL),
((SELECT id FROM players WHERE first_name = 'Jordan' AND last_name = 'Martinez'), (SELECT id FROM users WHERE email = 'medical.thunderbolts@sportshub.com'), 'Mild asthma', 'Albuterol inhaler as needed', false, 'Sprained ankle - 8 months ago', NULL, false, 'A+', 'Sprain', '2023-09-15', 'minor', 'Ankle sprain during training - fully recovered', 'cleared', true, NULL),
((SELECT id FROM players WHERE first_name = 'Ryan' AND last_name = 'Davis'), (SELECT id FROM users WHERE email = 'medical.thunderbolts@sportshub.com'), NULL, NULL, false, NULL, 'ACL reconstruction - 2 years ago', false, 'B+', 'Surgery', '2022-05-20', 'severe', 'ACL surgery - excellent recovery, no restrictions', 'cleared', true, NULL),
((SELECT id FROM players WHERE first_name = 'Tyler' AND last_name = 'Anderson'), (SELECT id FROM users WHERE email = 'medical.thunderbolts@sportshub.com'), NULL, NULL, false, 'Hamstring strain - 3 months ago', NULL, false, 'AB+', 'Strain', '2024-02-10', 'moderate', 'Grade 2 hamstring strain - cleared for full activity', 'cleared', true, NULL);

-- ============================================================================
-- SAMPLE PLAYER STATISTICS
-- ============================================================================

INSERT INTO player_stats (player_id, season, games_played, goals_scored, assists, shots_on_target, tackles, yellow_cards, rating) VALUES
((SELECT id FROM players WHERE first_name = 'Alex' AND last_name = 'Thompson'), '2024', 12, 0, 0, 0, 45, 0, 8.5),
((SELECT id FROM players WHERE first_name = 'Jordan' AND last_name = 'Martinez'), '2024', 15, 1, 3, 8, 52, 1, 7.8),
((SELECT id FROM players WHERE first_name = 'Ryan' AND last_name = 'Davis'), '2024', 14, 4, 7, 18, 38, 0, 8.2),
((SELECT id FROM players WHERE first_name = 'Tyler' AND last_name = 'Anderson'), '2024', 16, 12, 5, 32, 28, 2, 8.7),
((SELECT id FROM players WHERE first_name = 'Sam' AND last_name = 'Johnson'), '2024', 10, 0, 0, 0, 35, 0, 8.0),
((SELECT id FROM players WHERE first_name = 'Casey' AND last_name = 'Brown'), '2024', 12, 2, 2, 12, 48, 1, 7.5),
((SELECT id FROM players WHERE first_name = 'Jamie' AND last_name = 'Lee'), '2024', 13, 3, 8, 15, 42, 0, 8.3),
((SELECT id FROM players WHERE first_name = 'Taylor' AND last_name = 'White'), '2024', 14, 8, 4, 25, 31, 1, 8.1);

-- ============================================================================
-- SAMPLE EVENTS
-- ============================================================================

-- Training Sessions
INSERT INTO events (team_id, created_by, event_type, title, description, event_date, event_time, duration_minutes, location, status) VALUES
((SELECT id FROM teams WHERE name = 'Thunderbolts FC'), (SELECT id FROM users WHERE email = 'coach.thunderbolts@sportshub.com'), 'training', 'Defensive Tactics Training', 'Focus on defensive positioning and tackling', CURRENT_DATE - INTERVAL '2 days', '17:00:00', 90, 'Main Field', 'completed'),
((SELECT id FROM teams WHERE name = 'Thunderbolts FC'), (SELECT id FROM users WHERE email = 'coach.thunderbolts@sportshub.com'), 'training', 'Attacking Drills', 'Set pieces and finishing practice', CURRENT_DATE - INTERVAL '1 day', '16:30:00', 75, 'Training Pitch', 'completed'),
((SELECT id FROM teams WHERE name = 'Thunderbolts FC'), (SELECT id FROM users WHERE email = 'coach.thunderbolts@sportshub.com'), 'training', 'Fitness Session', 'Cardio and strength training', CURRENT_DATE, '18:00:00', 60, 'Gym', 'scheduled'),
((SELECT id FROM teams WHERE name = 'Eagles United'), (SELECT id FROM users WHERE email = 'coach.eagles@sportshub.com'), 'training', 'Team Building', 'Tactical understanding and communication', CURRENT_DATE - INTERVAL '1 day', '17:30:00', 90, 'Main Field', 'completed');

-- Games
INSERT INTO events (team_id, created_by, event_type, title, description, event_date, event_time, duration_minutes, location, opponent_name, status) VALUES
((SELECT id FROM teams WHERE name = 'Thunderbolts FC'), (SELECT id FROM users WHERE email = 'coach.thunderbolts@sportshub.com'), 'game', 'vs Eagles United', 'League match', CURRENT_DATE - INTERVAL '7 days', '15:00:00', 90, 'Stadium', 'Eagles United', 'completed'),
((SELECT id FROM teams WHERE name = 'Thunderbolts FC'), (SELECT id FROM users WHERE email = 'coach.thunderbolts@sportshub.com'), 'game', 'vs Titans Academy', 'Cup quarterfinal', CURRENT_DATE - INTERVAL '3 days', '14:00:00', 90, 'Away Stadium', 'Titans Academy', 'completed'),
((SELECT id FROM teams WHERE name = 'Thunderbolts FC'), (SELECT id FROM users WHERE email = 'coach.thunderbolts@sportshub.com'), 'game', 'vs City Rovers', 'League match', CURRENT_DATE + INTERVAL '7 days', '16:00:00', 90, 'Home Stadium', 'City Rovers', 'scheduled');

-- ============================================================================
-- SAMPLE EVENT ATTENDANCE
-- ============================================================================

-- Training attendance for Thunderbolts
INSERT INTO event_attendance (event_id, player_id, attendance_status, notes, recorded_at) VALUES
((SELECT id FROM events WHERE title = 'Defensive Tactics Training'), (SELECT id FROM players WHERE first_name = 'Alex' AND last_name = 'Thompson'), 'present', NULL, CURRENT_TIMESTAMP),
((SELECT id FROM events WHERE title = 'Defensive Tactics Training'), (SELECT id FROM players WHERE first_name = 'Jordan' AND last_name = 'Martinez'), 'present', NULL, CURRENT_TIMESTAMP),
((SELECT id FROM events WHERE title = 'Defensive Tactics Training'), (SELECT id FROM players WHERE first_name = 'Ryan' AND last_name = 'Davis'), 'present', NULL, CURRENT_TIMESTAMP),
((SELECT id FROM events WHERE title = 'Defensive Tactics Training'), (SELECT id FROM players WHERE first_name = 'Tyler' AND last_name = 'Anderson'), 'present', NULL, CURRENT_TIMESTAMP),
((SELECT id FROM events WHERE title = 'Defensive Tactics Training'), (SELECT id FROM players WHERE first_name = 'Chris' AND last_name = 'Wilson'), 'present', NULL, CURRENT_TIMESTAMP),
((SELECT id FROM events WHERE title = 'Defensive Tactics Training'), (SELECT id FROM players WHERE first_name = 'Morgan' AND last_name = 'Taylor'), 'absent', 'Family emergency', CURRENT_TIMESTAMP),

((SELECT id FROM events WHERE title = 'Attacking Drills'), (SELECT id FROM players WHERE first_name = 'Alex' AND last_name = 'Thompson'), 'present', NULL, CURRENT_TIMESTAMP),
((SELECT id FROM events WHERE title = 'Attacking Drills'), (SELECT id FROM players WHERE first_name = 'Jordan' AND last_name = 'Martinez'), 'present', NULL, CURRENT_TIMESTAMP),
((SELECT id FROM events WHERE title = 'Attacking Drills'), (SELECT id FROM players WHERE first_name = 'Ryan' AND last_name = 'Davis'), 'present', NULL, CURRENT_TIMESTAMP),
((SELECT id FROM events WHERE first_name = 'Tyler' AND last_name = 'Anderson'), (SELECT id FROM players WHERE first_name = 'Tyler' AND last_name = 'Anderson'), 'present', NULL, CURRENT_TIMESTAMP),
((SELECT id FROM events WHERE title = 'Attacking Drills'), (SELECT id FROM players WHERE first_name = 'Chris' AND last_name = 'Wilson'), 'present', NULL, CURRENT_TIMESTAMP),
((SELECT id FROM events WHERE title = 'Attacking Drills'), (SELECT id FROM players WHERE first_name = 'Morgan' AND last_name = 'Taylor'), 'present', NULL, CURRENT_TIMESTAMP);

-- ============================================================================
-- SAMPLE GAME RESULTS
-- ============================================================================

INSERT INTO game_results (event_id, recorded_by, home_score, away_score, weather_conditions, field_conditions, attendance_count) VALUES
((SELECT id FROM events WHERE title = 'vs Eagles United'), (SELECT id FROM users WHERE email = 'gamemaster.thunderbolts@sportshub.com'), 2, 1, 'Sunny', 'Good', 150),
((SELECT id FROM events WHERE title = 'vs Titans Academy'), (SELECT id FROM users WHERE email = 'gamemaster.thunderbolts@sportshub.com'), 3, 1, 'Cloudy', 'Wet', 200);

-- ============================================================================
-- SAMPLE PLAYER GAME STATS
-- ============================================================================

-- Game 1: Thunderbolts vs Eagles
INSERT INTO player_game_stats (game_result_id, player_id, minutes_played, goals, assists, shots, shots_on_target, tackles, passes, rating) VALUES
((SELECT id FROM game_results WHERE event_id = (SELECT id FROM events WHERE title = 'vs Eagles United')), (SELECT id FROM players WHERE first_name = 'Alex' AND last_name = 'Thompson'), 90, 0, 0, 0, 0, 8, 25, 8.5),
((SELECT id FROM game_results WHERE event_id = (SELECT id FROM events WHERE title = 'vs Eagles United')), (SELECT id FROM players WHERE first_name = 'Jordan' AND last_name = 'Martinez'), 90, 0, 1, 2, 1, 12, 35, 7.8),
((SELECT id FROM game_results WHERE event_id = (SELECT id FROM events WHERE title = 'vs Eagles United')), (SELECT id FROM players WHERE first_name = 'Ryan' AND last_name = 'Davis'), 85, 1, 1, 4, 2, 6, 28, 8.2),
((SELECT id FROM game_results WHERE event_id = (SELECT id FROM events WHERE title = 'vs Eagles United')), (SELECT id FROM players WHERE first_name = 'Tyler' AND last_name = 'Anderson'), 90, 1, 0, 6, 3, 4, 22, 8.7);

-- Game 2: Thunderbolts vs Titans
INSERT INTO player_game_stats (game_result_id, player_id, minutes_played, goals, assists, shots, shots_on_target, tackles, passes, rating) VALUES
((SELECT id FROM game_results WHERE event_id = (SELECT id FROM events WHERE title = 'vs Titans Academy')), (SELECT id FROM players WHERE first_name = 'Alex' AND last_name = 'Thompson'), 90, 0, 0, 0, 0, 6, 30, 8.0),
((SELECT id FROM game_results WHERE event_id = (SELECT id FROM events WHERE title = 'vs Titans Academy')), (SELECT id FROM players WHERE first_name = 'Jordan' AND last_name = 'Martinez'), 90, 0, 0, 1, 0, 10, 38, 7.5),
((SELECT id FROM game_results WHERE event_id = (SELECT id FROM events WHERE title = 'vs Titans Academy')), (SELECT id FROM players WHERE first_name = 'Ryan' AND last_name = 'Davis'), 90, 1, 1, 5, 3, 8, 32, 8.5),
((SELECT id FROM game_results WHERE event_id = (SELECT id FROM events WHERE title = 'vs Titans Academy')), (SELECT id FROM players WHERE first_name = 'Tyler' AND last_name = 'Anderson'), 90, 2, 0, 8, 5, 5, 25, 9.0);

-- ============================================================================
-- SAMPLE GAME VIOLATIONS
-- ============================================================================

INSERT INTO game_violations (game_result_id, player_id, recorded_by, violation_type, card_type, description, minute_occurred) VALUES
((SELECT id FROM game_results WHERE event_id = (SELECT id FROM events WHERE title = 'vs Eagles United')), (SELECT id FROM players WHERE first_name = 'Jordan' AND last_name = 'Martinez'), (SELECT id FROM users WHERE email = 'gamemaster.thunderbolts@sportshub.com'), 'physical_contact', 'yellow', 'Late tackle on opponent', 67),
((SELECT id FROM game_results WHERE event_id = (SELECT id FROM events WHERE title = 'vs Titans Academy')), (SELECT id FROM players WHERE first_name = 'Tyler' AND last_name = 'Anderson'), (SELECT id FROM users WHERE email = 'gamemaster.thunderbolts@sportshub.com'), 'dissent', 'yellow', 'Arguing with referee', 78);

-- ============================================================================
-- SAMPLE PERFORMANCE ANALYTICS
-- ============================================================================

INSERT INTO performance_analytics (player_id, date, training_attendance_rate, game_participation_rate, current_rating, consistency_score, medical_clearance_status, predicted_rating, risk_level, recommendation) VALUES
((SELECT id FROM players WHERE first_name = 'Alex' AND last_name = 'Thompson'), CURRENT_DATE, 95.0, 100.0, 8.5, 8.5, true, 8.7, 'low', 'starter'),
((SELECT id FROM players WHERE first_name = 'Jordan' AND last_name = 'Martinez'), CURRENT_DATE, 90.0, 93.0, 7.8, 7.8, true, 8.0, 'low', 'starter'),
((SELECT id FROM players WHERE first_name = 'Ryan' AND last_name = 'Davis'), CURRENT_DATE, 100.0, 100.0, 8.2, 8.2, true, 8.5, 'low', 'starter'),
((SELECT id FROM players WHERE first_name = 'Tyler' AND last_name = 'Anderson'), CURRENT_DATE, 95.0, 100.0, 8.7, 8.7, true, 8.9, 'low', 'starter'),
((SELECT id FROM players WHERE first_name = 'Chris' AND last_name = 'Wilson'), CURRENT_DATE, 85.0, 0.0, 6.5, 6.5, true, 7.0, 'medium', 'bench'),
((SELECT id FROM players WHERE first_name = 'Morgan' AND last_name = 'Taylor'), CURRENT_DATE, 90.0, 0.0, 7.0, 7.0, true, 7.2, 'low', 'bench');

-- ============================================================================
-- SAMPLE NOTIFICATIONS
-- ============================================================================

INSERT INTO notifications (recipient_id, sender_id, notification_type, title, message, priority, related_record_id, related_record_type) VALUES
((SELECT user_id FROM players WHERE first_name = 'Tyler' AND last_name = 'Anderson'), (SELECT id FROM users WHERE email = 'coach.thunderbolts@sportshub.com'), 'performance_alert', 'Outstanding Performance!', 'You scored 2 goals in the last game. Keep it up!', 'normal', (SELECT id FROM players WHERE first_name = 'Tyler' AND last_name = 'Anderson'), 'player'),
((SELECT user_id FROM players WHERE first_name = 'Chris' AND last_name = 'Wilson'), (SELECT id FROM users WHERE email = 'coach.thunderbolts@sportshub.com'), 'training_reminder', 'Training Tomorrow', 'Don''t forget training session at 17:00 on the Main Field', 'normal', (SELECT id FROM events WHERE title = 'Fitness Session'), 'event');

-- ============================================================================
-- RUN AUTOMATED FUNCTIONS
-- ============================================================================

-- Update performance analytics
SELECT update_performance_analytics();

-- Check for player promotions (this will promote players with 3+ consecutive attendances)
-- The trigger should handle this automatically, but we can run a check
UPDATE players SET status = 'OFFICIAL_PLAYER'
WHERE id IN (
  SELECT p.id FROM players p
  WHERE p.status = 'TRYOUT'
  AND p.attendance_streak >= 3
);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check team dashboard
SELECT 'Team Dashboard:' as info;
SELECT * FROM team_performance_dashboard;

-- Check player rankings
SELECT 'Player Rankings for Thunderbolts FC:' as info;
SELECT first_name, last_name, position, performance_rating, status, team_rank
FROM player_ranking
WHERE team_id = (SELECT id FROM teams WHERE name = 'Thunderbolts FC')
ORDER BY team_rank;

-- Check medical clearance
SELECT 'Medical Clearance Status:' as info;
SELECT p.first_name, p.last_name, mc.clearance_status, mc.risk_level
FROM players p
CROSS JOIN assess_medical_clearance(p.id) mc
WHERE p.team_id = (SELECT id FROM teams WHERE name = 'Thunderbolts FC');

-- Success message
SELECT 'Sample data inserted successfully! The Sports Hub system is ready for testing.' as status;</content>
<parameter name="filePath">c:\Users\ACER\Downloads\sportshub\sportshub\sportshub\docs\SPORTS_HUB_SAMPLE_DATA.sql