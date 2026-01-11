-- ============================================
-- Migration: commit_full_workout_v4 with Quality Gate
-- ============================================
-- Purpose: Align database ingestion with Canonical JSON Schema v3.2
-- Date: 2026-01-11
--
-- Changes:
-- 1. Add quality tracking columns (requires_review, review_reason, is_verified)
-- 2. Smart extraction of {value, unit} objects from v3.2 JSON
-- 3. Human-in-the-loop quality gate for incomplete data
-- 4. Full JSONB backup preservation
--
-- Compatible with: CANONICAL_JSON_SCHEMA.md v3.2.0
-- ============================================

-- ============================================
-- STEP 1: Schema Changes
-- ============================================

-- Add review tracking to workout_main
ALTER TABLE zamm.workout_main
ADD COLUMN IF NOT EXISTS requires_review BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS review_reason TEXT;

COMMENT ON COLUMN zamm.workout_main.requires_review IS
'Flag indicating this workout needs human review due to missing/incomplete data';

COMMENT ON COLUMN zamm.workout_main.review_reason IS
'Specific reason why review is required (e.g., "Missing exercise_key for 3 items")';

-- Add verification tracking to workout_items
ALTER TABLE zamm.workout_items
ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;

COMMENT ON COLUMN zamm.workout_items.is_verified IS
'Flag indicating this item has been verified to have complete exercise_key and prescription data';

-- Add extraction columns to res_item_sets for better queryability
-- (Keep load_kg, add duration_sec, distance_m)
ALTER TABLE zamm.res_item_sets
ADD COLUMN IF NOT EXISTS duration_sec NUMERIC,
ADD COLUMN IF NOT EXISTS distance_m NUMERIC;

COMMENT ON COLUMN zamm.res_item_sets.duration_sec IS
'Extracted duration in seconds from performed.duration.value (converted to seconds)';

COMMENT ON COLUMN zamm.res_item_sets.distance_m IS
'Extracted distance in meters from performed.distance.value (converted to meters)';

-- ============================================
-- STEP 2: Helper Function - Extract Value/Unit
-- ============================================

