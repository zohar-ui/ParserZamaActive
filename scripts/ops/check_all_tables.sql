-- ============================================
-- Check Row Counts in All ZAMM Tables
-- ============================================
-- Purpose: Verify current data state before cleanup
-- Created: January 9, 2026
-- Usage: Run in Supabase SQL Editor or via psql

-- Infrastructure Tables
SELECT 'dim_athletes' as table_name, COUNT(*) as row_count FROM zamm.dim_athletes
UNION ALL
SELECT 'parser_rulesets', COUNT(*) FROM zamm.parser_rulesets

-- Catalog Tables (New naming from migrations)
UNION ALL
SELECT 'exercise_catalog', COUNT(*) FROM zamm.exercise_catalog
UNION ALL
SELECT 'exercise_aliases', COUNT(*) FROM zamm.exercise_aliases
UNION ALL
SELECT 'equipment_catalog', COUNT(*) FROM zamm.equipment_catalog
UNION ALL
SELECT 'equipment_aliases', COUNT(*) FROM zamm.equipment_aliases
UNION ALL
SELECT 'block_type_catalog', COUNT(*) FROM zamm.block_type_catalog
UNION ALL
SELECT 'block_code_aliases', COUNT(*) FROM zamm.block_code_aliases

-- Configuration Tables
UNION ALL
SELECT 'equipment_config_templates', COUNT(*) FROM zamm.equipment_config_templates

-- Staging Tables (should be cleaned)
UNION ALL
SELECT 'imports', COUNT(*) FROM zamm.imports
UNION ALL
SELECT 'parse_drafts', COUNT(*) FROM zamm.parse_drafts
UNION ALL
SELECT 'draft_edits', COUNT(*) FROM zamm.draft_edits

-- Validation/Logging Tables (should be cleaned)
UNION ALL
SELECT 'validation_reports', COUNT(*) FROM zamm.validation_reports

-- Workout Core Tables (should be cleaned)
UNION ALL
SELECT 'workouts', COUNT(*) FROM zamm.workouts
UNION ALL
SELECT 'workout_sessions', COUNT(*) FROM zamm.workout_sessions
UNION ALL
SELECT 'workout_blocks', COUNT(*) FROM zamm.workout_blocks
UNION ALL
SELECT 'workout_items', COUNT(*) FROM zamm.workout_items
UNION ALL
SELECT 'item_set_results', COUNT(*) FROM zamm.item_set_results

-- Results Tables (should be cleaned)
UNION ALL
SELECT 'workout_block_results', COUNT(*) FROM zamm.workout_block_results
UNION ALL
SELECT 'interval_segments', COUNT(*) FROM zamm.interval_segments

ORDER BY 
    CASE 
        WHEN table_name LIKE '%athlete%' THEN 1
        WHEN table_name LIKE '%catalog%' THEN 2
        WHEN table_name LIKE '%alias%' THEN 3
        WHEN table_name LIKE 'import%' OR table_name LIKE '%draft%' THEN 4
        WHEN table_name LIKE '%validation%' THEN 5
        WHEN table_name LIKE 'workout%' THEN 6
        WHEN table_name LIKE '%result%' OR table_name LIKE '%segment%' THEN 7
        ELSE 10
    END,
    table_name;
