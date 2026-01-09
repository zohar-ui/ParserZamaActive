-- ============================================
-- Check Row Counts - Simplified Version
-- ============================================
-- Purpose: Count rows in all existing zamm tables
-- Created: January 9, 2026

SELECT 
    schemaname as schema,
    tablename as table_name,
    (xpath('/row/cnt/text()', 
        xmlquery(format('SELECT COUNT(*) as cnt FROM %I.%I', schemaname, tablename)))
    )[1]::text::int as row_count
FROM pg_tables
WHERE schemaname = 'zamm'
ORDER BY tablename;
