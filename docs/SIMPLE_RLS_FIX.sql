-- Simple RLS Fix - Core Tables Only
-- Drop all existing policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON ' || r.schemaname || '.' || r.tablename;
    END LOOP;
END $$;

-- Core table policies
CREATE POLICY "users_all" ON users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "teams_all" ON teams FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "players_all" ON players FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "player_stats_all" ON player_stats FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "medical_records_all" ON medical_records FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "training_sessions_all" ON training_sessions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "games_all" ON games FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "events_all" ON events FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "audit_logs_all" ON audit_logs FOR ALL USING (true) WITH CHECK (true);

SELECT 'Core RLS policies fixed!' as message;