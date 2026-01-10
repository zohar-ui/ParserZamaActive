-- ============================================
-- Expose Athlete Registration to PostgREST
-- ============================================
-- Purpose: Create wrapper function in public schema
-- Date: 2026-01-11
-- Version: 1.0

-- ============================================
-- Wrapper Function in public schema
-- ============================================

DROP FUNCTION IF EXISTS public.register_new_athlete(TEXT, TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.register_new_athlete(
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
BEGIN
    RETURN QUERY
    SELECT * FROM zamm.register_new_athlete(
        p_full_name,
        p_email,
        p_phone,
        p_gender,
        p_data_source
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.register_new_athlete IS
'Wrapper function to expose zamm.register_new_athlete to PostgREST API. Delegates to zamm schema.';

-- ============================================
-- Helper Wrapper
-- ============================================

CREATE OR REPLACE FUNCTION public.check_athlete_by_name(
    p_full_name TEXT
) RETURNS TABLE (
    found BOOLEAN,
    athlete_id UUID,
    full_name TEXT,
    email TEXT,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM zamm.check_athlete_by_name(p_full_name);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.check_athlete_by_name IS
'Wrapper function to expose zamm.check_athlete_by_name to PostgREST API.';

-- ============================================
-- Verification
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE 'Public Wrapper Functions Created';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE 'public.register_new_athlete()        ✓';
    RAISE NOTICE 'public.check_athlete_by_name()       ✓';
    RAISE NOTICE '';
    RAISE NOTICE 'Status: PostgREST API ready for athlete registration';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE '';
END;
$$;
