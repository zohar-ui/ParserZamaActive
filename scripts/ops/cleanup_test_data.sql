-- ============================================
-- Cleanup Test Data Before Production
-- ============================================
-- Purpose: Remove all test/draft data while preserving catalogs
-- Created: January 9, 2026
-- 
-- CAUTION: This will DELETE data. Backup recommended!
-- Run: PGPASSWORD="xxx" psql -h db.xxx.supabase.co -U postgres -d postgres -f scripts/cleanup_test_data.sql

BEGIN;

-- Show current counts BEFORE cleanup
SELECT '=== BEFORE CLEANUP ===' as status;
SELECT 'stg_imports' as table_name, COUNT(*) as row_count FROM zamm.stg_imports
UNION ALL SELECT 'stg_parse_drafts', COUNT(*) FROM zamm.stg_parse_drafts
UNION ALL SELECT 'stg_draft_edits', COUNT(*) FROM zamm.stg_draft_edits
UNION ALL SELECT 'log_validation_reports', COUNT(*) FROM zamm.log_validation_reports
UNION ALL SELECT 'workout_item_set_results', COUNT(*) FROM zamm.workout_item_set_results
UNION ALL SELECT 'workout_items', COUNT(*) FROM zamm.workout_items
UNION ALL SELECT 'workout_blocks', COUNT(*) FROM zamm.workout_blocks
UNION ALL SELECT 'workout_sessions', COUNT(*) FROM zamm.workout_sessions
UNION ALL SELECT 'workout_main', COUNT(*) FROM zamm.workout_main
UNION ALL SELECT 'res_item_sets', COUNT(*) FROM zamm.res_item_sets
UNION ALL SELECT 'res_intervals', COUNT(*) FROM zamm.res_intervals
UNION ALL SELECT 'res_blocks', COUNT(*) FROM zamm.res_blocks;

-- ============================================
-- DELETE Operations (Order matters for FK constraints!)
-- ============================================

-- Stage 1: Workout detail tables (bottom-up to respect FK constraints)
-- Must delete workouts FIRST because parse_drafts has FK from workout_main
DELETE FROM zamm.workout_item_set_results;  -- Child of workout_items
DELETE FROM zamm.workout_items;             -- Child of workout_blocks
DELETE FROM zamm.workout_blocks;            -- Child of workout_sessions
DELETE FROM zamm.workout_sessions;          -- Child of workout_main
DELETE FROM zamm.workout_main;              -- Top level (has FK to parse_drafts!)

-- Stage 2: Results tables
DELETE FROM zamm.res_item_sets;
DELETE FROM zamm.res_intervals;
DELETE FROM zamm.res_blocks;

-- Stage 3: Validation/Logging tables
DELETE FROM zamm.log_validation_reports;

-- Stage 4: Staging tables (now safe to delete)
DELETE FROM zamm.stg_draft_edits;
DELETE FROM zamm.stg_parse_drafts;
DELETE FROM zamm.stg_imports;

-- Show counts AFTER cleanup
SELECT '=== AFTER CLEANUP ===' as status;
SELECT 'stg_imports' as table_name, COUNT(*) as row_count FROM zamm.stg_imports
UNION ALL SELECT 'stg_parse_drafts', COUNT(*) FROM zamm.stg_parse_drafts
UNION ALL SELECT 'stg_draft_edits', COUNT(*) FROM zamm.stg_draft_edits
UNION ALL SELECT 'log_validation_reports', COUNT(*) FROM zamm.log_validation_reports
UNION ALL SELECT 'workout_item_set_results', COUNT(*) FROM zamm.workout_item_set_results
UNION ALL SELECT 'workout_items', COUNT(*) FROM zamm.workout_items
UNION ALL SELECT 'workout_blocks', COUNT(*) FROM zamm.workout_blocks
UNION ALL SELECT 'workout_sessions', COUNT(*) FROM zamm.workout_sessions
UNION ALL SELECT 'workout_main', COUNT(*) FROM zamm.workout_main
UNION ALL SELECT 'res_item_sets', COUNT(*) FROM zamm.res_item_sets
UNION ALL SELECT 'res_intervals', COUNT(*) FROM zamm.res_intervals
UNION ALL SELECT 'res_blocks', COUNT(*) FROM zamm.res_blocks;

-- Show preserved catalog data
SELECT '=== PRESERVED CATALOGS ===' as status;
SELECT 'lib_athletes' as table_name, COUNT(*) as row_count FROM zamm.lib_athletes
UNION ALL SELECT 'lib_coaches', COUNT(*) FROM zamm.lib_coaches
UNION ALL SELECT 'lib_exercise_catalog', COUNT(*) FROM zamm.lib_exercise_catalog
UNION ALL SELECT 'lib_equipment_catalog', COUNT(*) FROM zamm.lib_equipment_catalog
UNION ALL SELECT 'lib_block_types', COUNT(*) FROM zamm.lib_block_types
UNION ALL SELECT 'lib_parser_rulesets', COUNT(*) FROM zamm.lib_parser_rulesets;

COMMIT;

SELECT '✅ Cleanup complete! Database is ready for production data.' as result;
