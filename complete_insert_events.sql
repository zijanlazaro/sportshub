-- Get a user ID to use as created_by
SELECT id, email FROM users LIMIT 3;

-- Use the coach's ID from Bulls team: e08fd534-6088-4474-b788-b2e54df02839
INSERT INTO events (team_id, created_by, event_title, event_type, event_date, event_time, location, event_description, status) VALUES
('550e8400-e29b-41d4-a716-446655440003', 'e08fd534-6088-4474-b788-b2e54df02839', 'Bulls vs Bisaya Championship', 'game', '2025-01-30', '19:00', 'Sports Arena', 'Championship game between Bulls and Bisaya teams. This is a crucial match for the season standings. Opponent: Team Bisaya', 'scheduled'),
('550e8400-e29b-41d4-a716-446655440003', 'e08fd534-6088-4474-b788-b2e54df02839', 'Team Training Session', 'training', '2025-01-25', '16:00', 'Training Facility', 'Regular team training session focusing on offensive strategies.', 'scheduled'),
('550e8400-e29b-41d4-a716-446655440003', 'e08fd534-6088-4474-b788-b2e54df02839', 'Pre-Game Team Meeting', 'meeting', '2025-01-29', '17:00', 'Conference Room', 'Strategy meeting before the championship game against Bisaya.', 'scheduled'),
('550e8400-e29b-41d4-a716-446655440003', 'e08fd534-6088-4474-b788-b2e54df02839', 'Regional Tournament', 'tournament', '2025-02-15', '09:00', 'Regional Sports Complex', 'Multi-day regional tournament featuring top teams from the area.', 'scheduled'),
('550e8400-e29b-41d4-a716-446655440003', 'e08fd534-6088-4474-b788-b2e54df02839', 'Bulls vs Eagles', 'game', '2025-02-05', '20:00', 'Home Court', 'Regular season game against the Eagles team. Opponent: Team Eagles', 'scheduled'),
('550e8400-e29b-41d4-a716-446655440003', 'e08fd534-6088-4474-b788-b2e54df02839', 'Conditioning Training', 'training', '2025-01-27', '15:30', 'Gym', 'Physical conditioning and fitness training session.', 'scheduled'),
('550e8400-e29b-41d4-a716-446655440003', 'e08fd534-6088-4474-b788-b2e54df02839', 'Coach Strategy Session', 'meeting', '2025-02-01', '14:00', 'Coach Office', 'Coaching staff meeting to discuss upcoming games and player development.', 'scheduled');