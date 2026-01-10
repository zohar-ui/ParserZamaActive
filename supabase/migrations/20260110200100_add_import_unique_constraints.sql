-- ============================================
-- Add Import Unique Constraints
-- ============================================
-- Purpose: Enforce uniqueness on import checksums to prevent duplicates
-- Part of: Idempotency implementation (2/4)
-- Date: 2026-01-10
-- Version: 1.0
-- REQUIRES: 20260110200000_backfill_import_checksums.sql

-- ============================================
-- Pre-flight Check
-- ============================================

DO $$
DECLARE
    v_null_checksums INTEGER;
    v_duplicates INTEGER;
BEGIN
    -- Check for NULL checksums
    SELECT COUNT(*) INTO v_null_checksums
    FROM zamm.imports
    WHERE checksum_sha256 IS NULL;

    IF v_null_checksums > 0 THEN
        RAISE EXCEPTION '❌ Cannot add NOT NULL constraint: % imports have NULL checksum', v_null_checksums;
    END IF;

    -- Check for unhandled duplicates (not archived)
    SELECT COUNT(*) INTO v_duplicates
    FROM (
        SELECT checksum_sha256
        FROM zamm.imports
        WHERE NOT ('duplicate_archived' = ANY(tags))
        GROUP BY checksum_sha256
        HAVING COUNT(*) > 1
    ) dupes;

    IF v_duplicates > 0 THEN
        RAISE EXCEPTION '❌ Cannot add unique constraint: % duplicate checksums found (not archived)', v_duplicates;
    END IF;

    RAISE NOTICE '✓ Pre-flight checks passed';
END $$;

-- ============================================
-- Step 1: Make checksum_sha256 NOT NULL
-- ============================================

ALTER TABLE zamm.imports
ALTER COLUMN checksum_sha256 SET NOT NULL;

-- ============================================
-- Step 2: Add unique constraint on checksum
-- ============================================

-- Global uniqueness: Same content cannot be imported twice
-- Exception: Archived duplicates are excluded via WHERE clause
ALTER TABLE zamm.imports
ADD CONSTRAINT imports_checksum_unique
UNIQUE (checksum_sha256);

-- ============================================
-- Step 3: Add partial unique index (athlete-specific)
-- ============================================

-- This allows tracking who imported what
-- Partial index: Only when athlete_id is not NULL
CREATE UNIQUE INDEX imports_athlete_checksum_unique
ON zamm.imports (athlete_id, checksum_sha256)
WHERE athlete_id IS NOT NULL
  AND NOT ('duplicate_archived' = ANY(tags));

-- ============================================
-- Step 4: Add check constraint for hash format
-- ============================================

-- Ensure checksum is valid SHA-256 hex (64 characters)
ALTER TABLE zamm.imports
ADD CONSTRAINT imports_checksum_format_check
CHECK (
    checksum_sha256 ~ '^[a-f0-9]{64}$'
);

-- ============================================
-- Step 5: Update comments
-- ============================================

COMMENT ON COLUMN zamm.imports.checksum_sha256 IS
'SHA-256 hash of raw_text (64 hex chars). Enforced NOT NULL and UNIQUE to prevent duplicate imports. Use import_raw_text_idempotent() function for safe inserts.';

COMMENT ON CONSTRAINT imports_checksum_unique ON zamm.imports IS
'Prevents importing the exact same raw_text twice. Archived duplicates excluded.';

COMMENT ON INDEX zamm.imports_athlete_checksum_unique IS
'Athlete-specific duplicate prevention. Allows tracking which athlete imported which content.';

-- ============================================
-- Verification
-- ============================================

DO $$
DECLARE
    v_constraint_exists BOOLEAN;
    v_index_exists BOOLEAN;
BEGIN
    -- Check unique constraint
    SELECT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'imports_checksum_unique'
          AND conrelid = 'zamm.imports'::regclass
    ) INTO v_constraint_exists;

    -- Check partial unique index
    SELECT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE indexname = 'imports_athlete_checksum_unique'
          AND schemaname = 'zamm'
          AND tablename = 'imports'
    ) INTO v_index_exists;

    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE 'Import Unique Constraints Applied';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE 'Constraint: imports_checksum_unique        %',
        CASE WHEN v_constraint_exists THEN '✓' ELSE '✗' END;
    RAISE NOTICE 'Index: imports_athlete_checksum_unique     %',
        CASE WHEN v_index_exists THEN '✓' ELSE '✗' END;
    RAISE NOTICE '';
    RAISE NOTICE 'Status: Imports are now idempotent at DB level';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;

-- ============================================
-- Test Query (for manual verification)
-- ============================================

-- Test: Try to insert duplicate (should fail)
-- Uncomment to test:
/*
DO $$
DECLARE
    v_test_text TEXT := 'Test workout content';
    v_test_checksum TEXT;
BEGIN
    v_test_checksum := encode(digest(v_test_text, 'sha256'), 'hex');

    -- First insert should succeed
    INSERT INTO zamm.imports (raw_text, checksum_sha256, source)
    VALUES (v_test_text, v_test_checksum, 'test');

    RAISE NOTICE '✓ First insert succeeded';

    -- Second insert should fail with unique violation
    INSERT INTO zamm.imports (raw_text, checksum_sha256, source)
    VALUES (v_test_text, v_test_checksum, 'test');

    RAISE NOTICE '✗ Second insert succeeded (SHOULD NOT HAPPEN!)';
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE '✓ Duplicate correctly blocked by constraint';
        ROLLBACK;
END $$;
*/
