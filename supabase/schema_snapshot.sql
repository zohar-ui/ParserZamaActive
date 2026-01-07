


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "zamm";


ALTER SCHEMA "zamm" OWNER TO "postgres";


CREATE TYPE "zamm"."block_result_status" AS ENUM (
    'planned',
    'in_progress',
    'completed',
    'partial',
    'skipped'
);


ALTER TYPE "zamm"."block_result_status" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "zamm"."calculate_load_from_1rm"("p_athlete_natural_id" "uuid", "p_exercise_key" "text", "p_percentage" numeric) RETURNS numeric
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_one_rm NUMERIC(10,2);
    v_calculated_load NUMERIC(10,2);
BEGIN
    -- Get CURRENT 1RM for this exercise
    SELECT value
    INTO v_one_rm
    FROM zamm.athlete_personal_records
    WHERE athlete_natural_id = p_athlete_natural_id
    AND exercise_key = p_exercise_key
    AND pr_type = '1rm'
    AND is_current_pr = true;
    
    IF v_one_rm IS NULL THEN
        RAISE EXCEPTION 'No 1RM found for athlete % and exercise %', 
            p_athlete_natural_id, p_exercise_key;
    END IF;
    
    -- Calculate load
    v_calculated_load := v_one_rm * (p_percentage / 100.0);
    
    RETURN v_calculated_load;
END;
$$;


ALTER FUNCTION "zamm"."calculate_load_from_1rm"("p_athlete_natural_id" "uuid", "p_exercise_key" "text", "p_percentage" numeric) OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."calculate_load_from_1rm"("p_athlete_natural_id" "uuid", "p_exercise_key" "text", "p_percentage" numeric) IS 'Calculate load in kg from 1RM percentage (e.g., 80% of 1RM)';



CREATE OR REPLACE FUNCTION "zamm"."calculate_load_from_bodyweight"("p_athlete_natural_id" "uuid", "p_multiplier" numeric) RETURNS numeric
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_bodyweight_kg NUMERIC(5,2);
    v_calculated_load NUMERIC(10,2);
BEGIN
    -- Get current bodyweight
    SELECT current_weight_kg 
    INTO v_bodyweight_kg
    FROM zamm.dim_athletes
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


ALTER FUNCTION "zamm"."calculate_load_from_bodyweight"("p_athlete_natural_id" "uuid", "p_multiplier" numeric) OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."calculate_load_from_bodyweight"("p_athlete_natural_id" "uuid", "p_multiplier" numeric) IS 'Calculate load in kg from bodyweight multiplier (e.g., 0.8×BW)';



CREATE OR REPLACE FUNCTION "zamm"."check_athlete_exists"("p_search_name" "text") RETURNS TABLE("athlete_id" "uuid", "full_name" character varying, "email" character varying, "current_weight_kg" numeric, "gender" character varying)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'zamm', 'public'
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


