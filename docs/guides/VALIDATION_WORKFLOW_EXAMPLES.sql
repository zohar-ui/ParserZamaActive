-- ============================================================================
-- Example: Integrating Validation into Parser Workflow
-- ============================================================================
-- This script demonstrates how to use the validation functions in Stage 3
-- of the parser workflow (between parsing and commit)
-- ============================================================================

-- ============================================================================
-- SCENARIO 1: Validate draft before commit
-- ============================================================================

-- Step 1: Get a draft from parse_drafts table
DO $$
DECLARE
    v_draft_id UUID;
    v_parsed_json JSONB;
    v_validation_result RECORD;
BEGIN
    -- Example: Get latest draft
    SELECT draft_id, parsed_draft 
    INTO v_draft_id, v_parsed_json
    FROM zamm.stg_parse_drafts
    WHERE stage = 'draft'
    ORDER BY created_at DESC
    LIMIT 1;

    -- Step 2: Run validation
    SELECT * INTO v_validation_result
    FROM zamm.validate_parsed_workout(v_draft_id, v_parsed_json);

    -- Step 3: Log results
    INSERT INTO zamm.log_validation_reports (
        draft_id,
        validation_status,
        error_details,
        validated_at
    ) VALUES (
        v_draft_id,
        v_validation_result.validation_status,
        v_validation_result.report,
        NOW()
    );

    -- Step 4: Display results
    RAISE NOTICE 'Validation Status: %', v_validation_result.validation_status;
    RAISE NOTICE 'Total Checks: %', v_validation_result.total_checks;
    RAISE NOTICE 'Errors: %', v_validation_result.errors;
    RAISE NOTICE 'Warnings: %', v_validation_result.warnings;
    
    -- Step 5: Decide next action
    IF v_validation_result.validation_status = 'fail' THEN
        RAISE NOTICE '❌ VALIDATION FAILED - Cannot commit. Review errors in log_validation_reports.';
    ELSIF v_validation_result.validation_status = 'warning' THEN
        RAISE NOTICE '⚠️ WARNINGS PRESENT - Review before commit.';
    ELSE
        RAISE NOTICE '✅ VALIDATION PASSED - Safe to commit.';
    END IF;
END $$;

-- ============================================================================
-- SCENARIO 2: Batch validation of all pending drafts
-- ============================================================================

-- Run validation on all drafts that haven't been validated yet
INSERT INTO zamm.log_validation_reports (
    draft_id,
    validation_status,
    error_details,
    validated_at
)
SELECT 
    d.draft_id,
    v.validation_status,
    v.report,
    NOW()
FROM zamm.stg_parse_drafts d
CROSS JOIN LATERAL zamm.validate_parsed_workout(d.draft_id, d.parsed_draft) v
WHERE d.stage = 'draft'
  AND NOT EXISTS (
      SELECT 1 FROM zamm.log_validation_reports vr 
      WHERE vr.draft_id = d.draft_id
  )
ON CONFLICT (draft_id) DO UPDATE
SET 
    validation_status = EXCLUDED.validation_status,
    error_details = EXCLUDED.error_details,
    validated_at = EXCLUDED.validated_at;

-- ============================================================================
-- SCENARIO 3: Safe commit workflow (only commit if validated)
-- ============================================================================

DO $$
DECLARE
    v_draft_id UUID := 'YOUR-DRAFT-ID-HERE'; -- Replace with actual draft_id
    v_import_id UUID;
    v_athlete_id UUID;
    v_ruleset_id UUID;
    v_parsed_json JSONB;
    v_validation_status TEXT;
    v_workout_id UUID;
