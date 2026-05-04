-- First, let's see what columns exist in the events table
-- Run this query first to see the table structure:
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'events';

-- Based on common event table structures, try these variations:

-- Option 1: If columns are named differently
INSERT INTO events (name, type, date, time, location, description) VALUES
('Bulls vs Bisaya Championship', 'game', '2025-01-30', '19:00:00', 'Sports Arena', 'Championship game between Bulls and Bisaya teams vs Team Bisaya'),
('Team Training Session', 'training', '2025-01-25', '16:00:00', 'Training Facility', 'Regular team training session focusing on offensive strategies'),
('Pre-Game Team Meeting', 'meeting', '2025-01-29', '17:00:00', 'Conference Room', 'Strategy meeting before the championship game against Bisaya'),
('Regional Tournament', 'tournament', '2025-02-15', '09:00:00', 'Regional Sports Complex', 'Multi-day regional tournament featuring top teams from the area'),
('Bulls vs Eagles', 'game', '2025-02-05', '20:00:00', 'Home Court', 'Regular season game against Team Eagles'),
('Conditioning Training', 'training', '2025-01-27', '15:30:00', 'Gym', 'Physical conditioning and fitness training session'),
('Coach Strategy Session', 'meeting', '2025-02-01', '14:00:00', 'Coach Office', 'Coaching staff meeting to discuss upcoming games and player development');

-- If the above fails, try Option 2:
-- INSERT INTO events (event_name, event_type, event_date, event_time, venue, notes) VALUES ...

-- If that fails too, try Option 3:
-- INSERT INTO events (title, category, scheduled_date, scheduled_time, venue, details) VALUES ...