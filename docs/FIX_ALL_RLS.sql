-- Comprehensive RLS Policy Fix
-- Allow proper CRUD operations for all tables

-- Drop all existing policies to start fresh
DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all policies on all tables
    FOR r IN (SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON ' || r.schemaname || '.' || r.tablename;
    END LOOP;
END $$;

-- USERS TABLE POLICIES
CREATE POLICY "Allow user registration" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "Users view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- TEAMS TABLE POLICIES  
CREATE POLICY "Anyone can view teams" ON teams FOR SELECT USING (true);
CREATE POLICY "Anyone can create teams" ON teams FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update teams" ON teams FOR UPDATE USING (true);

-- PLAYERS TABLE POLICIES
CREATE POLICY "Anyone can view players" ON players FOR SELECT USING (true);
CREATE POLICY "Anyone can create players" ON players FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update players" ON players FOR UPDATE USING (true);
CREATE POLICY "Anyone can delete players" ON players FOR DELETE USING (true);

-- PLAYER STATS POLICIES
CREATE POLICY "Anyone can view player stats" ON player_stats FOR SELECT USING (true);
CREATE POLICY "Anyone can create player stats" ON player_stats FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update player stats" ON player_stats FOR UPDATE USING (true);

-- MEDICAL RECORDS POLICIES
CREATE POLICY "Anyone can view medical records" ON medical_records FOR SELECT USING (true);
CREATE POLICY "Anyone can create medical records" ON medical_records FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update medical records" ON medical_records FOR UPDATE USING (true);
CREATE POLICY "Anyone can delete medical records" ON medical_records FOR DELETE USING (true);

-- TRAINING SESSIONS POLICIES
CREATE POLICY "Anyone can view training sessions" ON training_sessions FOR SELECT USING (true);
CREATE POLICY "Anyone can create training sessions" ON training_sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update training sessions" ON training_sessions FOR UPDATE USING (true);
CREATE POLICY "Anyone can delete training sessions" ON training_sessions FOR DELETE USING (true);

-- TRAINING ATTENDANCE POLICIES
CREATE POLICY "Anyone can view training attendance" ON training_attendance FOR SELECT USING (true);
CREATE POLICY "Anyone can create training attendance" ON training_attendance FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update training attendance" ON training_attendance FOR UPDATE USING (true);

-- GAMES POLICIES
CREATE POLICY "Anyone can view games" ON games FOR SELECT USING (true);
CREATE POLICY "Anyone can create games" ON games FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update games" ON games FOR UPDATE USING (true);
CREATE POLICY "Anyone can delete games" ON games FOR DELETE USING (true);

-- EVENTS POLICIES
CREATE POLICY "Anyone can view events" ON events FOR SELECT USING (true);
CREATE POLICY "Anyone can create events" ON events FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update events" ON events FOR UPDATE USING (true);
CREATE POLICY "Anyone can delete events" ON events FOR DELETE USING (true);

-- NEW TABLES POLICIES
CREATE POLICY "Anyone can view player analytics" ON player_analytics FOR SELECT USING (true);
CREATE POLICY "Anyone can create player analytics" ON player_analytics FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update player analytics" ON player_analytics FOR UPDATE USING (true);

CREATE POLICY "Anyone can view team statistics" ON team_statistics FOR SELECT USING (true);
CREATE POLICY "Anyone can create team statistics" ON team_statistics FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update team statistics" ON team_statistics FOR UPDATE USING (true);

CREATE POLICY "Anyone can view medical assessments" ON medical_assessments FOR SELECT USING (true);
CREATE POLICY "Anyone can create medical assessments" ON medical_assessments FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update medical assessments" ON medical_assessments FOR UPDATE USING (true);

SELECT 'All RLS policies fixed - full CRUD access enabled!' as message;