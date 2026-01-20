-- Sports Hub Dummy Data
-- Sample data for testing the application

-- Insert sample teams
INSERT INTO teams (id, name, sport, season, active) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'Lakers', 'Basketball', '2024', true),
('550e8400-e29b-41d4-a716-446655440002', 'Warriors', 'Basketball', '2024', true),
('550e8400-e29b-41d4-a716-446655440003', 'Bulls', 'Basketball', '2024', true);

-- Insert sample players (without user_id since users must register normally)
INSERT INTO players (id, team_id, first_name, last_name, age, position, jersey_number, height_cm, weight_kg) VALUES
('550e8400-e29b-41d4-a716-446655440030', '550e8400-e29b-41d4-a716-446655440001', 'LeBron', 'James', 39, 'Forward', 6, 206, 113),
('550e8400-e29b-41d4-a716-446655440031', '550e8400-e29b-41d4-a716-446655440001', 'Anthony', 'Davis', 31, 'Center', 3, 211, 115),
('550e8400-e29b-41d4-a716-446655440032', '550e8400-e29b-41d4-a716-446655440001', 'Russell', 'Westbrook', 35, 'Guard', 0, 191, 91),
('550e8400-e29b-41d4-a716-446655440033', '550e8400-e29b-41d4-a716-446655440002', 'Stephen', 'Curry', 36, 'Guard', 30, 191, 84),
('550e8400-e29b-41d4-a716-446655440034', '550e8400-e29b-41d4-a716-446655440002', 'Klay', 'Thompson', 34, 'Guard', 11, 198, 98);

-- Insert player statistics
INSERT INTO player_stats (player_id, games_played, points_scored, assists, fouls_committed, avg_performance_rating) VALUES
('550e8400-e29b-41d4-a716-446655440030', 45, 1350, 405, 89, 8.5),
('550e8400-e29b-41d4-a716-446655440031', 42, 1260, 168, 112, 8.2),
('550e8400-e29b-41d4-a716-446655440032', 38, 912, 304, 95, 7.8),
('550e8400-e29b-41d4-a716-446655440033', 50, 1500, 350, 67, 9.1),
('550e8400-e29b-41d4-a716-446655440034', 35, 875, 140, 45, 8.0);

-- Insert player analytics
INSERT INTO player_analytics (player_id, training_attendance_rate, game_participation_rate, fitness_score, availability_status) VALUES
('550e8400-e29b-41d4-a716-446655440030', 95.5, 90.0, 8.5, 'available'),
('550e8400-e29b-41d4-a716-446655440031', 88.2, 84.0, 7.8, 'restricted'),
('550e8400-e29b-41d4-a716-446655440032', 92.1, 76.0, 8.2, 'available'),
('550e8400-e29b-41d4-a716-446655440033', 98.5, 100.0, 9.2, 'available'),
('550e8400-e29b-41d4-a716-446655440034', 85.0, 70.0, 7.5, 'injured');

-- Insert games
INSERT INTO games (team_id, opponent_name, game_date, game_time, location, status, notes) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'Boston Celtics', '2024-02-01', '19:30', 'Staples Center', 'upcoming', 'Important conference game'),
('550e8400-e29b-41d4-a716-446655440001', 'Miami Heat', '2024-01-20', '20:00', 'Staples Center', 'completed', 'Won 112-108'),
('550e8400-e29b-41d4-a716-446655440002', 'Lakers', '2024-02-05', '18:00', 'Chase Center', 'upcoming', 'Rivalry game');

-- Skip events and training sessions that require created_by (NOT NULL constraint)
-- These will be created after users register and login

-- Insert team statistics
INSERT INTO team_statistics (team_id, total_players, available_players, injured_players, restricted_players, avg_team_fitness, injury_rate, training_attendance_avg) VALUES
('550e8400-e29b-41d4-a716-446655440001', 3, 2, 0, 1, 8.17, 33.33, 88.9),
('550e8400-e29b-41d4-a716-446655440002', 2, 1, 1, 0, 8.35, 50.0, 91.8);

SELECT 'Dummy data inserted successfully!' as message;