-- ==================================================
-- DEMONSTRATION: Active Learning System
-- ==================================================
-- This demonstrates how the parser learns from corrections

-- Step 1: Insert a high-priority learning example
INSERT INTO zamm.log_learning_examples (
    original_text,
    original_json,
    corrected_json,
    error_type,
    error_location,
    error_description,
    correction_notes,
    learning_priority,
    tags,
    is_included_in_training
) VALUES (
    -- Original workout text
    E'Block C - Landmine Press Half Kneeling: 3×8/side @ RPE 5.5-6, Tempo 3-0-2-0, Rest 1.5 min\n\nPerformance Notes:\nRight shoulder hurt 5/10 in set 1. Left rear shoulder pain on lowering. Bar only (20kg).',
    
    -- WRONG parsing (what the parser initially produced)
    '{
        "block_code": "STR",
        "block_label": "C",
        "block_title": "Landmine Press Half Kneeling",
        "prescription": {
            "target_sets": 3,
            "target_reps": 8,
            "target_tempo": "3-0-2-0"
        },
        "performed": {
            "actual_weight_kg": 20,
            "notes": "Right shoulder hurt 5/10"
        },
        "items": [{
            "exercise_name": "Landmine Press",
            "prescription": {
                "target_sets": 3,
                "target_reps": 8,
                "target_tempo": "3-0-2-0"
            },
            "performed": {
                "actual_weight_kg": 20
            }
        }]
    }'::jsonb,
    
    -- CORRECT parsing (after human correction)
    '{
        "block_code": "STR",
        "block_label": "C",
        "block_title": "Landmine Press Half Kneeling",
        "prescription": {
            "description": "Landmine Press Half Kneeling: 3×8/side @ RPE 5.5-6, Tempo 3-0-2-0, Rest 1.5 min"
        },
        "performed": {
            "actual_sets": 3,
            "actual_reps": 8,
            "actual_sets_per_side": 1,
            "actual_weight": {
                "value": 20,
                "unit": "kg"
            },
            "notes": "Right shoulder hurt 5/10 in set 1. Left rear shoulder pain on lowering. Bar only (20kg)."
        },
        "items": [{
            "item_sequence": 1,
            "exercise_name": "Landmine Press",
            "equipment_key": "barbell",
            "prescription": {
                "target_sets": 3,
                "target_reps": 8,
                "target_sets_per_side": 1,
                "target_rpe_min": 5.5,
                "target_rpe_max": 6,
                "target_tempo": "3-0-2-0",
                "target_rest_sec": 90,
                "equipment": "barbell",
                "position": "half_kneeling"
            },
            "performed": {
                "actual_weight": {
                    "value": 20,
                    "unit": "kg"
                }
            }
        }]
    }'::jsonb,
    
    -- Error metadata
    'incomplete_prescription_parsing',
    'block.prescription + items[].prescription',
    'Parser missed critical prescription fields: RPE range, rest time, and sets_per_side structure',
    'CRITICAL ERROR: Parser created incomplete prescription at both block and item levels.

**The Complete Prescription Rule:**
Every prescription field from the original text MUST be captured. Missing fields = lost information.

**What went wrong:**
1. Block level: Put parsed fields instead of keeping description string
2. Item level: Missing target_rpe_min and target_rpe_max (text says "@ RPE 5.5-6")
3. Item level: Missing target_rest_sec (text says "Rest 1.5 min" = 90 seconds)
4. Item level: Missing target_sets_per_side clarification
5. Ambiguous structure: "3×8/side" means 3 sets total, each set is unilateral (both sides)

**The "/side" notation:**
- "3×8/side" = 3 sets, 8 reps per side, meaning each set includes both sides
- target_sets = 3 (total sets)
- target_reps = 8 (per side)
- target_sets_per_side = 1 (each set covers one side at a time, alternating)
- Total volume = 3 sets × 8 reps × 2 sides = 48 reps

**RPE Ranges (Principle #3):**
- "@ RPE 5.5-6" must be: target_rpe_min: 5.5, target_rpe_max: 6
- NEVER: target_rpe: "5.5-6" (string ranges forbidden!)

**Rest Periods:**
- "Rest 1.5 min" must be: target_rest_sec: 90
- Always convert to seconds for consistency

**Why this matters:**
Incomplete prescriptions break analytics. We cannot track program adherence, intensity progression, or rest adequacy without ALL prescribed parameters. Every number in the original text must appear in the JSON.',
    
    9,  -- High priority
    ARRAY['incomplete_prescription', 'rpe_ranges', 'rest_periods', 'unilateral_structure', 'canonical_schema'],
    false  -- Not yet included in training
)
ON CONFLICT DO NOTHING
RETURNING 
    example_id,
    error_type,
    learning_priority,
    created_at;

-- Step 2: Check how many untrained examples exist
SELECT 
    COUNT(*) as untrained_examples,
    MAX(learning_priority) as highest_priority,
    ARRAY_AGG(DISTINCT error_type) as error_types
FROM zamm.log_learning_examples
WHERE is_included_in_training = false
  AND learning_priority >= 7;
