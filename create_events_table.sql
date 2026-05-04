-- Create events table
CREATE TABLE IF NOT EXISTS events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('game', 'training', 'meeting', 'tournament', 'other')),
    event_date DATE NOT NULL,
    event_time TIME,
    location VARCHAR(255),
    opponent_team VARCHAR(255),
    description TEXT,
    team_id UUID REFERENCES teams(id),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_events_date ON events(event_date);
CREATE INDEX IF NOT EXISTS idx_events_team ON events(team_id);

-- Enable RLS (Row Level Security)
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view events" ON events;
DROP POLICY IF EXISTS "Users can insert events" ON events;
DROP POLICY IF EXISTS "Users can update their events" ON events;
DROP POLICY IF EXISTS "Users can delete their events" ON events;

-- Create RLS policies
CREATE POLICY "Users can view events" ON events FOR SELECT USING (true);
CREATE POLICY "Users can insert events" ON events FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can update their events" ON events FOR UPDATE USING (auth.uid() = created_by);
CREATE POLICY "Users can delete their events" ON events FOR DELETE USING (auth.uid() = created_by);

-- Insert sample events including Bulls vs Bisaya game (only if table is empty)
INSERT INTO events (title, event_type, event_date, event_time, location, opponent_team, description)
SELECT * FROM (
  VALUES
  ('Bulls vs Bisaya Championship', 'game', '2025-01-30', '19:00', 'Sports Arena', 'Team Bisaya', 'Championship game between Bulls and Bisaya teams. This is a crucial match for the season standings.'),
  ('Team Training Session', 'training', '2025-01-25', '16:00', 'Training Facility', NULL, 'Regular team training session focusing on offensive strategies.'),
  ('Pre-Game Team Meeting', 'meeting', '2025-01-29', '17:00', 'Conference Room', NULL, 'Strategy meeting before the championship game against Bisaya.'),
  ('Regional Tournament', 'tournament', '2025-02-15', '09:00', 'Regional Sports Complex', NULL, 'Multi-day regional tournament featuring top teams from the area.'),
  ('Bulls vs Eagles', 'game', '2025-02-05', '20:00', 'Home Court', 'Team Eagles', 'Regular season game against the Eagles team.'),
  ('Conditioning Training', 'training', '2025-01-27', '15:30', 'Gym', NULL, 'Physical conditioning and fitness training session.'),
  ('Coach Strategy Session', 'meeting', '2025-02-01', '14:00', 'Coach Office', NULL, 'Coaching staff meeting to discuss upcoming games and player development.')
) AS v(title, event_type, event_date, event_time, location, opponent_team, description)
WHERE NOT EXISTS (SELECT 1 FROM events LIMIT 1);

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();