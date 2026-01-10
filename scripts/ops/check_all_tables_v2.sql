-- ============================================
-- Check Row Counts - ALL ZAMM Tables
-- ============================================
-- Based on actual schema_snapshot.sql
-- Date: January 9, 2026

SELECT 'lib_athletes' as table_name, COUNT(*) as row_count FROM zamm.lib_athletes
UNION ALL SELECT 'lib_benchmarks', COUNT(*) FROM zamm.lib_benchmarks
UNION ALL SELECT 'lib_benchmark_blocks', COUNT(*) FROM zamm.lib_benchmark_blocks
UNION ALL SELECT 'lib_benchmark_exercises', COUNT(*) FROM zamm.lib_benchmark_exercises
UNION ALL SELECT 'lib_block_aliases', COUNT(*) FROM zamm.lib_block_aliases
UNION ALL SELECT 'lib_block_types', COUNT(*) FROM zamm.lib_block_types
UNION ALL SELECT 'lib_coaches', COUNT(*) FROM zamm.lib_coaches
UNION ALL SELECT 'lib_equipment_catalog', COUNT(*) FROM zamm.lib_equipment_catalog
UNION ALL SELECT 'lib_equipment_aliases', COUNT(*) FROM zamm.lib_equipment_aliases
UNION ALL SELECT 'lib_exercise_catalog', COUNT(*) FROM zamm.lib_exercise_catalog
UNION ALL SELECT 'lib_exercise_aliases', COUNT(*) FROM zamm.lib_exercise_aliases
UNION ALL SELECT 'lib_movement_patterns', COUNT(*) FROM zamm.lib_movement_patterns
UNION ALL SELECT 'lib_muscle_groups', COUNT(*) FROM zamm.lib_muscle_groups
UNION ALL SELECT 'lib_parser_rulesets', COUNT(*) FROM zamm.lib_parser_rulesets
UNION ALL SELECT 'lib_prescription_schemas', COUNT(*) FROM zamm.lib_prescription_schemas
UNION ALL SELECT 'lib_result_models', COUNT(*) FROM zamm.lib_result_models
UNION ALL SELECT 'stg_parse_drafts', COUNT(*) FROM zamm.stg_parse_drafts
UNION ALL SELECT 'stg_draft_edits', COUNT(*) FROM zamm.stg_draft_edits
UNION ALL SELECT 'stg_imports', COUNT(*) FROM zamm.stg_imports
UNION ALL SELECT 'log_validation_reports', COUNT(*) FROM zamm.log_validation_reports
UNION ALL SELECT 'workout_main', COUNT(*) FROM zamm.workout_main
UNION ALL SELECT 'workout_sessions', COUNT(*) FROM zamm.workout_sessions
UNION ALL SELECT 'workout_blocks', COUNT(*) FROM zamm.workout_blocks
UNION ALL SELECT 'workout_items', COUNT(*) FROM zamm.workout_items
UNION ALL SELECT 'res_blocks', COUNT(*) FROM zamm.res_blocks
UNION ALL SELECT 'res_intervals', COUNT(*) FROM zamm.res_intervals
UNION ALL SELECT 'res_item_sets', COUNT(*) FROM zamm.res_item_sets
ORDER BY table_name;