CREATE OR REPLACE FUNCTION zamm.extract_measurement_value(
    p_jsonb JSONB,
    p_target_unit TEXT DEFAULT NULL
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_value NUMERIC;
    v_unit TEXT;
    v_conversion_factor NUMERIC := 1.0;
BEGIN
    -- Return NULL if input is NULL or empty
    IF p_jsonb IS NULL OR p_jsonb = '{}'::jsonb OR p_jsonb = 'null'::jsonb THEN
        RETURN NULL;
    END IF;

    -- Extract value and unit
    v_value := (p_jsonb->>'value')::numeric;
    v_unit := p_jsonb->>'unit';

    -- If no unit specified, return raw value
    IF v_unit IS NULL THEN
        RETURN v_value;
    END IF;

    -- If no target unit specified, return raw value
    IF p_target_unit IS NULL THEN
        RETURN v_value;
    END IF;

    -- Convert to target unit
    CASE p_target_unit
        -- Weight conversions (target: kg)
        WHEN 'kg' THEN
            CASE v_unit
                WHEN 'kg' THEN v_conversion_factor := 1.0;
                WHEN 'lbs' THEN v_conversion_factor := 0.453592;
                WHEN 'g' THEN v_conversion_factor := 0.001;
                ELSE v_conversion_factor := 1.0;  -- Unknown unit, no conversion
            END CASE;

        -- Duration conversions (target: sec)
        WHEN 'sec' THEN
            CASE v_unit
                WHEN 'sec' THEN v_conversion_factor := 1.0;
                WHEN 'min' THEN v_conversion_factor := 60.0;
                WHEN 'hours' THEN v_conversion_factor := 3600.0;
                ELSE v_conversion_factor := 1.0;
            END CASE;

        -- Distance conversions (target: m)
        WHEN 'm' THEN
            CASE v_unit
                WHEN 'm' THEN v_conversion_factor := 1.0;
                WHEN 'km' THEN v_conversion_factor := 1000.0;
                WHEN 'yards' THEN v_conversion_factor := 0.9144;
                WHEN 'miles' THEN v_conversion_factor := 1609.34;
                ELSE v_conversion_factor := 1.0;
            END CASE;

        ELSE
            v_conversion_factor := 1.0;
    END CASE;

    RETURN v_value * v_conversion_factor;
END;
$$;

COMMENT ON FUNCTION zamm.extract_measurement_value IS
'Extracts numeric value from v3.2 {value, unit} objects with optional unit conversion';

-- ============================================
-- STEP 3: Quality Check Function
-- ============================================

CREATE OR REPLACE FUNCTION zamm.check_workout_quality(
    p_normalized_json JSONB
)
RETURNS TABLE(
    needs_review BOOLEAN,
    review_reason TEXT,
    missing_count INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_missing_items TEXT[];
    v_missing_count INTEGER := 0;
    v_item RECORD;
BEGIN
    -- Check for missing exercise_key or exercise_name in items
    FOR v_item IN
        SELECT
            sess_idx,
            block_idx,
            item_idx,
            item->>'exercise_name' as exercise_name,
            item->>'exercise_key' as exercise_key,
            item->'prescription_data' as prescription,
            item->'performed_data' as performed
        FROM
            jsonb_array_elements(p_normalized_json->'sessions') WITH ORDINALITY AS sess(data, sess_idx),
            jsonb_array_elements(sess.data->'blocks') WITH ORDINALITY AS blk(data, block_idx),
            jsonb_array_elements(blk.data->'items') WITH ORDINALITY AS item(data, item_idx)
    LOOP
        -- Check 1: Missing exercise_name
        IF v_item.exercise_name IS NULL OR v_item.exercise_name = '' THEN
            v_missing_items := array_append(v_missing_items,
                format('Session %s Block %s Item %s: Missing exercise_name',
                       v_item.sess_idx, v_item.block_idx, v_item.item_idx));
            v_missing_count := v_missing_count + 1;
        END IF;

        -- Check 2: Missing exercise_key (warning, not error)
        IF v_item.exercise_key IS NULL OR v_item.exercise_key = '' THEN
            v_missing_items := array_append(v_missing_items,
                format('Session %s Block %s Item %s: Missing exercise_key for "%s"',
                       v_item.sess_idx, v_item.block_idx, v_item.item_idx, v_item.exercise_name));
            v_missing_count := v_missing_count + 1;
        END IF;

        -- Check 3: Missing critical prescription data (sets/reps for strength blocks)
        IF v_item.prescription IS NOT NULL AND v_item.prescription != '{}'::jsonb THEN
            IF NOT (v_item.prescription ? 'target_sets' OR v_item.prescription ? 'target_reps') THEN
                v_missing_items := array_append(v_missing_items,
                    format('Session %s Block %s Item %s: Missing target_sets/target_reps for "%s"',
                           v_item.sess_idx, v_item.block_idx, v_item.item_idx, v_item.exercise_name));
                v_missing_count := v_missing_count + 1;
            END IF;
        END IF;
    END LOOP;

    -- Return results
    IF v_missing_count > 0 THEN
        RETURN QUERY SELECT
            true AS needs_review,
            array_to_string(v_missing_items, '; ') AS review_reason,
            v_missing_count AS missing_count;
    ELSE
        RETURN QUERY SELECT
            false AS needs_review,
            NULL::TEXT AS review_reason,
            0 AS missing_count;
    END IF;
END;
$$;

COMMENT ON FUNCTION zamm.check_workout_quality IS
'Validates workout JSON for missing critical data and returns review requirements';

-- ============================================
-- STEP 4: commit_full_workout_v4 - Main Procedure
-- ============================================

CREATE OR REPLACE FUNCTION zamm.commit_full_workout_v4(
    p_import_id UUID,
    p_draft_id UUID,
    p_ruleset_id UUID,
    p_athlete_id UUID,
    p_normalized_json JSONB
)
RETURNS UUID
LANGUAGE plpgsql
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
    v_source_ref TEXT;

    -- Quality gate variables
    v_quality_check RECORD;
    v_workout_status TEXT;
    v_requires_review BOOLEAN := false;
    v_review_reason TEXT := NULL;

    -- Extraction variables
    v_load_kg NUMERIC;
    v_duration_sec NUMERIC;
    v_distance_m NUMERIC;
    v_is_verified BOOLEAN;
BEGIN
    -- ============================================
    -- QUALITY GATE: Check data completeness
    -- ============================================
    SELECT * INTO v_quality_check
    FROM zamm.check_workout_quality(p_normalized_json);

    v_requires_review := v_quality_check.needs_review;
    v_review_reason := v_quality_check.review_reason;

    -- Set workout status based on quality check
    IF v_requires_review THEN
        v_workout_status := 'pending_review';
        RAISE NOTICE 'Workout flagged for review: %', v_review_reason;
    ELSE
        v_workout_status := 'completed';
    END IF;

    -- ============================================
    -- Extract workout date from import
    -- ============================================
    SELECT source_ref INTO v_source_ref
    FROM zamm.stg_imports
    WHERE import_id = p_import_id;

    -- Parse date from source_ref (extract YYYY-MM-DD from end of string)
    v_workout_date := (regexp_match(v_source_ref, '\d{4}-\d{2}-\d{2}'))[1]::date;

    -- ============================================
    -- 1. Create Workout Header (with quality flags)
    -- ============================================
    INSERT INTO zamm.workout_main (
        import_id,
        draft_id,
        ruleset_id,
        athlete_id,
        workout_date,
        status,
        requires_review,
        review_reason,
        created_at,
        approved_at
    )
    VALUES (
        p_import_id,
        p_draft_id,
        p_ruleset_id,
        p_athlete_id,
        v_workout_date,
        v_workout_status,
        v_requires_review,
        v_review_reason,
        NOW(),
        CASE WHEN v_workout_status = 'completed' THEN NOW() ELSE NULL END
    )
    RETURNING workout_id INTO v_workout_id;

    -- ============================================
    -- 2. Loop through Sessions
    -- ============================================
    FOR v_sess_rec IN
        SELECT * FROM jsonb_to_recordset(p_normalized_json->'sessions')
        AS x(sessionInfo jsonb, blocks jsonb)
    LOOP
        INSERT INTO zamm.workout_sessions (
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
            v_workout_status,
            NOW()
        )
        RETURNING session_id INTO v_session_id;

        -- ============================================
        -- 3. Loop through Blocks
        -- ============================================
        FOR v_blk_rec IN
            SELECT * FROM jsonb_to_recordset(v_sess_rec.blocks)
            AS y(
                block_code text,
                block_type text,
                name text,
                prescription jsonb,
                performed jsonb,
                items jsonb
            )
        LOOP
            -- Insert Block with prescription and performed data
            INSERT INTO zamm.workout_blocks (
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
                v_blk_rec.prescription,  -- Store full JSONB as backup
                COALESCE(v_blk_rec.performed, '{}'::jsonb),  -- Store full JSONB as backup
                '[]'::jsonb,
                0.95,
                NOW()
            )
            RETURNING block_id INTO v_block_id;

            -- Insert Block Result if performed data exists
            IF v_blk_rec.performed IS NOT NULL AND v_blk_rec.performed != '{}'::jsonb THEN
                INSERT INTO zamm.res_blocks (
                    block_id,
                    did_complete,
                    total_time_sec,
                    score_text,
                    athlete_notes,
                    created_at
                )
                VALUES (
                    v_block_id,
                    COALESCE((v_blk_rec.performed->>'did_complete')::boolean,
                             (v_blk_rec.performed->>'completed')::boolean,
                             true),
                    -- Extract duration from v3.2 structure
                    zamm.extract_measurement_value(
                        v_blk_rec.performed->'actual_duration',
                        'sec'
                    ),
                    v_blk_rec.performed->>'score_text',
                    v_blk_rec.performed->>'notes',
                    NOW()
                )
                ON CONFLICT (block_id) DO UPDATE
                SET
                    did_complete = EXCLUDED.did_complete,
                    total_time_sec = EXCLUDED.total_time_sec,
                    score_text = EXCLUDED.score_text,
                    athlete_notes = EXCLUDED.athlete_notes;
            END IF;

            -- ============================================
            -- 4. Loop through Items (Exercises)
            -- ============================================
            IF v_blk_rec.items IS NOT NULL THEN
                DECLARE
                    v_item_index INT := 0;
                BEGIN
                    FOR v_item_rec IN
                        SELECT * FROM jsonb_to_recordset(v_blk_rec.items) AS z(
                            item_sequence integer,
                            exercise_name text,
                            exercise_key text,
                            equipment_key text,
                            prescription_data jsonb,
                            performed_data jsonb,
                            notes text
                        )
                    LOOP
                        v_item_index := COALESCE(v_item_rec.item_sequence, v_item_index + 1);

                        -- Determine if item is verified (has exercise_key and basic prescription)
                        v_is_verified := (
                            v_item_rec.exercise_key IS NOT NULL
                            AND v_item_rec.exercise_key != ''
                            AND v_item_rec.prescription_data IS NOT NULL
                            AND v_item_rec.prescription_data != '{}'::jsonb
                        );

                        -- Insert workout item with prescription and performed data
                        INSERT INTO zamm.workout_items (
                            block_id,
                            item_order,
                            exercise_name,
                            exercise_key,
                            equipment_key,
                            tempo,
                            notes,
                            prescription_data,
                            performed_data,
                            is_verified,
                            created_at
                        )
                        VALUES (
                            v_block_id,
                            v_item_index,
                            v_item_rec.exercise_name,
                            v_item_rec.exercise_key,
                            v_item_rec.equipment_key,
                            v_item_rec.prescription_data->>'target_tempo',
                            v_item_rec.notes,
                            -- Store full prescription JSONB as backup
                            COALESCE(v_item_rec.prescription_data, '{}'::jsonb),
                            -- Store performed JSONB as backup
                            COALESCE(v_item_rec.performed_data, '{}'::jsonb),
                            v_is_verified,
                            NOW()
                        )
                        RETURNING item_id INTO v_item_id;

                        -- ============================================
                        -- 5. Insert individual set results (SMART EXTRACTION)
                        -- ============================================
                        IF v_item_rec.performed_data ? 'sets' THEN
                            FOR v_set_rec IN
                                SELECT * FROM jsonb_to_recordset(v_item_rec.performed_data->'sets')
                                    AS s(
                                        set_index integer,
                                        reps integer,
                                        load jsonb,      -- v3.2: {value, unit}
                                        duration jsonb,  -- v3.2: {value, unit}
                                        distance jsonb,  -- v3.2: {value, unit}
                                        rpe numeric,
                                        rir numeric,
                                        notes text
                                    )
                                LOOP
                                    -- ============================================
                                    -- SMART EXTRACTION: Extract {value, unit} objects
                                    -- ============================================

                                    -- Extract load (convert to kg)
                                    v_load_kg := zamm.extract_measurement_value(
                                        v_set_rec.load,
                                        'kg'
                                    );

                                    -- Extract duration (convert to sec)
                                    v_duration_sec := zamm.extract_measurement_value(
                                        v_set_rec.duration,
                                        'sec'
                                    );

                                    -- Extract distance (convert to m)
                                    v_distance_m := zamm.extract_measurement_value(
                                        v_set_rec.distance,
                                        'm'
                                    );

                                    -- Insert set result with extracted values
                                    INSERT INTO zamm.res_item_sets (
                                        block_id,
                                        item_id,
                                        set_index,
                                        reps,
                                        load_kg,
                                        duration_sec,
                                        distance_m,
                                        rpe,
                                        rir,
                                        notes,
                                        created_at
                                    )
                                    VALUES (
                                        v_block_id,
                                        v_item_id,
                                        v_set_rec.set_index,
                                        v_set_rec.reps,
                                        v_load_kg,
                                        v_duration_sec,
                                        v_distance_m,
                                        v_set_rec.rpe,
                                        v_set_rec.rir,
                                        v_set_rec.notes,
                                        NOW()
                                    );
                                END LOOP;
                        END IF;
                    END LOOP;
                END;  -- End DECLARE block
            END IF;
        END LOOP;
    END LOOP;

    -- ============================================
    -- Return workout ID on success
    -- ============================================
    RETURN v_workout_id;

EXCEPTION WHEN OTHERS THEN
    -- On any error, rollback everything and re-raise
    RAISE EXCEPTION 'commit_full_workout_v4 failed: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END;
$$;

-- ============================================
-- Metadata and Permissions
-- ============================================

COMMENT ON FUNCTION zamm.commit_full_workout_v4 IS
'v4: Aligns with Canonical JSON Schema v3.2 - Smart extraction of {value, unit} objects with quality gate for incomplete data';

GRANT EXECUTE ON FUNCTION zamm.commit_full_workout_v4 TO service_role;
GRANT EXECUTE ON FUNCTION zamm.commit_full_workout_v4 TO authenticated;

-- ============================================
-- STEP 5: Update Latest Alias
-- ============================================

CREATE OR REPLACE FUNCTION zamm.commit_full_workout_latest(
    p_import_id UUID,
    p_draft_id UUID,
    p_ruleset_id UUID,
    p_athlete_id UUID,
    p_normalized_json JSONB
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN zamm.commit_full_workout_v4(
        p_import_id,
        p_draft_id,
        p_ruleset_id,
        p_athlete_id,
        p_normalized_json
    );
END;
$$;

COMMENT ON FUNCTION zamm.commit_full_workout_latest IS
'Alias to the latest version of commit_full_workout (currently v4)';

GRANT EXECUTE ON FUNCTION zamm.commit_full_workout_latest TO service_role;
GRANT EXECUTE ON FUNCTION zamm.commit_full_workout_latest TO authenticated;

-- ============================================
-- STEP 6: Example Usage and Testing Query
-- ============================================

-- Example: Query workouts that need review
-- SELECT
--     workout_id,
--     athlete_id,
--     workout_date,
--     status,
--     review_reason
-- FROM zamm.workout_main
-- WHERE requires_review = true
-- ORDER BY created_at DESC;

-- Example: Query unverified workout items
-- SELECT
--     wi.item_id,
--     wi.exercise_name,
--     wi.exercise_key,
--     wi.is_verified,
--     wm.workout_date,
--     wm.requires_review
-- FROM zamm.workout_items wi
-- JOIN zamm.workout_blocks wb ON wi.block_id = wb.block_id
-- JOIN zamm.workout_sessions ws ON wb.session_id = ws.session_id
-- JOIN zamm.workout_main wm ON ws.workout_id = wm.workout_id
-- WHERE wi.is_verified = false
-- ORDER BY wm.workout_date DESC;

-- ============================================
-- Migration Complete
-- ============================================
