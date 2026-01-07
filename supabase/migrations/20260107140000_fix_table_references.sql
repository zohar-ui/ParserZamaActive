-- ============================================
-- Migration: Fix Table References in Functions
-- ============================================
-- Purpose: Update all SQL functions to use correct table names:
--   - dim_athletes → lib_athletes
--   - workouts → workout_main
-- Date: January 7, 2026
-- Version: 1.1.0

-- ============================================
-- Function: calculate_load_from_bodyweight
-- ============================================
CREATE OR REPLACE FUNCTION zamm.calculate_load_from_bodyweight(
    p_athlete_natural_id UUID,
    p_multiplier NUMERIC
) 
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_bodyweight_kg NUMERIC(5,2);
    v_calculated_load NUMERIC(10,2);
BEGIN
    -- Get current bodyweight
    SELECT current_weight_kg 
    INTO v_bodyweight_kg
    FROM zamm.lib_athletes
    WHERE athlete_natural_id = p_athlete_natural_id
    AND is_current = true;
    
    IF v_bodyweight_kg IS NULL THEN
        RAISE EXCEPTION 'Athlete bodyweight not found for athlete_natural_id: %', p_athlete_natural_id;
    END IF;
    
    -- Calculate load
    v_calculated_load := v_bodyweight_kg * p_multiplier;
    
    RETURN v_calculated_load;
END;
$$;

COMMENT ON FUNCTION zamm.calculate_load_from_bodyweight(UUID, NUMERIC) IS 
'Calculate load in kg from bodyweight multiplier (e.g., 0.8×BW)';

-- ============================================
-- Function: check_athlete_exists
-- ============================================
DROP FUNCTION IF EXISTS zamm.check_athlete_exists(TEXT);

CREATE OR REPLACE FUNCTION zamm.check_athlete_exists(p_full_name TEXT)
RETURNS TABLE (
    athlete_id UUID,
    full_name TEXT,
    current_weight_kg NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        da.athlete_natural_id AS athlete_id,
        da.full_name,
        da.current_weight_kg
    FROM zamm.lib_athletes da
    WHERE LOWER(da.full_name) = LOWER(p_full_name)
    AND da.is_current = true;
END;
$$;

COMMENT ON FUNCTION zamm.check_athlete_exists(TEXT) IS 
'AI Tool: Check if athlete exists by name. Returns athlete_id if found.';

-- ============================================
-- Function: get_athlete_context
-- ============================================
DROP FUNCTION IF EXISTS zamm.get_athlete_context(UUID);

CREATE OR REPLACE FUNCTION zamm.get_athlete_context(p_athlete_id UUID)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'athlete_id', da.athlete_natural_id,
        'full_name', da.full_name,
        'current_weight_kg', da.current_weight_kg,
        'recent_workouts', (
            SELECT json_agg(workout_summary)
            FROM (
                SELECT 
                    w.workout_id,
                    w.workout_date,
                    w.workout_title
                FROM zamm.workout_main w
                WHERE w.athlete_id = p_athlete_id
                ORDER BY w.workout_date DESC
                LIMIT 10
            ) AS workout_summary
        )
    )
    INTO v_result
    FROM zamm.lib_athletes da
    WHERE da.athlete_natural_id = p_athlete_id
    AND da.is_current = true;
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION zamm.get_athlete_context(UUID) IS 
'AI Tool: Get comprehensive athlete context including recent workouts.';

-- ============================================
-- Migration Complete
-- ============================================
-- All functions now reference correct table names:
-- ✅ lib_athletes (not dim_athletes)
-- ✅ workout_main (not workouts)
