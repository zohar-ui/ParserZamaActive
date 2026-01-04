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
BEGIN
    -- Extract workout date from JSON
    v_workout_date := (p_normalized_json->'sessions'->0->'sessionInfo'->>'date')::date;

    -- 1. Create Workout Header
    INSERT INTO zamm.workouts (
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
                performed jsonb
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
                INSERT INTO zamm.workout_block_results (
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
            IF v_blk_rec.prescription ? 'steps' THEN
                FOR v_item_rec IN 
                    SELECT * FROM jsonb_to_recordset(v_blk_rec.prescription->'steps') 
                    WITH ORDINALITY 
                    AS z(
                        exercise_name text,
                        target_sets integer,
                        target_reps integer,
                        target_load jsonb,
                        equipment_key text,
                        tempo text,
                        notes text,
                        ordinality int
                    )
                LOOP
                    -- Get corresponding performed data for this item
                    DECLARE
                        v_performed_item JSONB;
                    BEGIN
                        v_performed_item := COALESCE(
                            v_blk_rec.performed->'steps'->(v_item_rec.ordinality - 1),
                            '{}'::jsonb
                        );

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
                            v_item_rec.ordinality,
                            v_item_rec.exercise_name,
                            v_item_rec.equipment_key,
                            v_item_rec.tempo,
                            v_item_rec.notes,
                            -- Store full prescription data
                            jsonb_build_object(
                                'exercise_name', v_item_rec.exercise_name,
                                'target_sets', v_item_rec.target_sets,
                                'target_reps', v_item_rec.target_reps,
                                'target_load', v_item_rec.target_load,
                                'equipment_key', v_item_rec.equipment_key,
                                'tempo', v_item_rec.tempo,
                                'notes', v_item_rec.notes
                            ),
                            -- Store performed data (may be empty)
                            v_performed_item,
                            NOW()
                        )
                        RETURNING item_id INTO v_item_id;

                        -- 5. Insert individual set results if performed data has sets
                        IF v_performed_item ? 'sets' THEN
                            FOR v_set_rec IN 
                                SELECT * FROM jsonb_to_recordset(v_performed_item->'sets')
                                AS s(
                                    set_index integer,
                                    reps integer,
                                    load_kg numeric,
                                    rpe numeric,
                                    rir numeric,
                                    notes text
                                )
                            LOOP
                                INSERT INTO zamm.item_set_results (
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
                    END;
                END LOOP;
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
