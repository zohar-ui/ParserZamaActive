# Quick Test Queries
# Use these to verify all functions are working

-- ============================================
-- 1. Test AI Tools
-- ============================================

-- Test check_athlete_exists
SELECT * FROM zamm.check_athlete_exists('test');

-- Test check_equipment_exists  
SELECT * FROM zamm.check_equipment_exists('barbell');

-- Test get_active_ruleset
SELECT * FROM zamm.get_active_ruleset();

-- Test normalize_block_type
SELECT * FROM zamm.normalize_block_type('strength');
SELECT * FROM zamm.normalize_block_type('metcon');
SELECT * FROM zamm.normalize_block_type('unknown_type');

-- ============================================
-- 2. Test Validation Functions
-- ============================================

-- Create a test draft first
DO $$
DECLARE
    v_import_id UUID;
    v_draft_id UUID;
    v_ruleset_id UUID;
    v_test_json JSONB;
BEGIN
    -- Insert test import
    INSERT INTO zamm.imports (source, raw_text)
    VALUES ('test', 'Squat: 3x5 @ 100kg')
    RETURNING import_id INTO v_import_id;

    -- Get active ruleset
    SELECT ruleset_id INTO v_ruleset_id 
    FROM zamm.parser_rulesets 
    WHERE is_active = true 
    LIMIT 1;

    -- Create test JSON
    v_test_json := '{
        "sessions": [{
            "sessionInfo": {
                "date": "2026-01-04",
                "title": "Test Session"
            },
            "blocks": [{
                "block_code": "A",
                "block_type": "strength",
                "name": "Strength Block",
                "prescription": {
                    "structure": "sets_reps_load",
                    "steps": [{
                        "exercise_name": "Back Squat",
                        "target_sets": 3,
                        "target_reps": 5,
                        "target_load": {"value": 100, "unit": "kg"}
                    }]
                },
                "performed": {
                    "did_complete": true,
                    "steps": [{
                        "sets": [
                            {"set_index": 1, "reps": 5, "load_kg": 100},
                            {"set_index": 2, "reps": 5, "load_kg": 100},
                            {"set_index": 3, "reps": 4, "load_kg": 100}
                        ]
                    }]
                }
            }]
        }]
    }'::jsonb;

    -- Insert draft
    INSERT INTO zamm.parse_drafts (
        import_id, 
        ruleset_id, 
        parser_version, 
        stage, 
        parsed_draft,
        normalized_draft
    )
    VALUES (
        v_import_id,
        v_ruleset_id,
        'test-v1',
        'normalized',
        v_test_json,
        v_test_json
    )
    RETURNING draft_id INTO v_draft_id;

    RAISE NOTICE 'Created test draft: %', v_draft_id;
END $$;

-- Test validation on the draft you just created
-- Replace the UUID below with the one from NOTICE above
SELECT * FROM zamm.validate_workout_draft(
    'YOUR_DRAFT_ID_HERE'::uuid,
    (SELECT normalized_draft FROM zamm.parse_drafts WHERE draft_id = 'YOUR_DRAFT_ID_HERE'::uuid)
);

-- Or validate and save
SELECT * FROM zamm.validate_and_save_report(
    (SELECT draft_id FROM zamm.parse_drafts ORDER BY created_at DESC LIMIT 1),
    (SELECT normalized_draft FROM zamm.parse_drafts ORDER BY created_at DESC LIMIT 1)
);

-- Check validation status
SELECT * FROM zamm.get_draft_validation_status(
    (SELECT draft_id FROM zamm.parse_drafts ORDER BY created_at DESC LIMIT 1)
);

-- ============================================
-- 3. Test Prescription vs Performance Check
-- ============================================

SELECT * FROM zamm.check_prescription_performance_consistency(
    '{
        "prescription": {
            "steps": [{"exercise_name": "Squat", "target_sets": 3, "target_reps": 5}]
        },
        "performed": {
            "did_complete": true,
            "steps": [{
                "sets": [
                    {"set_index": 1, "reps": 5},
                    {"set_index": 2, "reps": 5},
                    {"set_index": 3, "reps": 4}
                ]
            }]
        }
    }'::jsonb
);

-- ============================================
-- 4. Monitoring Queries
-- ============================================

-- View all recent validation reports
SELECT 
    vr.report_id,
    vr.is_valid,
    jsonb_array_length(vr.errors) as errors,
    jsonb_array_length(vr.warnings) as warnings,
    vr.created_at
FROM zamm.validation_reports vr
ORDER BY vr.created_at DESC
LIMIT 10;

-- View pending drafts without validation
SELECT 
    pd.draft_id,
    pd.stage,
    pd.confidence_score,
    pd.created_at,
    CASE 
        WHEN EXISTS (SELECT 1 FROM zamm.validation_reports WHERE draft_id = pd.draft_id) 
        THEN 'validated' 
        ELSE 'pending' 
    END as status
FROM zamm.parse_drafts pd
WHERE pd.approved_at IS NULL
  AND pd.rejected_at IS NULL
ORDER BY pd.created_at DESC
LIMIT 10;

-- Batch validate all pending
SELECT * FROM zamm.validate_pending_drafts();

-- ============================================
-- 5. Check Function Exists
-- ============================================

-- List all zamm functions
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'zamm' 
    AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- ============================================
-- 6. Cleanup Test Data (Optional)
-- ============================================

-- Delete test drafts
-- DELETE FROM zamm.parse_drafts WHERE parser_version = 'test-v1';

-- Delete test imports
-- DELETE FROM zamm.imports WHERE source = 'test';
