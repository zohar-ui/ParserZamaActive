-- ============================================
-- AI Tools for n8n Agent
-- ============================================
-- These functions serve as SQL Tools that the AI Agent can call
-- to query the database for context during parsing

-- ============================================
-- Tool 1: Check if Athlete Exists
-- ============================================
-- Purpose: Search for an athlete by name and return their ID
-- Usage: AI can call this when it finds a name in the text
CREATE OR REPLACE FUNCTION zamm.check_athlete_exists(p_search_name TEXT)
RETURNS TABLE (
    athlete_id UUID,
    full_name VARCHAR(100),
    email VARCHAR(255),
    current_weight_kg NUMERIC(5,2),
    gender VARCHAR(20)
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        da.athlete_natural_id as athlete_id,
        da.full_name,
        da.email,
        da.current_weight_kg,
        da.gender
    FROM zamm.dim_athletes da
    WHERE 
        da.is_current = true
        AND (
            da.full_name ILIKE '%' || p_search_name || '%'
            OR da.email ILIKE '%' || p_search_name || '%'
        )
    ORDER BY 
        -- Exact match first
        CASE WHEN LOWER(da.full_name) = LOWER(p_search_name) THEN 0 ELSE 1 END,
        da.full_name
    LIMIT 5;
END;
$$;

COMMENT ON FUNCTION zamm.check_athlete_exists IS 
'AI Tool: Search for athletes by name or email. Returns up to 5 matches ordered by relevance.';

-- ============================================
-- Tool 2: Check Equipment Exists
-- ============================================
-- Purpose: Search for equipment by name (including aliases)
-- Usage: AI can validate equipment mentioned in workout text
CREATE OR REPLACE FUNCTION zamm.check_equipment_exists(p_search_name TEXT)
RETURNS TABLE (
    equipment_key TEXT,
    display_name TEXT,
    category TEXT,
    matched_via TEXT  -- Shows if matched by main name or alias
)
LANGUAGE plpgsql
SECURITY DEFINER
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
    FROM zamm.equipment_catalog ec
    LEFT JOIN zamm.equipment_aliases ea ON ec.equipment_key = ea.equipment_key
    WHERE 
        ec.is_active = true
        AND (
            ec.display_name ILIKE '%' || p_search_name || '%'
            OR ec.equipment_key ILIKE '%' || p_search_name || '%'
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

COMMENT ON FUNCTION zamm.check_equipment_exists IS 
'AI Tool: Search for equipment by name or alias. Returns up to 10 matches with category info.';

-- ============================================
-- Tool 3: Get Active Ruleset
-- ============================================
-- Purpose: Fetch the active parser ruleset for unit conversion and mapping rules
-- Usage: AI calls this once per parsing session to understand rules
CREATE OR REPLACE FUNCTION zamm.get_active_ruleset()
RETURNS TABLE (
    ruleset_id UUID,
    ruleset_name TEXT,
    version TEXT,
    units_catalog JSONB,
    parser_mapping_rules JSONB,
    value_unit_schema JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
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
    FROM zamm.parser_rulesets pr
    WHERE pr.is_active = true
    LIMIT 1;
END;
$$;

COMMENT ON FUNCTION zamm.get_active_ruleset IS 
'AI Tool: Get the currently active parser ruleset with all conversion rules and schemas.';

-- ============================================
-- Tool 4: Get Athlete Full Context
-- ============================================
-- Purpose: Get comprehensive athlete info for personalized parsing
-- Usage: Once athlete is identified, get full context for the session
CREATE OR REPLACE FUNCTION zamm.get_athlete_context(p_athlete_id UUID)
RETURNS TABLE (
    athlete_id UUID,
    full_name VARCHAR(100),
    gender VARCHAR(20),
    age_years INTEGER,
    height_cm INTEGER,
    current_weight_kg NUMERIC(5,2),
    recent_workouts_count BIGINT,
    last_workout_date DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
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
    FROM zamm.dim_athletes da
    LEFT JOIN zamm.workouts w ON da.athlete_natural_id = w.athlete_id
        AND w.workout_date >= CURRENT_DATE - INTERVAL '30 days'
    WHERE 
        da.athlete_natural_id = p_athlete_id
        AND da.is_current = true
    GROUP BY 
        da.athlete_natural_id, da.full_name, da.gender, 
        da.date_of_birth, da.height_cm, da.current_weight_kg;
END;
$$;

COMMENT ON FUNCTION zamm.get_athlete_context IS 
'AI Tool: Get comprehensive context for an athlete including recent activity stats.';

-- ============================================
-- Tool 5: Normalize Block Type
-- ============================================
-- Purpose: Validate and normalize block type names
-- Usage: AI can check if a block type it detected is valid
CREATE OR REPLACE FUNCTION zamm.normalize_block_type(p_block_type TEXT)
RETURNS TABLE (
    is_valid BOOLEAN,
    normalized_type TEXT,
    suggested_structure TEXT,
    common_patterns TEXT[]
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_normalized TEXT;
    v_valid BOOLEAN := false;
BEGIN
    -- Normalize the input (lowercase, trim)
    v_normalized := LOWER(TRIM(p_block_type));
    
    -- Check against known patterns
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

COMMENT ON FUNCTION zamm.normalize_block_type IS 
'AI Tool: Validate and normalize block type names to standard values.';

-- ============================================
-- Grant permissions (adjust as needed)
-- ============================================
-- For service_role (n8n typically uses this)
GRANT EXECUTE ON FUNCTION zamm.check_athlete_exists TO service_role;
GRANT EXECUTE ON FUNCTION zamm.check_equipment_exists TO service_role;
GRANT EXECUTE ON FUNCTION zamm.get_active_ruleset TO service_role;
GRANT EXECUTE ON FUNCTION zamm.get_athlete_context TO service_role;
GRANT EXECUTE ON FUNCTION zamm.normalize_block_type TO service_role;

-- For authenticated users (if needed)
GRANT EXECUTE ON FUNCTION zamm.check_athlete_exists TO authenticated;
GRANT EXECUTE ON FUNCTION zamm.check_equipment_exists TO authenticated;
GRANT EXECUTE ON FUNCTION zamm.get_active_ruleset TO authenticated;
GRANT EXECUTE ON FUNCTION zamm.get_athlete_context TO authenticated;
GRANT EXECUTE ON FUNCTION zamm.normalize_block_type TO authenticated;
