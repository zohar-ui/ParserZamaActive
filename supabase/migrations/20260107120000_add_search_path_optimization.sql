-- ============================================
-- Search Path Optimization
-- ============================================
-- Purpose: Add search_path to functions to allow shorter table references
-- Date: January 7, 2026
-- Impact: Improves code readability by removing zamm. prefix requirement

-- ============================================
-- Tool 1: Check if Athlete Exists (Updated)
-- ============================================
CREATE OR REPLACE FUNCTION zamm.check_athlete_exists(p_search_name TEXT)
RETURNS TABLE (
    athlete_id UUID,
    full_name VARCHAR(100),
    email VARCHAR(255),
    current_weight_kg NUMERIC(5,2),
    gender VARCHAR(20)
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = zamm, public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        da.athlete_natural_id as athlete_id,
        da.full_name,
        da.email,
        da.current_weight_kg,
        da.gender
    FROM dim_athletes da
    WHERE 
        da.is_current = true
        AND (
            da.full_name ILIKE '%' || p_search_name || '%'
            OR da.email ILIKE '%' || p_search_name || '%'
        )
    ORDER BY 
        CASE WHEN LOWER(da.full_name) = LOWER(p_search_name) THEN 0 ELSE 1 END,
        da.full_name
    LIMIT 5;
END;
$$;

-- ============================================
-- Tool 2: Check Equipment Exists (Updated)
-- ============================================
CREATE OR REPLACE FUNCTION zamm.check_equipment_exists(p_search_name TEXT)
RETURNS TABLE (
    equipment_key TEXT,
    display_name TEXT,
    category TEXT,
    matched_via TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = zamm, public
AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        ec.equipment_key,
        ec.display_name,
        ec.category,
        CASE 
            WHEN ec.display_name ILIKE '%' || p_search_name || '%' THEN 'display_name'
            ELSE 'alias'
        END as matched_via
    FROM equipment_catalog ec
    LEFT JOIN equipment_aliases ea ON ec.equipment_key = ea.equipment_key
    WHERE 
        ec.is_active = true
        AND (
            ec.display_name ILIKE '%' || p_search_name || '%'
            OR ec.equipment_key ILIKE '%' || p_search_name || '%'
            OR ea.alias ILIKE '%' || p_search_name || '%'
        )
    ORDER BY 
        CASE WHEN LOWER(ec.display_name) = LOWER(p_search_name) THEN 0 ELSE 1 END,
        matched_via,
        ec.display_name
    LIMIT 10;
END;
$$;

-- ============================================
-- Tool 3: Get Active Ruleset (Updated)
-- ============================================
CREATE OR REPLACE FUNCTION zamm.get_active_ruleset()
RETURNS TABLE (
    ruleset_id UUID,
    ruleset_name TEXT,
    version TEXT,
    units_catalog JSONB,
    parser_mapping_rules JSONB,
    value_unit_schema JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = zamm, public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pr.ruleset_id,
        pr.name as ruleset_name,
        pr.version,
        pr.units_catalog,
        pr.parser_mapping_rules,
        pr.value_unit_schema
    FROM parser_rulesets pr
    WHERE pr.is_active = true
    LIMIT 1;
END;
$$;

-- ============================================
-- Tool 4: Get Athlete Full Context (Updated)
-- ============================================
CREATE OR REPLACE FUNCTION zamm.get_athlete_context(p_athlete_id UUID)
RETURNS TABLE (
    athlete_id UUID,
    full_name VARCHAR(100),
    gender VARCHAR(20),
    age_years INTEGER,
    height_cm INTEGER,
    current_weight_kg NUMERIC(5,2),
    recent_workouts_count BIGINT,
    last_workout_date DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = zamm, public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        da.athlete_natural_id as athlete_id,
        da.full_name,
        da.gender,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, da.date_of_birth))::INTEGER as age_years,
        da.height_cm,
        da.current_weight_kg,
        COUNT(w.workout_id) as recent_workouts_count,
        MAX(w.workout_date) as last_workout_date
    FROM dim_athletes da
    LEFT JOIN workouts w ON da.athlete_natural_id = w.athlete_id
        AND w.workout_date >= CURRENT_DATE - INTERVAL '30 days'
    WHERE 
        da.athlete_natural_id = p_athlete_id
        AND da.is_current = true
    GROUP BY 
        da.athlete_natural_id, da.full_name, da.gender, 
        da.date_of_birth, da.height_cm, da.current_weight_kg;
END;
$$;

-- ============================================
-- Tool 5: Normalize Block Type (Updated)
-- ============================================
CREATE OR REPLACE FUNCTION zamm.normalize_block_type(p_block_type TEXT)
RETURNS TABLE (
    is_valid BOOLEAN,
    normalized_type TEXT,
    suggested_structure TEXT,
    common_patterns TEXT[]
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = zamm, public
AS $$
DECLARE
    v_normalized TEXT;
    v_valid BOOLEAN := false;
BEGIN
    v_normalized := LOWER(TRIM(p_block_type));
    
    CASE
        WHEN v_normalized IN ('strength', 'str', 'lifting', 'lift') THEN
            v_normalized := 'strength';
            v_valid := true;
        WHEN v_normalized IN ('metcon', 'conditioning', 'cardio', 'wod') THEN
            v_normalized := 'metcon';
            v_valid := true;
        WHEN v_normalized IN ('skill', 'skills', 'technique', 'tech') THEN
            v_normalized := 'skill';
            v_valid := true;
        WHEN v_normalized IN ('warmup', 'warm-up', 'wu') THEN
            v_normalized := 'warmup';
            v_valid := true;
        WHEN v_normalized IN ('cooldown', 'cool-down', 'cd') THEN
            v_normalized := 'cooldown';
            v_valid := true;
        WHEN v_normalized IN ('accessory', 'accessories', 'acc') THEN
            v_normalized := 'accessory';
            v_valid := true;
        WHEN v_normalized IN ('interval', 'intervals', 'int') THEN
            v_normalized := 'interval';
            v_valid := true;
        ELSE
            v_normalized := 'unknown';
            v_valid := false;
    END CASE;
    
    RETURN QUERY
    SELECT 
        v_valid as is_valid,
        v_normalized as normalized_type,
        CASE v_normalized
            WHEN 'strength' THEN 'sets_reps_load'
            WHEN 'metcon' THEN 'amrap_or_fortime'
            WHEN 'skill' THEN 'practice_accumulate'
            WHEN 'interval' THEN 'work_rest_rounds'
            WHEN 'warmup' THEN 'movement_prep'
            WHEN 'cooldown' THEN 'recovery_stretch'
            WHEN 'accessory' THEN 'sets_reps'
            ELSE 'unknown'
        END as suggested_structure,
        CASE v_normalized
            WHEN 'strength' THEN ARRAY['5x5', '3x8', '1RM', 'heavy single']
            WHEN 'metcon' THEN ARRAY['for time', 'AMRAP', '21-15-9', 'EMOM']
            WHEN 'skill' THEN ARRAY['practice', '10 min work', 'accumulate']
            WHEN 'interval' THEN ARRAY['30 on/30 off', '400m x 5', 'tabata']
            ELSE ARRAY['unknown pattern']
        END as common_patterns;
END;
$$;

-- ============================================
-- Update commit_full_workout_v3 (Updated)
-- DROP first to avoid parameter name conflict
-- ============================================
DROP FUNCTION IF EXISTS zamm.commit_full_workout_v3(UUID, UUID, UUID, UUID, JSONB);

CREATE FUNCTION zamm.commit_full_workout_v3(
    p_import_id UUID,
    p_draft_id UUID,
    p_ruleset_id UUID,
    p_athlete_id UUID,
    p_normalized_json JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SET search_path = zamm, public
AS $$
DECLARE
    v_workout_id UUID;
    v_sess_rec RECORD;
    v_blk_rec RECORD;
    v_item_rec RECORD;
    v_set_rec RECORD;
    v_session_id UUID;
    v_block_id UUID;
    v_item_id UUID;
    v_workout_date DATE;
BEGIN
    v_workout_date := (p_normalized_json->'sessions'->0->'sessionInfo'->>'date')::date;

    -- 1. Create Workout Header
    INSERT INTO workouts (
        import_id, draft_id, ruleset_id, athlete_id, 
        workout_date, status, created_at, approved_at
    )
    VALUES (
        p_import_id, p_draft_id, p_ruleset_id, p_athlete_id, 
        v_workout_date, 'completed', NOW(), NOW()
    )
    RETURNING workout_id INTO v_workout_id;

    -- 2. Loop through Sessions
    FOR v_sess_rec IN 
        SELECT * FROM jsonb_to_recordset(p_normalized_json->'sessions') 
        AS x(sessionInfo jsonb, blocks jsonb)
    LOOP
        INSERT INTO workout_sessions (
            workout_id, 
            session_title, 
            date,
            status, 
            created_at
        )
        VALUES (
            v_workout_id, 
            COALESCE(v_sess_rec.sessionInfo->>'title', 'Main Session'),
            v_workout_date,
            'completed',
            NOW()
        )
        RETURNING session_id INTO v_session_id;

        -- 3. Loop through Blocks
        FOR v_blk_rec IN 
            SELECT * FROM jsonb_to_recordset(v_sess_rec.blocks) 
            AS y(
                block_code text, 
                block_type text, 
                name text, 
                prescription jsonb, 
                performed jsonb
            )
        LOOP
            INSERT INTO workout_blocks (
                session_id,
                letter,
                block_code,
                block_type,
                name,
                structure_model,
                presentation_structure,
                result_entry_model,
                prescription,
                performed,
                block_notes,
                confidence_score,
                created_at
            )
            VALUES (
                v_session_id,
                v_blk_rec.block_code,
                v_blk_rec.block_code,
                COALESCE(v_blk_rec.block_type, 'unknown'),
                COALESCE(v_blk_rec.name, v_blk_rec.block_code),
                COALESCE(v_blk_rec.prescription->>'structure', 'sets_reps'),
                'standard',
                'sets_reps_load',
                v_blk_rec.prescription,
                COALESCE(v_blk_rec.performed, '{}'::jsonb),
                NULL,
                95.0,
                NOW()
            )
            RETURNING block_id INTO v_block_id;

            -- 4. Loop through Items (exercises)
            FOR v_item_rec IN 
                SELECT * FROM jsonb_to_recordset(v_blk_rec.prescription->'steps') 
                AS z(
                    exercise_name text,
                    target_sets int,
                    target_reps int,
                    target_load jsonb
                )
            LOOP
                INSERT INTO workout_items (
                    block_id,
                    item_index,
                    exercise_name,
                    exercise_key,
                    prescription_data,
                    performed_data,
                    created_at
                )
                VALUES (
                    v_block_id,
                    1,
                    v_item_rec.exercise_name,
                    NULL,
                    jsonb_build_object(
                        'target_sets', v_item_rec.target_sets,
                        'target_reps', v_item_rec.target_reps,
                        'target_load', v_item_rec.target_load
                    ),
                    COALESCE(
                        (SELECT performed->'steps'->0 FROM jsonb_array_elements(v_blk_rec.performed->'steps') steps LIMIT 1),
                        '{}'::jsonb
                    ),
                    NOW()
                )
                RETURNING item_id INTO v_item_id;

                -- 5. Create set results if performed data exists
                IF v_blk_rec.performed IS NOT NULL AND v_blk_rec.performed != '{}'::jsonb THEN
                    FOR v_set_rec IN
                        SELECT * FROM jsonb_to_recordset(
                            (SELECT performed->'steps'->0->'sets' 
                             FROM jsonb_array_elements(v_blk_rec.performed->'steps') steps LIMIT 1)
                        ) AS s(
                            set_index int,
                            reps int,
                            load_kg numeric,
                            rpe numeric,
                            rir int,
                            notes text
                        )
                    LOOP
                        INSERT INTO item_set_results (
                            item_id,
                            set_index,
                            reps_performed,
                            load_kg,
                            rpe,
                            rir,
                            notes,
                            created_at
                        )
                        VALUES (
                            v_item_id,
                            v_set_rec.set_index,
                            v_set_rec.reps,
                            v_set_rec.load_kg,
                            v_set_rec.rpe,
                            v_set_rec.rir,
                            v_set_rec.notes,
                            NOW()
                        );
                    END LOOP;
                END IF;
            END LOOP;
        END LOOP;
    END LOOP;

    RETURN v_workout_id;
END;
$$;

COMMENT ON FUNCTION zamm.commit_full_workout_v3 IS 
'Enhanced workout commit with search_path optimization for cleaner code.';
