-- ============================================================================
-- Comprehensive Validation Functions for Parser Stage 3
-- ============================================================================
-- Purpose: Implement production-ready validation functions for parsed workout JSON
-- Version: 1.0.0
-- Date: 2026-01-07
-- Author: ZAMM Development Team
--
-- This migration creates all validation functions referenced in:
-- docs/guides/PARSER_AUDIT_CHECKLIST.md
-- ============================================================================

-- ============================================================================
-- 1. STRUCTURE VALIDATION
-- ============================================================================

-- --------------------------------------------------------
-- validate_parsed_structure: Check basic JSON structure
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION zamm.validate_parsed_structure(parsed_json JSONB)
RETURNS TABLE (
    is_valid BOOLEAN,
    severity TEXT,
    field TEXT,
    issue TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check workout_date
    IF NOT (parsed_json ? 'workout_date') THEN
        RETURN QUERY SELECT FALSE, 'error', 'workout_date', 'Missing required field';
    ELSIF parsed_json->>'workout_date' !~ '^\d{4}-\d{2}-\d{2}$' THEN
        RETURN QUERY SELECT FALSE, 'error', 'workout_date', 'Invalid date format (expected YYYY-MM-DD)';
    ELSIF (parsed_json->>'workout_date')::DATE > CURRENT_DATE THEN
        RETURN QUERY SELECT FALSE, 'error', 'workout_date', 'Date is in the future';
    ELSIF (parsed_json->>'workout_date')::DATE < '2015-01-01' THEN
        RETURN QUERY SELECT FALSE, 'warning', 'workout_date', 'Date is before 2015 (very old)';
    END IF;

    -- Check athlete_id
    IF NOT (parsed_json ? 'athlete_id') THEN
        RETURN QUERY SELECT FALSE, 'error', 'athlete_id', 'Missing required field';
    ELSIF parsed_json->>'athlete_id' !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        RETURN QUERY SELECT FALSE, 'error', 'athlete_id', 'Invalid UUID format';
    ELSIF NOT EXISTS (
        SELECT 1 FROM zamm.lib_athletes WHERE athlete_id = (parsed_json->>'athlete_id')::UUID
    ) THEN
        RETURN QUERY SELECT FALSE, 'error', 'athlete_id', 'Athlete ID not found in lib_athletes table';
    END IF;

    -- Check sessions exist
    IF NOT (parsed_json ? 'sessions') THEN
        RETURN QUERY SELECT FALSE, 'error', 'sessions', 'Missing required field';
    ELSIF jsonb_typeof(parsed_json->'sessions') != 'array' THEN
        RETURN QUERY SELECT FALSE, 'error', 'sessions', 'Must be an array';
    ELSIF jsonb_array_length(parsed_json->'sessions') = 0 THEN
        RETURN QUERY SELECT FALSE, 'error', 'sessions', 'Sessions array is empty';
    END IF;

    -- If all checks passed
    IF NOT FOUND THEN
        RETURN QUERY SELECT TRUE, 'info', NULL::TEXT, 'All structure checks passed';
    END IF;
END;
$$;

COMMENT ON FUNCTION zamm.validate_parsed_structure IS 
'Validates basic JSON structure (workout_date, athlete_id, sessions). Returns errors/warnings.';

-- ============================================================================
-- 2. BLOCK CODE VALIDATION
-- ============================================================================

-- --------------------------------------------------------
-- validate_block_codes: Check all block codes are valid
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION zamm.validate_block_codes(parsed_json JSONB)
RETURNS TABLE (
    is_valid BOOLEAN,
    severity TEXT,
    field TEXT,
    issue TEXT,
    location TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_session JSONB;
    v_block JSONB;
    v_block_code TEXT;
    v_session_idx INT := 0;
    v_block_idx INT := 0;
    v_valid_codes TEXT[] := ARRAY[
        'WU','ACT','MOB',           -- PREPARATION
        'STR','ACC','HYP',          -- STRENGTH
        'PWR','WL',                 -- POWER
        'SKILL','GYM',              -- SKILL
        'METCON','INTV','SS','HYROX', -- CONDITIONING
        'CD','STRETCH','BREATH'     -- RECOVERY
    ];
BEGIN
    -- Loop through sessions
    FOR v_session IN SELECT * FROM jsonb_array_elements(parsed_json->'sessions')
    LOOP
        v_session_idx := v_session_idx + 1;
        v_block_idx := 0;
        
        -- Check session_code
        IF NOT (v_session ? 'session_code') THEN
            RETURN QUERY SELECT 
                FALSE, 
                'error', 
                'session_code', 
                'Missing required field',
                format('Session %s', v_session_idx);
        ELSIF v_session->>'session_code' NOT IN ('AM', 'PM', 'SINGLE') THEN
            RETURN QUERY SELECT 
                FALSE, 
                'error', 
                'session_code', 
                format('Invalid value "%s" (must be AM, PM, or SINGLE)', v_session->>'session_code'),
                format('Session %s', v_session_idx);
        END IF;
        
        -- Check blocks exist
        IF NOT (v_session ? 'blocks') THEN
            RETURN QUERY SELECT 
                FALSE, 
                'error', 
                'blocks', 
                'Missing required field',
                format('Session %s', v_session_idx);
            CONTINUE;
        ELSIF jsonb_array_length(v_session->'blocks') = 0 THEN
            RETURN QUERY SELECT 
                FALSE, 
                'error', 
                'blocks', 
                'Blocks array is empty',
                format('Session %s', v_session_idx);
            CONTINUE;
        END IF;
        
        -- Loop through blocks
        FOR v_block IN SELECT * FROM jsonb_array_elements(v_session->'blocks')
        LOOP
            v_block_idx := v_block_idx + 1;
            v_block_code := v_block->>'block_code';
            
            -- Check if block_code exists
            IF v_block_code IS NULL THEN
                RETURN QUERY SELECT 
                    FALSE, 
                    'error',
                    'block_code',
                    'Missing required field',
                    format('Session %s, Block %s', v_session_idx, v_block_idx);
            -- Check if block_code is valid
            ELSIF NOT (v_block_code = ANY(v_valid_codes)) THEN
                RETURN QUERY SELECT 
                    FALSE, 
                    'error',
                    'block_code',
                    format('Invalid block_code "%s" (must be one of 17 standard codes)', v_block_code),
                    format('Session %s, Block %s', v_session_idx, v_block_idx);
            END IF;
            
            -- Check block_label exists
            IF NOT (v_block ? 'block_label') THEN
                RETURN QUERY SELECT 
                    FALSE, 
                    'error',
                    'block_label',
                    'Missing required field',
                    format('Session %s, Block %s', v_session_idx, v_block_idx);
            END IF;
            
            -- Check prescription exists
            IF NOT (v_block ? 'prescription') THEN
                RETURN QUERY SELECT 
                    FALSE, 
                    'error',
                    'prescription',
                    'Missing required field',
                    format('Session %s, Block %s', v_session_idx, v_block_idx);
            END IF;
            
            -- Check performed exists (can be null or {})
            IF NOT (v_block ? 'performed') THEN
                RETURN QUERY SELECT 
                    FALSE, 
                    'error',
                    'performed',
                    'Missing required field (use null or {} if no performance data)',
                    format('Session %s, Block %s', v_session_idx, v_block_idx);
            END IF;
        END LOOP;
    END LOOP;

    -- If all checks passed
    IF NOT FOUND THEN
        RETURN QUERY SELECT TRUE, 'info', NULL::TEXT, 'All block codes are valid', NULL::TEXT;
    END IF;
END;
$$;

COMMENT ON FUNCTION zamm.validate_block_codes IS 
'Validates all block codes against the 17 standard codes. Also checks session_code and basic block structure.';

-- ============================================================================
-- 3. DATA VALUES VALIDATION
-- ============================================================================

-- --------------------------------------------------------
-- validate_data_values: Check numeric values are reasonable
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION zamm.validate_data_values(parsed_json JSONB)
RETURNS TABLE (
    is_valid BOOLEAN,
    severity TEXT,
    field TEXT,
    issue TEXT,
    location TEXT,
    actual_value TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_session JSONB;
    v_block JSONB;
    v_step JSONB;
    v_set JSONB;
    v_load NUMERIC;
    v_reps INTEGER;
    v_sets INTEGER;
    v_time INTEGER;
    v_rpe NUMERIC;
    v_rir INTEGER;
    v_session_idx INT := 0;
    v_block_idx INT := 0;
BEGIN
    -- Loop through sessions and blocks
    FOR v_session IN SELECT * FROM jsonb_array_elements(parsed_json->'sessions')
    LOOP
        v_session_idx := v_session_idx + 1;
        v_block_idx := 0;
        
        FOR v_block IN SELECT * FROM jsonb_array_elements(v_session->'blocks')
        LOOP
            v_block_idx := v_block_idx + 1;
            
            -- Validate prescription values
            IF v_block->'prescription' IS NOT NULL AND v_block->'prescription' != '{}'::jsonb THEN
                
                -- Check target_sets
                IF v_block->'prescription' ? 'steps' THEN
                    FOR v_step IN SELECT * FROM jsonb_array_elements(v_block->'prescription'->'steps')
                    LOOP
                        v_sets := (v_step->>'target_sets')::INTEGER;
                        IF v_sets IS NOT NULL AND (v_sets < 1 OR v_sets > 10) THEN
                            IF v_sets > 10 THEN
                                RETURN QUERY SELECT 
                                    FALSE, 'warning', 'target_sets',
                                    format('Unusually high (%s sets - typically 1-8)', v_sets),
                                    format('Session %s, Block %s', v_session_idx, v_block_idx),
                                    v_sets::TEXT;
                            ELSE
                                RETURN QUERY SELECT 
                                    FALSE, 'error', 'target_sets',
                                    format('Invalid value %s (must be >= 1)', v_sets),
                                    format('Session %s, Block %s', v_session_idx, v_block_idx),
                                    v_sets::TEXT;
                            END IF;
                        END IF;
                        
                        -- Check target_reps
                        v_reps := (v_step->>'target_reps')::INTEGER;
                        IF v_reps IS NOT NULL THEN
                            IF v_reps > 200 THEN
                                RETURN QUERY SELECT 
                                    FALSE, 'error', 'target_reps',
                                    format('Unrealistic value (%s reps)', v_reps),
                                    format('Session %s, Block %s', v_session_idx, v_block_idx),
                                    v_reps::TEXT;
                            ELSIF v_reps > 50 THEN
                                RETURN QUERY SELECT 
                                    FALSE, 'warning', 'target_reps',
                                    format('High rep count (%s reps - verify this is correct)', v_reps),
                                    format('Session %s, Block %s', v_session_idx, v_block_idx),
                                    v_reps::TEXT;
                            ELSIF v_reps < 1 THEN
                                RETURN QUERY SELECT 
                                    FALSE, 'error', 'target_reps',
                                    'Must be at least 1',
                                    format('Session %s, Block %s', v_session_idx, v_block_idx),
                                    v_reps::TEXT;
                            END IF;
                        END IF;
                        
                        -- Check target_load
                        IF v_step->'target_load' ? 'value' THEN
                            v_load := (v_step->'target_load'->>'value')::NUMERIC;
                            IF v_load IS NOT NULL THEN
                                IF v_load > 500 THEN
                                    RETURN QUERY SELECT 
                                        FALSE, 'error', 'target_load',
                                        format('Unrealistic load (%s kg)', v_load),
                                        format('Session %s, Block %s', v_session_idx, v_block_idx),
                                        v_load::TEXT;
                                ELSIF v_load > 300 THEN
                                    RETURN QUERY SELECT 
                                        FALSE, 'warning', 'target_load',
                                        format('Very heavy load (%s kg - verify this is correct)', v_load),
                                        format('Session %s, Block %s', v_session_idx, v_block_idx),
                                        v_load::TEXT;
                                ELSIF v_load <= 0 THEN
                                    RETURN QUERY SELECT 
                                        FALSE, 'error', 'target_load',
                                        'Must be greater than 0',
                                        format('Session %s, Block %s', v_session_idx, v_block_idx),
                                        v_load::TEXT;
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;
                END IF;
                
                -- Check time values
                v_time := (v_block->'prescription'->>'time_cap_seconds')::INTEGER;
                IF v_time IS NOT NULL THEN
                    IF v_time > 7200 THEN
                        RETURN QUERY SELECT 
                            FALSE, 'error', 'time_cap_seconds',
                            format('Unrealistic time cap (%s seconds = %s hours)', v_time, ROUND(v_time::NUMERIC/3600, 1)),
                            format('Session %s, Block %s', v_session_idx, v_block_idx),
                            v_time::TEXT;
                    ELSIF v_time > 3600 THEN
                        RETURN QUERY SELECT 
                            FALSE, 'warning', 'time_cap_seconds',
                            format('Very long time cap (%s seconds = %s minutes)', v_time, ROUND(v_time::NUMERIC/60, 0)),
                            format('Session %s, Block %s', v_session_idx, v_block_idx),
                            v_time::TEXT;
                    END IF;
                END IF;
            END IF;
            
            -- Validate performed values
            IF v_block->'performed' IS NOT NULL AND v_block->'performed' != '{}'::jsonb THEN
                
                -- Check total_time_sec
                v_time := (v_block->'performed'->>'total_time_sec')::INTEGER;
                IF v_time IS NOT NULL THEN
                    IF v_time > 10800 THEN
                        RETURN QUERY SELECT 
                            FALSE, 'error', 'total_time_sec',
                            format('Unrealistic workout time (%s seconds = %s hours)', v_time, ROUND(v_time::NUMERIC/3600, 1)),
                            format('Session %s, Block %s (performed)', v_session_idx, v_block_idx),
                            v_time::TEXT;
                    ELSIF v_time > 3600 THEN
                        RETURN QUERY SELECT 
                            FALSE, 'warning', 'total_time_sec',
                            format('Very long workout (%s seconds = %s minutes)', v_time, ROUND(v_time::NUMERIC/60, 0)),
                            format('Session %s, Block %s (performed)', v_session_idx, v_block_idx),
                            v_time::TEXT;
                    END IF;
                END IF;
                
                -- Validate individual sets
                IF v_block->'performed' ? 'steps' THEN
                    FOR v_step IN SELECT * FROM jsonb_array_elements(v_block->'performed'->'steps')
                    LOOP
                        IF v_step ? 'sets' THEN
                            FOR v_set IN SELECT * FROM jsonb_array_elements(v_step->'sets')
                            LOOP
                                -- Check RPE
                                v_rpe := (v_set->>'rpe')::NUMERIC;
                                IF v_rpe IS NOT NULL AND (v_rpe < 1 OR v_rpe > 10) THEN
                                    RETURN QUERY SELECT 
                                        FALSE, 'error', 'rpe',
                                        format('RPE must be between 1-10 (got %s)', v_rpe),
                                        format('Session %s, Block %s, Set %s', v_session_idx, v_block_idx, v_set->>'set_index'),
                                        v_rpe::TEXT;
                                END IF;

                                -- Check RIR
                                v_rir := (v_set->>'rir')::INTEGER;
                                IF v_rir IS NOT NULL AND (v_rir < 0 OR v_rir > 10) THEN
                                    RETURN QUERY SELECT 
                                        FALSE, 'error', 'rir',
                                        format('RIR must be between 0-10 (got %s)', v_rir),
                                        format('Session %s, Block %s, Set %s', v_session_idx, v_block_idx, v_set->>'set_index'),
                                        v_rir::TEXT;
                                END IF;
                                
                                -- Check load_kg
                                v_load := (v_set->>'load_kg')::NUMERIC;
                                IF v_load IS NOT NULL THEN
                                    IF v_load > 500 THEN
                                        RETURN QUERY SELECT 
                                            FALSE, 'error', 'load_kg',
                                            format('Unrealistic load (%s kg)', v_load),
                                            format('Session %s, Block %s, Set %s', v_session_idx, v_block_idx, v_set->>'set_index'),
                                            v_load::TEXT;
                                    ELSIF v_load > 300 THEN
                                        RETURN QUERY SELECT 
                                            FALSE, 'warning', 'load_kg',
                                            format('Very heavy (%s kg)', v_load),
                                            format('Session %s, Block %s, Set %s', v_session_idx, v_block_idx, v_set->>'set_index'),
                                            v_load::TEXT;
                                    END IF;
                                END IF;
                                
                                -- Check reps
                                v_reps := (v_set->>'reps')::INTEGER;
                                IF v_reps IS NOT NULL THEN
                                    IF v_reps > 200 THEN
                                        RETURN QUERY SELECT 
                                            FALSE, 'error', 'reps',
                                            format('Unrealistic (%s reps)', v_reps),
                                            format('Session %s, Block %s, Set %s', v_session_idx, v_block_idx, v_set->>'set_index'),
                                            v_reps::TEXT;
                                    ELSIF v_reps > 50 THEN
                                        RETURN QUERY SELECT 
                                            FALSE, 'warning', 'reps',
                                            format('High rep count (%s)', v_reps),
                                            format('Session %s, Block %s, Set %s', v_session_idx, v_block_idx, v_set->>'set_index'),
                                            v_reps::TEXT;
                                    END IF;
                                END IF;
                            END LOOP;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        END LOOP;
    END LOOP;

    -- If all checks passed
    IF NOT FOUND THEN
        RETURN QUERY SELECT TRUE, 'info', NULL::TEXT, 'All data values are reasonable', NULL::TEXT, NULL::TEXT;
    END IF;
END;
$$;

COMMENT ON FUNCTION zamm.validate_data_values IS 
'Validates numeric values (loads, reps, sets, times, RPE, RIR) are within reasonable ranges.';

-- ============================================================================
-- 4. CATALOG VALIDATION
-- ============================================================================

-- --------------------------------------------------------
-- validate_catalog_references: Check exercises and equipment exist
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION zamm.validate_catalog_references(parsed_json JSONB)
RETURNS TABLE (
    is_valid BOOLEAN,
    severity TEXT,
    field TEXT,
    issue TEXT,
    location TEXT,
    value TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_session JSONB;
    v_block JSONB;
    v_step JSONB;
    v_exercise_name TEXT;
    v_equipment_key TEXT;
    v_session_idx INT := 0;
    v_block_idx INT := 0;
    v_step_idx INT := 0;
BEGIN
    -- Loop through sessions and blocks
    FOR v_session IN SELECT * FROM jsonb_array_elements(parsed_json->'sessions')
    LOOP
        v_session_idx := v_session_idx + 1;
        v_block_idx := 0;
        
        FOR v_block IN SELECT * FROM jsonb_array_elements(v_session->'blocks')
        LOOP
            v_block_idx := v_block_idx + 1;
            v_step_idx := 0;
            
            -- Check exercises in prescription
            IF v_block->'prescription' ? 'steps' THEN
                FOR v_step IN SELECT * FROM jsonb_array_elements(v_block->'prescription'->'steps')
                LOOP
                    v_step_idx := v_step_idx + 1;
                    v_exercise_name := v_step->>'exercise_name';
                    
                    -- Validate exercise name
                    IF v_exercise_name IS NOT NULL THEN
                        IF NOT EXISTS (
                            SELECT 1 FROM zamm.lib_exercise_catalog 
                            WHERE LOWER(exercise_name) = LOWER(v_exercise_name)
                        ) AND NOT EXISTS (
                            SELECT 1 FROM zamm.lib_exercise_aliases 
                            WHERE LOWER(alias) = LOWER(v_exercise_name)
                        ) THEN
                            RETURN QUERY SELECT 
                                FALSE, 'error', 'exercise_name',
                                format('Exercise "%s" not found in catalog', v_exercise_name),
                                format('Session %s, Block %s, Step %s', v_session_idx, v_block_idx, v_step_idx),
                                v_exercise_name;
                        END IF;
                    END IF;
                    
                    -- Validate equipment key
                    v_equipment_key := v_step->>'equipment_key';
                    IF v_equipment_key IS NOT NULL THEN
                        IF NOT EXISTS (
                            SELECT 1 FROM zamm.lib_equipment_catalog 
                            WHERE equipment_key = v_equipment_key
                        ) AND NOT EXISTS (
                            SELECT 1 FROM zamm.lib_equipment_aliases 
                            WHERE alias = v_equipment_key
                        ) THEN
                            RETURN QUERY SELECT 
                                FALSE, 'error', 'equipment_key',
                                format('Equipment "%s" not found in catalog', v_equipment_key),
                                format('Session %s, Block %s, Step %s', v_session_idx, v_block_idx, v_step_idx),
                                v_equipment_key;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END LOOP;
    END LOOP;

    -- If all checks passed
    IF NOT FOUND THEN
        RETURN QUERY SELECT TRUE, 'info', NULL::TEXT, 'All catalog references are valid', NULL::TEXT, NULL::TEXT;
    END IF;
END;
$$;

COMMENT ON FUNCTION zamm.validate_catalog_references IS 
'Validates that all exercise names and equipment keys exist in their respective catalogs or alias tables.';

-- ============================================================================
-- 5. PRESCRIPTION VS PERFORMANCE SEPARATION
-- ============================================================================

-- --------------------------------------------------------
-- validate_prescription_performance_separation: Critical business rule
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION zamm.validate_prescription_performance_separation(parsed_json JSONB)
RETURNS TABLE (
    is_valid BOOLEAN,
    severity TEXT,
    field TEXT,
    issue TEXT,
    location TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_session JSONB;
    v_block JSONB;
    v_step JSONB;
    v_session_idx INT := 0;
    v_block_idx INT := 0;
    v_forbidden_prescription_keys TEXT[] := ARRAY['actual_sets', 'actual_reps', 'reps_performed', 'sets_performed', 'did_complete', 'notes_performed'];
    v_forbidden_performed_keys TEXT[] := ARRAY['target_sets', 'target_reps', 'target_load', 'target_reps_planned'];
    v_key TEXT;
BEGIN
    -- Loop through sessions and blocks
    FOR v_session IN SELECT * FROM jsonb_array_elements(parsed_json->'sessions')
    LOOP
        v_session_idx := v_session_idx + 1;
        v_block_idx := 0;
        
        FOR v_block IN SELECT * FROM jsonb_array_elements(v_session->'blocks')
        LOOP
            v_block_idx := v_block_idx + 1;
            
            -- Check prescription doesn't have performance keys
            IF v_block->'prescription' IS NOT NULL THEN
                FOREACH v_key IN ARRAY v_forbidden_prescription_keys
                LOOP
                    IF v_block->'prescription' ? v_key THEN
                        RETURN QUERY SELECT 
                            FALSE, 'error', v_key,
                            format('Prescription contains performance key "%s" - violation of separation principle', v_key),
                            format('Session %s, Block %s (prescription)', v_session_idx, v_block_idx);
                    END IF;
                END LOOP;
                
                -- Check steps
                IF v_block->'prescription' ? 'steps' THEN
                    FOR v_step IN SELECT * FROM jsonb_array_elements(v_block->'prescription'->'steps')
                    LOOP
                        FOREACH v_key IN ARRAY v_forbidden_prescription_keys
                        LOOP
                            IF v_step ? v_key THEN
                                RETURN QUERY SELECT 
                                    FALSE, 'error', v_key,
                                    format('Prescription step contains performance key "%s"', v_key),
                                    format('Session %s, Block %s (prescription steps)', v_session_idx, v_block_idx);
                            END IF;
                        END LOOP;
                    END LOOP;
                END IF;
            END IF;
            
            -- Check performed doesn't have prescription keys
            IF v_block->'performed' IS NOT NULL AND v_block->'performed' != '{}'::jsonb THEN
                FOREACH v_key IN ARRAY v_forbidden_performed_keys
                LOOP
                    IF v_block->'performed' ? v_key THEN
                        RETURN QUERY SELECT 
                            FALSE, 'error', v_key,
                            format('Performed contains prescription key "%s" - violation of separation principle', v_key),
                            format('Session %s, Block %s (performed)', v_session_idx, v_block_idx);
                    END IF;
                END LOOP;
                
                -- Check steps
                IF v_block->'performed' ? 'steps' THEN
                    FOR v_step IN SELECT * FROM jsonb_array_elements(v_block->'performed'->'steps')
                    LOOP
                        FOREACH v_key IN ARRAY v_forbidden_performed_keys
                        LOOP
                            IF v_step ? v_key THEN
                                RETURN QUERY SELECT 
                                    FALSE, 'error', v_key,
                                    format('Performed step contains prescription key "%s"', v_key),
                                    format('Session %s, Block %s (performed steps)', v_session_idx, v_block_idx);
                            END IF;
                        END LOOP;
                    END LOOP;
                END IF;
            END IF;
        END LOOP;
    END LOOP;

    -- If all checks passed
    IF NOT FOUND THEN
        RETURN QUERY SELECT TRUE, 'info', NULL::TEXT, 'Prescription/Performance separation is correct', NULL::TEXT;
    END IF;
END;
$$;

COMMENT ON FUNCTION zamm.validate_prescription_performance_separation IS 
'CRITICAL: Validates that prescription and performed fields are never mixed. Core business rule.';

-- ============================================================================
-- 6. MASTER VALIDATION FUNCTION
-- ============================================================================

-- --------------------------------------------------------
-- validate_parsed_workout: Run all validation checks
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION zamm.validate_parsed_workout(
    p_draft_id UUID,
    p_parsed_json JSONB
)
RETURNS TABLE (
    validation_status TEXT,
    total_checks INTEGER,
    errors INTEGER,
    warnings INTEGER,
    info INTEGER,
    report JSONB
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_errors JSONB := '[]'::JSONB;
    v_warnings JSONB := '[]'::JSONB;
    v_info JSONB := '[]'::JSONB;
    v_result RECORD;
    v_error_count INT := 0;
    v_warning_count INT := 0;
    v_info_count INT := 0;
    v_total_count INT := 0;
    v_final_status TEXT;
BEGIN
    -- 1. Structure validation
    FOR v_result IN SELECT * FROM zamm.validate_parsed_structure(p_parsed_json)
    LOOP
        v_total_count := v_total_count + 1;
        IF v_result.severity = 'error' THEN
            v_error_count := v_error_count + 1;
            v_errors := v_errors || jsonb_build_object(
                'severity', 'error',
                'category', 'structure',
                'field', v_result.field,
                'issue', v_result.issue
            );
        ELSIF v_result.severity = 'warning' THEN
            v_warning_count := v_warning_count + 1;
            v_warnings := v_warnings || jsonb_build_object(
                'severity', 'warning',
                'category', 'structure',
                'field', v_result.field,
                'issue', v_result.issue
            );
        ELSE
            v_info_count := v_info_count + 1;
            v_info := v_info || jsonb_build_object(
                'severity', 'info',
                'category', 'structure',
                'message', v_result.issue
            );
        END IF;
    END LOOP;

    -- 2. Block code validation
    FOR v_result IN SELECT * FROM zamm.validate_block_codes(p_parsed_json)
    LOOP
        v_total_count := v_total_count + 1;
        IF v_result.severity = 'error' THEN
            v_error_count := v_error_count + 1;
            v_errors := v_errors || jsonb_build_object(
                'severity', 'error',
                'category', 'block_structure',
                'field', v_result.field,
                'issue', v_result.issue,
                'location', v_result.location
            );
        ELSIF v_result.severity = 'warning' THEN
            v_warning_count := v_warning_count + 1;
            v_warnings := v_warnings || jsonb_build_object(
                'severity', 'warning',
                'category', 'block_structure',
                'field', v_result.field,
                'issue', v_result.issue,
                'location', v_result.location
            );
        ELSE
            v_info_count := v_info_count + 1;
        END IF;
    END LOOP;

    -- 3. Data values validation
    FOR v_result IN SELECT * FROM zamm.validate_data_values(p_parsed_json)
    LOOP
        v_total_count := v_total_count + 1;
        IF v_result.severity = 'error' THEN
            v_error_count := v_error_count + 1;
            v_errors := v_errors || jsonb_build_object(
                'severity', 'error',
                'category', 'data_values',
                'field', v_result.field,
                'issue', v_result.issue,
                'location', v_result.location,
                'actual_value', v_result.actual_value
            );
        ELSIF v_result.severity = 'warning' THEN
            v_warning_count := v_warning_count + 1;
            v_warnings := v_warnings || jsonb_build_object(
                'severity', 'warning',
                'category', 'data_values',
                'field', v_result.field,
                'issue', v_result.issue,
                'location', v_result.location,
                'actual_value', v_result.actual_value
            );
        ELSE
            v_info_count := v_info_count + 1;
        END IF;
    END LOOP;

    -- 4. Catalog validation
    FOR v_result IN SELECT * FROM zamm.validate_catalog_references(p_parsed_json)
    LOOP
        v_total_count := v_total_count + 1;
        IF v_result.severity = 'error' THEN
            v_error_count := v_error_count + 1;
            v_errors := v_errors || jsonb_build_object(
                'severity', 'error',
                'category', 'catalog',
                'field', v_result.field,
                'issue', v_result.issue,
                'location', v_result.location,
                'value', v_result.value
            );
        ELSIF v_result.severity = 'warning' THEN
            v_warning_count := v_warning_count + 1;
            v_warnings := v_warnings || jsonb_build_object(
                'severity', 'warning',
                'category', 'catalog',
                'field', v_result.field,
                'issue', v_result.issue,
                'location', v_result.location,
                'value', v_result.value
            );
        ELSE
            v_info_count := v_info_count + 1;
        END IF;
    END LOOP;

    -- 5. Prescription vs Performance separation (CRITICAL)
    FOR v_result IN SELECT * FROM zamm.validate_prescription_performance_separation(p_parsed_json)
    LOOP
        v_total_count := v_total_count + 1;
        IF v_result.severity = 'error' THEN
            v_error_count := v_error_count + 1;
            v_errors := v_errors || jsonb_build_object(
                'severity', 'error',
                'category', 'prescription_performance_separation',
                'field', v_result.field,
                'issue', v_result.issue,
                'location', v_result.location
            );
        ELSIF v_result.severity = 'warning' THEN
            v_warning_count := v_warning_count + 1;
            v_warnings := v_warnings || jsonb_build_object(
                'severity', 'warning',
                'category', 'prescription_performance_separation',
                'field', v_result.field,
                'issue', v_result.issue,
                'location', v_result.location
            );
        ELSE
            v_info_count := v_info_count + 1;
        END IF;
    END LOOP;

    -- Determine final status
    IF v_error_count > 0 THEN
        v_final_status := 'fail';
    ELSIF v_warning_count > 0 THEN
        v_final_status := 'warning';
    ELSE
        v_final_status := 'pass';
    END IF;

    -- Build final report
    RETURN QUERY SELECT 
        v_final_status,
        v_total_count,
        v_error_count,
        v_warning_count,
        v_info_count,
        jsonb_build_object(
            'validation_status', v_final_status,
            'draft_id', p_draft_id,
            'validated_at', NOW(),
            'summary', jsonb_build_object(
                'total_checks', v_total_count,
                'passed', (v_total_count - v_error_count - v_warning_count),
                'errors', v_error_count,
                'warnings', v_warning_count,
                'info', v_info_count
            ),
            'errors', v_errors,
            'warnings', v_warnings,
            'info', v_info
        );
END;
$$;

COMMENT ON FUNCTION zamm.validate_parsed_workout IS 
'Master validation function that runs all checks and returns comprehensive report. Use this in Stage 3 workflow.';

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION zamm.validate_parsed_structure TO service_role;
GRANT EXECUTE ON FUNCTION zamm.validate_block_codes TO service_role;
GRANT EXECUTE ON FUNCTION zamm.validate_data_values TO service_role;
GRANT EXECUTE ON FUNCTION zamm.validate_catalog_references TO service_role;
GRANT EXECUTE ON FUNCTION zamm.validate_prescription_performance_separation TO service_role;
GRANT EXECUTE ON FUNCTION zamm.validate_parsed_workout TO service_role;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
