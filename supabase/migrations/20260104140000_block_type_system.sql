-- ============================================
-- Block Type System Enhancement
-- ============================================
-- Adds UI hints and standardizes block codes

-- ============================================
-- 1. Add UI Hint Column
-- ============================================

ALTER TABLE zamm.workout_blocks
ADD COLUMN IF NOT EXISTS ui_hint TEXT;

COMMENT ON COLUMN zamm.workout_blocks.ui_hint IS 
'UI rendering hint: how to display this block in the interface';

-- ============================================
-- 2. Block Type Catalog
-- ============================================

CREATE TABLE IF NOT EXISTS zamm.block_type_catalog (
    block_code TEXT PRIMARY KEY,
    block_type TEXT NOT NULL,
    category TEXT NOT NULL,
    result_model TEXT NOT NULL,
    ui_hint TEXT NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    sort_order INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE zamm.block_type_catalog IS 
'Master catalog of standardized block types with UI rendering hints';

-- Insert standard block types
INSERT INTO zamm.block_type_catalog (
    block_code, block_type, category, result_model, ui_hint, 
    display_name, description, icon, sort_order
) VALUES
    -- PREP (Preparation)
    ('WU', 'prep', 'preparation', 'completion', 'item_list_with_done',
     'Warm-Up', 'General warm-up and mobility prep', '🔥', 1),
    
    ('ACT', 'prep', 'preparation', 'completion', 'item_list_with_done',
     'Activation', 'Muscle activation drills', '⚡', 2),
    
    ('MOB', 'prep', 'preparation', 'completion', 'item_list_with_side_hold',
     'Mobility', 'Mobility work and stretching', '🧘', 3),
    
    -- STRENGTH (Force Production)
    ('STR', 'strength', 'strength', 'tracked_sets', 'exercise_table_with_sets',
     'Strength', 'Heavy compound lifts, max effort', '💪', 10),
    
    ('ACC', 'strength', 'strength', 'tracked_sets', 'exercise_table_compact',
     'Accessory', 'Supplemental strength work', '🔧', 11),
    
    ('HYP', 'strength', 'strength', 'tracked_sets', 'exercise_table_with_sets',
     'Hypertrophy', 'Muscle building, higher volume', '💎', 12),
    
    -- POWER (Explosive)
    ('PWR', 'power', 'power', 'tracked_sets', 'exercise_table_short_sets',
     'Power', 'Explosive movements, max velocity', '⚡', 20),
    
    ('WL', 'power', 'power', 'tracked_sets', 'exercise_table_with_attempts',
     'Weightlifting', 'Olympic lifts and derivatives', '🏋️', 21),
    
    -- SKILL (Technical)
    ('SKILL', 'skill', 'skill', 'practice_quality', 'skill_card_with_quality',
     'Skill', 'Technical skill development', '🎯', 30),
    
    ('GYM', 'skill', 'skill', 'practice_quality', 'skill_card_with_progression',
     'Gymnastics', 'Bodyweight skill progressions', '🤸', 31),
    
    -- CONDITIONING (Metabolic)
    ('METCON', 'conditioning', 'conditioning', 'scored_effort_metcon', 'score_card_central',
     'Metcon', 'Mixed-modal conditioning (AMRAP/For Time)', '🔥', 40),
    
    ('INTV', 'conditioning', 'conditioning', 'scored_effort_intervals', 'splits_table',
     'Intervals', 'High-intensity interval training', '⏱️', 41),
    
    ('SS', 'conditioning', 'conditioning', 'scored_effort_steady_state', 'summary_card_pace',
     'Steady State', 'Long-duration aerobic work', '🏃', 42),
    
    ('HYROX', 'conditioning', 'conditioning', 'scored_effort_hyrox', 'score_card_with_splits',
     'Hyrox', 'Hyrox-style workout with splits', '🏆', 43),
    
    -- RECOVERY (Cool-down)
    ('CD', 'recovery', 'recovery', 'completion', 'item_list_with_done',
     'Cool-Down', 'Post-workout cool-down', '❄️', 50),
    
    ('STRETCH', 'recovery', 'recovery', 'completion', 'stretch_list',
     'Stretching', 'Static stretching protocol', '🧘', 51),
    
    ('BREATH', 'recovery', 'recovery', 'completion', 'breath_protocol',
     'Breathwork', 'Breathing exercises and recovery', '🌬️', 52)
ON CONFLICT (block_code) DO NOTHING;

-- ============================================
-- 3. Block Code Aliases
-- ============================================

CREATE TABLE IF NOT EXISTS zamm.block_code_aliases (
    alias TEXT PRIMARY KEY,
    block_code TEXT NOT NULL REFERENCES zamm.block_type_catalog(block_code),
    locale TEXT DEFAULT 'en',
    is_common BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE zamm.block_code_aliases IS 
'Alternative names/codes for block types';

INSERT INTO zamm.block_code_aliases (alias, block_code, locale) VALUES
    -- Warmup aliases
    ('warmup', 'WU', 'en'),
    ('warm-up', 'WU', 'en'),
    ('warm_up', 'WU', 'en'),
    ('חימום', 'WU', 'he'),
    
    -- Activation aliases
    ('activation', 'ACT', 'en'),
    ('active', 'ACT', 'en'),
    ('הפעלה', 'ACT', 'he'),
    
    -- Mobility aliases
    ('mobility', 'MOB', 'en'),
    ('mob', 'MOB', 'en'),
    ('ניידות', 'MOB', 'he'),
    
    -- Strength aliases
    ('strength', 'STR', 'en'),
    ('str', 'STR', 'en'),
    ('כוח', 'STR', 'he'),
    ('a', 'STR', 'en'),  -- Common letter code
    
    -- Accessory aliases
    ('accessory', 'ACC', 'en'),
    ('acc', 'ACC', 'en'),
    ('accessories', 'ACC', 'en'),
    ('עזר', 'ACC', 'he'),
    
    -- Hypertrophy aliases
    ('hypertrophy', 'HYP', 'en'),
    ('hyp', 'HYP', 'en'),
    ('bodybuilding', 'HYP', 'en'),
    ('היפרטרופיה', 'HYP', 'he'),
    
    -- Power aliases
    ('power', 'PWR', 'en'),
    ('pwr', 'PWR', 'en'),
    ('explosive', 'PWR', 'en'),
    ('עוצמה', 'PWR', 'he'),
    
    -- Weightlifting aliases
    ('weightlifting', 'WL', 'en'),
    ('wl', 'WL', 'en'),
    ('olympic', 'WL', 'en'),
    ('oly', 'WL', 'en'),
    ('הרמת משקולות', 'WL', 'he'),
    
    -- Skill aliases
    ('skill', 'SKILL', 'en'),
    ('skills', 'SKILL', 'en'),
    ('technique', 'SKILL', 'en'),
    ('מיומנות', 'SKILL', 'he'),
    
    -- Gymnastics aliases
    ('gymnastics', 'GYM', 'en'),
    ('gym', 'GYM', 'en'),
    ('bodyweight', 'GYM', 'en'),
    ('התעמלות', 'GYM', 'he'),
    
    -- Metcon aliases
    ('metcon', 'METCON', 'en'),
    ('conditioning', 'METCON', 'en'),
    ('wod', 'METCON', 'en'),
    ('b', 'METCON', 'en'),  -- Common letter code
    ('קונדישן', 'METCON', 'he'),
    
    -- Intervals aliases
    ('intervals', 'INTV', 'en'),
    ('interval', 'INTV', 'en'),
    ('intv', 'INTV', 'en'),
    ('hiit', 'INTV', 'en'),
    ('אינטרוולים', 'INTV', 'he'),
    
    -- Steady State aliases
    ('steady_state', 'SS', 'en'),
    ('steady-state', 'SS', 'en'),
    ('ss', 'SS', 'en'),
    ('cardio', 'SS', 'en'),
    ('aerobic', 'SS', 'en'),
    ('קרדיו', 'SS', 'he'),
    
    -- Hyrox aliases
    ('hyrox', 'HYROX', 'en'),
    ('hyrox_workout', 'HYROX', 'en'),
    
    -- Cool-down aliases
    ('cooldown', 'CD', 'en'),
    ('cool-down', 'CD', 'en'),
    ('cool_down', 'CD', 'en'),
    ('קירור', 'CD', 'he'),
    
    -- Stretch aliases
    ('stretching', 'STRETCH', 'en'),
    ('stretch', 'STRETCH', 'en'),
    ('מתיחות', 'STRETCH', 'he'),
    
    -- Breath aliases
    ('breathwork', 'BREATH', 'en'),
    ('breathing', 'BREATH', 'en'),
    ('breath', 'BREATH', 'en'),
    ('נשימה', 'BREATH', 'he')
ON CONFLICT (alias) DO NOTHING;

-- ============================================
-- 4. Enhanced normalize_block_type Function
-- ============================================

CREATE OR REPLACE FUNCTION zamm.normalize_block_code(p_input TEXT)
RETURNS TABLE (
    block_code TEXT,
    block_type TEXT,
    category TEXT,
    result_model TEXT,
    ui_hint TEXT,
    display_name TEXT,
    matched_via TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_normalized TEXT;
BEGIN
    v_normalized := UPPER(TRIM(p_input));
    
    RETURN QUERY
    -- Try exact block_code match first
    SELECT 
        btc.block_code,
        btc.block_type,
        btc.category,
        btc.result_model,
        btc.ui_hint,
        btc.display_name,
        'exact'::TEXT as matched_via
    FROM zamm.block_type_catalog btc
    WHERE UPPER(btc.block_code) = v_normalized
    AND btc.is_active = true
    
    UNION ALL
    
    -- Try alias match
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
    WHERE LOWER(bca.alias) = LOWER(p_input)
    AND btc.is_active = true
    
    UNION ALL
    
    -- Try partial match on display_name
    SELECT 
        btc.block_code,
        btc.block_type,
        btc.category,
        btc.result_model,
        btc.ui_hint,
        btc.display_name,
        'partial'::TEXT as matched_via
    FROM zamm.block_type_catalog btc
    WHERE LOWER(btc.display_name) ILIKE '%' || LOWER(p_input) || '%'
    AND btc.is_active = true
    
    ORDER BY matched_via, sort_order
    LIMIT 5;
END;
$$;

COMMENT ON FUNCTION zamm.normalize_block_code IS 
'AI Tool: Normalize block code/type input to standard block_code with full metadata';

GRANT EXECUTE ON FUNCTION zamm.normalize_block_code TO service_role;
GRANT EXECUTE ON FUNCTION zamm.normalize_block_code TO authenticated;

-- ============================================
-- 5. Helper Views
-- ============================================

-- View: Complete block type reference
CREATE OR REPLACE VIEW zamm.v_block_types_reference AS
SELECT 
    btc.block_code,
    btc.block_type,
    btc.category,
    btc.result_model,
    btc.ui_hint,
    btc.display_name,
    btc.description,
    btc.icon,
    btc.sort_order,
    ARRAY_AGG(DISTINCT bca.alias) FILTER (WHERE bca.alias IS NOT NULL) as aliases
FROM zamm.block_type_catalog btc
LEFT JOIN zamm.block_code_aliases bca ON btc.block_code = bca.block_code
WHERE btc.is_active = true
GROUP BY 
    btc.block_code, btc.block_type, btc.category, btc.result_model, 
    btc.ui_hint, btc.display_name, btc.description, btc.icon, btc.sort_order
ORDER BY btc.sort_order;

COMMENT ON VIEW zamm.v_block_types_reference IS 
'Complete block type reference with aliases for UI/documentation';

-- View: Block types by category
CREATE OR REPLACE VIEW zamm.v_block_types_by_category AS
SELECT 
    category,
    ARRAY_AGG(
        jsonb_build_object(
            'code', block_code,
            'type', block_type,
            'name', display_name,
            'result_model', result_model,
            'ui_hint', ui_hint,
            'icon', icon
        ) ORDER BY sort_order
    ) as blocks
FROM zamm.block_type_catalog
WHERE is_active = true
GROUP BY category
ORDER BY MIN(sort_order);

COMMENT ON VIEW zamm.v_block_types_by_category IS 
'Block types grouped by category for UI navigation';

-- ============================================
-- 6. Update Existing Records (Optional)
-- ============================================

-- Set ui_hint for existing blocks based on block_type
UPDATE zamm.workout_blocks wb
SET ui_hint = btc.ui_hint
FROM zamm.block_type_catalog btc
WHERE wb.block_code = btc.block_code
AND wb.ui_hint IS NULL;

-- For blocks without matching block_code, infer from block_type
UPDATE zamm.workout_blocks
SET ui_hint = CASE 
    WHEN block_type = 'strength' THEN 'exercise_table_with_sets'
    WHEN block_type = 'metcon' THEN 'score_card_central'
    WHEN block_type = 'skill' THEN 'skill_card_with_quality'
    WHEN block_type IN ('warmup', 'prep') THEN 'item_list_with_done'
    WHEN block_type = 'accessory' THEN 'exercise_table_compact'
    WHEN block_type = 'recovery' THEN 'item_list_with_done'
    ELSE 'exercise_table_with_sets'
END
WHERE ui_hint IS NULL;

-- ============================================
-- 7. Validation Constraint
-- ============================================

-- Add check constraint for valid ui_hints
ALTER TABLE zamm.workout_blocks
DROP CONSTRAINT IF EXISTS chk_valid_ui_hint;

ALTER TABLE zamm.workout_blocks
ADD CONSTRAINT chk_valid_ui_hint CHECK (
    ui_hint IN (
        'item_list_with_done',
        'item_list_with_side_hold',
        'exercise_table_with_sets',
        'exercise_table_compact',
        'exercise_table_short_sets',
        'exercise_table_with_attempts',
        'skill_card_with_quality',
        'skill_card_with_progression',
        'score_card_central',
        'splits_table',
        'summary_card_pace',
        'score_card_with_splits',
        'stretch_list',
        'breath_protocol'
    )
);

-- ============================================
-- Summary
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '✅ Block type catalog created with % types', 
        (SELECT COUNT(*) FROM zamm.block_type_catalog);
    RAISE NOTICE '✅ Block code aliases created with % entries', 
        (SELECT COUNT(*) FROM zamm.block_code_aliases);
    RAISE NOTICE '✅ UI hints added to workout_blocks table';
    RAISE NOTICE '✅ normalize_block_code() function created';
    RAISE NOTICE '✅ Helper views created (v_block_types_reference, v_block_types_by_category)';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Usage:';
    RAISE NOTICE '  SELECT * FROM zamm.normalize_block_code(''strength'');';
    RAISE NOTICE '  SELECT * FROM zamm.v_block_types_reference;';
    RAISE NOTICE '  SELECT * FROM zamm.v_block_types_by_category;';
END $$;
