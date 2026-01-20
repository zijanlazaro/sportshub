-- Enhanced Medical Records Database Schema
-- Add new columns for comprehensive medical data

-- Add new columns to medical_records table
ALTER TABLE medical_records 
ADD COLUMN IF NOT EXISTS blood_pressure VARCHAR(20),
ADD COLUMN IF NOT EXISTS heart_rate INTEGER,
ADD COLUMN IF NOT EXISTS temperature DECIMAL(4,1),
ADD COLUMN IF NOT EXISTS weight DECIMAL(5,1),
ADD COLUMN IF NOT EXISTS treatment TEXT,
ADD COLUMN IF NOT EXISTS expected_return_date DATE,
ADD COLUMN IF NOT EXISTS follow_up_required BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS follow_up_date DATE,
ADD COLUMN IF NOT EXISTS actual_return_date DATE;

-- Update existing columns to allow more comprehensive data
ALTER TABLE medical_records 
ALTER COLUMN injury_type TYPE VARCHAR(100),
ALTER COLUMN description TYPE TEXT;

-- Add check constraint for severity if not exists
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.check_constraints 
                   WHERE constraint_name = 'medical_records_severity_check') THEN
        ALTER TABLE medical_records 
        ADD CONSTRAINT medical_records_severity_check 
        CHECK (severity IN ('minor', 'moderate', 'severe') OR severity IS NULL);
    END IF;
END $$;

-- Ensure recovery_status constraint allows our values
ALTER TABLE medical_records DROP CONSTRAINT IF EXISTS medical_records_recovery_status_check;
ALTER TABLE medical_records 
ADD CONSTRAINT medical_records_recovery_status_check 
CHECK (recovery_status IN ('cleared', 'recovering', 'chronic'));

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_medical_records_clearance ON medical_records(clearance_to_play);
CREATE INDEX IF NOT EXISTS idx_medical_records_recovery_status ON medical_records(recovery_status);
CREATE INDEX IF NOT EXISTS idx_medical_records_follow_up ON medical_records(follow_up_required, follow_up_date);

-- Create a view for medical clearance status
CREATE OR REPLACE VIEW player_medical_status AS
SELECT 
    p.id as player_id,
    p.first_name,
    p.last_name,
    p.jersey_number,
    COALESCE(latest_record.clearance_to_play, true) as cleared_to_play,
    latest_record.recovery_status,
    latest_record.restrictions,
    latest_record.injury_date as last_medical_date,
    latest_record.injury_type as last_medical_type
FROM players p
LEFT JOIN LATERAL (
    SELECT *
    FROM medical_records mr
    WHERE mr.player_id = p.id
    ORDER BY mr.injury_date DESC, mr.created_at DESC
    LIMIT 1
) latest_record ON true;

SELECT 'Enhanced medical records schema updated successfully!' as message;