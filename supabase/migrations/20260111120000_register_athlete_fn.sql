-- ============================================
-- Register Athlete Function (Idempotent)
-- ============================================
-- Purpose: Safe, idempotent athlete registration
-- Date: 2026-01-11
-- Version: 1.0

-- ============================================
-- Function: register_new_athlete()
-- ============================================

DROP FUNCTION IF EXISTS zamm.register_new_athlete(TEXT, TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION zamm.register_new_athlete(
    p_full_name TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_gender TEXT DEFAULT 'unknown',
    p_data_source TEXT DEFAULT 'manual_registration'
) RETURNS TABLE (
    result_athlete_id UUID,
    is_new BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_normalized_name TEXT;
    v_existing_athlete_id UUID;
    v_new_athlete_id UUID;
BEGIN
    -- Validate input
    IF p_full_name IS NULL OR trim(p_full_name) = '' THEN
        RAISE EXCEPTION 'full_name cannot be NULL or empty';
    END IF;

    -- Normalize name: trim and lowercase for comparison
    v_normalized_name := lower(trim(p_full_name));

    -- Check if athlete already exists (case-insensitive, active records only)
    SELECT
        athlete_id
    INTO
        v_existing_athlete_id
    FROM zamm.lib_athletes
    WHERE lower(trim(full_name)) = v_normalized_name
      AND is_active = true
    LIMIT 1;

    -- If exists, return existing athlete (IDEMPOTENT)
    IF v_existing_athlete_id IS NOT NULL THEN
        RETURN QUERY
        SELECT
            v_existing_athlete_id,
            false,  -- is_new
            format(
                'Athlete already exists: "%s" (ID: %s)',
                p_full_name,
                v_existing_athlete_id
            );
        RETURN;
    END IF;

    -- Create new athlete
    INSERT INTO zamm.lib_athletes (
        full_name,
        email,
        phone,
        gender,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        trim(p_full_name),  -- Store with proper capitalization
        NULLIF(trim(p_email), ''),
        NULLIF(trim(p_phone), ''),
        CASE 
            WHEN lower(trim(p_gender)) = 'male' THEN 'M'
            WHEN lower(trim(p_gender)) = 'female' THEN 'F'
            WHEN lower(trim(p_gender)) = 'other' THEN 'O'
            ELSE 'N'
        END,
        true,
        now(),
        now()
    ) RETURNING athlete_id INTO v_new_athlete_id;

    -- Return new athlete
    RETURN QUERY
    SELECT
        v_new_athlete_id,
        true,  -- is_new
        format(
            'New athlete registered: "%s" (ID: %s)',
            p_full_name,
            v_new_athlete_id
        );

END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION zamm.register_new_athlete IS
'Idempotent athlete registration. Checks for existing athlete (case-insensitive name match) before inserting. Returns existing athlete_id if duplicate detected.';

-- ============================================
-- Helper Function: check_athlete_by_name()
-- ============================================

CREATE OR REPLACE FUNCTION zamm.check_athlete_by_name(
    p_full_name TEXT
) RETURNS TABLE (
    found BOOLEAN,
    athlete_id UUID,
    full_name TEXT,
    email TEXT,
    is_active BOOLEAN
) AS $$
DECLARE
    v_normalized_name TEXT;
BEGIN
    -- Normalize input
    v_normalized_name := lower(trim(p_full_name));

    RETURN QUERY
    SELECT
        true,
        a.athlete_id,
        a.full_name,
        a.email,
        a.is_active
    FROM zamm.lib_athletes a
    WHERE lower(trim(a.full_name)) = v_normalized_name
      AND a.is_active = true
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN QUERY
        SELECT false, NULL::UUID, NULL::TEXT, NULL::TEXT, NULL::BOOLEAN;
    END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION zamm.check_athlete_by_name IS
'Helper function to check if an athlete with given name already exists (case-insensitive). Returns athlete details if found.';

-- ============================================
-- Verification
-- ============================================

DO $$
DECLARE
    v_register_func_exists BOOLEAN;
    v_check_func_exists BOOLEAN;
BEGIN
    -- Check if functions exist
    SELECT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'zamm'
          AND p.proname = 'register_new_athlete'
    ) INTO v_register_func_exists;

    SELECT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'zamm'
          AND p.proname = 'check_athlete_by_name'
    ) INTO v_check_func_exists;

    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE 'Athlete Registration Functions Created';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE 'register_new_athlete()                 %',
        CASE WHEN v_register_func_exists THEN '✓' ELSE '✗' END;
    RAISE NOTICE 'check_athlete_by_name()                %',
        CASE WHEN v_check_func_exists THEN '✓' ELSE '✗' END;
    RAISE NOTICE '';
    RAISE NOTICE 'Status: Athlete registration system ready';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;

-- ============================================
-- Usage Examples (for documentation)
-- ============================================

/*
-- Example 1: Register new athlete (first time)
SELECT * FROM zamm.register_new_athlete('John Doe', 'john@example.com');
-- Returns: (uuid-123, true, 'New athlete registered: "John Doe"...')

-- Example 2: Register same athlete again
SELECT * FROM zamm.register_new_athlete('John Doe');
-- Returns: (uuid-123, false, 'Athlete already exists: "John Doe"...')
-- ↑ Same athlete_id returned!

-- Example 3: Register with different capitalization (should detect duplicate)
SELECT * FROM zamm.register_new_athlete('JOHN DOE');
-- Returns: (uuid-123, false, 'Athlete already exists...')
-- ↑ Case-insensitive match works!

-- Example 4: Check if athlete exists before registering
SELECT * FROM zamm.check_athlete_by_name('John Doe');
-- Returns: (true, uuid-123, 1, 'John Doe', 'john@example.com', true)

-- Example 5: Register with phone and gender
SELECT * FROM zamm.register_new_athlete(
    'Jane Smith',
    'jane@example.com',
    '+1-555-0123',
    'female'
);
*/
