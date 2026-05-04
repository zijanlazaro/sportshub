-- Update all event dates from 2025 to 2026
UPDATE events 
SET event_date = REPLACE(event_date::text, '2025-', '2026-')::date
WHERE event_date::text LIKE '2025-%';

-- Verify the update
SELECT event_title, event_date FROM events ORDER BY event_date;