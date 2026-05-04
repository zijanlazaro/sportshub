-- First get a team ID to use for the events
-- Run this first to see available teams:
SELECT id, name FROM teams LIMIT 5;

-- Then use one of the team IDs in the insert below
-- Replace 'YOUR_TEAM_ID_HERE' with an actual team ID from the query above

INSERT INTO events (team_id, event_title, event_type, event_date, event_time, location, event_description, status) VALUES
('YOUR_TEAM_ID_HERE', 'Bulls vs Bisaya Championship', 'game', '2025-01-30', '19:00', 'Sports Arena', 'Championship game between Bulls and Bisaya teams. This is a crucial match for the season standings. Opponent: Team Bisaya', 'scheduled'),
('YOUR_TEAM_ID_HERE', 'Team Training Session', 'training', '2025-01-25', '16:00', 'Training Facility', 'Regular team training session focusing on offensive strategies.', 'scheduled'),
('YOUR_TEAM_ID_HERE', 'Pre-Game Team Meeting', 'meeting', '2025-01-29', '17:00', 'Conference Room', 'Strategy meeting before the championship game against Bisaya.', 'scheduled'),
('YOUR_TEAM_ID_HERE', 'Regional Tournament', 'tournament', '2025-02-15', '09:00', 'Regional Sports Complex', 'Multi-day regional tournament featuring top teams from the area.', 'scheduled'),
('YOUR_TEAM_ID_HERE', 'Bulls vs Eagles', 'game', '2025-02-05', '20:00', 'Home Court', 'Regular season game against the Eagles team. Opponent: Team Eagles', 'scheduled'),
('YOUR_TEAM_ID_HERE', 'Conditioning Training', 'training', '2025-01-27', '15:30', 'Gym', 'Physical conditioning and fitness training session.', 'scheduled'),
('YOUR_TEAM_ID_HERE', 'Coach Strategy Session', 'meeting', '2025-02-01', '14:00', 'Coach Office', 'Coaching staff meeting to discuss upcoming games and player development.', 'scheduled');