ALTER FUNCTION "zamm"."check_athlete_exists"("p_search_name" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."check_athlete_exists"("p_search_name" "text") IS 'AI Tool: Search for athletes by name or email. Returns up to 5 matches ordered by relevance.';



CREATE OR REPLACE FUNCTION "zamm"."check_equipment_exists"("p_search_name" "text") RETURNS TABLE("equipment_key" "text", "display_name" "text", "category" "text", "matched_via" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'zamm', 'public'
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


ALTER FUNCTION "zamm"."check_equipment_exists"("p_search_name" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."check_equipment_exists"("p_search_name" "text") IS 'AI Tool: Search for equipment by name or alias. Returns up to 10 matches with category info.';



CREATE OR REPLACE FUNCTION "zamm"."check_exercise_exists"("p_search_name" "text") RETURNS TABLE("exercise_key" "text", "display_name" "text", "category" "text", "movement_pattern" "text", "matched_via" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        ec.exercise_key,
        ec.display_name,
        ec.category,
        ec.movement_pattern,
        CASE 
            WHEN ec.display_name ILIKE '%' || p_search_name || '%' THEN 'display_name'
            WHEN ec.exercise_key ILIKE '%' || p_search_name || '%' THEN 'exercise_key'
            ELSE 'alias'
        END as matched_via
    FROM zamm.exercise_catalog ec
    LEFT JOIN zamm.exercise_aliases ea ON ec.exercise_key = ea.exercise_key
    WHERE 
        ec.is_active = true
        AND (
            ec.display_name ILIKE '%' || p_search_name || '%'
            OR ec.exercise_key ILIKE '%' || p_search_name || '%'
            OR ea.alias ILIKE '%' || p_search_name || '%'
        )
    ORDER BY 
        -- Exact matches first
        CASE WHEN LOWER(ec.display_name) = LOWER(p_search_name) THEN 0 ELSE 1 END,
        matched_via,
        ec.display_name
    LIMIT 10;
END;
$$;


ALTER FUNCTION "zamm"."check_exercise_exists"("p_search_name" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."check_exercise_exists"("p_search_name" "text") IS 'AI Tool: Search for exercises by name or alias. Returns up to 10 matches with metadata.';



CREATE OR REPLACE FUNCTION "zamm"."check_prescription_performance_consistency"("p_block" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_issues JSONB := '[]'::JSONB;
    v_prescription JSONB;
    v_performed JSONB;
    v_presc_steps INTEGER;
    v_perf_steps INTEGER;
BEGIN
    v_prescription := p_block->'prescription';
    v_performed := p_block->'performed';

    -- If no performance data, no inconsistency possible
    IF v_performed IS NULL THEN
        RETURN jsonb_build_object(
            'consistent', true,
            'issues', '[]'::JSONB,
            'note', 'No performance data to compare'
        );
    END IF;

    -- Check 1: Number of exercises matches
    v_presc_steps := jsonb_array_length(v_prescription->'steps');
    v_perf_steps := jsonb_array_length(v_performed->'steps');

    IF v_presc_steps != v_perf_steps THEN
        v_issues := v_issues || jsonb_build_object(
            'type', 'step_count_mismatch',
            'message', format('Prescription has %s exercises but performance has %s', 
                            v_presc_steps, v_perf_steps),
            'severity', 'warning'
        );
    END IF;

    -- Check 2: If performed exists but is empty
    IF v_performed ? 'steps' AND jsonb_array_length(v_performed->'steps') = 0 THEN
        v_issues := v_issues || jsonb_build_object(
            'type', 'empty_performance',
            'message', 'Performance data exists but contains no steps',
            'severity', 'warning'
        );
    END IF;

    -- Check 3: If did_complete is false, there should be notes
    IF (v_performed->>'did_complete')::BOOLEAN = false AND 
       NOT (v_performed ? 'notes') THEN
        v_issues := v_issues || jsonb_build_object(
            'type', 'incomplete_without_reason',
            'message', 'Block marked as incomplete but no notes explaining why',
            'severity', 'info'
        );
    END IF;

    RETURN jsonb_build_object(
        'consistent', (jsonb_array_length(v_issues) = 0),
        'issues', v_issues,
        'issues_count', jsonb_array_length(v_issues)
    );
END;
$$;


ALTER FUNCTION "zamm"."check_prescription_performance_consistency"("p_block" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."check_prescription_performance_consistency"("p_block" "jsonb") IS 'Compares prescription vs performance data for consistency';



CREATE OR REPLACE FUNCTION "zamm"."commit_emom_workout"("p_athlete_id" "uuid", "p_workout_date" "date", "p_emom_config" "jsonb", "p_results" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_workout_id UUID;
    v_session_id UUID;
    v_block_id UUID;
    v_item JSONB;
    v_item_id UUID;
    v_round JSONB;
    v_round_num INTEGER;
BEGIN
    -- Create workout
    INSERT INTO zamm.workout_main (
        athlete_id,
        workout_date,
        workout_type,
        status
    ) VALUES (
        p_athlete_id,
        p_workout_date,
        'conditioning',
        'completed'
    ) RETURNING workout_id INTO v_workout_id;
    
    -- Create session
    INSERT INTO zamm.workout_sessions (
        workout_id,
        session_number,
        session_type
    ) VALUES (
        v_workout_id,
        1,
        'main'
    ) RETURNING session_id INTO v_session_id;
    
    -- Create EMOM block
    INSERT INTO zamm.workout_blocks (
        session_id,
        block_number,
        block_code,
        block_type,
        work_time_sec,
        rounds,
        prescription_data,
        notes
    ) VALUES (
        v_session_id,
        1,
        'INTV',
        'conditioning',
        (p_emom_config->>'interval_sec')::INTEGER,
        ((p_emom_config->>'duration_min')::INTEGER * 60) / (p_emom_config->>'interval_sec')::INTEGER,
        p_emom_config,
        p_emom_config->>'pattern' || ' ' || p_emom_config->>'duration_min' || ' min'
    ) RETURNING block_id INTO v_block_id;
    
    -- Add items (exercises)
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_emom_config->'items')
    LOOP
        INSERT INTO zamm.workout_items (
            block_id,
            item_number,
            exercise_key,
            prescription_data,
            notes
        ) VALUES (
            v_block_id,
            (v_item->>'item_number')::INTEGER,
            v_item->>'exercise_key',
            v_item->'prescription_data',
            v_item->>'notes'
        ) RETURNING item_id INTO v_item_id;
    END LOOP;
    
    -- Add interval results (round by round)
    v_round_num := 1;
    FOR v_round IN SELECT * FROM jsonb_array_elements(p_results->'rounds')
    LOOP
        INSERT INTO zamm.res_intervals (
            block_id,
            segment_index,
            work_time_sec,
            distance_meters,
            calories,
            notes
        ) VALUES (
            v_block_id,
            v_round_num,
            (p_emom_config->>'interval_sec')::INTEGER,
            (v_round->>'distance_meters')::NUMERIC,
            (v_round->>'calories')::INTEGER,
            v_round->>'notes'
        );
        
        v_round_num := v_round_num + 1;
    END LOOP;
    
    -- Add block summary
    INSERT INTO zamm.res_blocks (
        block_id,
        result_model_id,
        result_type,
        result_canonical,
        result_display
    ) VALUES (
        v_block_id,
        'interval_splits',
        'scored',
        p_results,
        zamm.format_emom_results(v_block_id)
    );
    
    RETURN v_workout_id;
END;
$$;


ALTER FUNCTION "zamm"."commit_emom_workout"("p_athlete_id" "uuid", "p_workout_date" "date", "p_emom_config" "jsonb", "p_results" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."commit_emom_workout"("p_athlete_id" "uuid", "p_workout_date" "date", "p_emom_config" "jsonb", "p_results" "jsonb") IS 'Complete function to commit an EMOM workout with config and results';



CREATE OR REPLACE FUNCTION "zamm"."commit_full_workout_latest"("p_import_id" "uuid", "p_draft_id" "uuid", "p_athlete_id" "uuid", "p_ruleset_id" "uuid", "p_normalized_json" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN zamm.commit_full_workout_v3(
        p_import_id,
        p_draft_id,
        p_athlete_id,
        p_ruleset_id,
        p_normalized_json
    );
END;
$$;


ALTER FUNCTION "zamm"."commit_full_workout_latest"("p_import_id" "uuid", "p_draft_id" "uuid", "p_athlete_id" "uuid", "p_ruleset_id" "uuid", "p_normalized_json" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."commit_full_workout_latest"("p_import_id" "uuid", "p_draft_id" "uuid", "p_athlete_id" "uuid", "p_ruleset_id" "uuid", "p_normalized_json" "jsonb") IS 'Alias to the latest version of commit_full_workout (currently v3 with updated table names)';



CREATE OR REPLACE FUNCTION "zamm"."commit_full_workout_v3"("p_import_id" "uuid", "p_draft_id" "uuid", "p_ruleset_id" "uuid", "p_athlete_id" "uuid", "p_normalized_json" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'zamm', 'public'
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


ALTER FUNCTION "zamm"."commit_full_workout_v3"("p_import_id" "uuid", "p_draft_id" "uuid", "p_ruleset_id" "uuid", "p_athlete_id" "uuid", "p_normalized_json" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."commit_full_workout_v3"("p_import_id" "uuid", "p_draft_id" "uuid", "p_ruleset_id" "uuid", "p_athlete_id" "uuid", "p_normalized_json" "jsonb") IS 'Enhanced workout commit with search_path optimization for cleaner code.';



CREATE OR REPLACE FUNCTION "zamm"."compute_avg_rpe"("p_canonical" "jsonb") RETURNS numeric
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    RETURN (
        SELECT AVG((s->>'rpe')::NUMERIC)
        FROM jsonb_array_elements(p_canonical->'sets') s
        WHERE s ? 'rpe'
    );
END;
$$;


ALTER FUNCTION "zamm"."compute_avg_rpe"("p_canonical" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "zamm"."compute_best_make"("p_canonical" "jsonb") RETURNS numeric
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    v_best NUMERIC := 0;
    v_attempt JSONB;
BEGIN
    FOR v_attempt IN SELECT * FROM jsonb_array_elements(p_canonical->'attempts')
    LOOP
        IF v_attempt->>'result' = 'make' THEN
            v_best := GREATEST(v_best, (v_attempt->>'load_kg')::NUMERIC);
        END IF;
    END LOOP;
    
    RETURN v_best;
END;
$$;


ALTER FUNCTION "zamm"."compute_best_make"("p_canonical" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "zamm"."compute_tonnage"("p_canonical" "jsonb") RETURNS numeric
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    v_tonnage NUMERIC := 0;
    v_set JSONB;
BEGIN
    FOR v_set IN SELECT * FROM jsonb_array_elements(p_canonical->'sets')
    LOOP
        v_tonnage := v_tonnage + 
            COALESCE((v_set->>'reps_completed')::INTEGER, 0) * 
            COALESCE((v_set->>'load_kg')::NUMERIC, 0);
    END LOOP;
    
    RETURN v_tonnage;
END;
$$;


ALTER FUNCTION "zamm"."compute_tonnage"("p_canonical" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "zamm"."create_hyrox_split"("p_split_number" integer, "p_station_name" "text", "p_exercise_key" "text", "p_time_seconds" integer, "p_distance_meters" integer DEFAULT NULL::integer, "p_reps" integer DEFAULT NULL::integer, "p_load_kg" numeric DEFAULT NULL::numeric, "p_pace" "text" DEFAULT NULL::"text", "p_spm" integer DEFAULT NULL::integer, "p_is_transition" boolean DEFAULT false, "p_notes" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    v_split JSONB;
BEGIN
    v_split := jsonb_build_object(
        'split_number', p_split_number,
        'station_name', p_station_name,
        'exercise_key', p_exercise_key,
        'time_seconds', p_time_seconds,
        'is_transition', p_is_transition
    );
    
    IF p_distance_meters IS NOT NULL THEN
        v_split := v_split || jsonb_build_object('distance_meters', p_distance_meters);
    END IF;
    
    IF p_reps IS NOT NULL THEN
        v_split := v_split || jsonb_build_object('reps', p_reps);
    END IF;
    
    IF p_load_kg IS NOT NULL THEN
        v_split := v_split || jsonb_build_object('load_kg', p_load_kg);
    END IF;
    
    IF p_pace IS NOT NULL THEN
        v_split := v_split || jsonb_build_object('pace', p_pace);
    END IF;
    
    IF p_spm IS NOT NULL THEN
        v_split := v_split || jsonb_build_object('spm', p_spm);
    END IF;
    
    IF p_notes IS NOT NULL THEN
        v_split := v_split || jsonb_build_object('notes', p_notes);
    END IF;
    
    RETURN v_split;
END;
$$;


ALTER FUNCTION "zamm"."create_hyrox_split"("p_split_number" integer, "p_station_name" "text", "p_exercise_key" "text", "p_time_seconds" integer, "p_distance_meters" integer, "p_reps" integer, "p_load_kg" numeric, "p_pace" "text", "p_spm" integer, "p_is_transition" boolean, "p_notes" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."create_hyrox_split"("p_split_number" integer, "p_station_name" "text", "p_exercise_key" "text", "p_time_seconds" integer, "p_distance_meters" integer, "p_reps" integer, "p_load_kg" numeric, "p_pace" "text", "p_spm" integer, "p_is_transition" boolean, "p_notes" "text") IS 'Helper function to create properly structured HYROX split JSONB objects';



CREATE OR REPLACE FUNCTION "zamm"."create_workout_manual"("p_athlete_id" "uuid", "p_workout_date" "date", "p_session_title" "text" DEFAULT 'Main Session'::"text", "p_workout_json" "jsonb" DEFAULT NULL::"jsonb", "p_created_by" "uuid" DEFAULT NULL::"uuid") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_import_id UUID;
    v_draft_id UUID;
    v_ruleset_id UUID;
    v_workout_id UUID;
BEGIN
    -- Validation
    IF p_athlete_id IS NULL THEN
        RAISE EXCEPTION 'athlete_id is required';
    END IF;
    
    IF p_workout_date IS NULL THEN
        p_workout_date := CURRENT_DATE;
    END IF;
    
    -- אם לא סופק JSON, נצור מבנה בסיסי
    IF p_workout_json IS NULL THEN
        p_workout_json := jsonb_build_object(
            'sessions', jsonb_build_array(
                jsonb_build_object(
                    'sessionInfo', jsonb_build_object(
                        'date', p_workout_date,
                        'title', p_session_title
                    ),
                    'blocks', jsonb_build_array()
                )
            )
        );
    END IF;
    
    -- 1. יצירת import אוטומטי
    INSERT INTO zamm.imports (
        source, 
        athlete_id, 
        raw_text, 
        created_at
    )
    VALUES (
        'manual_direct',
        p_athlete_id,
        COALESCE(p_session_title, 'Manual Workout'),
        NOW()
    )
    RETURNING import_id INTO v_import_id;
    
    -- 2. קבלת ruleset פעיל
    SELECT ruleset_id INTO v_ruleset_id
    FROM zamm.lib_parser_rulesets
    WHERE is_active = true
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- אם אין ruleset פעיל, ניצור dummy
    IF v_ruleset_id IS NULL THEN
        INSERT INTO zamm.lib_parser_rulesets (
            name,
            version,
            is_active,
            rules
        )
        VALUES (
            'manual_default',
            '1.0',
            true,
            '{}'::jsonb
        )
        RETURNING ruleset_id INTO v_ruleset_id;
    END IF;
    
    -- 3. יצירת draft אוטומטי
    INSERT INTO zamm.parse_drafts (
        import_id,
        ruleset_id,
        parser_version,
        stage,
        normalized_draft,
        confidence_score,
        created_at
    )
    VALUES (
        v_import_id,
        v_ruleset_id,
        'manual_v1',
        'normalized',
        p_workout_json,
        1.0,
        NOW()
    )
    RETURNING draft_id INTO v_draft_id;
    
    -- 4. קריאה ל-commit_full_workout_v3
    v_workout_id := zamm.commit_full_workout_v3(
        v_import_id,
        v_draft_id,
        v_ruleset_id,
        p_athlete_id,
        p_workout_json
    );
    
    -- 5. עדכון created_by אם סופק
    IF p_created_by IS NOT NULL THEN
        UPDATE zamm.workouts
        SET created_by = p_created_by
        WHERE workout_id = v_workout_id;
    END IF;
    
    RETURN v_workout_id;
    
EXCEPTION 
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in create_workout_manual: %', SQLERRM;
        RAISE;
END;
$$;


ALTER FUNCTION "zamm"."create_workout_manual"("p_athlete_id" "uuid", "p_workout_date" "date", "p_session_title" "text", "p_workout_json" "jsonb", "p_created_by" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."create_workout_manual"("p_athlete_id" "uuid", "p_workout_date" "date", "p_session_title" "text", "p_workout_json" "jsonb", "p_created_by" "uuid") IS 'יצירת workout ישיר ללא צורך ב-import ו-draft מוקדמים. יוצר אותם אוטומטית.
דוגמה:
  SELECT zamm.create_workout_manual(
    ''athlete-uuid'',
    ''2026-01-05'',
    ''Morning Workout'',
    ''{"sessions": [...]}''::jsonb
  );';



CREATE OR REPLACE FUNCTION "zamm"."detect_and_record_pr"("p_athlete_natural_id" "uuid", "p_exercise_key" "text", "p_pr_type" "text", "p_value" numeric, "p_unit" "text", "p_workout_id" "uuid", "p_block_id" "uuid" DEFAULT NULL::"uuid", "p_item_id" "uuid" DEFAULT NULL::"uuid", "p_set_result_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("is_new_pr" boolean, "pr_id" "uuid", "previous_value" numeric, "improvement" numeric)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_current_pr NUMERIC(10,2);
    v_current_pr_id UUID;
    v_new_pr_id UUID;
    v_improvement NUMERIC(5,2);
    v_athlete_bodyweight NUMERIC(5,2);
BEGIN
    -- Get current PR
    SELECT pr.value, pr.pr_id
    INTO v_current_pr, v_current_pr_id
    FROM zamm.athlete_personal_records pr
    WHERE pr.athlete_natural_id = p_athlete_natural_id
    AND pr.exercise_key = p_exercise_key
    AND pr.pr_type = p_pr_type
    AND pr.is_current_pr = true;
    
    -- Get athlete's current bodyweight
    SELECT current_weight_kg
    INTO v_athlete_bodyweight
    FROM zamm.dim_athletes
    WHERE athlete_natural_id = p_athlete_natural_id
    AND is_current = true;
    
    -- Check if this is a new PR
    IF v_current_pr IS NULL OR p_value > v_current_pr THEN
        -- Calculate improvement
        IF v_current_pr IS NOT NULL THEN
            v_improvement := ((p_value - v_current_pr) / v_current_pr) * 100;
            
            -- Mark old PR as not current
            UPDATE zamm.athlete_personal_records
            SET is_current_pr = false,
                updated_at = NOW()
            WHERE pr_id = v_current_pr_id;
        END IF;
        
        -- Insert new PR
        INSERT INTO zamm.athlete_personal_records (
            athlete_natural_id,
            exercise_key,
            pr_type,
            value,
            unit,
            workout_id,
            block_id,
            item_id,
            set_result_id,
            achieved_at,
            previous_pr,
            improvement_percent,
            athlete_bodyweight_kg,
            is_current_pr,
            is_verified
        ) VALUES (
            p_athlete_natural_id,
            p_exercise_key,
            p_pr_type,
            p_value,
            p_unit,
            p_workout_id,
            p_block_id,
            p_item_id,
            p_set_result_id,
            NOW(),
            v_current_pr,
            v_improvement,
            v_athlete_bodyweight,
            true,
            false
        )
        RETURNING athlete_personal_records.pr_id INTO v_new_pr_id;
        
        -- Return success
        RETURN QUERY SELECT 
            true as is_new_pr,
            v_new_pr_id as pr_id,
            v_current_pr as previous_value,
            v_improvement as improvement;
    ELSE
        -- Not a PR
        RETURN QUERY SELECT 
            false as is_new_pr,
            NULL::UUID as pr_id,
            v_current_pr as previous_value,
            NULL::NUMERIC as improvement;
    END IF;
END;
$$;


ALTER FUNCTION "zamm"."detect_and_record_pr"("p_athlete_natural_id" "uuid", "p_exercise_key" "text", "p_pr_type" "text", "p_value" numeric, "p_unit" "text", "p_workout_id" "uuid", "p_block_id" "uuid", "p_item_id" "uuid", "p_set_result_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."detect_and_record_pr"("p_athlete_natural_id" "uuid", "p_exercise_key" "text", "p_pr_type" "text", "p_value" numeric, "p_unit" "text", "p_workout_id" "uuid", "p_block_id" "uuid", "p_item_id" "uuid", "p_set_result_id" "uuid") IS 'Automatically detect if a performance is a new PR and record it. 
Updates old PR to is_current_pr=false and creates new record with is_current_pr=true';



CREATE OR REPLACE FUNCTION "zamm"."enrich_split_data"("p_split" "jsonb", "p_exercise_catalog" "jsonb" DEFAULT NULL::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    v_enriched JSONB;
    v_station_type TEXT;
BEGIN
    v_enriched := p_split;
    v_station_type := p_split->>'station_type';
    
    -- Auto-detect if this is a transition
    IF v_station_type = 'rox' OR (p_split->>'station_name') ILIKE '%rox%' THEN
        v_enriched := v_enriched || jsonb_build_object('is_transition', true);
    END IF;
    
    -- Add exercise_key if not present but exercise_name is
    IF NOT (v_enriched ? 'exercise_key') AND (v_enriched ? 'exercise_name') THEN
        v_enriched := v_enriched || jsonb_build_object(
            'exercise_key', 
            lower(regexp_replace(v_enriched->>'exercise_name', '[^a-zA-Z0-9]+', '_', 'g'))
        );
    END IF;
    
    RETURN v_enriched;
END;
$$;


ALTER FUNCTION "zamm"."enrich_split_data"("p_split" "jsonb", "p_exercise_catalog" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."enrich_split_data"("p_split" "jsonb", "p_exercise_catalog" "jsonb") IS 'Enrich split data with computed fields (is_transition, exercise_key)';



CREATE OR REPLACE FUNCTION "zamm"."fn_get_benchmark_template"("p_benchmark_key" "text", "p_block_code" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
    v_template JSONB;
BEGIN
    SELECT prescription_template INTO v_template
    FROM zamm.lib_benchmark_blocks
    WHERE benchmark_key = p_benchmark_key
      AND block_code = p_block_code
      AND is_active = true;
    
    RETURN COALESCE(v_template, '{}'::jsonb);
END;
$$;


ALTER FUNCTION "zamm"."fn_get_benchmark_template"("p_benchmark_key" "text", "p_block_code" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."fn_get_benchmark_template"("p_benchmark_key" "text", "p_block_code" "text") IS 'Get prescription template for a benchmark+blocktype combination';



CREATE OR REPLACE FUNCTION "zamm"."fn_validate_benchmark_block"("p_benchmark_key" "text", "p_block_code" "text") RETURNS boolean
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM zamm.lib_benchmark_blocks 
        WHERE benchmark_key = p_benchmark_key 
          AND block_code = p_block_code 
          AND is_active = true
    );
END;
$$;


ALTER FUNCTION "zamm"."fn_validate_benchmark_block"("p_benchmark_key" "text", "p_block_code" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."fn_validate_benchmark_block"("p_benchmark_key" "text", "p_block_code" "text") IS 'Check if a benchmark is valid for a given block type';



CREATE OR REPLACE FUNCTION "zamm"."fn_validate_benchmark_exercise"("p_benchmark_key" "text", "p_exercise_key" "text") RETURNS boolean
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM zamm.lib_benchmark_exercises 
        WHERE benchmark_key = p_benchmark_key 
          AND exercise_key = p_exercise_key 
          AND is_active = true
    );
END;
$$;


ALTER FUNCTION "zamm"."fn_validate_benchmark_exercise"("p_benchmark_key" "text", "p_exercise_key" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."fn_validate_benchmark_exercise"("p_benchmark_key" "text", "p_exercise_key" "text") IS 'Check if a benchmark includes a given exercise';



CREATE OR REPLACE FUNCTION "zamm"."format_bilateral_reps"("p_reps" integer, "p_reps_right" integer, "p_reps_left" integer, "p_is_bilateral" boolean) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    IF p_is_bilateral AND p_reps_right IS NOT NULL AND p_reps_left IS NOT NULL THEN
        RETURN p_reps_right::TEXT || '/' || p_reps_left::TEXT;
    ELSIF p_reps IS NOT NULL THEN
        RETURN p_reps::TEXT;
    ELSE
        RETURN NULL;
    END IF;
END;
$$;


ALTER FUNCTION "zamm"."format_bilateral_reps"("p_reps" integer, "p_reps_right" integer, "p_reps_left" integer, "p_is_bilateral" boolean) OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."format_bilateral_reps"("p_reps" integer, "p_reps_right" integer, "p_reps_left" integer, "p_is_bilateral" boolean) IS 'Format reps display: returns "10/10" for bilateral movements or "20" for regular reps';



CREATE OR REPLACE FUNCTION "zamm"."format_emom_results"("p_block_id" "uuid") RETURNS "text"
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
    v_summary RECORD;
    v_round RECORD;
    v_result TEXT := '';
    v_block_notes TEXT;
BEGIN
    -- Get block notes (e.g., "E3MOM 12 min")
    SELECT notes INTO v_block_notes
    FROM zamm.workout_blocks
    WHERE block_id = p_block_id;
    
    -- Get summary
    SELECT * INTO v_summary
    FROM zamm.get_interval_results_summary(p_block_id);
    
    IF v_summary.total_rounds IS NULL OR v_summary.total_rounds = 0 THEN
        RETURN 'No results recorded';
    END IF;
    
    -- Build result string
    v_result := COALESCE(v_block_notes, 'EMOM') || E'\n';
    v_result := v_result || format('Total Rounds: %s', v_summary.total_rounds) || E'\n';
    
    IF v_summary.total_calories > 0 THEN
        v_result := v_result || format('Total Calories: %s (avg: %s)', 
            v_summary.total_calories, 
            ROUND(v_summary.avg_calories, 1)
        ) || E'\n';
    END IF;
    
    IF v_summary.total_distance > 0 THEN
        v_result := v_result || format('Total Distance: %sm (avg: %sm)', 
            v_summary.total_distance, 
            ROUND(v_summary.avg_distance, 1)
        ) || E'\n';
    END IF;
    
    -- Add round details
    v_result := v_result || E'\nRound Details:\n';
    FOR v_round IN 
        SELECT * FROM jsonb_array_elements(v_summary.rounds_data)
    LOOP
        v_result := v_result || format('  Round %s: %s', 
            v_round.value->>'round',
            COALESCE(v_round.value->>'notes', 'completed')
        ) || E'\n';
    END LOOP;
    
    RETURN v_result;
END;
$$;


ALTER FUNCTION "zamm"."format_emom_results"("p_block_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."format_emom_results"("p_block_id" "uuid") IS 'Format EMOM workout results into human-readable text';



CREATE OR REPLACE FUNCTION "zamm"."format_prescription_display"("p_prescription_data" "jsonb") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    v_display TEXT;
    v_item JSONB;
    v_items_array TEXT[] := ARRAY[]::TEXT[];
    v_item_display TEXT;
BEGIN
    -- Bilateral reps
    IF (p_prescription_data->>'is_bilateral')::boolean = true AND p_prescription_data ? 'reps_per_side' THEN
        v_display := (p_prescription_data->>'sets') || ' × ' || 
                     (p_prescription_data->>'reps_per_side') || '/' || 
                     (p_prescription_data->>'reps_per_side');
        
        IF p_prescription_data ? 'load_kg' THEN
            v_display := v_display || ' @ ' || (p_prescription_data->>'load_kg') || 'kg';
        END IF;
    
    -- Bilateral duration
    ELSIF (p_prescription_data->>'is_bilateral')::boolean = true AND p_prescription_data ? 'duration_per_side_sec' THEN
        v_display := (p_prescription_data->>'duration_per_side_sec') || 's R / ' || 
                     (p_prescription_data->>'duration_per_side_sec') || 's L';
    
    -- Standard sets × reps
    ELSIF p_prescription_data ? 'sets' AND p_prescription_data ? 'reps' THEN
        v_display := (p_prescription_data->>'sets') || ' × ' || (p_prescription_data->>'reps');
        
        IF p_prescription_data ? 'load_kg' THEN
            v_display := v_display || ' @ ' || (p_prescription_data->>'load_kg') || 'kg';
        ELSIF p_prescription_data ? 'load_range' THEN
            v_display := v_display || ' @ ' || (p_prescription_data->>'load_range');
        END IF;
    
    -- Sets × reps range
    ELSIF p_prescription_data ? 'sets' AND p_prescription_data ? 'reps_range' THEN
        v_display := (p_prescription_data->>'sets') || ' × ' || (p_prescription_data->>'reps_range');
    
    -- Duration
    ELSIF p_prescription_data ? 'duration_sec' THEN
        v_display := (p_prescription_data->>'duration_sec') || 's';
    
    ELSIF p_prescription_data ? 'duration_min' THEN
        v_display := (p_prescription_data->>'duration_min') || ' min';
    
    -- AMRAP with items
    ELSIF p_prescription_data ? 'time_cap_min' AND p_prescription_data ? 'items' THEN
        v_display := 'AMRAP ' || (p_prescription_data->>'time_cap_min') || 'min: ';
        
        -- Build items list
        FOR v_item IN SELECT jsonb_array_elements FROM jsonb_array_elements(p_prescription_data->'items')
        LOOP
            v_item_display := '';
            
            IF v_item ? 'reps' THEN
                v_item_display := (v_item->>'reps') || ' ';
            END IF;
            
            IF v_item ? 'distance_meters' THEN
                v_item_display := v_item_display || (v_item->>'distance_meters') || 'm ';
            END IF;
            
            v_item_display := v_item_display || (v_item->>'exercise_name');
            
            IF v_item ? 'load_kg' THEN
                v_item_display := v_item_display || ' @ ' || (v_item->>'load_kg') || 'kg';
            END IF;
            
            v_items_array := array_append(v_items_array, v_item_display);
        END LOOP;
        
        v_display := v_display || array_to_string(v_items_array, ', ');
    
    -- For Time with items
    ELSIF p_prescription_data ? 'rounds' AND p_prescription_data ? 'items' THEN
        v_display := (p_prescription_data->>'rounds') || ' rounds: ';
        
        -- Build items list
        FOR v_item IN SELECT jsonb_array_elements FROM jsonb_array_elements(p_prescription_data->'items')
        LOOP
            v_item_display := '';
            
            IF v_item ? 'reps' THEN
                v_item_display := (v_item->>'reps') || ' ';
            END IF;
            
            IF v_item ? 'distance_meters' THEN
                v_item_display := v_item_display || (v_item->>'distance_meters') || 'm ';
            END IF;
            
            v_item_display := v_item_display || (v_item->>'exercise_name');
            
            IF v_item ? 'load_kg' THEN
                v_item_display := v_item_display || ' @ ' || (v_item->>'load_kg') || 'kg';
            END IF;
            
            v_items_array := array_append(v_items_array, v_item_display);
        END LOOP;
        
        v_display := v_display || array_to_string(v_items_array, ', ');
        
        -- Add time cap if exists
        IF p_prescription_data ? 'time_cap_min' THEN
            v_display := v_display || ' (Cap ' || (p_prescription_data->>'time_cap_min') || 'min)';
        END IF;
        
        -- Add rest if exists (rounds for quality)
        IF p_prescription_data ? 'rest_between_rounds_sec' THEN
            v_display := v_display || ' (Rest ' || (p_prescription_data->>'rest_between_rounds_sec') || 's)';
        END IF;
    
    -- EMOM with items
    ELSIF p_prescription_data ? 'minutes' AND p_prescription_data ? 'items' THEN
        v_display := 'EMOM ' || (p_prescription_data->>'minutes') || 'min: ';
        
        -- Build items list
        FOR v_item IN SELECT jsonb_array_elements FROM jsonb_array_elements(p_prescription_data->'items')
        LOOP
            v_item_display := '';
            
            IF v_item ? 'minute' THEN
                v_item_display := 'Min' || (v_item->>'minute') || ' ';
            END IF;
            
            IF v_item ? 'reps' THEN
                v_item_display := v_item_display || (v_item->>'reps') || ' ';
            END IF;
            
            v_item_display := v_item_display || (v_item->>'exercise_name');
            
            v_items_array := array_append(v_items_array, v_item_display);
        END LOOP;
        
        v_display := v_display || array_to_string(v_items_array, ', ');
    
    ELSE
        v_display := 'Custom';
    END IF;
    
    RETURN v_display;
END;
$$;


ALTER FUNCTION "zamm"."format_prescription_display"("p_prescription_data" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."format_prescription_display"("p_prescription_data" "jsonb") IS 'Formats prescription_data into human-readable display string with full item details';



CREATE OR REPLACE FUNCTION "zamm"."get_active_ruleset"() RETURNS TABLE("ruleset_id" "uuid", "ruleset_name" "text", "version" "text", "units_catalog" "jsonb", "parser_mapping_rules" "jsonb", "value_unit_schema" "jsonb")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'zamm', 'public'
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


ALTER FUNCTION "zamm"."get_active_ruleset"() OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."get_active_ruleset"() IS 'AI Tool: Get the currently active parser ruleset with all conversion rules and schemas.';



CREATE OR REPLACE FUNCTION "zamm"."get_athlete_context"("p_athlete_id" "uuid") RETURNS TABLE("athlete_id" "uuid", "full_name" character varying, "gender" character varying, "age_years" integer, "height_cm" integer, "current_weight_kg" numeric, "recent_workouts_count" bigint, "last_workout_date" "date")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'zamm', 'public'
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


ALTER FUNCTION "zamm"."get_athlete_context"("p_athlete_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."get_athlete_context"("p_athlete_id" "uuid") IS 'AI Tool: Get comprehensive context for an athlete including recent activity stats.';



CREATE OR REPLACE FUNCTION "zamm"."get_bilateral_sets"("p_item_id" "uuid") RETURNS TABLE("side" "text", "set_index" integer, "reps" integer, "load_kg" numeric, "rpe" numeric, "rir" numeric)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        isr.side,
        isr.set_index,
        isr.reps,
        isr.load_kg,
        isr.rpe,
        isr.rir
    FROM zamm.res_item_sets isr
    JOIN zamm.workout_items wi ON isr.item_id = wi.item_id
    WHERE wi.item_id = p_item_id
    AND wi.bilateral = true
    ORDER BY isr.set_index, isr.side;
END;
$$;


ALTER FUNCTION "zamm"."get_bilateral_sets"("p_item_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."get_bilateral_sets"("p_item_id" "uuid") IS 'Get all sets for a bilateral exercise, organized by side';



CREATE OR REPLACE FUNCTION "zamm"."get_draft_validation_status"("p_draft_id" "uuid") RETURNS TABLE("draft_id" "uuid", "is_validated" boolean, "is_valid" boolean, "error_count" integer, "warning_count" integer, "confidence_score" numeric, "needs_review" boolean, "validation_summary" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pd.draft_id,
        (vr.report_id IS NOT NULL) as is_validated,
        COALESCE(vr.is_valid, false) as is_valid,
        COALESCE(jsonb_array_length(vr.errors), 0)::INTEGER as error_count,
        COALESCE(jsonb_array_length(vr.warnings), 0)::INTEGER as warning_count,
        pd.confidence_score,
        (COALESCE(jsonb_array_length(vr.errors), 0) > 0 OR pd.confidence_score < 0.7) as needs_review,
        CASE 
            WHEN vr.report_id IS NULL THEN 'Not validated yet'
            WHEN vr.is_valid AND jsonb_array_length(vr.warnings) = 0 THEN 'Valid - no issues'
            WHEN vr.is_valid AND jsonb_array_length(vr.warnings) > 0 THEN 
                format('Valid with %s warnings', jsonb_array_length(vr.warnings))
            ELSE format('Invalid - %s errors', jsonb_array_length(vr.errors))
        END as validation_summary
    FROM zamm.parse_drafts pd
    LEFT JOIN zamm.validation_reports vr ON pd.draft_id = vr.draft_id
    WHERE pd.draft_id = p_draft_id;
END;
$$;


ALTER FUNCTION "zamm"."get_draft_validation_status"("p_draft_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."get_draft_validation_status"("p_draft_id" "uuid") IS 'Returns quick validation status summary for a draft';



CREATE OR REPLACE FUNCTION "zamm"."get_exercises_by_muscle"("p_muscle" "text") RETURNS TABLE("exercise_key" "text", "display_name" "text", "category" "text", "movement_pattern" "text", "is_primary" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ec.exercise_key,
        ec.display_name,
        ec.category,
        ec.movement_pattern,
        (p_muscle = ANY(ec.primary_muscles)) as is_primary
    FROM zamm.lib_exercise_catalog ec
    WHERE ec.is_active = true
      AND (
          p_muscle = ANY(ec.primary_muscles)
          OR p_muscle = ANY(ec.secondary_muscles)
      )
    ORDER BY is_primary DESC, ec.display_name;
END;
$$;


ALTER FUNCTION "zamm"."get_exercises_by_muscle"("p_muscle" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."get_exercises_by_muscle"("p_muscle" "text") IS 'Get all exercises that work a specific muscle (primary or secondary)';



CREATE OR REPLACE FUNCTION "zamm"."get_exercises_by_pattern"("p_pattern" "text") RETURNS TABLE("exercise_key" "text", "display_name" "text", "category" "text", "difficulty_level" integer, "primary_muscles" "text"[])
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ec.exercise_key,
        ec.display_name,
        ec.category,
        ec.difficulty_level,
        ec.primary_muscles
    FROM zamm.lib_exercise_catalog ec
    WHERE ec.movement_pattern = p_pattern
      AND ec.is_active = true
    ORDER BY ec.difficulty_level, ec.display_name;
END;
$$;


ALTER FUNCTION "zamm"."get_exercises_by_pattern"("p_pattern" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."get_exercises_by_pattern"("p_pattern" "text") IS 'Get all exercises for a specific movement pattern, ordered by difficulty';



CREATE OR REPLACE FUNCTION "zamm"."get_interval_results_summary"("p_block_id" "uuid") RETURNS TABLE("total_rounds" integer, "avg_work_time" numeric, "total_distance" numeric, "avg_distance" numeric, "total_calories" integer, "avg_calories" numeric, "rounds_data" "jsonb")
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_rounds,
        AVG(work_time_sec)::NUMERIC(10,2) as avg_work_time,
        SUM(COALESCE(distance_meters, 0))::NUMERIC(10,2) as total_distance,
        AVG(COALESCE(distance_meters, 0))::NUMERIC(10,2) as avg_distance,
        SUM(COALESCE(calories, 0))::INTEGER as total_calories,
        AVG(COALESCE(calories, 0))::NUMERIC(10,2) as avg_calories,
        jsonb_agg(
            jsonb_build_object(
                'round', segment_index,
                'work_time_sec', work_time_sec,
                'distance_meters', distance_meters,
                'calories', calories,
                'pace', split_pace,
                'notes', notes
            ) ORDER BY segment_index
        ) as rounds_data
    FROM zamm.res_intervals
    WHERE block_id = p_block_id;
END;
$$;


ALTER FUNCTION "zamm"."get_interval_results_summary"("p_block_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."get_interval_results_summary"("p_block_id" "uuid") IS 'Get aggregated summary of interval results for a block (EMOM, Tabata, etc.)';



CREATE OR REPLACE FUNCTION "zamm"."get_parser_rule"("rule_id_param" integer) RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$
    SELECT rule
    FROM zamm.lib_parser_rulesets,
         LATERAL jsonb_array_elements(parser_mapping_rules->'rules') AS rule
    WHERE is_active = true
      AND (rule->>'rule_id')::INT = rule_id_param
    LIMIT 1;
$$;


ALTER FUNCTION "zamm"."get_parser_rule"("rule_id_param" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."get_parser_rule"("rule_id_param" integer) IS 'Returns a specific parser rule by ID from the active ruleset.
Example: SELECT * FROM zamm.get_parser_rule(10); -- Gets Rule 10 (hold vs dynamic)';



CREATE OR REPLACE FUNCTION "zamm"."get_parser_rules"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$
    SELECT parser_mapping_rules
    FROM zamm.lib_parser_rulesets
    WHERE is_active = true
    LIMIT 1;
$$;


ALTER FUNCTION "zamm"."get_parser_rules"() OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."get_parser_rules"() IS 'Returns the active parser_mapping_rules from lib_parser_rulesets.
Use this in AI parsing workflows to get current rules from database.';



CREATE OR REPLACE FUNCTION "zamm"."get_result_model_for_block"("p_block_code" "text") RETURNS TABLE("result_model_id" "text", "display_name" "text", "json_schema" "jsonb")
    LANGUAGE "sql" STABLE
    AS $$
    SELECT 
        result_model_id,
        display_name,
        json_schema
    FROM zamm.lib_result_models
    WHERE p_block_code = ANY(applicable_block_codes)
      AND is_active = true;
$$;


ALTER FUNCTION "zamm"."get_result_model_for_block"("p_block_code" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."get_result_model_for_block"("p_block_code" "text") IS 'Get applicable result models for a given block code';



CREATE OR REPLACE FUNCTION "zamm"."get_workout_results"("p_workout_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'workout_id', w.workout_id,
        'athlete_id', w.athlete_id,
        'workout_date', w.workout_date,
        'status', w.status,
        'sessions', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'session_id', ws.session_id,
                    'session_title', ws.session_title,
                    'blocks', (
                        SELECT jsonb_agg(
                            jsonb_build_object(
                                'block_id', wb.block_id,
                                'block_code', wb.block_code,
                                'name', wb.name,
                                'prescription', wb.prescription,
                                'performed', wb.performed,
                                'block_result', (
                                    SELECT jsonb_build_object(
                                        'total_time_sec', rb.total_time_sec,
                                        'score_text', rb.score_text,
                                        'calories', rb.calories,
                                        'status', rb.status
                                    )
                                    FROM zamm.res_blocks rb
                                    WHERE rb.block_id = wb.block_id
                                ),
                                'set_results', (
                                    SELECT jsonb_agg(
                                        jsonb_build_object(
                                            'set_index', ris.set_index,
                                            'reps', ris.reps,
                                            'load_kg', ris.load_kg,
                                            'rpe', ris.rpe,
                                            'rir', ris.rir
                                        )
                                        ORDER BY ris.set_index
                                    )
                                    FROM zamm.res_item_sets ris
                                    WHERE ris.block_id = wb.block_id
                                )
                            )
                        )
                        FROM zamm.workout_blocks wb
                        WHERE wb.session_id = ws.session_id
                    )
                )
            )
            FROM zamm.workout_sessions ws
            WHERE ws.workout_id = w.workout_id
        )
    ) INTO v_result
    FROM zamm.workout_main w
    WHERE w.workout_id = p_workout_id;
    
    RETURN v_result;
END;
$$;


ALTER FUNCTION "zamm"."get_workout_results"("p_workout_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."get_workout_results"("p_workout_id" "uuid") IS 'שאילתת תוצאות מלאות של workout כולל prescription + performed.
דוגמה:
  SELECT zamm.get_workout_results(''workout-uuid'');';



CREATE OR REPLACE FUNCTION "zamm"."list_common_muscles"() RETURNS TABLE("muscle_key" "text", "display_name" "text")
    LANGUAGE "sql" STABLE
    AS $$
    SELECT 
        muscle_key, 
        display_name
    FROM zamm.lib_muscle_groups
    WHERE is_active = true
    ORDER BY muscle_key;
$$;


ALTER FUNCTION "zamm"."list_common_muscles"() OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."list_common_muscles"() IS 'Returns list of common muscle groups from lib_muscle_groups table.
This is for UI suggestions only - exercises are not limited to these muscles.';



CREATE OR REPLACE FUNCTION "zamm"."normalize_block_code"("p_input" "text") RETURNS TABLE("block_code" "text", "block_type" "text", "category" "text", "result_model" "text", "ui_hint" "text", "display_name" "text", "matched_via" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_normalized TEXT;
BEGIN
    v_normalized := UPPER(TRIM(p_input));
    
    RETURN QUERY
    SELECT 
        btc.block_code,
        btc.block_type,
        btc.category,
        btc.result_model,
        btc.ui_hint,
        btc.display_name,
        'exact'::TEXT as matched_via
    FROM zamm.block_type_catalog btc
    WHERE UPPER(btc.block_code) = v_normalized AND btc.is_active = true
    
    UNION ALL
    
    SELECT 
        btc.block_code,
        btc.block_type,
        btc.category,
        btc.result_model,
        btc.ui_hint,
        btc.display_name,
        'alias'::TEXT as matched_via
    FROM zamm.block_code_aliases bca
    JOIN zamm.block_type_catalog btc ON bca.block_code = btc.block_code
    WHERE LOWER(bca.alias) = LOWER(p_input) AND btc.is_active = true
    
    ORDER BY matched_via
    LIMIT 5;
END;
$$;


ALTER FUNCTION "zamm"."normalize_block_code"("p_input" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "zamm"."normalize_block_type"("p_block_type" "text") RETURNS TABLE("is_valid" boolean, "normalized_type" "text", "suggested_structure" "text", "common_patterns" "text"[])
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'zamm', 'public'
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


ALTER FUNCTION "zamm"."normalize_block_type"("p_block_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "zamm"."resolve_exercise_key"("p_exercise_name" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_exercise_key TEXT;
BEGIN
    -- נסיון 1: חיפוש ישיר ב-catalog לפי display_name
    SELECT exercise_key INTO v_exercise_key
    FROM zamm.lib_exercise_catalog
    WHERE LOWER(display_name) = LOWER(p_exercise_name)
    LIMIT 1;
    
    IF v_exercise_key IS NOT NULL THEN
        RETURN v_exercise_key;
    END IF;
    
    -- נסיון 2: חיפוש ב-aliases
    SELECT exercise_key INTO v_exercise_key
    FROM zamm.lib_exercise_aliases
    WHERE LOWER(alias) = LOWER(p_exercise_name)
    LIMIT 1;
    
    IF v_exercise_key IS NOT NULL THEN
        RETURN v_exercise_key;
    END IF;
    
    -- נסיון 3: חיפוש חלקי (LIKE)
    SELECT exercise_key INTO v_exercise_key
    FROM zamm.lib_exercise_catalog
    WHERE LOWER(display_name) LIKE '%' || LOWER(p_exercise_name) || '%'
    LIMIT 1;
    
    IF v_exercise_key IS NOT NULL THEN
        RETURN v_exercise_key;
    END IF;
    
    -- לא נמצא - להחזיר NULL
    RETURN NULL;
END;
$$;


ALTER FUNCTION "zamm"."resolve_exercise_key"("p_exercise_name" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."resolve_exercise_key"("p_exercise_name" "text") IS 'מנסה למצוא exercise_key לפי exercise_name.
מחפש ב-catalog (display_name), aliases, ואז LIKE חלקי.
מחזיר NULL אם לא נמצא.';



CREATE OR REPLACE FUNCTION "zamm"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "zamm"."set_updated_at"() OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."set_updated_at"() IS 'Universal trigger function to automatically update updated_at timestamp on row updates';



CREATE OR REPLACE FUNCTION "zamm"."submit_block_result"("p_block_id" "uuid", "p_total_time_sec" integer DEFAULT NULL::integer, "p_score_text" "text" DEFAULT NULL::"text", "p_did_complete" boolean DEFAULT true, "p_calories" integer DEFAULT NULL::integer, "p_notes" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_block_result_id UUID;
BEGIN
    -- בדיקת קיום block
    IF NOT EXISTS (SELECT 1 FROM zamm.workout_blocks WHERE block_id = p_block_id) THEN
        RAISE EXCEPTION 'workout_block with id % does not exist', p_block_id;
    END IF;
    
    -- הוספה או עדכון ב-res_blocks
    INSERT INTO zamm.res_blocks (
        block_id,
        total_time_sec,
        score_text,
        calories,
        status,
        created_at
    )
    VALUES (
        p_block_id,
        p_total_time_sec,
        p_score_text,
        p_calories,
        CASE WHEN p_did_complete THEN 'completed' ELSE 'partial' END,
        NOW()
    )
    ON CONFLICT (block_id) 
    DO UPDATE SET
        total_time_sec = COALESCE(EXCLUDED.total_time_sec, zamm.res_blocks.total_time_sec),
        score_text = COALESCE(EXCLUDED.score_text, zamm.res_blocks.score_text),
        calories = COALESCE(EXCLUDED.calories, zamm.res_blocks.calories),
        status = EXCLUDED.status,
        created_at = NOW()
    RETURNING block_result_id INTO v_block_result_id;
    
    -- עדכון performed ב-workout_blocks
    UPDATE zamm.workout_blocks
    SET performed = jsonb_build_object(
        'did_complete', p_did_complete,
        'total_time_sec', p_total_time_sec,
        'score_text', p_score_text,
        'calories', p_calories,
        'notes', p_notes
    )
    WHERE block_id = p_block_id;
    
    -- עדכון סטטוס workout אם כל הבלוקים הושלמו
    UPDATE zamm.workout_main w
    SET status = 'completed'
    WHERE workout_id IN (
        SELECT ws.workout_id
        FROM zamm.workout_sessions ws
        JOIN zamm.workout_blocks wb ON ws.session_id = wb.session_id
        WHERE wb.block_id = p_block_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM zamm.workout_sessions ws2
        JOIN zamm.workout_blocks wb2 ON ws2.session_id = wb2.session_id
        WHERE ws2.workout_id = w.workout_id
        AND NOT EXISTS (
            SELECT 1 FROM zamm.res_blocks rb
            WHERE rb.block_id = wb2.block_id
        )
    );
    
    RETURN v_block_result_id;
END;
$$;


ALTER FUNCTION "zamm"."submit_block_result"("p_block_id" "uuid", "p_total_time_sec" integer, "p_score_text" "text", "p_did_complete" boolean, "p_calories" integer, "p_notes" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."submit_block_result"("p_block_id" "uuid", "p_total_time_sec" integer, "p_score_text" "text", "p_did_complete" boolean, "p_calories" integer, "p_notes" "text") IS 'דיווח תוצאת בלוק שלם (זמן, ניקוד, קלוריות).
עדכון אוטומטי של סטטוס האימון.
דוגמה:
  SELECT zamm.submit_block_result(
    ''block-uuid'',     -- block_id
    420,                -- total_time_sec (7 minutes)
    ''21-15-9 Rx'',     -- score_text
    true,               -- did_complete
    150,                -- calories
    ''Felt strong''     -- notes
  );';



CREATE OR REPLACE FUNCTION "zamm"."submit_set_result"("p_item_id" "uuid", "p_set_index" integer, "p_reps" integer DEFAULT NULL::integer, "p_load_kg" numeric DEFAULT NULL::numeric, "p_rpe" numeric DEFAULT NULL::numeric, "p_rir" numeric DEFAULT NULL::numeric, "p_notes" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_set_result_id UUID;
    v_block_id UUID;
BEGIN
    -- בדיקת קיום item
    IF NOT EXISTS (SELECT 1 FROM zamm.workout_items WHERE item_id = p_item_id) THEN
        RAISE EXCEPTION 'workout_item with id % does not exist', p_item_id;
    END IF;
    
    -- קבלת block_id
    SELECT block_id INTO v_block_id
    FROM zamm.workout_items
    WHERE item_id = p_item_id;
    
    -- הוספה או עדכון
    INSERT INTO zamm.res_item_sets (
        block_id,
        item_id,
        set_index,
        reps,
        load_kg,
        rpe,
        rir,
        notes,
        created_at
    )
    VALUES (
        v_block_id,
        p_item_id,
        p_set_index,
        p_reps,
        p_load_kg,
        p_rpe,
        p_rir,
        p_notes,
        NOW()
    )
    ON CONFLICT (item_id, set_index) 
    DO UPDATE SET
        reps = COALESCE(EXCLUDED.reps, zamm.res_item_sets.reps),
        load_kg = COALESCE(EXCLUDED.load_kg, zamm.res_item_sets.load_kg),
        rpe = COALESCE(EXCLUDED.rpe, zamm.res_item_sets.rpe),
        rir = COALESCE(EXCLUDED.rir, zamm.res_item_sets.rir),
        notes = COALESCE(EXCLUDED.notes, zamm.res_item_sets.notes),
        created_at = NOW()
    RETURNING set_result_id INTO v_set_result_id;
    
    -- עדכון performed_data ב-workout_items
    UPDATE zamm.workout_items
    SET performed_data = jsonb_set(
        COALESCE(performed_data, '{}'::jsonb),
        ARRAY['sets', (p_set_index - 1)::text],
        jsonb_build_object(
            'set_index', p_set_index,
            'reps', p_reps,
            'load_kg', p_load_kg,
            'rpe', p_rpe,
            'rir', p_rir,
            'notes', p_notes
        ),
        true
    )
    WHERE item_id = p_item_id;
    
    RETURN v_set_result_id;
END;
$$;


ALTER FUNCTION "zamm"."submit_set_result"("p_item_id" "uuid", "p_set_index" integer, "p_reps" integer, "p_load_kg" numeric, "p_rpe" numeric, "p_rir" numeric, "p_notes" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."submit_set_result"("p_item_id" "uuid", "p_set_index" integer, "p_reps" integer, "p_load_kg" numeric, "p_rpe" numeric, "p_rir" numeric, "p_notes" "text") IS 'דיווח תוצאת סט בודד. מאפשר דיווח הדרגתי סט אחר סט.
דוגמה:
  SELECT zamm.submit_set_result(
    ''item-uuid'',  -- item_id
    1,              -- set_index
    5,              -- reps
    100.0,          -- load_kg
    8.0,            -- rpe
    2.0             -- rir
  );';



CREATE OR REPLACE FUNCTION "zamm"."suggest_balanced_exercises"("p_primary_pattern" "text" DEFAULT NULL::"text", "p_difficulty" integer DEFAULT 3) RETURNS TABLE("movement_pattern" "text", "pattern_category" "text", "exercise_key" "text", "display_name" "text", "difficulty_level" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- If specific pattern provided, get exercises for it and its complementary patterns
    IF p_primary_pattern IS NOT NULL THEN
        RETURN QUERY
        WITH pattern_context AS (
            SELECT 
                mp.pattern_key,
                mp.category
            FROM zamm.lib_movement_patterns mp
            WHERE mp.pattern_key = p_primary_pattern
        )
        SELECT 
            ec.movement_pattern,
            mp.category as pattern_category,
            ec.exercise_key,
            ec.display_name,
            ec.difficulty_level
        FROM zamm.lib_exercise_catalog ec
        JOIN zamm.lib_movement_patterns mp ON ec.movement_pattern = mp.pattern_key
        WHERE ec.is_active = true
          AND ec.difficulty_level <= p_difficulty
          AND (
              ec.movement_pattern = p_primary_pattern
              OR mp.category = (SELECT category FROM pattern_context)
          )
        ORDER BY 
            CASE WHEN ec.movement_pattern = p_primary_pattern THEN 0 ELSE 1 END,
            ec.difficulty_level,
            ec.display_name;
    ELSE
        -- Return balanced selection from each category
        RETURN QUERY
        SELECT DISTINCT ON (mp.category, ec.exercise_key)
            ec.movement_pattern,
            mp.category as pattern_category,
            ec.exercise_key,
            ec.display_name,
            ec.difficulty_level
        FROM zamm.lib_exercise_catalog ec
        JOIN zamm.lib_movement_patterns mp ON ec.movement_pattern = mp.pattern_key
        WHERE ec.is_active = true
          AND ec.difficulty_level <= p_difficulty
        ORDER BY mp.category, ec.difficulty_level, ec.display_name;
    END IF;
END;
$$;


ALTER FUNCTION "zamm"."suggest_balanced_exercises"("p_primary_pattern" "text", "p_difficulty" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."suggest_balanced_exercises"("p_primary_pattern" "text", "p_difficulty" integer) IS 'Suggest exercises for balanced programming. Can focus on specific pattern or return varied selection.';



CREATE OR REPLACE FUNCTION "zamm"."trg_set_exercise_key"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- אם exercise_key לא סופק, ננסה לזהות אוטומטית
    IF NEW.exercise_key IS NULL AND NEW.exercise_name IS NOT NULL THEN
        NEW.exercise_key := zamm.resolve_exercise_key(NEW.exercise_name);
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "zamm"."trg_set_exercise_key"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "zamm"."validate_and_save_report"("p_draft_id" "uuid", "p_parsed_json" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_validation_result JSONB;
    v_report_id UUID;
BEGIN
    -- Run validation
    v_validation_result := zamm.validate_workout_draft(p_draft_id, p_parsed_json);

    -- Insert into validation_reports table
    INSERT INTO zamm.validation_reports (
        draft_id,
        is_valid,
        errors,
        warnings,
        validator_version,
        created_at
    )
    VALUES (
        p_draft_id,
        (v_validation_result->>'is_valid')::BOOLEAN,
        v_validation_result->'errors',
        v_validation_result->'warnings',
        'v1.0.0',
        NOW()
    )
    RETURNING report_id INTO v_report_id;

    -- Update draft's confidence score
    UPDATE zamm.parse_drafts
    SET 
        confidence_score = (v_validation_result->>'confidence_score')::NUMERIC,
        updated_at = NOW()
    WHERE draft_id = p_draft_id;

    RETURN v_report_id;
END;
$$;


ALTER FUNCTION "zamm"."validate_and_save_report"("p_draft_id" "uuid", "p_parsed_json" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."validate_and_save_report"("p_draft_id" "uuid", "p_parsed_json" "jsonb") IS 'Validates draft and automatically saves report to validation_reports table';



CREATE OR REPLACE FUNCTION "zamm"."validate_pending_drafts"() RETURNS TABLE("draft_id" "uuid", "report_id" "uuid", "is_valid" boolean, "error_count" integer)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_draft RECORD;
    v_report_id UUID;
BEGIN
    FOR v_draft IN 
        SELECT pd.draft_id, pd.normalized_draft
        FROM zamm.parse_drafts pd
        LEFT JOIN zamm.validation_reports vr ON pd.draft_id = vr.draft_id
        WHERE vr.report_id IS NULL
          AND pd.stage = 'normalized'
          AND pd.normalized_draft IS NOT NULL
    LOOP
        -- Validate and save
        v_report_id := zamm.validate_and_save_report(
            v_draft.draft_id, 
            v_draft.normalized_draft
        );

        -- Return row
        RETURN QUERY
        SELECT 
            v_draft.draft_id,
            v_report_id,
            vr.is_valid,
            jsonb_array_length(vr.errors)::INTEGER
        FROM zamm.validation_reports vr
        WHERE vr.report_id = v_report_id;
    END LOOP;
END;
$$;


ALTER FUNCTION "zamm"."validate_pending_drafts"() OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."validate_pending_drafts"() IS 'Batch validates all drafts that do not have validation reports yet';



CREATE OR REPLACE FUNCTION "zamm"."validate_prescription_data"("p_prescription_data" "jsonb", "p_block_type" "text" DEFAULT NULL::"text") RETURNS TABLE("is_valid" boolean, "schema_matched" "text", "errors" "text"[])
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_schema RECORD;
    v_errors TEXT[] := ARRAY[]::TEXT[];
    v_matched_schema TEXT := NULL;
BEGIN
    -- Check for bilateral fields
    IF p_prescription_data ? 'is_bilateral' AND (p_prescription_data->>'is_bilateral')::boolean = true THEN
        -- Check if it has reps_per_side (bilateral reps)
        IF p_prescription_data ? 'reps_per_side' THEN
            v_matched_schema := 'bilateral_sets_reps';
            
            IF NOT (p_prescription_data ? 'sets') THEN
                v_errors := array_append(v_errors, 'bilateral_sets_reps requires "sets" field');
            END IF;
        
        -- Check if it has duration_per_side_sec (bilateral duration)
        ELSIF p_prescription_data ? 'duration_per_side_sec' THEN
            v_matched_schema := 'bilateral_duration';
        
        ELSE
            v_errors := array_append(v_errors, 'bilateral movement must have either reps_per_side or duration_per_side_sec');
        END IF;
    
    -- Check for standard sets/reps
    ELSIF p_prescription_data ? 'sets' AND (p_prescription_data ? 'reps' OR p_prescription_data ? 'reps_range') THEN
        v_matched_schema := 'sets_reps';
    
    -- Check for duration
    ELSIF p_prescription_data ? 'duration_sec' OR p_prescription_data ? 'duration_min' THEN
        v_matched_schema := 'duration';
    
    -- Check for AMRAP
    ELSIF p_prescription_data ? 'time_cap_min' AND p_prescription_data ? 'items' THEN
        v_matched_schema := 'amrap';
    
    -- Check for For Time
    ELSIF p_prescription_data ? 'rounds' AND p_prescription_data ? 'items' THEN
        IF p_prescription_data ? 'rest_between_rounds_sec' THEN
            v_matched_schema := 'rounds_quality';
        ELSE
            v_matched_schema := 'for_time';
        END IF;
    
    -- Check for EMOM
    ELSIF p_prescription_data ? 'minutes' AND p_prescription_data ? 'pattern' THEN
        v_matched_schema := 'emom';
    
    END IF;
    
    -- Return results
    RETURN QUERY SELECT 
        (array_length(v_errors, 1) IS NULL OR array_length(v_errors, 1) = 0) as is_valid,
        v_matched_schema as schema_matched,
        COALESCE(v_errors, ARRAY[]::TEXT[]) as errors;
END;
$$;


ALTER FUNCTION "zamm"."validate_prescription_data"("p_prescription_data" "jsonb", "p_block_type" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."validate_prescription_data"("p_prescription_data" "jsonb", "p_block_type" "text") IS 'Validates prescription_data JSONB against known schemas and returns matched schema + errors';



CREATE OR REPLACE FUNCTION "zamm"."validate_result_canonical"("p_result_model_id" "text", "p_canonical" "jsonb") RETURNS boolean
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
    v_schema JSONB;
    v_required_fields TEXT[];
    v_field TEXT;
BEGIN
    -- Get schema for the model
    SELECT json_schema INTO v_schema
    FROM zamm.lib_result_models
    WHERE result_model_id = p_result_model_id;
    
    IF v_schema IS NULL THEN
        RAISE EXCEPTION 'Unknown result_model_id: %', p_result_model_id;
    END IF;
    
    -- Extract required fields
    v_required_fields := ARRAY(
        SELECT jsonb_array_elements_text(v_schema->'required')
    );
    
    -- Check all required fields exist
    FOREACH v_field IN ARRAY v_required_fields
    LOOP
        IF NOT p_canonical ? v_field THEN
            RAISE EXCEPTION 'Missing required field: %', v_field;
        END IF;
    END LOOP;
    
    RETURN true;
END;
$$;


ALTER FUNCTION "zamm"."validate_result_canonical"("p_result_model_id" "text", "p_canonical" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."validate_result_canonical"("p_result_model_id" "text", "p_canonical" "jsonb") IS 'Validate canonical data against result model schema';



CREATE OR REPLACE FUNCTION "zamm"."validate_workout_draft"("p_draft_id" "uuid", "p_parsed_json" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_errors JSONB := '[]'::JSONB;
    v_warnings JSONB := '[]'::JSONB;
    v_session JSONB;
    v_block JSONB;
    v_step JSONB;
    v_set JSONB;
    v_is_valid BOOLEAN := true;
    v_confidence NUMERIC := 1.0;
BEGIN
    -- Validation 1: Check required fields exist
    IF NOT (p_parsed_json ? 'sessions') THEN
        v_errors := v_errors || jsonb_build_object(
            'field', 'sessions',
            'issue', 'Missing required field: sessions',
            'severity', 'error'
        );
        v_is_valid := false;
    END IF;

    -- Loop through sessions
    FOR v_session IN SELECT * FROM jsonb_array_elements(p_parsed_json->'sessions')
    LOOP
        -- Validation 2: Check session has date
        IF NOT (v_session->'sessionInfo' ? 'date') THEN
            v_errors := v_errors || jsonb_build_object(
                'field', 'sessionInfo.date',
                'issue', 'Missing session date',
                'severity', 'error'
            );
            v_is_valid := false;
        END IF;

        -- Loop through blocks
        FOR v_block IN SELECT * FROM jsonb_array_elements(v_session->'blocks')
        LOOP
            -- Validation 3: Check block has type
            IF NOT (v_block ? 'block_type') THEN
                v_warnings := v_warnings || jsonb_build_object(
                    'field', 'block_type',
                    'issue', 'Missing block type',
                    'severity', 'warning'
                );
                v_confidence := v_confidence - 0.1;
            ELSIF (v_block->>'block_type') = 'unknown' THEN
                v_warnings := v_warnings || jsonb_build_object(
                    'field', 'block_type',
                    'issue', 'Block type is unknown - needs classification',
                    'severity', 'warning'
                );
                v_confidence := v_confidence - 0.05;
            END IF;

            -- Validation 4: Check prescription exists
            IF NOT (v_block ? 'prescription') THEN
                v_errors := v_errors || jsonb_build_object(
                    'field', 'prescription',
                    'issue', 'Missing prescription data',
                    'severity', 'error'
                );
                v_is_valid := false;
            ELSE
                -- Loop through prescription steps
                FOR v_step IN SELECT * FROM jsonb_array_elements(v_block->'prescription'->'steps')
                LOOP
                    -- Validation 5: Check exercise name exists
                    IF NOT (v_step ? 'exercise_name') OR (v_step->>'exercise_name') = '' THEN
                        v_errors := v_errors || jsonb_build_object(
                            'field', 'prescription.steps.exercise_name',
                            'issue', 'Missing or empty exercise name',
                            'severity', 'error'
                        );
                        v_is_valid := false;
                    END IF;

                    -- Validation 6: Check load is reasonable
                    IF (v_step->'target_load'->>'value')::NUMERIC > 500 THEN
                        v_warnings := v_warnings || jsonb_build_object(
                            'field', 'prescription.steps.target_load',
                            'issue', 'Load exceeds 500kg - verify if correct',
                            'severity', 'warning',
                            'value', v_step->'target_load'->>'value'
                        );
                        v_confidence := v_confidence - 0.05;
                    END IF;

                    -- Validation 7: Check reps is reasonable
                    IF (v_step->>'target_reps')::INTEGER > 100 THEN
                        v_warnings := v_warnings || jsonb_build_object(
                            'field', 'prescription.steps.target_reps',
                            'issue', 'Reps exceed 100 - verify if correct',
                            'severity', 'warning',
                            'value', v_step->>'target_reps'
                        );
                    END IF;
                END LOOP;
            END IF;

            -- Validation 8: If performed exists, validate it
            IF (v_block ? 'performed') AND (v_block->'performed') IS NOT NULL THEN
                FOR v_step IN SELECT * FROM jsonb_array_elements(v_block->'performed'->'steps')
                LOOP
                    FOR v_set IN SELECT * FROM jsonb_array_elements(v_step->'sets')
                    LOOP
                        -- Validation 9: Check set_index exists
                        IF NOT (v_set ? 'set_index') THEN
                            v_errors := v_errors || jsonb_build_object(
                                'field', 'performed.steps.sets.set_index',
                                'issue', 'Missing set_index in performed data',
                                'severity', 'error'
                            );
                            v_is_valid := false;
                        END IF;

                        -- Validation 10: Check RPE is 0-10
                        IF (v_set ? 'rpe') AND 
                           ((v_set->>'rpe')::NUMERIC < 0 OR (v_set->>'rpe')::NUMERIC > 10) THEN
                            v_errors := v_errors || jsonb_build_object(
                                'field', 'performed.steps.sets.rpe',
                                'issue', 'RPE must be between 0-10',
                                'severity', 'error',
                                'value', v_set->>'rpe'
                            );
                            v_is_valid := false;
                        END IF;

                        -- Validation 11: Check RIR is reasonable
                        IF (v_set ? 'rir') AND (v_set->>'rir')::NUMERIC > 10 THEN
                            v_warnings := v_warnings || jsonb_build_object(
                                'field', 'performed.steps.sets.rir',
                                'issue', 'RIR typically should not exceed 10',
                                'severity', 'warning',
                                'value', v_set->>'rir'
                            );
                        END IF;

                        -- Validation 12: Check load is reasonable
                        IF (v_set ? 'load_kg') AND (v_set->>'load_kg')::NUMERIC > 500 THEN
                            v_warnings := v_warnings || jsonb_build_object(
                                'field', 'performed.steps.sets.load_kg',
                                'issue', 'Load exceeds 500kg - verify if correct',
                                'severity', 'warning',
                                'value', v_set->>'load_kg'
                            );
                        END IF;
                    END LOOP;
                END LOOP;
            END IF;
        END LOOP;
    END LOOP;

    -- Ensure confidence doesn't go below 0
    v_confidence := GREATEST(v_confidence, 0.0);

    -- Build final report
    RETURN jsonb_build_object(
        'is_valid', v_is_valid,
        'errors', v_errors,
        'warnings', v_warnings,
        'confidence_score', ROUND(v_confidence, 3),
        'total_errors', jsonb_array_length(v_errors),
        'total_warnings', jsonb_array_length(v_warnings),
        'validated_at', NOW()
    );
END;
$$;


ALTER FUNCTION "zamm"."validate_workout_draft"("p_draft_id" "uuid", "p_parsed_json" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "zamm"."validate_workout_draft"("p_draft_id" "uuid", "p_parsed_json" "jsonb") IS 'Validates parsed workout JSON and returns comprehensive error/warning report';


SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "zamm"."lib_athletes" (
    "athlete_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "full_name" "text" NOT NULL,
    "email" "text",
    "phone" "text",
    "date_of_birth" "date",
    "gender" "text",
    "is_active" boolean DEFAULT true,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "primary_coach_id" "uuid",
    CONSTRAINT "lib_athletes_gender_check" CHECK (("gender" = ANY (ARRAY['M'::"text", 'F'::"text", 'O'::"text", 'N'::"text"])))
);


ALTER TABLE "zamm"."lib_athletes" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_athletes" IS 'Library: Master catalog of athletes in the ZAMM system';



COMMENT ON COLUMN "zamm"."lib_athletes"."athlete_id" IS 'Primary key: UUID for global uniqueness';



COMMENT ON COLUMN "zamm"."lib_athletes"."gender" IS 'M=Male, F=Female, O=Other, N=Not specified';



CREATE TABLE IF NOT EXISTS "zamm"."workout_blocks" (
    "block_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "letter" "text",
    "block_code" "text" NOT NULL,
    "block_type" "text" NOT NULL,
    "name" "text" NOT NULL,
    "structure_model" "text" NOT NULL,
    "presentation_structure" "text" NOT NULL,
    "result_entry_model" "text" NOT NULL,
    "prescription" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "raw_block_text" "text" DEFAULT ''::"text" NOT NULL,
    "confidence_score" numeric(4,3) DEFAULT 1.000 NOT NULL,
    "block_notes" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "performed" "jsonb" DEFAULT '{}'::"jsonb",
    "ui_hint" "text",
    "benchmark_key" "text",
    "is_benchmark" boolean DEFAULT false,
    "coach_prescription_notes" "text",
    "coach_feedback" "text",
    "coach_feedback_at" timestamp with time zone,
    "coach_feedback_by" "uuid"
);


ALTER TABLE "zamm"."workout_blocks" OWNER TO "postgres";


COMMENT ON COLUMN "zamm"."workout_blocks"."benchmark_key" IS 'Benchmark identifier - should exist in lib_benchmarks and have corresponding entry in lib_benchmark_blocks';



CREATE TABLE IF NOT EXISTS "zamm"."workout_main" (
    "workout_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "import_id" "uuid",
    "draft_id" "uuid",
    "ruleset_id" "uuid",
    "athlete_id" "uuid",
    "workout_date" "date",
    "session_title" "text",
    "session_type" "text" DEFAULT 'training'::"text" NOT NULL,
    "status" "text" DEFAULT 'planned'::"text" NOT NULL,
    "estimated_duration_min" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "approved_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "approved_by" "uuid",
    "coach_id" "uuid",
    "program_name" "text",
    "program_week" integer,
    "coach_prescription_notes" "text",
    "coach_feedback" "text",
    "coach_feedback_at" timestamp with time zone,
    "created_by" "uuid",
    "original_date" timestamp with time zone,
    "data_source" "text" DEFAULT 'live'::"text",
    CONSTRAINT "chk_status" CHECK (("status" = ANY (ARRAY['draft'::"text", 'scheduled'::"text", 'in_progress'::"text", 'completed'::"text", 'cancelled'::"text", 'archived'::"text"]))),
    CONSTRAINT "workout_main_data_source_check" CHECK (("data_source" = ANY (ARRAY['live'::"text", 'import'::"text", 'manual'::"text", 'csv'::"text", 'excel'::"text", 'bulk_import'::"text", 'api'::"text"])))
);


ALTER TABLE "zamm"."workout_main" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."workout_main" IS 'Workout Events: Root table for workout instances. Parent of workout_sessions.';



COMMENT ON COLUMN "zamm"."workout_main"."created_by" IS 'מי יצר את האימון (מאמן/מערכת/משתמש)';



COMMENT ON COLUMN "zamm"."workout_main"."original_date" IS 'Original workout date (for historical imports). NULL for live entries where created_at is sufficient.';



COMMENT ON COLUMN "zamm"."workout_main"."data_source" IS 'Source of the workout data: live (real-time), import (SMS/WhatsApp), manual (coach entry), csv/excel/bulk_import (historical), api (external system)';



COMMENT ON CONSTRAINT "chk_status" ON "zamm"."workout_main" IS 'Ensures workout status is one of the allowed values';



CREATE TABLE IF NOT EXISTS "zamm"."workout_sessions" (
    "session_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "workout_id" "uuid" NOT NULL,
    "date" "date",
    "week_number" integer,
    "day_of_week" integer,
    "day_name" "text",
    "phase_name" "text",
    "session_title" "text",
    "session_type" "text" DEFAULT 'training'::"text" NOT NULL,
    "status" "text" DEFAULT 'planned'::"text" NOT NULL,
    "estimated_duration_min" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "zamm"."workout_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."cfg_parser_rules" (
    "ruleset_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "version" "text" NOT NULL,
    "is_active" boolean DEFAULT false NOT NULL,
    "units_catalog" "jsonb" NOT NULL,
    "units_metadata" "jsonb" NOT NULL,
    "parser_mapping_rules" "jsonb" NOT NULL,
    "value_unit_schema" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "zamm"."cfg_parser_rules" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."cfg_parser_rules" IS 'Configuration: Parser rules and patterns';



CREATE TABLE IF NOT EXISTS "zamm"."dim_athletes_backup" (
    "athlete_sk" integer,
    "athlete_natural_id" "uuid",
    "full_name" character varying(100),
    "email" character varying(255),
    "phone" character varying(50),
    "gender" character varying(20),
    "date_of_birth" "date",
    "height_cm" integer,
    "current_weight_kg" numeric(5,2),
    "valid_from" timestamp with time zone,
    "valid_to" timestamp with time zone,
    "is_current" boolean,
    "data_source" character varying(50),
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);


ALTER TABLE "zamm"."dim_athletes_backup" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."evt_athlete_personal_records" (
    "pr_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "athlete_natural_id" "uuid" NOT NULL,
    "exercise_key" "text" NOT NULL,
    "pr_type" "text" NOT NULL,
    "value" numeric(10,2) NOT NULL,
    "unit" "text" NOT NULL,
    "workout_id" "uuid",
    "block_id" "uuid",
    "item_id" "uuid",
    "set_result_id" "uuid",
    "achieved_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "previous_pr" numeric(10,2),
    "improvement_percent" numeric(5,2),
    "athlete_bodyweight_kg" numeric(5,2),
    "is_verified" boolean DEFAULT false,
    "is_current_pr" boolean DEFAULT true,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "chk_pr_type" CHECK (("pr_type" = ANY (ARRAY['1rm'::"text", '2rm'::"text", '3rm'::"text", '5rm'::"text", '10rm'::"text", '20rm'::"text", 'max_reps'::"text", 'max_distance'::"text", 'max_height'::"text", 'fastest_time'::"text", 'max_rounds'::"text", 'max_calories'::"text", 'longest_hold'::"text", 'heaviest_complex'::"text"]))),
    CONSTRAINT "chk_unit" CHECK (("unit" = ANY (ARRAY['kg'::"text", 'lbs'::"text", 'reps'::"text", 'meters'::"text", 'feet'::"text", 'inches'::"text", 'seconds'::"text", 'minutes'::"text", 'rounds'::"text", 'calories'::"text"]))),
    CONSTRAINT "chk_value_positive" CHECK (("value" > (0)::numeric))
);


ALTER TABLE "zamm"."evt_athlete_personal_records" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."evt_athlete_personal_records" IS 'Event: Personal record achievements (PRs) for athletes. Time-stamped milestone events.';



COMMENT ON COLUMN "zamm"."evt_athlete_personal_records"."pr_type" IS 'Type of PR: 1rm, 3rm, 5rm, max_reps, fastest_time, max_distance, etc.';



COMMENT ON COLUMN "zamm"."evt_athlete_personal_records"."athlete_bodyweight_kg" IS 'Athlete bodyweight at the time this PR was achieved (for context)';



COMMENT ON COLUMN "zamm"."evt_athlete_personal_records"."is_current_pr" IS 'True if this is the current PR. When beaten, this becomes false and new record gets true';



CREATE TABLE IF NOT EXISTS "zamm"."lib_benchmark_blocks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "benchmark_key" "text" NOT NULL,
    "block_code" "text" NOT NULL,
    "prescription_template" "jsonb" DEFAULT '{}'::"jsonb",
    "rx_standards" "jsonb" DEFAULT '{}'::"jsonb",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "zamm"."lib_benchmark_blocks" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_benchmark_blocks" IS 'Junction table connecting benchmarks to block types';



COMMENT ON COLUMN "zamm"."lib_benchmark_blocks"."prescription_template" IS 'Default prescription template for this benchmark+blocktype combo';



COMMENT ON COLUMN "zamm"."lib_benchmark_blocks"."rx_standards" IS 'RX standards (e.g., {"male": "225lb", "female": "155lb"})';



CREATE TABLE IF NOT EXISTS "zamm"."lib_benchmark_exercises" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "benchmark_key" "text" NOT NULL,
    "exercise_key" "text" NOT NULL,
    "test_type" "text",
    "rx_standards" "jsonb" DEFAULT '{}'::"jsonb",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "lib_benchmark_exercises_test_type_check" CHECK (("test_type" = ANY (ARRAY['1rm'::"text", '3rm'::"text", '5rm'::"text", '10rm'::"text", 'max_reps'::"text", 'max_distance'::"text", 'max_time'::"text", 'for_time'::"text"])))
);


ALTER TABLE "zamm"."lib_benchmark_exercises" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_benchmark_exercises" IS 'Junction table connecting benchmarks to exercises';



COMMENT ON COLUMN "zamm"."lib_benchmark_exercises"."test_type" IS 'Type of test for this exercise (1rm, max_reps, for_time, etc.)';



COMMENT ON COLUMN "zamm"."lib_benchmark_exercises"."rx_standards" IS 'RX standards for this specific exercise in the benchmark';



CREATE TABLE IF NOT EXISTS "zamm"."lib_benchmarks" (
    "benchmark_key" "text" NOT NULL,
    "display_name" "text" NOT NULL,
    "category" "text" NOT NULL,
    "description" "text",
    "typical_result_type" "text",
    "difficulty_level" integer,
    "tags" "text"[],
    "is_active" boolean DEFAULT true
);


ALTER TABLE "zamm"."lib_benchmarks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."lib_block_aliases" (
    "alias" "text" NOT NULL,
    "block_code" "text" NOT NULL,
    "locale" "text" DEFAULT 'en'::"text",
    "is_common" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "zamm"."lib_block_aliases" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_block_aliases" IS 'Library: Multilingual aliases for block codes (warmup→WU, כוח→STR, etc)';



CREATE TABLE IF NOT EXISTS "zamm"."lib_block_types" (
    "block_code" "text" NOT NULL,
    "block_type" "text" NOT NULL,
    "category" "text" NOT NULL,
    "result_model" "text" NOT NULL,
    "ui_hint" "text" NOT NULL,
    "display_name" "text" NOT NULL,
    "description" "text",
    "sort_order" integer,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "zamm"."lib_block_types" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_block_types" IS 'Library: Master catalog of all block types in the ZAMM system';



CREATE TABLE IF NOT EXISTS "zamm"."lib_coaches" (
    "coach_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "full_name" "text" NOT NULL,
    "email" "text",
    "phone" "text",
    "specializations" "text"[],
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "zamm"."lib_coaches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."lib_equipment_aliases" (
    "alias" "text" NOT NULL,
    "equipment_key" "text" NOT NULL,
    "locale" "text" DEFAULT 'en'::"text" NOT NULL
);


ALTER TABLE "zamm"."lib_equipment_aliases" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_equipment_aliases" IS 'Library: Multilingual aliases for equipment (barbell→bar, משקולת→dumbbell, etc)';



CREATE TABLE IF NOT EXISTS "zamm"."lib_equipment_catalog" (
    "equipment_key" "text" NOT NULL,
    "display_name" "text" NOT NULL,
    "category" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL
);


ALTER TABLE "zamm"."lib_equipment_catalog" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_equipment_catalog" IS 'Library: Master catalog of equipment types in the ZAMM system';



CREATE TABLE IF NOT EXISTS "zamm"."lib_equipment_config_templates" (
    "equipment_key" "text" NOT NULL,
    "template" "jsonb" NOT NULL
);


ALTER TABLE "zamm"."lib_equipment_config_templates" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_equipment_config_templates" IS 'Library: Configuration templates for equipment setup';



CREATE TABLE IF NOT EXISTS "zamm"."lib_exercise_aliases" (
    "alias" "text" NOT NULL,
    "exercise_key" "text" NOT NULL,
    "locale" "text" DEFAULT 'en'::"text" NOT NULL,
    "is_abbreviation" boolean DEFAULT false,
    "is_common" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "zamm"."lib_exercise_aliases" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_exercise_aliases" IS 'Library: Multilingual aliases for exercises';



CREATE TABLE IF NOT EXISTS "zamm"."lib_exercise_catalog" (
    "exercise_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "exercise_key" "text" NOT NULL,
    "display_name" "text" NOT NULL,
    "category" "text" NOT NULL,
    "movement_pattern" "text",
    "primary_muscles" "text"[] DEFAULT '{}'::"text"[],
    "secondary_muscles" "text"[] DEFAULT '{}'::"text"[],
    "difficulty_level" integer,
    "equipment_required" "text"[] DEFAULT '{}'::"text"[],
    "is_compound" boolean DEFAULT true,
    "is_unilateral" boolean DEFAULT false,
    "is_active" boolean DEFAULT true,
    "description" "text",
    "video_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "exercise_catalog_difficulty_level_check" CHECK ((("difficulty_level" >= 1) AND ("difficulty_level" <= 5))),
    CONSTRAINT "valid_category" CHECK (("category" = ANY (ARRAY['strength'::"text", 'olympic'::"text", 'gymnastics'::"text", 'cardio'::"text", 'mobility'::"text", 'plyometric'::"text", 'accessory'::"text"])))
);


ALTER TABLE "zamm"."lib_exercise_catalog" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_exercise_catalog" IS 'Library: Master catalog of all exercises';



COMMENT ON COLUMN "zamm"."lib_exercise_catalog"."exercise_key" IS 'Normalized key for programmatic use (e.g., "back_squat")';



COMMENT ON COLUMN "zamm"."lib_exercise_catalog"."movement_pattern" IS 'Primary movement pattern for exercise classification';



CREATE TABLE IF NOT EXISTS "zamm"."lib_movement_patterns" (
    "pattern_key" "text" NOT NULL,
    "display_name" "text" NOT NULL,
    "category" "text" NOT NULL,
    "primary_joints" "text"[] DEFAULT '{}'::"text"[],
    "biomechanics_description" "text",
    "teaching_cues" "text"[] DEFAULT '{}'::"text"[],
    "common_faults" "text"[] DEFAULT '{}'::"text"[],
    "progression_levels" "jsonb" DEFAULT '{}'::"jsonb",
    "typical_equipment" "text"[] DEFAULT '{}'::"text"[],
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "valid_pattern_category" CHECK (("category" = ANY (ARRAY['lower_body'::"text", 'upper_body'::"text", 'full_body'::"text", 'core'::"text", 'carry'::"text", 'rotation'::"text"])))
);


ALTER TABLE "zamm"."lib_movement_patterns" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_movement_patterns" IS 'Master catalog of movement patterns with biomechanics and teaching notes';



COMMENT ON COLUMN "zamm"."lib_movement_patterns"."pattern_key" IS 'Normalized pattern identifier (e.g., "squat", "hinge", "push")';



COMMENT ON COLUMN "zamm"."lib_movement_patterns"."primary_joints" IS 'Primary joints involved in the movement pattern';



COMMENT ON COLUMN "zamm"."lib_movement_patterns"."teaching_cues" IS 'Key teaching points and coaching cues for the pattern';



COMMENT ON COLUMN "zamm"."lib_movement_patterns"."progression_levels" IS 'JSON structure with progression stages from beginner to advanced';



CREATE TABLE IF NOT EXISTS "zamm"."lib_muscle_groups" (
    "muscle_key" "text" NOT NULL,
    "display_name" "text" NOT NULL,
    "muscle_group" "text" NOT NULL,
    "body_region" "text" NOT NULL,
    "function_description" "text",
    "antagonist_muscle" "text",
    "typical_exercises" "text"[] DEFAULT '{}'::"text"[],
    "recovery_time_hours" integer,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "valid_body_region" CHECK (("body_region" = ANY (ARRAY['lower_body'::"text", 'upper_body'::"text", 'core'::"text"]))),
    CONSTRAINT "valid_muscle_group" CHECK (("muscle_group" = ANY (ARRAY['legs'::"text", 'back'::"text", 'chest'::"text", 'shoulders'::"text", 'arms'::"text", 'core'::"text", 'glutes'::"text", 'calves'::"text"])))
);


ALTER TABLE "zamm"."lib_muscle_groups" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_muscle_groups" IS 'Reference catalog for common muscle groups used in CrossFit/strength training.
NOT enforced on lib_exercise_catalog - exercises can specify any muscle name.
Used for UI dropdowns, filtering, and suggestions, but not validation.

Common muscle groups in this table:
- Legs: quadriceps, hamstrings, glutes, calves, quads
- Upper body: chest, lats, triceps, biceps, shoulders, traps, forearms
- Back: (currently no distinction between upper/lower/mid)
- Core: (not currently in this table - exercises can still use "core", "abs", etc.)

For rehabilitation/mobility exercises, use anatomically accurate names even if not in this table.';



COMMENT ON COLUMN "zamm"."lib_muscle_groups"."muscle_key" IS 'Normalized muscle identifier (e.g., "quadriceps", "glutes")';



COMMENT ON COLUMN "zamm"."lib_muscle_groups"."antagonist_muscle" IS 'Key of the opposing muscle group for balanced programming';



COMMENT ON COLUMN "zamm"."lib_muscle_groups"."recovery_time_hours" IS 'Typical recovery time needed between intense training sessions';



CREATE TABLE IF NOT EXISTS "zamm"."lib_parser_rulesets" (
    "ruleset_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "version" "text" DEFAULT '1.0.0'::"text" NOT NULL,
    "is_active" boolean DEFAULT false,
    "units_catalog" "jsonb",
    "units_metadata" "jsonb",
    "parser_mapping_rules" "jsonb",
    "value_unit_schema" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "zamm"."lib_parser_rulesets" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_parser_rulesets" IS 'Parser configuration with units catalog and mapping rules';



CREATE TABLE IF NOT EXISTS "zamm"."lib_prescription_schemas" (
    "schema_id" "text" NOT NULL,
    "schema_name" "text" NOT NULL,
    "description" "text",
    "category" "text" NOT NULL,
    "json_schema" "jsonb" NOT NULL,
    "examples" "jsonb",
    "applicable_block_types" "text"[],
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "zamm"."lib_prescription_schemas" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_prescription_schemas" IS 'Library: Defines the structure and rules for prescription_data JSONB in workout_items';



CREATE TABLE IF NOT EXISTS "zamm"."lib_result_models" (
    "result_model_id" "text" NOT NULL,
    "display_name" "text" NOT NULL,
    "description" "text",
    "category" "text" NOT NULL,
    "json_schema" "jsonb" NOT NULL,
    "applicable_block_codes" "text"[],
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "zamm"."lib_result_models" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."lib_result_models" IS 'Library: Catalog of all result models with their schemas and applicable block types';



CREATE TABLE IF NOT EXISTS "zamm"."log_validation_reports" (
    "report_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "draft_id" "uuid" NOT NULL,
    "is_valid" boolean NOT NULL,
    "errors" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "warnings" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "validator_version" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "zamm"."log_validation_reports" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."log_validation_reports" IS 'Log: Historical validation reports and errors';



CREATE TABLE IF NOT EXISTS "zamm"."res_blocks" (
    "block_result_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "block_id" "uuid" NOT NULL,
    "did_complete" boolean,
    "total_time_sec" integer,
    "score_time_sec" integer,
    "score_text" "text",
    "distance_m" integer,
    "avg_hr_bpm" integer,
    "calories" integer,
    "athlete_notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "result_model_id" "text",
    "result_model_version" integer DEFAULT 1,
    "canonical" "jsonb" DEFAULT '{}'::"jsonb",
    "computed" "jsonb" DEFAULT '{}'::"jsonb",
    "raw_input" "jsonb" DEFAULT '{}'::"jsonb",
    "ingest_key" "text",
    "block_code" "text",
    "status" "zamm"."block_result_status" DEFAULT 'completed'::"zamm"."block_result_status"
);


ALTER TABLE "zamm"."res_blocks" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."res_blocks" IS 'Results at the block level (time, score, calories)';



COMMENT ON COLUMN "zamm"."res_blocks"."result_model_id" IS 'Type of result model: completion_check, time_only, rounds_reps, interval_splits, steady_state_summary, tracked_sets, olympic_attempts, skill_quality';



COMMENT ON COLUMN "zamm"."res_blocks"."canonical" IS 'Structured result data according to result_model_id schema';



COMMENT ON COLUMN "zamm"."res_blocks"."computed" IS 'Computed metrics (tonnage, best_make, average_pace, etc)';



COMMENT ON COLUMN "zamm"."res_blocks"."raw_input" IS 'Original unprocessed input from user';



COMMENT ON COLUMN "zamm"."res_blocks"."ingest_key" IS 'Unique key to prevent duplicate inserts';



CREATE TABLE IF NOT EXISTS "zamm"."res_intervals" (
    "interval_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "block_id" "uuid" NOT NULL,
    "segment_index" integer NOT NULL,
    "work_time_sec" integer,
    "rest_time_sec" integer,
    "split_pace" "text",
    "distance_meters" numeric(10,2),
    "calories" integer,
    "heart_rate_avg" integer,
    "heart_rate_max" integer,
    "power_watts" integer,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "res_intervals_segment_index_check" CHECK (("segment_index" > 0))
);


ALTER TABLE "zamm"."res_intervals" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."res_intervals" IS 'Results for interval segments (work time, rest time, splits)';



CREATE TABLE IF NOT EXISTS "zamm"."res_item_sets" (
    "set_result_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "block_id" "uuid" NOT NULL,
    "item_id" "uuid" NOT NULL,
    "set_index" integer NOT NULL,
    "reps" integer,
    "load_kg" numeric(10,2),
    "rpe" numeric(4,2),
    "rir" numeric(4,2),
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "reps_right" integer,
    "reps_left" integer,
    "is_bilateral" boolean DEFAULT false,
    "set_type" "text" DEFAULT 'normal'::"text",
    "related_set_id" "uuid",
    "side" "text",
    "duration_sec" integer,
    "distance_m" numeric(10,2),
    CONSTRAINT "chk_load_kg" CHECK ((("load_kg" >= (0)::numeric) AND ("load_kg" <= (99999)::numeric))),
    CONSTRAINT "chk_reps" CHECK ((("reps" >= 0) AND ("reps" <= 1000))),
    CONSTRAINT "chk_rir" CHECK ((("rir" IS NULL) OR (("rir" >= (0)::numeric) AND ("rir" <= (10)::numeric)))),
    CONSTRAINT "chk_rpe" CHECK ((("rpe" IS NULL) OR (("rpe" >= (1)::numeric) AND ("rpe" <= (10)::numeric)))),
    CONSTRAINT "chk_valid_set_type" CHECK (("set_type" = ANY (ARRAY['normal'::"text", 'warmup'::"text", 'working'::"text", 'backoff'::"text", 'drop'::"text", 'cluster'::"text", 'rest_pause'::"text", 'amrap'::"text", 'myoreps'::"text", 'top_set'::"text", 'warmup_ramping'::"text"]))),
    CONSTRAINT "chk_valid_side" CHECK ((("side" IS NULL) OR ("side" = ANY (ARRAY['left'::"text", 'right'::"text", 'both'::"text"])))),
    CONSTRAINT "res_item_sets_bilateral_check" CHECK (((("is_bilateral" = true) AND ("reps_right" IS NOT NULL) AND ("reps_left" IS NOT NULL) AND ("reps" IS NULL)) OR ("is_bilateral" = false)))
);


ALTER TABLE "zamm"."res_item_sets" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."res_item_sets" IS 'Results at the set level (reps, load, RPE, RIR)';



COMMENT ON COLUMN "zamm"."res_item_sets"."reps_right" IS 'Reps performed on right side (for bilateral movements like 10/10)';



COMMENT ON COLUMN "zamm"."res_item_sets"."reps_left" IS 'Reps performed on left side (for bilateral movements like 10/10)';



COMMENT ON COLUMN "zamm"."res_item_sets"."is_bilateral" IS 'TRUE if this is a bilateral movement with separate tracking for each side';



COMMENT ON COLUMN "zamm"."res_item_sets"."set_type" IS 'Type of set: normal, warmup, working, backoff, drop, cluster, rest_pause, amrap, myoreps, top_set';



COMMENT ON COLUMN "zamm"."res_item_sets"."related_set_id" IS 'Links to another set for supersets, tri-sets, or circuits. Points to the paired set.';



COMMENT ON COLUMN "zamm"."res_item_sets"."side" IS 'For bilateral exercises: "left", "right", or NULL for both sides';



COMMENT ON COLUMN "zamm"."res_item_sets"."duration_sec" IS 'Duration in seconds for timed holds (planks, wall sits, handstands, etc.)';



COMMENT ON COLUMN "zamm"."res_item_sets"."distance_m" IS 'Distance in meters for exercises like sled push, farmer walks, etc.';



COMMENT ON CONSTRAINT "chk_load_kg" ON "zamm"."res_item_sets" IS 'Ensures load is non-negative and below 99,999 kg';



COMMENT ON CONSTRAINT "chk_reps" ON "zamm"."res_item_sets" IS 'Ensures reps are between 0-1000 (realistic range)';



COMMENT ON CONSTRAINT "chk_rir" ON "zamm"."res_item_sets" IS 'Ensures RIR (Reps in Reserve) is between 0-10';



COMMENT ON CONSTRAINT "chk_rpe" ON "zamm"."res_item_sets" IS 'Ensures RPE (Rate of Perceived Exertion) is between 1-10';



CREATE TABLE IF NOT EXISTS "zamm"."stg_draft_edits" (
    "edit_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "draft_id" "uuid" NOT NULL,
    "editor_id" "uuid",
    "patch" "jsonb" NOT NULL,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "zamm"."stg_draft_edits" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."stg_draft_edits" IS 'Staging: Manual edits to draft workouts';



CREATE TABLE IF NOT EXISTS "zamm"."stg_imports" (
    "import_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "source" "text" NOT NULL,
    "source_ref" "text",
    "athlete_id" "uuid",
    "raw_text" "text" NOT NULL,
    "raw_payload" "jsonb",
    "received_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "checksum_sha256" "text",
    "tags" "text"[] DEFAULT '{}'::"text"[] NOT NULL
);


ALTER TABLE "zamm"."stg_imports" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."stg_imports" IS 'Staging: Raw imported workout data awaiting processing';



CREATE TABLE IF NOT EXISTS "zamm"."stg_parse_drafts" (
    "draft_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "import_id" "uuid" NOT NULL,
    "ruleset_id" "uuid" NOT NULL,
    "parser_version" "text" NOT NULL,
    "stage" "text" NOT NULL,
    "confidence_score" numeric(4,3),
    "parsed_draft" "jsonb" NOT NULL,
    "normalized_draft" "jsonb",
    "flags" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "approved_at" timestamp with time zone,
    "approved_by" "uuid",
    "rejected_at" timestamp with time zone,
    "rejected_by" "uuid",
    "rejection_reason" "text",
    "stage_snapshots" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "zamm"."stg_parse_drafts" OWNER TO "postgres";


COMMENT ON TABLE "zamm"."stg_parse_drafts" IS 'Staging: Parsed workout drafts pending validation';



CREATE OR REPLACE VIEW "zamm"."v_active_functions" AS
 SELECT "p"."proname" AS "function_name",
    "pg_get_function_identity_arguments"("p"."oid") AS "parameters",
    "obj_description"("p"."oid", 'pg_proc'::"name") AS "description",
        CASE
            WHEN ("p"."provolatile" = 'i'::"char") THEN 'IMMUTABLE'::"text"
            WHEN ("p"."provolatile" = 's'::"char") THEN 'STABLE'::"text"
            WHEN ("p"."provolatile" = 'v'::"char") THEN 'VOLATILE'::"text"
            ELSE NULL::"text"
        END AS "volatility",
    "l"."lanname" AS "language"
   FROM (("pg_proc" "p"
     JOIN "pg_namespace" "n" ON (("p"."pronamespace" = "n"."oid")))
     JOIN "pg_language" "l" ON (("p"."prolang" = "l"."oid")))
  WHERE (("n"."nspname" = 'zamm'::"name") AND ("p"."proname" !~~ 'pg_%'::"text"))
  ORDER BY "p"."proname";


ALTER VIEW "zamm"."v_active_functions" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_active_functions" IS 'View of all active functions in zamm schema after cleanup';



CREATE TABLE IF NOT EXISTS "zamm"."workout_items" (
    "item_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "block_id" "uuid" NOT NULL,
    "exercise_name" "text" NOT NULL,
    "category" "text",
    "pattern" "text",
    "equipment_primary" "text",
    "equipment_config" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "dose" "jsonb",
    "load" "jsonb",
    "intensity" "jsonb",
    "device" "jsonb",
    "tempo" "text",
    "notes" "text",
    "original_text" "text",
    "item_order" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "equipment_key" "text",
    "prescription_data" "jsonb" DEFAULT '{}'::"jsonb",
    "performed_data" "jsonb" DEFAULT '{}'::"jsonb",
    "exercise_key" "text",
    "benchmark_key" "text",
    "is_benchmark" boolean DEFAULT false,
    "coach_prescription_notes" "text",
    "coach_feedback" "text",
    "coach_feedback_at" timestamp with time zone,
    "coach_feedback_by" "uuid",
    "bilateral" boolean DEFAULT false,
    "tempo_details" "jsonb",
    "movement_pattern" "text",
    CONSTRAINT "chk_valid_movement_pattern" CHECK ((("movement_pattern" IS NULL) OR ("movement_pattern" = ANY (ARRAY['squat'::"text", 'hinge'::"text", 'push'::"text", 'pull'::"text", 'carry'::"text", 'lunge'::"text", 'rotate'::"text", 'plank'::"text", 'olympic'::"text", 'mixed'::"text"]))))
);


ALTER TABLE "zamm"."workout_items" OWNER TO "postgres";


COMMENT ON COLUMN "zamm"."workout_items"."exercise_key" IS 'Normalized reference to exercise catalog (added in v2)';



COMMENT ON COLUMN "zamm"."workout_items"."benchmark_key" IS 'Benchmark identifier - should exist in lib_benchmarks and have corresponding entry in lib_benchmark_exercises';



COMMENT ON COLUMN "zamm"."workout_items"."bilateral" IS 'TRUE if exercise is performed unilaterally (per side), e.g., Single Arm Bench Press';



COMMENT ON COLUMN "zamm"."workout_items"."tempo_details" IS 'Detailed tempo breakdown: {"eccentric": 3, "bottom_hold": 2, "concentric": 1, "top_hold": 0}';



COMMENT ON COLUMN "zamm"."workout_items"."movement_pattern" IS 'Primary movement pattern: squat, hinge, push, pull, carry, lunge, rotate, plank';



CREATE OR REPLACE VIEW "zamm"."v_analytics_flat_history" AS
 SELECT "w"."workout_date",
    "w"."workout_id",
    "s"."session_title",
    "b"."block_code",
    "b"."name" AS "block_name",
    "i"."item_order",
    COALESCE("i"."exercise_name", ("i"."prescription_data" ->> 'exercise_name'::"text"), 'Unknown Exercise'::"text") AS "exercise",
    "i"."exercise_key",
    "zamm"."format_bilateral_reps"("r"."reps", "r"."reps_right", "r"."reps_left", "r"."is_bilateral") AS "reps_display",
    "r"."reps",
    "r"."reps_right",
    "r"."reps_left",
    "r"."is_bilateral",
    "r"."load_kg",
    "r"."rpe",
    "r"."rir",
    "r"."notes"
   FROM (((("zamm"."workout_main" "w"
     JOIN "zamm"."workout_sessions" "s" ON (("w"."workout_id" = "s"."workout_id")))
     JOIN "zamm"."workout_blocks" "b" ON (("s"."session_id" = "b"."session_id")))
     JOIN "zamm"."workout_items" "i" ON (("b"."block_id" = "i"."block_id")))
     LEFT JOIN "zamm"."res_item_sets" "r" ON (("i"."item_id" = "r"."item_id")))
  WHERE ("w"."status" = 'completed'::"text")
  ORDER BY "w"."workout_date" DESC, "s"."session_id", "b"."block_id", "i"."item_order";


ALTER VIEW "zamm"."v_analytics_flat_history" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_analytics_flat_history" IS 'Flattened workout history with bilateral movement support';



CREATE OR REPLACE VIEW "zamm"."v_antagonist_pairs" AS
 SELECT "mg1"."muscle_key" AS "muscle_1",
    "mg1"."display_name" AS "muscle_1_name",
    "mg2"."muscle_key" AS "muscle_2",
    "mg2"."display_name" AS "muscle_2_name",
    "mg1"."body_region",
    "mg1"."muscle_group"
   FROM ("zamm"."lib_muscle_groups" "mg1"
     JOIN "zamm"."lib_muscle_groups" "mg2" ON (("mg1"."antagonist_muscle" = "mg2"."muscle_key")))
  WHERE (("mg1"."is_active" = true) AND ("mg2"."is_active" = true));


ALTER VIEW "zamm"."v_antagonist_pairs" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_antagonist_pairs" IS 'Paired antagonist muscles for balanced programming';



CREATE OR REPLACE VIEW "zamm"."v_athlete_bader" AS
 SELECT "athlete_id",
    "full_name",
    "email",
    "date_of_birth",
    "gender",
    "is_active"
   FROM "zamm"."lib_athletes"
  WHERE ("athlete_id" = '550e8400-e29b-41d4-a716-446655440001'::"uuid");


ALTER VIEW "zamm"."v_athlete_bader" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_athlete_bader" IS 'Quick reference for Bader Madhat athlete ID';



CREATE OR REPLACE VIEW "zamm"."v_benchmarks_by_block_type" AS
 SELECT "bt"."block_code",
    "bt"."display_name",
    "bt"."description" AS "block_description",
    "json_agg"("json_build_object"('benchmark_key', "b"."benchmark_key", 'display_name', "b"."display_name", 'category', "b"."category", 'difficulty_level', "b"."difficulty_level", 'prescription_template', "bb"."prescription_template", 'rx_standards', "bb"."rx_standards") ORDER BY "b"."display_name") AS "benchmarks"
   FROM (("zamm"."lib_block_types" "bt"
     JOIN "zamm"."lib_benchmark_blocks" "bb" ON (("bb"."block_code" = "bt"."block_code")))
     JOIN "zamm"."lib_benchmarks" "b" ON (("b"."benchmark_key" = "bb"."benchmark_key")))
  WHERE (("bt"."is_active" = true) AND ("bb"."is_active" = true) AND ("b"."is_active" = true))
  GROUP BY "bt"."block_code", "bt"."display_name", "bt"."description"
  ORDER BY "bt"."display_name";


ALTER VIEW "zamm"."v_benchmarks_by_block_type" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_benchmarks_by_block_type" IS 'Benchmarks organized by block type for easy lookup';



CREATE OR REPLACE VIEW "zamm"."v_benchmarks_full" AS
 SELECT "benchmark_key",
    "display_name",
    "category",
    "description",
    "typical_result_type",
    "difficulty_level",
    "tags",
    ( SELECT "json_agg"("json_build_object"('block_code', "bt"."block_code", 'display_name', "bt"."display_name", 'prescription_template', "bb"."prescription_template", 'rx_standards', "bb"."rx_standards")) AS "json_agg"
           FROM ("zamm"."lib_benchmark_blocks" "bb"
             JOIN "zamm"."lib_block_types" "bt" ON (("bt"."block_code" = "bb"."block_code")))
          WHERE (("bb"."benchmark_key" = "b"."benchmark_key") AND ("bb"."is_active" = true))) AS "connected_blocks",
    ( SELECT "json_agg"("json_build_object"('exercise_key', "ex"."exercise_key", 'display_name', "ex"."display_name", 'test_type', "be"."test_type", 'rx_standards', "be"."rx_standards")) AS "json_agg"
           FROM ("zamm"."lib_benchmark_exercises" "be"
             JOIN "zamm"."lib_exercise_catalog" "ex" ON (("ex"."exercise_key" = "be"."exercise_key")))
          WHERE (("be"."benchmark_key" = "b"."benchmark_key") AND ("be"."is_active" = true))) AS "connected_exercises",
    "is_active"
   FROM "zamm"."lib_benchmarks" "b"
  WHERE ("is_active" = true);


ALTER VIEW "zamm"."v_benchmarks_full" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_benchmarks_full" IS 'Complete benchmark view with all connected blocks and exercises';



CREATE OR REPLACE VIEW "zamm"."v_bilateral_summary" AS
 SELECT "w"."workout_date",
    "ws"."session_title",
    "wb"."block_code",
    "wi"."exercise_name",
    "isr"."set_index",
    "isr"."side",
    "isr"."reps",
    "isr"."load_kg",
    "isr"."rpe",
    "isr"."rir"
   FROM (((("zamm"."workout_main" "w"
     JOIN "zamm"."workout_sessions" "ws" ON (("w"."workout_id" = "ws"."workout_id")))
     JOIN "zamm"."workout_blocks" "wb" ON (("ws"."session_id" = "wb"."session_id")))
     JOIN "zamm"."workout_items" "wi" ON (("wb"."block_id" = "wi"."block_id")))
     JOIN "zamm"."res_item_sets" "isr" ON (("wi"."item_id" = "isr"."item_id")))
  WHERE ("wi"."bilateral" = true)
  ORDER BY "w"."workout_date" DESC, "isr"."set_index", "isr"."side";


ALTER VIEW "zamm"."v_bilateral_summary" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_bilateral_summary" IS 'Summary of all bilateral exercise results with side tracking';



CREATE OR REPLACE VIEW "zamm"."v_block_results_enhanced" AS
 SELECT "block_result_id",
    "block_id",
    "block_code",
    "result_model_id",
    "canonical",
    "computed",
    "raw_input",
    "status",
    "ingest_key",
    "created_at"
   FROM "zamm"."res_blocks" "br";


ALTER VIEW "zamm"."v_block_results_enhanced" OWNER TO "postgres";


CREATE OR REPLACE VIEW "zamm"."v_current_prs" AS
 SELECT "pr_id",
    "athlete_natural_id",
    "exercise_key" AS "exercise",
    "pr_type",
    "value",
    "unit",
    "achieved_at",
    "improvement_percent",
    "is_verified",
    "athlete_bodyweight_kg",
    "workout_id",
    "block_id"
   FROM "zamm"."evt_athlete_personal_records" "pr"
  WHERE ("is_current_pr" = true)
  ORDER BY "achieved_at" DESC;


ALTER VIEW "zamm"."v_current_prs" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_current_prs" IS 'Shows only the current PRs for each athlete/exercise/type combination';



CREATE OR REPLACE VIEW "zamm"."v_exercises_enriched" AS
 SELECT "ec"."exercise_key",
    "ec"."display_name",
    "ec"."category",
    "ec"."movement_pattern",
    "mp"."display_name" AS "movement_pattern_name",
    "mp"."category" AS "pattern_category",
    "mp"."teaching_cues",
    "ec"."primary_muscles",
    ( SELECT "array_agg"("mg"."display_name" ORDER BY "mg"."display_name") AS "array_agg"
           FROM ("unnest"("ec"."primary_muscles") "pm"("pm")
             JOIN "zamm"."lib_muscle_groups" "mg" ON (("mg"."muscle_key" = "pm"."pm")))) AS "primary_muscles_display",
    "ec"."secondary_muscles",
    ( SELECT "array_agg"("mg"."display_name" ORDER BY "mg"."display_name") AS "array_agg"
           FROM ("unnest"("ec"."secondary_muscles") "sm"("sm")
             JOIN "zamm"."lib_muscle_groups" "mg" ON (("mg"."muscle_key" = "sm"."sm")))) AS "secondary_muscles_display",
    ( SELECT "max"("mg"."recovery_time_hours") AS "max"
           FROM ("unnest"("ec"."primary_muscles") "pm"("pm")
             JOIN "zamm"."lib_muscle_groups" "mg" ON (("mg"."muscle_key" = "pm"."pm")))) AS "recommended_recovery_hours",
    "ec"."difficulty_level",
    "ec"."equipment_required",
    "ec"."is_compound",
    "ec"."is_unilateral",
    "ec"."is_active",
    "ec"."description",
    "ec"."video_url"
   FROM ("zamm"."lib_exercise_catalog" "ec"
     LEFT JOIN "zamm"."lib_movement_patterns" "mp" ON (("ec"."movement_pattern" = "mp"."pattern_key")));


ALTER VIEW "zamm"."v_exercises_enriched" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_exercises_enriched" IS 'Exercise catalog enriched with movement pattern and muscle group metadata';



CREATE OR REPLACE VIEW "zamm"."v_exercises_with_aliases" AS
 SELECT "ec"."exercise_key",
    "ec"."display_name",
    "ec"."category",
    "ec"."movement_pattern",
    "array_agg"(DISTINCT "ea"."alias") FILTER (WHERE ("ea"."alias" IS NOT NULL)) AS "all_aliases",
    "ec"."primary_muscles",
    "ec"."is_active"
   FROM ("zamm"."lib_exercise_catalog" "ec"
     LEFT JOIN "zamm"."lib_exercise_aliases" "ea" ON (("ec"."exercise_key" = "ea"."exercise_key")))
  GROUP BY "ec"."exercise_key", "ec"."display_name", "ec"."category", "ec"."movement_pattern", "ec"."primary_muscles", "ec"."is_active";


ALTER VIEW "zamm"."v_exercises_with_aliases" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_exercises_with_aliases" IS 'Exercise catalog with all aliases aggregated for easy viewing';



CREATE OR REPLACE VIEW "zamm"."v_movement_patterns_full" AS
 SELECT "mp"."pattern_key",
    "mp"."display_name",
    "mp"."category",
    "mp"."primary_joints",
    "mp"."teaching_cues",
    "mp"."common_faults",
    "mp"."typical_equipment",
    "mp"."progression_levels",
    "count"(DISTINCT "ec"."exercise_key") AS "exercise_count"
   FROM ("zamm"."lib_movement_patterns" "mp"
     LEFT JOIN "zamm"."lib_exercise_catalog" "ec" ON (("ec"."movement_pattern" = "mp"."pattern_key")))
  WHERE ("mp"."is_active" = true)
  GROUP BY "mp"."pattern_key", "mp"."display_name", "mp"."category", "mp"."primary_joints", "mp"."teaching_cues", "mp"."common_faults", "mp"."typical_equipment", "mp"."progression_levels";


ALTER VIEW "zamm"."v_movement_patterns_full" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_movement_patterns_full" IS 'Complete movement pattern reference with exercise counts';



CREATE OR REPLACE VIEW "zamm"."v_muscle_groups_by_region" AS
 SELECT "body_region",
    "muscle_group",
    "array_agg"("muscle_key" ORDER BY "display_name") AS "muscles",
    "array_agg"("display_name" ORDER BY "display_name") AS "display_names",
    "avg"("recovery_time_hours") AS "avg_recovery_hours"
   FROM "zamm"."lib_muscle_groups" "mg"
  WHERE ("is_active" = true)
  GROUP BY "body_region", "muscle_group";


ALTER VIEW "zamm"."v_muscle_groups_by_region" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_muscle_groups_by_region" IS 'Muscle groups organized by body region and muscle group';



CREATE OR REPLACE VIEW "zamm"."v_pr_history" AS
 SELECT "pr_id",
    "athlete_natural_id",
    "exercise_key" AS "exercise",
    "pr_type",
    "value",
    "previous_pr",
    "improvement_percent",
    "achieved_at",
    "is_current_pr",
    "athlete_bodyweight_kg",
    "workout_id",
    "block_id"
   FROM "zamm"."evt_athlete_personal_records" "pr"
  ORDER BY "exercise_key", "achieved_at" DESC;


ALTER VIEW "zamm"."v_pr_history" OWNER TO "postgres";


COMMENT ON VIEW "zamm"."v_pr_history" IS 'Shows full PR history including old records that have been beaten';



CREATE TABLE IF NOT EXISTS "zamm"."workout_item_set_results" (
    "set_result_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "block_id" "uuid" NOT NULL,
    "item_id" "uuid" NOT NULL,
    "set_index" integer NOT NULL,
    "reps" integer,
    "load_kg" numeric(10,2),
    "rpe" numeric(4,2),
    "rir" numeric(4,2),
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "zamm"."workout_item_set_results" OWNER TO "postgres";


ALTER TABLE ONLY "zamm"."evt_athlete_personal_records"
    ADD CONSTRAINT "athlete_personal_records_pkey" PRIMARY KEY ("pr_id");



ALTER TABLE ONLY "zamm"."lib_block_aliases"
    ADD CONSTRAINT "block_code_aliases_pkey" PRIMARY KEY ("alias");



ALTER TABLE ONLY "zamm"."res_blocks"
    ADD CONSTRAINT "block_results_block_id_key" UNIQUE ("block_id");



ALTER TABLE ONLY "zamm"."res_blocks"
    ADD CONSTRAINT "block_results_pkey" PRIMARY KEY ("block_result_id");



ALTER TABLE ONLY "zamm"."lib_block_types"
    ADD CONSTRAINT "block_type_catalog_pkey" PRIMARY KEY ("block_code");



ALTER TABLE ONLY "zamm"."stg_draft_edits"
    ADD CONSTRAINT "draft_edits_pkey" PRIMARY KEY ("edit_id");



ALTER TABLE ONLY "zamm"."lib_equipment_aliases"
    ADD CONSTRAINT "equipment_aliases_pkey" PRIMARY KEY ("alias");



ALTER TABLE ONLY "zamm"."lib_equipment_catalog"
    ADD CONSTRAINT "equipment_catalog_pkey" PRIMARY KEY ("equipment_key");



ALTER TABLE ONLY "zamm"."lib_equipment_config_templates"
    ADD CONSTRAINT "equipment_config_templates_pkey" PRIMARY KEY ("equipment_key");



ALTER TABLE ONLY "zamm"."lib_exercise_aliases"
    ADD CONSTRAINT "exercise_aliases_pkey" PRIMARY KEY ("alias");



ALTER TABLE ONLY "zamm"."lib_exercise_catalog"
    ADD CONSTRAINT "exercise_catalog_exercise_key_key" UNIQUE ("exercise_key");



ALTER TABLE ONLY "zamm"."lib_exercise_catalog"
    ADD CONSTRAINT "exercise_catalog_pkey" PRIMARY KEY ("exercise_id");



ALTER TABLE ONLY "zamm"."stg_imports"
    ADD CONSTRAINT "imports_pkey" PRIMARY KEY ("import_id");



ALTER TABLE ONLY "zamm"."workout_item_set_results"
    ADD CONSTRAINT "item_set_results_pkey" PRIMARY KEY ("set_result_id");



ALTER TABLE ONLY "zamm"."lib_athletes"
    ADD CONSTRAINT "lib_athletes_email_key" UNIQUE ("email");



ALTER TABLE ONLY "zamm"."lib_athletes"
    ADD CONSTRAINT "lib_athletes_pkey" PRIMARY KEY ("athlete_id");



ALTER TABLE ONLY "zamm"."lib_benchmark_blocks"
    ADD CONSTRAINT "lib_benchmark_blocks_benchmark_key_block_code_key" UNIQUE ("benchmark_key", "block_code");



ALTER TABLE ONLY "zamm"."lib_benchmark_blocks"
    ADD CONSTRAINT "lib_benchmark_blocks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "zamm"."lib_benchmark_exercises"
    ADD CONSTRAINT "lib_benchmark_exercises_benchmark_key_exercise_key_test_typ_key" UNIQUE ("benchmark_key", "exercise_key", "test_type");



ALTER TABLE ONLY "zamm"."lib_benchmark_exercises"
    ADD CONSTRAINT "lib_benchmark_exercises_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "zamm"."lib_benchmarks"
    ADD CONSTRAINT "lib_benchmarks_pkey" PRIMARY KEY ("benchmark_key");



ALTER TABLE ONLY "zamm"."lib_coaches"
    ADD CONSTRAINT "lib_coaches_email_key" UNIQUE ("email");



ALTER TABLE ONLY "zamm"."lib_coaches"
    ADD CONSTRAINT "lib_coaches_pkey" PRIMARY KEY ("coach_id");



ALTER TABLE ONLY "zamm"."lib_movement_patterns"
    ADD CONSTRAINT "lib_movement_patterns_pkey" PRIMARY KEY ("pattern_key");



ALTER TABLE ONLY "zamm"."lib_muscle_groups"
    ADD CONSTRAINT "lib_muscle_groups_pkey" PRIMARY KEY ("muscle_key");



ALTER TABLE ONLY "zamm"."lib_parser_rulesets"
    ADD CONSTRAINT "lib_parser_rulesets_pkey" PRIMARY KEY ("ruleset_id");



ALTER TABLE ONLY "zamm"."lib_prescription_schemas"
    ADD CONSTRAINT "lib_prescription_schemas_pkey" PRIMARY KEY ("schema_id");



ALTER TABLE ONLY "zamm"."lib_result_models"
    ADD CONSTRAINT "lib_result_models_pkey" PRIMARY KEY ("result_model_id");



ALTER TABLE ONLY "zamm"."stg_parse_drafts"
    ADD CONSTRAINT "parse_drafts_pkey" PRIMARY KEY ("draft_id");



ALTER TABLE ONLY "zamm"."cfg_parser_rules"
    ADD CONSTRAINT "parser_rulesets_name_version_key" UNIQUE ("name", "version");



ALTER TABLE ONLY "zamm"."cfg_parser_rules"
    ADD CONSTRAINT "parser_rulesets_pkey" PRIMARY KEY ("ruleset_id");



ALTER TABLE ONLY "zamm"."res_intervals"
    ADD CONSTRAINT "res_intervals_pkey" PRIMARY KEY ("interval_id");



ALTER TABLE ONLY "zamm"."res_item_sets"
    ADD CONSTRAINT "res_item_sets_pkey" PRIMARY KEY ("set_result_id");



ALTER TABLE ONLY "zamm"."res_blocks"
    ADD CONSTRAINT "uq_res_blocks_block" UNIQUE ("block_id");



ALTER TABLE ONLY "zamm"."res_item_sets"
    ADD CONSTRAINT "uq_res_item_sets_item_set" UNIQUE ("item_id", "set_index");



ALTER TABLE ONLY "zamm"."log_validation_reports"
    ADD CONSTRAINT "validation_reports_pkey" PRIMARY KEY ("report_id");



ALTER TABLE ONLY "zamm"."workout_blocks"
    ADD CONSTRAINT "workout_blocks_pkey" PRIMARY KEY ("block_id");



ALTER TABLE ONLY "zamm"."workout_items"
    ADD CONSTRAINT "workout_items_pkey" PRIMARY KEY ("item_id");



ALTER TABLE ONLY "zamm"."workout_sessions"
    ADD CONSTRAINT "workout_sessions_pkey" PRIMARY KEY ("session_id");



ALTER TABLE ONLY "zamm"."workout_main"
    ADD CONSTRAINT "workouts_pkey" PRIMARY KEY ("workout_id");



CREATE INDEX "idx_athletes_coach" ON "zamm"."lib_athletes" USING "btree" ("primary_coach_id");



CREATE INDEX "idx_benchmark_blocks_benchmark" ON "zamm"."lib_benchmark_blocks" USING "btree" ("benchmark_key");



CREATE INDEX "idx_benchmark_blocks_block" ON "zamm"."lib_benchmark_blocks" USING "btree" ("block_code");



CREATE INDEX "idx_benchmark_exercises_benchmark" ON "zamm"."lib_benchmark_exercises" USING "btree" ("benchmark_key");



CREATE INDEX "idx_benchmark_exercises_exercise" ON "zamm"."lib_benchmark_exercises" USING "btree" ("exercise_key");



CREATE INDEX "idx_block_results_block" ON "zamm"."res_blocks" USING "btree" ("block_id");



CREATE INDEX "idx_block_results_block_code" ON "zamm"."res_blocks" USING "btree" ("block_code");



CREATE INDEX "idx_block_results_canonical_gin" ON "zamm"."res_blocks" USING "gin" ("canonical");



CREATE INDEX "idx_block_results_computed_gin" ON "zamm"."res_blocks" USING "gin" ("computed");



CREATE INDEX "idx_block_results_ingest_key" ON "zamm"."res_blocks" USING "btree" ("ingest_key");



CREATE INDEX "idx_block_results_model" ON "zamm"."res_blocks" USING "btree" ("result_model_id");



CREATE INDEX "idx_block_results_status" ON "zamm"."res_blocks" USING "btree" ("status");



CREATE INDEX "idx_blocks_benchmark" ON "zamm"."workout_blocks" USING "btree" ("benchmark_key") WHERE ("benchmark_key" IS NOT NULL);



CREATE INDEX "idx_blocks_session" ON "zamm"."workout_blocks" USING "btree" ("session_id");



CREATE INDEX "idx_blocks_type" ON "zamm"."workout_blocks" USING "btree" ("block_type");



CREATE INDEX "idx_coaches_active" ON "zamm"."lib_coaches" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_draft_edits_created_at" ON "zamm"."stg_draft_edits" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_draft_edits_draft" ON "zamm"."stg_draft_edits" USING "btree" ("draft_id");



CREATE INDEX "idx_drafts_import" ON "zamm"."stg_parse_drafts" USING "btree" ("import_id");



CREATE INDEX "idx_drafts_pending" ON "zamm"."stg_parse_drafts" USING "btree" ("created_at" DESC) WHERE (("approved_at" IS NULL) AND ("rejected_at" IS NULL));



CREATE INDEX "idx_drafts_stage" ON "zamm"."stg_parse_drafts" USING "btree" ("stage", "created_at" DESC);



CREATE INDEX "idx_equipment_aliases_key" ON "zamm"."lib_equipment_aliases" USING "btree" ("equipment_key");



CREATE INDEX "idx_equipment_catalog_active" ON "zamm"."lib_equipment_catalog" USING "btree" ("equipment_key") WHERE ("is_active" = true);



CREATE INDEX "idx_exercise_aliases_key" ON "zamm"."lib_exercise_aliases" USING "btree" ("exercise_key");



CREATE INDEX "idx_exercise_catalog_category" ON "zamm"."lib_exercise_catalog" USING "btree" ("category") WHERE ("is_active" = true);



CREATE INDEX "idx_exercise_catalog_movement_pattern" ON "zamm"."lib_exercise_catalog" USING "btree" ("movement_pattern") WHERE (("movement_pattern" IS NOT NULL) AND ("is_active" = true));



CREATE INDEX "idx_exercise_catalog_pattern" ON "zamm"."lib_exercise_catalog" USING "btree" ("movement_pattern") WHERE ("is_active" = true);



CREATE INDEX "idx_exercise_catalog_primary_muscles_gin" ON "zamm"."lib_exercise_catalog" USING "gin" ("primary_muscles");



CREATE INDEX "idx_exercise_catalog_secondary_muscles_gin" ON "zamm"."lib_exercise_catalog" USING "gin" ("secondary_muscles");



CREATE INDEX "idx_imports_athlete" ON "zamm"."stg_imports" USING "btree" ("athlete_id");



CREATE INDEX "idx_imports_received_at" ON "zamm"."stg_imports" USING "btree" ("received_at" DESC);



CREATE INDEX "idx_imports_source" ON "zamm"."stg_imports" USING "btree" ("source");



CREATE INDEX "idx_item_set_results_block" ON "zamm"."workout_item_set_results" USING "btree" ("block_id");



CREATE INDEX "idx_item_set_results_item" ON "zamm"."workout_item_set_results" USING "btree" ("item_id");



CREATE INDEX "idx_item_set_results_item_set" ON "zamm"."workout_item_set_results" USING "btree" ("item_id", "set_index");



CREATE INDEX "idx_items_benchmark" ON "zamm"."workout_items" USING "btree" ("benchmark_key") WHERE ("benchmark_key" IS NOT NULL);



CREATE INDEX "idx_items_bilateral" ON "zamm"."workout_items" USING "btree" ("bilateral") WHERE ("bilateral" = true);



CREATE INDEX "idx_items_block" ON "zamm"."workout_items" USING "btree" ("block_id");



CREATE INDEX "idx_items_exercise" ON "zamm"."workout_items" USING "btree" ("exercise_name");



CREATE INDEX "idx_items_exercise_key" ON "zamm"."workout_items" USING "btree" ("exercise_key") WHERE ("exercise_key" IS NOT NULL);



CREATE INDEX "idx_items_movement_pattern" ON "zamm"."workout_items" USING "btree" ("movement_pattern") WHERE ("movement_pattern" IS NOT NULL);



CREATE INDEX "idx_items_performed_gin" ON "zamm"."workout_items" USING "gin" ("performed_data");



CREATE INDEX "idx_items_prescription_gin" ON "zamm"."workout_items" USING "gin" ("prescription_data");



CREATE INDEX "idx_lib_athletes_active" ON "zamm"."lib_athletes" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_lib_athletes_email" ON "zamm"."lib_athletes" USING "btree" ("email") WHERE ("email" IS NOT NULL);



CREATE INDEX "idx_lib_athletes_name" ON "zamm"."lib_athletes" USING "btree" ("full_name");



CREATE INDEX "idx_lib_parser_rulesets_active" ON "zamm"."lib_parser_rulesets" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_movement_patterns_category" ON "zamm"."lib_movement_patterns" USING "btree" ("category") WHERE ("is_active" = true);



CREATE INDEX "idx_muscle_groups_muscle_group" ON "zamm"."lib_muscle_groups" USING "btree" ("muscle_group") WHERE ("is_active" = true);



CREATE INDEX "idx_muscle_groups_region" ON "zamm"."lib_muscle_groups" USING "btree" ("body_region") WHERE ("is_active" = true);



CREATE INDEX "idx_parse_drafts_created_at" ON "zamm"."stg_parse_drafts" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_parse_drafts_import" ON "zamm"."stg_parse_drafts" USING "btree" ("import_id");



CREATE INDEX "idx_parse_drafts_ruleset" ON "zamm"."stg_parse_drafts" USING "btree" ("ruleset_id");



CREATE INDEX "idx_parse_drafts_stage" ON "zamm"."stg_parse_drafts" USING "btree" ("stage");



CREATE INDEX "idx_parser_rulesets_active" ON "zamm"."cfg_parser_rules" USING "btree" ("is_active");



CREATE INDEX "idx_prs_achieved" ON "zamm"."evt_athlete_personal_records" USING "btree" ("achieved_at" DESC);



CREATE INDEX "idx_prs_athlete" ON "zamm"."evt_athlete_personal_records" USING "btree" ("athlete_natural_id");



CREATE INDEX "idx_prs_block" ON "zamm"."evt_athlete_personal_records" USING "btree" ("block_id");



CREATE INDEX "idx_prs_current" ON "zamm"."evt_athlete_personal_records" USING "btree" ("athlete_natural_id", "exercise_key", "pr_type", "is_current_pr");



CREATE INDEX "idx_prs_exercise" ON "zamm"."evt_athlete_personal_records" USING "btree" ("exercise_key");



CREATE INDEX "idx_prs_type" ON "zamm"."evt_athlete_personal_records" USING "btree" ("pr_type");



CREATE INDEX "idx_prs_workout" ON "zamm"."evt_athlete_personal_records" USING "btree" ("workout_id");



CREATE INDEX "idx_res_blocks_block" ON "zamm"."res_blocks" USING "btree" ("block_id");



CREATE INDEX "idx_res_blocks_block_code" ON "zamm"."res_blocks" USING "btree" ("block_code");



CREATE INDEX "idx_res_blocks_status" ON "zamm"."res_blocks" USING "btree" ("status");



CREATE INDEX "idx_res_intervals_block" ON "zamm"."res_intervals" USING "btree" ("block_id");



CREATE INDEX "idx_res_intervals_block_segment" ON "zamm"."res_intervals" USING "btree" ("block_id", "segment_index");



CREATE INDEX "idx_res_item_sets_bilateral" ON "zamm"."res_item_sets" USING "btree" ("is_bilateral") WHERE ("is_bilateral" = true);



CREATE INDEX "idx_res_item_sets_block" ON "zamm"."res_item_sets" USING "btree" ("block_id");



CREATE INDEX "idx_res_item_sets_item" ON "zamm"."res_item_sets" USING "btree" ("item_id");



CREATE INDEX "idx_res_item_sets_item_set" ON "zamm"."res_item_sets" USING "btree" ("item_id", "set_index");



CREATE INDEX "idx_sessions_date" ON "zamm"."workout_sessions" USING "btree" ("date" DESC);



CREATE INDEX "idx_sessions_workout" ON "zamm"."workout_sessions" USING "btree" ("workout_id");



CREATE INDEX "idx_set_results_block" ON "zamm"."workout_item_set_results" USING "btree" ("block_id");



CREATE INDEX "idx_set_results_item" ON "zamm"."workout_item_set_results" USING "btree" ("item_id", "set_index");



CREATE INDEX "idx_set_results_side" ON "zamm"."res_item_sets" USING "btree" ("item_id", "side") WHERE ("side" IS NOT NULL);



CREATE INDEX "idx_set_results_type" ON "zamm"."res_item_sets" USING "btree" ("set_type");



CREATE INDEX "idx_validation_draft" ON "zamm"."log_validation_reports" USING "btree" ("draft_id", "created_at" DESC);



CREATE INDEX "idx_validation_invalid" ON "zamm"."log_validation_reports" USING "btree" ("created_at" DESC) WHERE ("is_valid" = false);



CREATE INDEX "idx_validation_reports_draft" ON "zamm"."log_validation_reports" USING "btree" ("draft_id");



CREATE INDEX "idx_validation_reports_valid" ON "zamm"."log_validation_reports" USING "btree" ("is_valid");



CREATE INDEX "idx_workout_blocks_code" ON "zamm"."workout_blocks" USING "btree" ("block_code");



CREATE INDEX "idx_workout_blocks_result_model" ON "zamm"."workout_blocks" USING "btree" ("result_entry_model");



CREATE INDEX "idx_workout_blocks_session" ON "zamm"."workout_blocks" USING "btree" ("session_id");



CREATE INDEX "idx_workout_items_block" ON "zamm"."workout_items" USING "btree" ("block_id");



CREATE INDEX "idx_workout_items_equipment_key" ON "zamm"."workout_items" USING "btree" ("equipment_key");



CREATE INDEX "idx_workout_items_exercise_key" ON "zamm"."workout_items" USING "btree" ("exercise_key");



CREATE INDEX "idx_workout_items_name" ON "zamm"."workout_items" USING "btree" ("exercise_name");



CREATE INDEX "idx_workout_main_created_by" ON "zamm"."workout_main" USING "btree" ("created_by");



CREATE INDEX "idx_workout_main_data_source" ON "zamm"."workout_main" USING "btree" ("data_source");



CREATE INDEX "idx_workout_main_original_date" ON "zamm"."workout_main" USING "btree" ("original_date") WHERE ("original_date" IS NOT NULL);



CREATE UNIQUE INDEX "idx_workout_main_unique" ON "zamm"."workout_main" USING "btree" ("athlete_id", "workout_date", COALESCE("session_title", 'default'::"text")) WHERE ("status" <> ALL (ARRAY['cancelled'::"text", 'archived'::"text"]));



COMMENT ON INDEX "zamm"."idx_workout_main_unique" IS 'מונע כפילויות של אימונים לאותו אתלט באותו תאריך (למעט cancelled/archived)';



CREATE INDEX "idx_workout_sessions_workout" ON "zamm"."workout_sessions" USING "btree" ("workout_id");



CREATE INDEX "idx_workouts_athlete_date" ON "zamm"."workout_main" USING "btree" ("athlete_id", "workout_date" DESC);



CREATE INDEX "idx_workouts_coach" ON "zamm"."workout_main" USING "btree" ("coach_id");



CREATE INDEX "idx_workouts_date" ON "zamm"."workout_main" USING "btree" ("workout_date" DESC);



CREATE INDEX "idx_workouts_draft" ON "zamm"."workout_main" USING "btree" ("draft_id");



CREATE INDEX "idx_workouts_import" ON "zamm"."workout_main" USING "btree" ("import_id");



CREATE INDEX "idx_workouts_status_completed" ON "zamm"."workout_main" USING "btree" ("status") WHERE ("status" = 'completed'::"text");



CREATE UNIQUE INDEX "uq_active_ruleset" ON "zamm"."lib_parser_rulesets" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE OR REPLACE TRIGGER "trg_parse_drafts_updated_at" BEFORE UPDATE ON "zamm"."stg_parse_drafts" FOR EACH ROW EXECUTE FUNCTION "zamm"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_workout_items_set_exercise_key" BEFORE INSERT OR UPDATE OF "exercise_name" ON "zamm"."workout_items" FOR EACH ROW EXECUTE FUNCTION "zamm"."trg_set_exercise_key"();



COMMENT ON TRIGGER "trg_workout_items_set_exercise_key" ON "zamm"."workout_items" IS 'מזהה אוטומטית exercise_key מ-exercise_name בעת INSERT/UPDATE';



ALTER TABLE ONLY "zamm"."evt_athlete_personal_records"
    ADD CONSTRAINT "athlete_personal_records_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "zamm"."workout_blocks"("block_id");



ALTER TABLE ONLY "zamm"."evt_athlete_personal_records"
    ADD CONSTRAINT "athlete_personal_records_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "zamm"."workout_items"("item_id");



ALTER TABLE ONLY "zamm"."evt_athlete_personal_records"
    ADD CONSTRAINT "athlete_personal_records_set_result_id_fkey" FOREIGN KEY ("set_result_id") REFERENCES "zamm"."res_item_sets"("set_result_id");



ALTER TABLE ONLY "zamm"."evt_athlete_personal_records"
    ADD CONSTRAINT "athlete_personal_records_workout_id_fkey" FOREIGN KEY ("workout_id") REFERENCES "zamm"."workout_main"("workout_id");



ALTER TABLE ONLY "zamm"."lib_block_aliases"
    ADD CONSTRAINT "block_code_aliases_block_code_fkey" FOREIGN KEY ("block_code") REFERENCES "zamm"."lib_block_types"("block_code");



ALTER TABLE ONLY "zamm"."res_blocks"
    ADD CONSTRAINT "block_results_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "zamm"."workout_blocks"("block_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."stg_draft_edits"
    ADD CONSTRAINT "draft_edits_draft_id_fkey" FOREIGN KEY ("draft_id") REFERENCES "zamm"."stg_parse_drafts"("draft_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."lib_equipment_aliases"
    ADD CONSTRAINT "equipment_aliases_equipment_key_fkey" FOREIGN KEY ("equipment_key") REFERENCES "zamm"."lib_equipment_catalog"("equipment_key") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."lib_equipment_config_templates"
    ADD CONSTRAINT "equipment_config_templates_equipment_key_fkey" FOREIGN KEY ("equipment_key") REFERENCES "zamm"."lib_equipment_catalog"("equipment_key") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."lib_exercise_aliases"
    ADD CONSTRAINT "exercise_aliases_exercise_key_fkey" FOREIGN KEY ("exercise_key") REFERENCES "zamm"."lib_exercise_catalog"("exercise_key") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."lib_exercise_catalog"
    ADD CONSTRAINT "fk_exercise_movement_pattern" FOREIGN KEY ("movement_pattern") REFERENCES "zamm"."lib_movement_patterns"("pattern_key") ON UPDATE CASCADE ON DELETE RESTRICT;



COMMENT ON CONSTRAINT "fk_exercise_movement_pattern" ON "zamm"."lib_exercise_catalog" IS 'Ensures movement_pattern references valid pattern from lib_movement_patterns. NULL allowed for exercises without clear pattern.';



ALTER TABLE ONLY "zamm"."workout_item_set_results"
    ADD CONSTRAINT "item_set_results_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "zamm"."workout_blocks"("block_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."workout_item_set_results"
    ADD CONSTRAINT "item_set_results_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "zamm"."workout_items"("item_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."lib_athletes"
    ADD CONSTRAINT "lib_athletes_primary_coach_id_fkey" FOREIGN KEY ("primary_coach_id") REFERENCES "zamm"."lib_coaches"("coach_id");



ALTER TABLE ONLY "zamm"."lib_benchmark_blocks"
    ADD CONSTRAINT "lib_benchmark_blocks_benchmark_key_fkey" FOREIGN KEY ("benchmark_key") REFERENCES "zamm"."lib_benchmarks"("benchmark_key") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."lib_benchmark_blocks"
    ADD CONSTRAINT "lib_benchmark_blocks_block_code_fkey" FOREIGN KEY ("block_code") REFERENCES "zamm"."lib_block_types"("block_code") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."lib_benchmark_exercises"
    ADD CONSTRAINT "lib_benchmark_exercises_benchmark_key_fkey" FOREIGN KEY ("benchmark_key") REFERENCES "zamm"."lib_benchmarks"("benchmark_key") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."lib_benchmark_exercises"
    ADD CONSTRAINT "lib_benchmark_exercises_exercise_key_fkey" FOREIGN KEY ("exercise_key") REFERENCES "zamm"."lib_exercise_catalog"("exercise_key") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."stg_parse_drafts"
    ADD CONSTRAINT "parse_drafts_import_id_fkey" FOREIGN KEY ("import_id") REFERENCES "zamm"."stg_imports"("import_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."stg_parse_drafts"
    ADD CONSTRAINT "parse_drafts_ruleset_id_fkey" FOREIGN KEY ("ruleset_id") REFERENCES "zamm"."cfg_parser_rules"("ruleset_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "zamm"."res_intervals"
    ADD CONSTRAINT "res_intervals_block_fkey" FOREIGN KEY ("block_id") REFERENCES "zamm"."workout_blocks"("block_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."res_item_sets"
    ADD CONSTRAINT "res_item_sets_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "zamm"."workout_blocks"("block_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."res_item_sets"
    ADD CONSTRAINT "res_item_sets_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "zamm"."workout_items"("item_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."res_item_sets"
    ADD CONSTRAINT "res_item_sets_related_set_id_fkey" FOREIGN KEY ("related_set_id") REFERENCES "zamm"."res_item_sets"("set_result_id");



ALTER TABLE ONLY "zamm"."log_validation_reports"
    ADD CONSTRAINT "validation_reports_draft_id_fkey" FOREIGN KEY ("draft_id") REFERENCES "zamm"."stg_parse_drafts"("draft_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."res_blocks"
    ADD CONSTRAINT "workout_block_results_result_model_fkey" FOREIGN KEY ("result_model_id") REFERENCES "zamm"."lib_result_models"("result_model_id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "zamm"."workout_blocks"
    ADD CONSTRAINT "workout_blocks_benchmark_key_fkey" FOREIGN KEY ("benchmark_key") REFERENCES "zamm"."lib_benchmarks"("benchmark_key");



ALTER TABLE ONLY "zamm"."workout_blocks"
    ADD CONSTRAINT "workout_blocks_block_code_fkey" FOREIGN KEY ("block_code") REFERENCES "zamm"."lib_block_types"("block_code") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "zamm"."workout_blocks"
    ADD CONSTRAINT "workout_blocks_coach_feedback_by_fkey" FOREIGN KEY ("coach_feedback_by") REFERENCES "zamm"."lib_coaches"("coach_id");



ALTER TABLE ONLY "zamm"."workout_blocks"
    ADD CONSTRAINT "workout_blocks_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "zamm"."workout_sessions"("session_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."workout_items"
    ADD CONSTRAINT "workout_items_benchmark_key_fkey" FOREIGN KEY ("benchmark_key") REFERENCES "zamm"."lib_benchmarks"("benchmark_key");



ALTER TABLE ONLY "zamm"."workout_items"
    ADD CONSTRAINT "workout_items_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "zamm"."workout_blocks"("block_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."workout_items"
    ADD CONSTRAINT "workout_items_coach_feedback_by_fkey" FOREIGN KEY ("coach_feedback_by") REFERENCES "zamm"."lib_coaches"("coach_id");



ALTER TABLE ONLY "zamm"."workout_items"
    ADD CONSTRAINT "workout_items_equipment_fk" FOREIGN KEY ("equipment_key") REFERENCES "zamm"."lib_equipment_catalog"("equipment_key") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "zamm"."workout_items"
    ADD CONSTRAINT "workout_items_exercise_key_fkey" FOREIGN KEY ("exercise_key") REFERENCES "zamm"."lib_exercise_catalog"("exercise_key") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "zamm"."workout_main"
    ADD CONSTRAINT "workout_main_coach_id_fkey" FOREIGN KEY ("coach_id") REFERENCES "zamm"."lib_coaches"("coach_id");



ALTER TABLE ONLY "zamm"."workout_sessions"
    ADD CONSTRAINT "workout_sessions_workout_id_fkey" FOREIGN KEY ("workout_id") REFERENCES "zamm"."workout_main"("workout_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."workout_main"
    ADD CONSTRAINT "workouts_athlete_id_fkey" FOREIGN KEY ("athlete_id") REFERENCES "zamm"."lib_athletes"("athlete_id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "zamm"."workout_main"
    ADD CONSTRAINT "workouts_draft_id_fkey" FOREIGN KEY ("draft_id") REFERENCES "zamm"."stg_parse_drafts"("draft_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "zamm"."workout_main"
    ADD CONSTRAINT "workouts_import_id_fkey" FOREIGN KEY ("import_id") REFERENCES "zamm"."stg_imports"("import_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "zamm"."workout_main"
    ADD CONSTRAINT "workouts_ruleset_id_fkey" FOREIGN KEY ("ruleset_id") REFERENCES "zamm"."cfg_parser_rules"("ruleset_id") ON DELETE RESTRICT;



CREATE POLICY "Athletes can view own PRs" ON "zamm"."evt_athlete_personal_records" FOR SELECT USING (true);



CREATE POLICY "System can insert PRs" ON "zamm"."evt_athlete_personal_records" FOR INSERT WITH CHECK (true);



CREATE POLICY "System can update PRs" ON "zamm"."evt_athlete_personal_records" FOR UPDATE USING (true);



ALTER TABLE "zamm"."evt_athlete_personal_records" ENABLE ROW LEVEL SECURITY;


GRANT ALL ON FUNCTION "zamm"."check_athlete_exists"("p_search_name" "text") TO "service_role";
GRANT ALL ON FUNCTION "zamm"."check_athlete_exists"("p_search_name" "text") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."check_equipment_exists"("p_search_name" "text") TO "service_role";
GRANT ALL ON FUNCTION "zamm"."check_equipment_exists"("p_search_name" "text") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."check_exercise_exists"("p_search_name" "text") TO "service_role";
GRANT ALL ON FUNCTION "zamm"."check_exercise_exists"("p_search_name" "text") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."check_prescription_performance_consistency"("p_block" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "zamm"."check_prescription_performance_consistency"("p_block" "jsonb") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."commit_full_workout_latest"("p_import_id" "uuid", "p_draft_id" "uuid", "p_athlete_id" "uuid", "p_ruleset_id" "uuid", "p_normalized_json" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "zamm"."commit_full_workout_latest"("p_import_id" "uuid", "p_draft_id" "uuid", "p_athlete_id" "uuid", "p_ruleset_id" "uuid", "p_normalized_json" "jsonb") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."compute_avg_rpe"("p_canonical" "jsonb") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."compute_best_make"("p_canonical" "jsonb") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."compute_tonnage"("p_canonical" "jsonb") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."get_active_ruleset"() TO "service_role";
GRANT ALL ON FUNCTION "zamm"."get_active_ruleset"() TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."get_athlete_context"("p_athlete_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "zamm"."get_athlete_context"("p_athlete_id" "uuid") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."get_draft_validation_status"("p_draft_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "zamm"."get_draft_validation_status"("p_draft_id" "uuid") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."get_exercises_by_muscle"("p_muscle" "text") TO "service_role";
GRANT ALL ON FUNCTION "zamm"."get_exercises_by_muscle"("p_muscle" "text") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."get_exercises_by_pattern"("p_pattern" "text") TO "service_role";
GRANT ALL ON FUNCTION "zamm"."get_exercises_by_pattern"("p_pattern" "text") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."get_result_model_for_block"("p_block_code" "text") TO "authenticated";
GRANT ALL ON FUNCTION "zamm"."get_result_model_for_block"("p_block_code" "text") TO "service_role";



GRANT ALL ON FUNCTION "zamm"."normalize_block_code"("p_input" "text") TO "service_role";
GRANT ALL ON FUNCTION "zamm"."normalize_block_code"("p_input" "text") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."suggest_balanced_exercises"("p_primary_pattern" "text", "p_difficulty" integer) TO "service_role";
GRANT ALL ON FUNCTION "zamm"."suggest_balanced_exercises"("p_primary_pattern" "text", "p_difficulty" integer) TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."validate_and_save_report"("p_draft_id" "uuid", "p_parsed_json" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "zamm"."validate_and_save_report"("p_draft_id" "uuid", "p_parsed_json" "jsonb") TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."validate_pending_drafts"() TO "service_role";
GRANT ALL ON FUNCTION "zamm"."validate_pending_drafts"() TO "authenticated";



GRANT ALL ON FUNCTION "zamm"."validate_result_canonical"("p_result_model_id" "text", "p_canonical" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "zamm"."validate_result_canonical"("p_result_model_id" "text", "p_canonical" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "zamm"."validate_workout_draft"("p_draft_id" "uuid", "p_parsed_json" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "zamm"."validate_workout_draft"("p_draft_id" "uuid", "p_parsed_json" "jsonb") TO "authenticated";



GRANT SELECT ON TABLE "zamm"."lib_result_models" TO "authenticated";
GRANT SELECT ON TABLE "zamm"."lib_result_models" TO "service_role";




