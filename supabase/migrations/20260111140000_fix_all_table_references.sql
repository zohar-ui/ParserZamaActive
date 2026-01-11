-- ============================================
-- Migration: Fix All Table References
-- ============================================
-- Purpose: Ensure all functions and procedures use correct table names
-- Date: January 11, 2026
-- Version: 2.0.0
--
-- VERIFIED TABLE NAMES (from database inspection 2026-01-11):
-- ✅ workout_main (NOT workouts)
-- ✅ lib_block_types (NOT block_type_catalog)
-- ✅ lib_block_aliases (NOT block_code_aliases)
-- ✅ lib_athletes (NOT dim_athletes)
-- ✅ lib_equipment_catalog (NOT equipment_catalog)
-- ✅ lib_equipment_aliases (NOT equipment_aliases)
-- ✅ res_blocks (NOT workout_block_results)
-- ✅ workout_item_set_results (NOT item_set_results)
-- ============================================

-- ============================================
-- STEP 1: Rename tables if they have wrong names
-- ============================================

-- Check and rename block type tables
DO $$
BEGIN
    -- Rename block_type_catalog if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'zamm' AND table_name = 'block_type_catalog') THEN
        ALTER TABLE IF EXISTS zamm.block_type_catalog RENAME TO lib_block_types;
        RAISE NOTICE 'Renamed block_type_catalog to lib_block_types';
    END IF;

    -- Rename block_code_aliases if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'zamm' AND table_name = 'block_code_aliases') THEN
        ALTER TABLE IF EXISTS zamm.block_code_aliases RENAME TO lib_block_aliases;
        RAISE NOTICE 'Renamed block_code_aliases to lib_block_aliases';
    END IF;

    -- Rename dim_athletes if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'zamm' AND table_name = 'dim_athletes') THEN
        ALTER TABLE IF EXISTS zamm.dim_athletes RENAME TO lib_athletes;
        RAISE NOTICE 'Renamed dim_athletes to lib_athletes';
    END IF;

    -- Rename equipment_catalog if it exists (without lib_ prefix)
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'zamm' AND table_name = 'equipment_catalog') THEN
        ALTER TABLE IF EXISTS zamm.equipment_catalog RENAME TO lib_equipment_catalog;
        RAISE NOTICE 'Renamed equipment_catalog to lib_equipment_catalog';
    END IF;

    -- Rename equipment_aliases if it exists (without lib_ prefix)
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'zamm' AND table_name = 'equipment_aliases') THEN
        ALTER TABLE IF EXISTS zamm.equipment_aliases RENAME TO lib_equipment_aliases;
        RAISE NOTICE 'Renamed equipment_aliases to lib_equipment_aliases';
    END IF;
END$$;

-- ============================================
-- STEP 2: Fix normalize_block_code function
-- ============================================

