-- ============================================================================
-- SPORTS HUB - NEW RLS POLICIES FOR ANALYTICS TABLES
-- Add policies only for new tables to avoid conflicts
-- ============================================================================

-- Enable RLS on new tables only
DO $$ 
BEGIN
    -- Enable RLS on new tables if they exist
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'player_analytics') THEN
        ALTER TABLE player_analytics ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'team_statistics') THEN
        ALTER TABLE team_statistics ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'medical_assessments') THEN
        ALTER TABLE medical_assessments ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- ============================================================================
-- PLAYER ANALYTICS TABLE POLICIES
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Team members can view player analytics" ON player_analytics;
DROP POLICY IF EXISTS "Coaches can update player analytics" ON player_analytics;
DROP POLICY IF EXISTS "System can insert player analytics" ON player_analytics;

-- Team members can view player analytics
CREATE POLICY "Team members can view player analytics" ON player_analytics
FOR SELECT USING (
  player_id IN (SELECT id FROM players WHERE team_id IN (
    SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL
  ))
  OR auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- Coaches and medical staff can update analytics
CREATE POLICY "Coaches can update player analytics" ON player_analytics
FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach', 'medical_staff'))
)
WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach', 'medical_staff'))
);

-- System can insert analytics (for automated updates)
CREATE POLICY "System can insert player analytics" ON player_analytics
FOR INSERT WITH CHECK (true);

-- ============================================================================
-- TEAM STATISTICS TABLE POLICIES
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Team members can view team statistics" ON team_statistics;
DROP POLICY IF EXISTS "Coaches can update team statistics" ON team_statistics;
DROP POLICY IF EXISTS "System can insert team statistics" ON team_statistics;

-- Team members can view team statistics
CREATE POLICY "Team members can view team statistics" ON team_statistics
FOR SELECT USING (
  team_id IN (SELECT team_id FROM users WHERE id = auth.uid() AND team_id IS NOT NULL)
  OR auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- Coaches and admins can update team statistics
CREATE POLICY "Coaches can update team statistics" ON team_statistics
FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
)
WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'coach'))
);

-- System can insert team statistics (for automated updates)
CREATE POLICY "System can insert team statistics" ON team_statistics
FOR INSERT WITH CHECK (true);

-- ============================================================================
-- MEDICAL ASSESSMENTS TABLE POLICIES
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Medical staff can view assessments" ON medical_assessments;
DROP POLICY IF EXISTS "Players can view own assessments" ON medical_assessments;
DROP POLICY IF EXISTS "Medical staff can insert assessments" ON medical_assessments;
DROP POLICY IF EXISTS "Medical staff can update assessments" ON medical_assessments;

-- Medical staff and admins can view all assessments
CREATE POLICY "Medical staff can view assessments" ON medical_assessments
FOR SELECT USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

-- Players can view their own assessments
CREATE POLICY "Players can view own assessments" ON medical_assessments
FOR SELECT USING (
  player_id IN (SELECT id FROM players WHERE user_id = auth.uid())
);

-- Medical staff and admins can insert assessments
CREATE POLICY "Medical staff can insert assessments" ON medical_assessments
FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

-- Medical staff and admins can update assessments
CREATE POLICY "Medical staff can update assessments" ON medical_assessments
FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
)
WITH CHECK (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'medical_staff'))
);

-- Success message
SELECT 'New RLS policies for analytics tables created successfully!' as message;