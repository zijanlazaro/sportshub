-- ============================================================================
-- GAME MASTER FEATURE MIGRATION
-- ============================================================================

-- 1. Update users role constraint to include game_master
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check
  CHECK (role IN ('admin', 'coach', 'medical_staff', 'player', 'game_master'));

-- 2. Game Results table
CREATE TABLE game_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  recorded_by UUID NOT NULL REFERENCES users(id),

  -- Score
  team_score INT NOT NULL DEFAULT 0,
  opponent_score INT NOT NULL DEFAULT 0,

  -- Result
  result TEXT CHECK (result IN ('win', 'loss', 'draw')),

  -- Team-level stats
  team_fouls INT DEFAULT 0,
  opponent_fouls INT DEFAULT 0,

  -- MVP
  mvp_player_id UUID REFERENCES players(id),
  mvp_notes TEXT,

  -- Extra details
  notes TEXT,
  half_time_score TEXT, -- e.g. "2-1"

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(event_id)
);

-- 3. Per-player game stats
CREATE TABLE player_game_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_result_id UUID NOT NULL REFERENCES game_results(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,

  points INT DEFAULT 0,
  assists INT DEFAULT 0,
  fouls INT DEFAULT 0,
  yellow_cards INT DEFAULT 0,
  red_cards INT DEFAULT 0,
  minutes_played INT DEFAULT 0,
  did_not_play BOOLEAN DEFAULT false,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(game_result_id, player_id)
);

-- 4. Indexes
CREATE INDEX idx_game_results_event_id ON game_results(event_id);
CREATE INDEX idx_game_results_team_id ON game_results(team_id);
CREATE INDEX idx_player_game_stats_game_result_id ON player_game_stats(game_result_id);
CREATE INDEX idx_player_game_stats_player_id ON player_game_stats(player_id);

-- 5. RLS
ALTER TABLE game_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_game_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "game_results_select" ON game_results FOR SELECT USING (true);
CREATE POLICY "game_results_insert" ON game_results FOR INSERT WITH CHECK (auth.uid() = recorded_by);
CREATE POLICY "game_results_update" ON game_results FOR UPDATE USING (auth.uid() = recorded_by);

CREATE POLICY "player_game_stats_select" ON player_game_stats FOR SELECT USING (true);
CREATE POLICY "player_game_stats_insert" ON player_game_stats FOR INSERT WITH CHECK (true);
CREATE POLICY "player_game_stats_update" ON player_game_stats FOR UPDATE USING (true);