BEGIN
    -- Step 1: Get draft data
    SELECT 
        import_id,
        ruleset_id,
        parsed_draft
    INTO v_import_id, v_ruleset_id, v_parsed_json
    FROM zamm.stg_parse_drafts
    WHERE draft_id = v_draft_id;

    -- Extract athlete_id from JSON
    v_athlete_id := (v_parsed_json->>'athlete_id')::UUID;

    -- Step 2: Check if already validated
    SELECT validation_status INTO v_validation_status
    FROM zamm.log_validation_reports
    WHERE draft_id = v_draft_id
    ORDER BY validated_at DESC
    LIMIT 1;

    -- Step 3: If not validated, run validation now
    IF v_validation_status IS NULL THEN
        RAISE NOTICE 'No validation record found. Running validation...';
        
        INSERT INTO zamm.log_validation_reports (
            draft_id,
            validation_status,
            error_details,
            validated_at
        )
        SELECT 
            v_draft_id,
            validation_status,
            report,
            NOW()
        FROM zamm.validate_parsed_workout(v_draft_id, v_parsed_json);

        -- Refresh validation_status
        SELECT validation_status INTO v_validation_status
        FROM zamm.log_validation_reports
        WHERE draft_id = v_draft_id
        ORDER BY validated_at DESC
        LIMIT 1;
    END IF;

    -- Step 4: Only commit if validation passed
    IF v_validation_status = 'fail' THEN
        RAISE EXCEPTION 'Cannot commit: Validation failed with errors. Check log_validation_reports for details.';
    ELSIF v_validation_status = 'warning' THEN
        RAISE WARNING 'Validation has warnings. Proceeding with commit anyway (manual override).';
    END IF;

    -- Step 5: Commit
    RAISE NOTICE 'Validation passed. Committing workout...';
    v_workout_id := zamm.commit_full_workout_v3(
        v_import_id,
        v_draft_id,
        v_ruleset_id,
        v_athlete_id,
        v_parsed_json
    );

    RAISE NOTICE '✅ Workout committed successfully: %', v_workout_id;
END $$;

-- ============================================================================
-- SCENARIO 4: Query validation reports
-- ============================================================================

-- Get summary of validation results
SELECT 
    validation_status,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) as percentage
FROM zamm.log_validation_reports
GROUP BY validation_status
ORDER BY count DESC;

-- Get recent failures
SELECT 
    vr.draft_id,
    vr.validation_status,
    vr.validated_at,
    vr.error_details->'summary'->>'errors' as error_count,
    vr.error_details->'summary'->>'warnings' as warning_count,
    pd.created_at as draft_created_at
FROM zamm.log_validation_reports vr
JOIN zamm.stg_parse_drafts pd ON vr.draft_id = pd.draft_id
WHERE vr.validation_status = 'fail'
ORDER BY vr.validated_at DESC
LIMIT 10;

-- Get detailed errors for a specific draft
SELECT 
    draft_id,
    jsonb_pretty(error_details->'errors') as errors,
    jsonb_pretty(error_details->'warnings') as warnings
FROM zamm.log_validation_reports
WHERE draft_id = 'YOUR-DRAFT-ID-HERE';

-- ============================================================================
-- SCENARIO 5: Individual validation checks (for debugging)
-- ============================================================================

-- Test structure validation only
SELECT * FROM zamm.validate_parsed_structure(
    '{"workout_date": "2026-01-07", "athlete_id": "550e8400-e29b-41d4-a716-446655440000", "sessions": []}'::JSONB
);

-- Test block codes only
SELECT * FROM zamm.validate_block_codes(
    '{
        "sessions": [{
            "session_code": "AM",
            "blocks": [{
                "block_code": "STR",
                "block_label": "A",
                "prescription": {},
                "performed": {}
            }]
        }]
    }'::JSONB
);

-- Test prescription/performance separation
SELECT * FROM zamm.validate_prescription_performance_separation(
    '{
        "sessions": [{
            "session_code": "AM",
            "blocks": [{
                "block_code": "STR",
                "block_label": "A",
                "prescription": {
                    "steps": [{
                        "exercise_name": "Back Squat",
                        "target_sets": 3,
                        "target_reps": 5
                    }]
                },
                "performed": {
                    "steps": [{
                        "sets": [
                            {"set_index": 1, "reps": 5, "load_kg": 100}
                        ]
                    }]
                }
            }]
        }]
    }'::JSONB
);

-- ============================================================================
-- SCENARIO 6: Create a view for easy validation status checking
-- ============================================================================

