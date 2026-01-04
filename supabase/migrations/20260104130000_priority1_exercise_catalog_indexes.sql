-- ============================================
-- Priority 1 Improvements: Exercise Catalog + Indexes
-- ============================================
-- This migration adds the critical missing pieces

-- ============================================
-- 1. Exercise Catalog
-- ============================================

CREATE TABLE IF NOT EXISTS zamm.exercise_catalog (
    exercise_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_key TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    category TEXT NOT NULL, -- 'strength', 'olympic', 'gymnastics', 'cardio', 'mobility'
    movement_pattern TEXT, -- 'squat', 'hinge', 'push', 'pull', 'lunge', 'carry', 'rotation'
    primary_muscles TEXT[] DEFAULT '{}',
    secondary_muscles TEXT[] DEFAULT '{}',
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 5),
    equipment_required TEXT[] DEFAULT '{}',
    is_compound BOOLEAN DEFAULT true,
    is_unilateral BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    video_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_category CHECK (category IN (
        'strength', 'olympic', 'gymnastics', 'cardio', 
        'mobility', 'plyometric', 'accessory'
    ))
);

COMMENT ON TABLE zamm.exercise_catalog IS 
'Master catalog of all exercises with metadata';

COMMENT ON COLUMN zamm.exercise_catalog.exercise_key IS 
'Normalized key for programmatic use (e.g., "back_squat")';

COMMENT ON COLUMN zamm.exercise_catalog.movement_pattern IS 
'Primary movement pattern for exercise classification';