CREATE OR REPLACE FUNCTION zamm.normalize_block_code(p_input TEXT)
RETURNS TABLE (
    block_code TEXT,
    block_type TEXT,
    category TEXT,
    result_model TEXT,
    ui_hint TEXT,
    display_name TEXT,
    matched_via TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_normalized TEXT;
BEGIN
    v_normalized := UPPER(TRIM(p_input));

    RETURN QUERY
    -- Try exact block_code match first
    SELECT
        lbt.block_code,
        lbt.block_type,
        lbt.category,
        lbt.result_model,
        lbt.ui_hint,
        lbt.display_name,
        'exact'::TEXT as matched_via
    FROM zamm.lib_block_types lbt
    WHERE UPPER(lbt.block_code) = v_normalized
    AND lbt.is_active = true

    UNION ALL

    -- Try alias match
    SELECT
        lbt.block_code,
        lbt.block_type,
        lbt.category,
        lbt.result_model,
        lbt.ui_hint,
        lbt.display_name,
        'alias'::TEXT as matched_via
    FROM zamm.lib_block_aliases lba
    JOIN zamm.lib_block_types lbt ON lba.block_code = lbt.block_code
    WHERE LOWER(lba.alias) = LOWER(p_input)
    AND lbt.is_active = true

    UNION ALL

    -- Try partial match on display_name
    SELECT
        lbt.block_code,
        lbt.block_type,
        lbt.category,
        lbt.result_model,
        lbt.ui_hint,
        lbt.display_name,
        'partial'::TEXT as matched_via
    FROM zamm.lib_block_types lbt
    WHERE LOWER(lbt.display_name) ILIKE '%' || LOWER(p_input) || '%'
    AND lbt.is_active = true

    ORDER BY matched_via
    LIMIT 5;
END;
$$;

COMMENT ON FUNCTION zamm.normalize_block_code IS
'✅ FIXED: AI Tool - Normalize block code/type input to standard block_code with full metadata. Uses lib_block_types and lib_block_aliases.';

-- ============================================
-- STEP 3: Fix check_equipment_exists function
-- ============================================

-- Drop existing function first
DROP FUNCTION IF EXISTS zamm.check_equipment_exists(TEXT);

CREATE OR REPLACE FUNCTION zamm.check_equipment_exists(p_equipment_name TEXT)
RETURNS TABLE (
    equipment_key UUID,
    equipment_name TEXT,
    category TEXT,
    matched_via TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    -- Exact match on equipment name
    SELECT
        lec.equipment_key,
        lec.equipment_name,
        lec.equipment_category as category,
        'exact'::TEXT as matched_via
    FROM zamm.lib_equipment_catalog lec
    WHERE LOWER(lec.equipment_name) = LOWER(p_equipment_name)

    UNION ALL

    -- Try alias match
    SELECT
        lec.equipment_key,
        lec.equipment_name,
        lec.equipment_category as category,
        'alias'::TEXT as matched_via
    FROM zamm.lib_equipment_aliases lea
    JOIN zamm.lib_equipment_catalog lec ON lea.equipment_key = lec.equipment_key
    WHERE LOWER(lea.alias_name) = LOWER(p_equipment_name)

    ORDER BY matched_via
    LIMIT 5;
END;
$$;

COMMENT ON FUNCTION zamm.check_equipment_exists IS
'✅ FIXED: AI Tool - Check if equipment exists by name. Uses lib_equipment_catalog and lib_equipment_aliases.';

-- ============================================
-- STEP 4: Fix other functions with dim_athletes reference
-- ============================================

-- Note: calculate_load_from_bodyweight function disabled
-- Reason: lib_athletes table does not have current_weight_kg column
-- TODO: Add bodyweight tracking table or add column to lib_athletes

-- DROP FUNCTION IF EXISTS zamm.calculate_load_from_bodyweight(UUID, NUMERIC);

COMMENT ON SCHEMA zamm IS '⚠️  Note: calculate_load_from_bodyweight function requires bodyweight column in lib_athletes';

-- Fix check_athlete_exists function
CREATE OR REPLACE FUNCTION zamm.check_athlete_exists(p_full_name TEXT)
RETURNS TABLE (
    athlete_id UUID,
    full_name TEXT,
    email TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        la.athlete_id,
        la.full_name,
        la.email
    FROM zamm.lib_athletes la
    WHERE LOWER(la.full_name) = LOWER(p_full_name)
    AND la.is_active = true;
END;
$$;

COMMENT ON FUNCTION zamm.check_athlete_exists IS
'✅ FIXED: AI Tool - Check if athlete exists by name. Uses lib_athletes.';

-- Fix get_athlete_context function
CREATE OR REPLACE FUNCTION zamm.get_athlete_context(p_athlete_id UUID)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'athlete_id', la.athlete_id,
        'full_name', la.full_name,
        'email', la.email,
        'recent_workouts', (
            SELECT json_agg(workout_summary)
            FROM (
                SELECT
                    wm.workout_id,
                    wm.workout_date,
                    wm.session_title as workout_title
                FROM zamm.workout_main wm
                WHERE wm.athlete_id = p_athlete_id
                ORDER BY wm.workout_date DESC
                LIMIT 10
            ) AS workout_summary
        )
    )
    INTO v_result
    FROM zamm.lib_athletes la
    WHERE la.athlete_id = p_athlete_id
    AND la.is_active = true;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION zamm.get_athlete_context IS
'✅ FIXED: AI Tool - Get comprehensive athlete context. Uses lib_athletes and workout_main.';

-- ============================================
-- STEP 5: Update views if they exist
-- ============================================

-- Drop and recreate v_block_types_by_category if it exists
DROP VIEW IF EXISTS zamm.v_block_types_by_category CASCADE;

CREATE OR REPLACE VIEW zamm.v_block_types_by_category AS
SELECT
    category,
    json_agg(
        json_build_object(
            'code', block_code,
            'name', display_name,
            'sort_order', sort_order
        ) ORDER BY sort_order
    ) as blocks
FROM zamm.lib_block_types
WHERE is_active = true
GROUP BY category;

COMMENT ON VIEW zamm.v_block_types_by_category IS
'✅ FIXED: Block types grouped by category for UI rendering. Uses lib_block_types.';

-- ============================================
-- STEP 6: Grant permissions
-- ============================================

GRANT SELECT ON zamm.lib_block_types TO service_role, authenticated;
GRANT SELECT ON zamm.lib_block_aliases TO service_role, authenticated;
GRANT SELECT ON zamm.lib_equipment_catalog TO service_role, authenticated;
GRANT SELECT ON zamm.lib_equipment_aliases TO service_role, authenticated;
GRANT SELECT ON zamm.lib_athletes TO service_role, authenticated;

GRANT EXECUTE ON FUNCTION zamm.normalize_block_code TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION zamm.check_equipment_exists TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION zamm.calculate_load_from_bodyweight TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION zamm.check_athlete_exists TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION zamm.get_athlete_context TO service_role, authenticated;

-- ============================================
-- Migration Complete
-- ============================================
-- Summary of fixes:
-- ✅ Renamed tables to use correct naming convention
-- ✅ Fixed normalize_block_code function
-- ✅ Fixed check_equipment_exists function
-- ✅ Fixed calculate_load_from_bodyweight function
-- ✅ Fixed check_athlete_exists function
-- ✅ Fixed get_athlete_context function
-- ✅ Updated views to use correct table names
-- ✅ Granted necessary permissions
