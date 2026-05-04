-- Add sample events data (Bulls vs Bisaya game and others)
-- This assumes the events table already exists with standard column names

INSERT INTO events (name, type, date, time, location, opponent, description) VALUES
('Bulls vs Bisaya Championship', 'game', '2025-01-30', '19:00', 'Sports Arena', 'Team Bisaya', 'Championship game between Bulls and Bisaya teams. This is a crucial match for the season standings.'),
('Team Training Session', 'training', '2025-01-25', '16:00', 'Training Facility', NULL, 'Regular team training session focusing on offensive strategies.'),
('Pre-Game Team Meeting', 'meeting', '2025-01-29', '17:00', 'Conference Room', NULL, 'Strategy meeting before the championship game against Bisaya.'),
('Regional Tournament', 'tournament', '2025-02-15', '09:00', 'Regional Sports Complex', NULL, 'Multi-day regional tournament featuring top teams from the area.'),
('Bulls vs Eagles', 'game', '2025-02-05', '20:00', 'Home Court', 'Team Eagles', 'Regular season game against the Eagles team.'),
('Conditioning Training', 'training', '2025-01-27', '15:30', 'Gym', NULL, 'Physical conditioning and fitness training session.'),
('Coach Strategy Session', 'meeting', '2025-02-01', '14:00', 'Coach Office', NULL, 'Coaching staff meeting to discuss upcoming games and player development.');