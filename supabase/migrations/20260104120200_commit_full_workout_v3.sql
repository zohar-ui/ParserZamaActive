-- ============================================
-- Enhanced commit_full_workout_v3
-- ============================================
-- This version properly handles prescription/performance separation
-- and creates individual set results in item_set_results table

CREATE OR REPLACE FUNCTION zamm.commit_full_workout_v3(
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
BEGIN
    -- Extract workout date from import source_ref (format: athlete_workout_YYYY-MM-DD)
    SELECT source_ref INTO v_source_ref
    FROM zamm.stg_imports
    WHERE import_id = p_import_id;
    
    -- Parse date from source_ref (extract YYYY-MM-DD from end of string)
    v_workout_date := (regexp_match(v_source_ref, '\d{4}-\d{2}-\d{2}'))[1]::date;

    -- 1. Create Workout Header
    INSERT INTO zamm.workout_main (
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
                v_blk_rec.prescription,
                COALESCE(v_blk_rec.performed, '{}'::jsonb),
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
                    COALESCE((v_blk_rec.performed->>'did_complete')::boolean, true),
                    (v_blk_rec.performed->>'total_time_sec')::integer,
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

            -- 4. Loop through Items (Exercises)
            IF v_blk_rec.items IS NOT NULL THEN
                DECLARE
                    v_item_index INT := 0;
                BEGIN
                    FOR v_item_rec IN 
                        SELECT * FROM jsonb_to_recordset(v_blk_rec.items) AS z(
                            exercise_name text,
                            equipment_key text,
                            prescription jsonb,
                            performed jsonb,
                            notes jsonb
                        )
                    LOOP
                        v_item_index := v_item_index + 1;
                    -- Insert workout item with prescription and performed data
                    INSERT INTO zamm.workout_items (
                        block_id,
                        item_order,
                        exercise_name,
                        equipment_key,
                        tempo,
                        notes,
                        prescription_data,
                        performed_data,
                        created_at
                    )
                    VALUES (
                        v_block_id,
                        v_item_index,
                        v_item_rec.exercise_name,
                        v_item_rec.equipment_key,
                        NULL,  -- tempo
                        v_item_rec.notes,
                        -- Store full prescription data
                        COALESCE(v_item_rec.prescription, '{}'::jsonb),
                        -- Store performed data (may be empty)
                        COALESCE(v_item_rec.performed, '{}'::jsonb),
                        NOW()
                    )
                    RETURNING item_id INTO v_item_id;

                    -- 5. Insert individual set results if performed data has sets
                    IF v_item_rec.performed ? 'sets' THEN
                        FOR v_set_rec IN 
                            SELECT * FROM jsonb_to_recordset(v_item_rec.performed->'sets')
                                AS s(
                                    set_index integer,
                                    reps integer,
                                    load_kg numeric,
                                    rpe numeric,
                                    rir numeric,
                                    notes text
                                )
                            LOOP
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
                END;  -- End DECLARE block
            END IF;
        END LOOP;
    END LOOP;

    -- Return the workout ID on success
    RETURN v_workout_id;

EXCEPTION WHEN OTHERS THEN
    -- On any error, rollback everything and re-raise
    RAISE;
END;
$$;

-- Add comment
COMMENT ON FUNCTION zamm.commit_full_workout_v3 IS 
'Enhanced version that properly handles prescription/performance separation and creates item_set_results';

-- Grant permissions
GRANT EXECUTE ON FUNCTION zamm.commit_full_workout_v3 TO service_role;
GRANT EXECUTE ON FUNCTION zamm.commit_full_workout_v3 TO authenticated;

-- ============================================
-- Migration Helper: Update existing workflow to use v3
-- ============================================

-- You can optionally create an alias that points to v3
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
    RETURN zamm.commit_full_workout_v3(
        p_import_id,
        p_draft_id,
        p_ruleset_id,
        p_athlete_id,
        p_normalized_json
    );
END;
$$;

COMMENT ON FUNCTION zamm.commit_full_workout_latest IS 
'Alias to the latest version of commit_full_workout (currently v3)';

GRANT EXECUTE ON FUNCTION zamm.commit_full_workout_latest TO service_role;
GRANT EXECUTE ON FUNCTION zamm.commit_full_workout_latest TO authenticated;
