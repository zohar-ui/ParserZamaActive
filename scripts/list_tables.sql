-- Get all table names in zamm schema
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'zamm' 
ORDER BY table_name;