CREATE OR REPLACE VIEW zamm.v_draft_validation_status AS
SELECT 
    pd.draft_id,
    pd.import_id,
    pd.stage as draft_stage,
    pd.created_at as draft_created_at,
    vr.validation_status,
    vr.validated_at,
    vr.error_details->'summary'->>'total_checks' as total_checks,
    vr.error_details->'summary'->>'errors' as errors,
    vr.error_details->'summary'->>'warnings' as warnings,
    CASE 
        WHEN vr.validation_status IS NULL THEN 'not_validated'
        WHEN vr.validation_status = 'fail' THEN 'blocked'
        WHEN vr.validation_status = 'warning' THEN 'review_recommended'
        WHEN vr.validation_status = 'pass' THEN 'ready_to_commit'
    END as commit_status
FROM zamm.stg_parse_drafts pd
LEFT JOIN zamm.log_validation_reports vr ON pd.draft_id = vr.draft_id
WHERE pd.stage = 'draft';

COMMENT ON VIEW zamm.v_draft_validation_status IS 
'Shows validation status of all drafts with human-readable commit status.';

-- Query the view
SELECT * FROM zamm.v_draft_validation_status
ORDER BY draft_created_at DESC;

-- ============================================================================
-- SCENARIO 7: Automated workflow trigger (example)
-- ============================================================================

-- This function can be called by n8n or other automation
CREATE OR REPLACE FUNCTION zamm.auto_validate_and_commit(p_draft_id UUID)
RETURNS TABLE (
    success BOOLEAN,
    workout_id UUID,
    message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_import_id UUID;
    v_athlete_id UUID;
    v_ruleset_id UUID;
    v_parsed_json JSONB;
    v_validation RECORD;
    v_workout_id UUID;
BEGIN
    -- Get draft data
    SELECT 
        import_id,
        ruleset_id,
        parsed_draft
    INTO v_import_id, v_ruleset_id, v_parsed_json
    FROM zamm.stg_parse_drafts
    WHERE draft_id = p_draft_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, 'Draft not found';
        RETURN;
    END IF;

    v_athlete_id := (v_parsed_json->>'athlete_id')::UUID;

    -- Run validation
    SELECT * INTO v_validation
    FROM zamm.validate_parsed_workout(p_draft_id, v_parsed_json);

    -- Log validation
    INSERT INTO zamm.log_validation_reports (
        draft_id,
        validation_status,
        error_details,
        validated_at
    ) VALUES (
        p_draft_id,
        v_validation.validation_status,
        v_validation.report,
        NOW()
    )
    ON CONFLICT (draft_id) DO UPDATE
    SET 
        validation_status = EXCLUDED.validation_status,
        error_details = EXCLUDED.error_details,
        validated_at = EXCLUDED.validated_at;

    -- If validation failed, return error
    IF v_validation.validation_status = 'fail' THEN
        RETURN QUERY SELECT 
            FALSE, 
            NULL::UUID, 
            format('Validation failed: %s errors', v_validation.errors);
        RETURN;
    END IF;

    -- If warnings, log but continue
    IF v_validation.validation_status = 'warning' THEN
        RAISE WARNING 'Validation has % warnings, but continuing with commit', v_validation.warnings;
    END IF;

    -- Commit
    BEGIN
        v_workout_id := zamm.commit_full_workout_v3(
            v_import_id,
            p_draft_id,
            v_ruleset_id,
            v_athlete_id,
            v_parsed_json
        );

        RETURN QUERY SELECT 
            TRUE, 
            v_workout_id, 
            format('Workout committed successfully (ID: %s)', v_workout_id);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 
            FALSE, 
            NULL::UUID, 
            format('Commit failed: %s', SQLERRM);
    END;
END;
$$;

COMMENT ON FUNCTION zamm.auto_validate_and_commit IS 
'Automated workflow: validate draft, then commit if valid. Returns success status and workout_id.';

GRANT EXECUTE ON FUNCTION zamm.auto_validate_and_commit TO service_role;

-- Example usage:
-- SELECT * FROM zamm.auto_validate_and_commit('draft-uuid-here');
