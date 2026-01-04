-- ============================================
-- Validation Functions for Workout Parser
-- ============================================
-- These functions perform automated validation and consistency checks

-- ============================================
-- Function 1: Validate Workout Draft
-- ============================================
-- Purpose: Comprehensive validation of parsed workout JSON
-- Returns: Validation report with errors and warnings
CREATE OR REPLACE FUNCTION zamm.validate_workout_draft(
    p_draft_id UUID,
    p_parsed_json JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
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

COMMENT ON FUNCTION zamm.validate_workout_draft IS 
'Validates parsed workout JSON and returns comprehensive error/warning report';

-- ============================================
-- Function 2: Check Prescription vs Performance Consistency
-- ============================================
-- Purpose: Compare what was planned vs what was done
CREATE OR REPLACE FUNCTION zamm.check_prescription_performance_consistency(
    p_block JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
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

COMMENT ON FUNCTION zamm.check_prescription_performance_consistency IS 
'Compares prescription vs performance data for consistency';

-- ============================================
-- Function 3: Auto-Save Validation Report
-- ============================================
-- Purpose: Validate draft and automatically save to validation_reports table
CREATE OR REPLACE FUNCTION zamm.validate_and_save_report(
    p_draft_id UUID,
    p_parsed_json JSONB
)
RETURNS UUID
LANGUAGE plpgsql
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

COMMENT ON FUNCTION zamm.validate_and_save_report IS 
'Validates draft and automatically saves report to validation_reports table';

-- ============================================
-- Function 4: Get Draft Validation Status
-- ============================================
-- Purpose: Quick check if a draft has been validated and is ready to commit
CREATE OR REPLACE FUNCTION zamm.get_draft_validation_status(p_draft_id UUID)
RETURNS TABLE (
    draft_id UUID,
    is_validated BOOLEAN,
    is_valid BOOLEAN,
    error_count INTEGER,
    warning_count INTEGER,
    confidence_score NUMERIC,
    needs_review BOOLEAN,
    validation_summary TEXT
)
LANGUAGE plpgsql
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

COMMENT ON FUNCTION zamm.get_draft_validation_status IS 
'Returns quick validation status summary for a draft';

-- ============================================
-- Function 5: Batch Validation for Multiple Drafts
-- ============================================
-- Purpose: Validate all pending drafts
CREATE OR REPLACE FUNCTION zamm.validate_pending_drafts()
RETURNS TABLE (
    draft_id UUID,
    report_id UUID,
    is_valid BOOLEAN,
    error_count INTEGER
)
LANGUAGE plpgsql
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

COMMENT ON FUNCTION zamm.validate_pending_drafts IS 
'Batch validates all drafts that do not have validation reports yet';

-- ============================================
-- Grant permissions
-- ============================================
GRANT EXECUTE ON FUNCTION zamm.validate_workout_draft TO service_role;
GRANT EXECUTE ON FUNCTION zamm.check_prescription_performance_consistency TO service_role;
GRANT EXECUTE ON FUNCTION zamm.validate_and_save_report TO service_role;
GRANT EXECUTE ON FUNCTION zamm.get_draft_validation_status TO service_role;
GRANT EXECUTE ON FUNCTION zamm.validate_pending_drafts TO service_role;

GRANT EXECUTE ON FUNCTION zamm.validate_workout_draft TO authenticated;
GRANT EXECUTE ON FUNCTION zamm.check_prescription_performance_consistency TO authenticated;
GRANT EXECUTE ON FUNCTION zamm.validate_and_save_report TO authenticated;
GRANT EXECUTE ON FUNCTION zamm.get_draft_validation_status TO authenticated;
GRANT EXECUTE ON FUNCTION zamm.validate_pending_drafts TO authenticated;
