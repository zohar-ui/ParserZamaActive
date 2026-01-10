-- ============================================
-- SQL Template with Schema Verification
-- ============================================
-- Purpose: Template for writing safe SQL queries
-- Always copy this when writing new SQL

-- ============================================
-- STEP 1: VERIFY TABLE EXISTS
-- ============================================
-- Uncomment and run first to verify table name:
/*
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'zamm' 
  AND table_name = 'YOUR_TABLE_NAME';
*/

-- ============================================
-- STEP 2: VERIFY COLUMNS
-- ============================================
-- Uncomment and run to see column structure:
/*
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'zamm' 
  AND table_name = 'YOUR_TABLE_NAME'
ORDER BY ordinal_position;
*/

-- ============================================
-- STEP 3: WRITE YOUR QUERY
-- ============================================
-- Now write your actual query with verified names:

-- Example:
-- SELECT * FROM zamm.YOUR_TABLE_NAME LIMIT 10;
