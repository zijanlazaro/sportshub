-- Ensure proper RLS policies for medical and training CRUD operations

-- Medical records policies
DROP POLICY IF EXISTS "medical_records_all" ON medical_records;
CREATE POLICY "medical_records_select" ON medical_records FOR SELECT USING (true);
CREATE POLICY "medical_records_insert" ON medical_records FOR INSERT WITH CHECK (true);
CREATE POLICY "medical_records_update" ON medical_records FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "medical_records_delete" ON medical_records FOR DELETE USING (true);

-- Training sessions policies  
DROP POLICY IF EXISTS "training_sessions_all" ON training_sessions;
CREATE POLICY "training_sessions_select" ON training_sessions FOR SELECT USING (true);
CREATE POLICY "training_sessions_insert" ON training_sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "training_sessions_update" ON training_sessions FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "training_sessions_delete" ON training_sessions FOR DELETE USING (true);

-- Training attendance policies
DROP POLICY IF EXISTS "training_attendance_all" ON training_attendance;
CREATE POLICY "training_attendance_select" ON training_attendance FOR SELECT USING (true);
CREATE POLICY "training_attendance_insert" ON training_attendance FOR INSERT WITH CHECK (true);
CREATE POLICY "training_attendance_update" ON training_attendance FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "training_attendance_delete" ON training_attendance FOR DELETE USING (true);

-- Medical documents policies (if table exists)
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'medical_documents') THEN
        EXECUTE 'DROP POLICY IF EXISTS "medical_documents_all" ON medical_documents';
        EXECUTE 'CREATE POLICY "medical_documents_select" ON medical_documents FOR SELECT USING (true)';
        EXECUTE 'CREATE POLICY "medical_documents_insert" ON medical_documents FOR INSERT WITH CHECK (true)';
        EXECUTE 'CREATE POLICY "medical_documents_update" ON medical_documents FOR UPDATE USING (true) WITH CHECK (true)';
        EXECUTE 'CREATE POLICY "medical_documents_delete" ON medical_documents FOR DELETE USING (true)';
    END IF;
END $$;

SELECT 'Medical and Training CRUD policies updated successfully!' as message;