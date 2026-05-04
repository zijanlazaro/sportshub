-- Check what status values are allowed
SELECT conname, consrc FROM pg_constraint WHERE conname LIKE '%status%';

-- Try with common status values
INSERT INTO events (team_id, created_by, event_title, event_type, event_date, event_time, location, event_description, status) VALUES
('550e8400-e29b-41d4-a716-446655440003', 'e08fd534-6088-4474-b788-b2e54df02839', 'Bulls vs Bisaya Championship', 'game', '2025-01-30', '19:00', 'Sports Arena', 'Championship game between Bulls and Bisaya teams. This is a crucial match for the season standings. Opponent: Team Bisaya', 'upcoming'),
('550e8400-e29b-41d4-a716-446655440003', 'e08fd534-6088-4474-b788-b2e54df02839', 'Team Training Session', 'training', '2025-01-25', '16:00', 'Training Facility', 'Regular team training session focusing on offensive strategies.', 'upcoming'),
('550e8400-e29b-41d4-a716-446655440003', 'e08fd534-6088-4474-b788-b2e54df02839', 'Pre-Game Team Meeting', 'meeting', '2025-01-29', '17:00', 'Conference Room', 'Strategy meeting before the championship game against Bisaya.', 'upcoming');

-- If that fails, try without status (it might have a default)
-- INSERT INTO events (team_id, created_by, event_title, event_type, event_date, event_time, location, event_description) VALUES ...