-- Exercise aliases for different names/languages
CREATE TABLE IF NOT EXISTS zamm.exercise_aliases (
    alias TEXT PRIMARY KEY,
    exercise_key TEXT NOT NULL REFERENCES zamm.exercise_catalog(exercise_key) ON DELETE CASCADE,
    locale TEXT DEFAULT 'en' NOT NULL,
    is_abbreviation BOOLEAN DEFAULT false,
    is_common BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE zamm.exercise_aliases IS 
'Alternative names for exercises (different languages, abbreviations, variations)';

-- ============================================
-- 2. Update workout_items to reference exercises
-- ============================================

ALTER TABLE zamm.workout_items
ADD COLUMN IF NOT EXISTS exercise_key TEXT REFERENCES zamm.exercise_catalog(exercise_key);

COMMENT ON COLUMN zamm.workout_items.exercise_key IS 
'Normalized reference to exercise catalog (added in v2)';

-- ============================================
-- 3. Add Performance Indexes
-- ============================================

-- Workout queries (most common)
CREATE INDEX IF NOT EXISTS idx_workouts_athlete_date 
ON zamm.workouts(athlete_id, workout_date DESC);

CREATE INDEX IF NOT EXISTS idx_workouts_date 
ON zamm.workouts(workout_date DESC);

CREATE INDEX IF NOT EXISTS idx_workouts_status_completed 
ON zamm.workouts(status) 
WHERE status = 'completed';

CREATE INDEX IF NOT EXISTS idx_workouts_draft 
ON zamm.workouts(draft_id);

-- Session queries
CREATE INDEX IF NOT EXISTS idx_sessions_workout 
ON zamm.workout_sessions(workout_id);

CREATE INDEX IF NOT EXISTS idx_sessions_date 
ON zamm.workout_sessions(date DESC);

-- Block queries
CREATE INDEX IF NOT EXISTS idx_blocks_session 
ON zamm.workout_blocks(session_id);

CREATE INDEX IF NOT EXISTS idx_blocks_type 
ON zamm.workout_blocks(block_type);

-- Item queries
CREATE INDEX IF NOT EXISTS idx_items_block 
ON zamm.workout_items(block_id);

CREATE INDEX IF NOT EXISTS idx_items_exercise 
ON zamm.workout_items(exercise_name);

CREATE INDEX IF NOT EXISTS idx_items_exercise_key 
ON zamm.workout_items(exercise_key) 
WHERE exercise_key IS NOT NULL;

-- Set results queries (heavy queries)
CREATE INDEX IF NOT EXISTS idx_set_results_item 
ON zamm.item_set_results(item_id, set_index);

CREATE INDEX IF NOT EXISTS idx_set_results_block 
ON zamm.item_set_results(block_id);

-- Block results
CREATE INDEX IF NOT EXISTS idx_block_results_block 
ON zamm.workout_block_results(block_id);

-- Athlete lookups
CREATE INDEX IF NOT EXISTS idx_athletes_name 
ON zamm.dim_athletes(full_name) 
WHERE is_current = true;

CREATE INDEX IF NOT EXISTS idx_athletes_email 
ON zamm.dim_athletes(email) 
WHERE is_current = true AND email IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_athletes_natural_id 
ON zamm.dim_athletes(athlete_natural_id) 
WHERE is_current = true;

-- Equipment lookups
CREATE INDEX IF NOT EXISTS idx_equipment_aliases_key 
ON zamm.equipment_aliases(equipment_key);

CREATE INDEX IF NOT EXISTS idx_equipment_catalog_active 
ON zamm.equipment_catalog(equipment_key) 
WHERE is_active = true;

-- Exercise lookups
CREATE INDEX IF NOT EXISTS idx_exercise_aliases_key 
ON zamm.exercise_aliases(exercise_key);

CREATE INDEX IF NOT EXISTS idx_exercise_catalog_category 
ON zamm.exercise_catalog(category) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_exercise_catalog_pattern 
ON zamm.exercise_catalog(movement_pattern) 
WHERE is_active = true;

-- Draft processing (staging)
CREATE INDEX IF NOT EXISTS idx_drafts_stage 
ON zamm.parse_drafts(stage, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_drafts_import 
ON zamm.parse_drafts(import_id);

CREATE INDEX IF NOT EXISTS idx_drafts_pending 
ON zamm.parse_drafts(created_at DESC) 
WHERE approved_at IS NULL AND rejected_at IS NULL;

-- Imports
CREATE INDEX IF NOT EXISTS idx_imports_athlete 
ON zamm.imports(athlete_id, received_at DESC);

CREATE INDEX IF NOT EXISTS idx_imports_source 
ON zamm.imports(source, received_at DESC);

-- Validation
CREATE INDEX IF NOT EXISTS idx_validation_draft 
ON zamm.validation_reports(draft_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_validation_invalid 
ON zamm.validation_reports(created_at DESC) 
WHERE is_valid = false;

-- ============================================
-- 4. AI Tool: Check Exercise Exists
-- ============================================

CREATE OR REPLACE FUNCTION zamm.check_exercise_exists(p_search_name TEXT)
RETURNS TABLE (
    exercise_key TEXT,
    display_name TEXT,
    category TEXT,
    movement_pattern TEXT,
    matched_via TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
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

COMMENT ON FUNCTION zamm.check_exercise_exists IS 
'AI Tool: Search for exercises by name or alias. Returns up to 10 matches with metadata.';

GRANT EXECUTE ON FUNCTION zamm.check_exercise_exists TO service_role;
GRANT EXECUTE ON FUNCTION zamm.check_exercise_exists TO authenticated;

-- ============================================
-- 5. Seed Common Exercises
-- ============================================

INSERT INTO zamm.exercise_catalog (
    exercise_key, display_name, category, movement_pattern, 
    primary_muscles, secondary_muscles, difficulty_level, 
    equipment_required, is_compound
) VALUES
    -- Squats
    ('back_squat', 'Back Squat', 'strength', 'squat', 
     ARRAY['quadriceps', 'glutes'], ARRAY['hamstrings', 'core'], 3, 
     ARRAY['barbell', 'rack'], true),
    ('front_squat', 'Front Squat', 'strength', 'squat',
     ARRAY['quadriceps', 'core'], ARRAY['glutes', 'upper_back'], 4,
     ARRAY['barbell', 'rack'], true),
    ('overhead_squat', 'Overhead Squat', 'olympic', 'squat',
     ARRAY['quadriceps', 'shoulders'], ARRAY['core', 'upper_back'], 5,
     ARRAY['barbell'], true),
    
    -- Deadlifts
    ('deadlift', 'Deadlift', 'strength', 'hinge',
     ARRAY['hamstrings', 'glutes', 'lower_back'], ARRAY['lats', 'traps'], 3,
     ARRAY['barbell'], true),
    ('sumo_deadlift', 'Sumo Deadlift', 'strength', 'hinge',
     ARRAY['glutes', 'hamstrings'], ARRAY['quads', 'lower_back'], 3,
     ARRAY['barbell'], true),
    
    -- Presses
    ('bench_press', 'Bench Press', 'strength', 'push',
     ARRAY['chest', 'triceps'], ARRAY['shoulders'], 2,
     ARRAY['barbell', 'bench'], true),
    ('overhead_press', 'Overhead Press', 'strength', 'push',
     ARRAY['shoulders', 'triceps'], ARRAY['upper_back', 'core'], 3,
     ARRAY['barbell'], true),
    ('push_press', 'Push Press', 'olympic', 'push',
     ARRAY['shoulders', 'legs'], ARRAY['triceps', 'core'], 3,
     ARRAY['barbell'], true),
    
    -- Pulls
    ('pull_up', 'Pull-Up', 'gymnastics', 'pull',
     ARRAY['lats', 'biceps'], ARRAY['upper_back', 'forearms'], 3,
     ARRAY['pull_up_bar'], true),
    ('row', 'Barbell Row', 'strength', 'pull',
     ARRAY['upper_back', 'lats'], ARRAY['biceps', 'lower_back'], 2,
     ARRAY['barbell'], true),
    
    -- Olympic lifts
    ('clean', 'Clean', 'olympic', 'pull',
     ARRAY['legs', 'back', 'shoulders'], ARRAY['core'], 4,
     ARRAY['barbell'], true),
    ('snatch', 'Snatch', 'olympic', 'pull',
     ARRAY['legs', 'back', 'shoulders'], ARRAY['core'], 5,
     ARRAY['barbell'], true),
    
    -- Gymnastics
    ('handstand_push_up', 'Handstand Push-Up', 'gymnastics', 'push',
     ARRAY['shoulders', 'triceps'], ARRAY['core'], 4,
     ARRAY[]::TEXT[], true),
    ('muscle_up', 'Muscle-Up', 'gymnastics', 'pull',
     ARRAY['lats', 'chest', 'triceps'], ARRAY['core'], 5,
     ARRAY['rings', 'pull_up_bar'], true)
ON CONFLICT (exercise_key) DO NOTHING;

-- Seed common aliases
INSERT INTO zamm.exercise_aliases (alias, exercise_key, locale, is_abbreviation) VALUES
    -- Squat aliases
    ('squat', 'back_squat', 'en', false),
    ('bs', 'back_squat', 'en', true),
    ('סקוואט', 'back_squat', 'he', false),
    ('fs', 'front_squat', 'en', true),
    ('ohs', 'overhead_squat', 'en', true),
    
    -- Deadlift aliases
    ('dl', 'deadlift', 'en', true),
    ('דדליפט', 'deadlift', 'he', false),
    
    -- Press aliases
    ('bp', 'bench_press', 'en', true),
    ('ohp', 'overhead_press', 'en', true),
    ('press', 'overhead_press', 'en', false),
    ('pp', 'push_press', 'en', true),
    
    -- Pull aliases
    ('pu', 'pull_up', 'en', true),
    ('pullup', 'pull_up', 'en', false),
    ('mu', 'muscle_up', 'en', true),
    ('hspu', 'handstand_push_up', 'en', true)
ON CONFLICT (alias) DO NOTHING;

-- ============================================
-- 6. Update Trigger for exercise_catalog
-- ============================================

CREATE OR REPLACE FUNCTION zamm.update_exercise_catalog_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_exercise_catalog_updated
BEFORE UPDATE ON zamm.exercise_catalog
FOR EACH ROW
EXECUTE FUNCTION zamm.update_exercise_catalog_timestamp();

-- ============================================
-- 7. Helpful Views
-- ============================================

-- View: Exercises with all aliases
CREATE OR REPLACE VIEW zamm.v_exercises_with_aliases AS
SELECT 
    ec.exercise_key,
    ec.display_name,
    ec.category,
    ec.movement_pattern,
    ARRAY_AGG(DISTINCT ea.alias) FILTER (WHERE ea.alias IS NOT NULL) as all_aliases,
    ec.primary_muscles,
    ec.is_active
FROM zamm.exercise_catalog ec
LEFT JOIN zamm.exercise_aliases ea ON ec.exercise_key = ea.exercise_key
GROUP BY ec.exercise_key, ec.display_name, ec.category, ec.movement_pattern, ec.primary_muscles, ec.is_active;

COMMENT ON VIEW zamm.v_exercises_with_aliases IS 
'Exercise catalog with all aliases aggregated for easy viewing';

-- ============================================
-- Summary
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '✅ Exercise catalog created with % exercises', 
        (SELECT COUNT(*) FROM zamm.exercise_catalog);
    RAISE NOTICE '✅ Exercise aliases created with % entries', 
        (SELECT COUNT(*) FROM zamm.exercise_aliases);
    RAISE NOTICE '✅ Performance indexes created';
    RAISE NOTICE '✅ AI tool check_exercise_exists() created';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Next steps:';
    RAISE NOTICE '1. Add more exercises to the catalog';
    RAISE NOTICE '2. Update existing workout_items with exercise_key';
    RAISE NOTICE '3. Update AI prompts to use check_exercise_exists()';
END $$;
