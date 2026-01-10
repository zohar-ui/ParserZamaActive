-- ============================================
-- Add Workout Idempotency
-- ============================================
-- Purpose: Add content hash reference to workouts and prevent duplicate commits
-- Part of: Idempotency implementation (3/4)
-- Date: 2026-01-10
-- Version: 1.0

-- ============================================
-- Step 1: Add content_hash_ref column
-- ============================================

ALTER TABLE zamm.workouts
ADD COLUMN content_hash_ref TEXT;


-- ============================================
-- Step 2: Backfill existing workouts
-- ============================================

-- Populate content_hash_ref from linked imports
UPDATE zamm.workouts w
SET content_hash_ref = i.checksum_sha256
FROM zamm.imports i
WHERE w.import_id = i.import_id
  AND w.content_hash_ref IS NULL;

-- Log backfill results
DO $$
DECLARE
    v_total_workouts INTEGER;
    v_with_hash INTEGER;
    v_null_hash INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_total_workouts FROM zamm.workouts;
    SELECT COUNT(*) INTO v_with_hash FROM zamm.workouts WHERE content_hash_ref IS NOT NULL;
    SELECT COUNT(*) INTO v_null_hash FROM zamm.workouts WHERE content_hash_ref IS NULL;

    RAISE NOTICE '✓ Backfilled % workouts with content hash', v_with_hash;

    IF v_null_hash > 0 THEN
        RAISE NOTICE '⚠  % workouts still missing content_hash_ref (orphaned imports?)', v_null_hash;
    END IF;
END $$;

-- ============================================
-- Step 3: Add unique constraint (business logic dedup)
-- ============================================

-- Prevent same athlete from having duplicate workouts on same date with same content
-- Partial index: Only enforced when all components are present
CREATE UNIQUE INDEX workouts_athlete_date_hash_unique
ON zamm.workouts (athlete_id, workout_date, content_hash_ref)
WHERE athlete_id IS NOT NULL
  AND workout_date IS NOT NULL
  AND content_hash_ref IS NOT NULL;


-- ============================================
-- Step 4: Add performance indexes
-- ============================================

-- Index for lookup by content hash
CREATE INDEX IF NOT EXISTS idx_workouts_content_hash
ON zamm.workouts(content_hash_ref)
WHERE content_hash_ref IS NOT NULL;


-- Composite index for common query pattern (athlete + date)
CREATE INDEX IF NOT EXISTS idx_workouts_athlete_date
ON zamm.workouts(athlete_id, workout_date)
WHERE athlete_id IS NOT NULL AND workout_date IS NOT NULL;


-- ============================================
-- Step 5: Add check constraint for hash format
-- ============================================

-- Ensure content_hash_ref matches SHA-256 format if present
ALTER TABLE zamm.workouts
ADD CONSTRAINT workouts_hash_format_check
CHECK (
    content_hash_ref IS NULL OR
    content_hash_ref ~ '^[a-f0-9]{64}$'
);


-- ============================================
-- Step 6: Update comments
-- ============================================

COMMENT ON COLUMN zamm.workouts.content_hash_ref IS
'Reference to imports.checksum_sha256. Prevents duplicate workouts from same source content. Combined with athlete_id + workout_date for uniqueness.';

COMMENT ON INDEX zamm.workouts_athlete_date_hash_unique IS
'Business logic deduplication: Prevents same athlete from having duplicate workouts (same date + same content hash).';

COMMENT ON INDEX zamm.idx_workouts_content_hash IS
'Performance index for finding workouts by source content hash.';

COMMENT ON INDEX zamm.idx_workouts_athlete_date IS
'Performance index for common query: find all workouts for athlete on specific date.';

-- ============================================
-- Step 7: Create helper view for duplicate detection
-- ============================================

CREATE OR REPLACE VIEW zamm.v_potential_duplicate_workouts AS
SELECT
    w1.workout_id as workout_id_1,
    w2.workout_id as workout_id_2,
    w1.athlete_id,
    w1.workout_date,
    w1.content_hash_ref,
    w1.session_title as title_1,
    w2.session_title as title_2,
    w1.created_at as created_1,
    w2.created_at as created_2
FROM zamm.workouts w1
JOIN zamm.workouts w2
    ON w1.athlete_id = w2.athlete_id
    AND w1.workout_date = w2.workout_date
    AND w1.content_hash_ref = w2.content_hash_ref
    AND w1.workout_id < w2.workout_id  -- Avoid double-counting
WHERE w1.athlete_id IS NOT NULL
  AND w1.workout_date IS NOT NULL
  AND w1.content_hash_ref IS NOT NULL;

COMMENT ON VIEW zamm.v_potential_duplicate_workouts IS
'Helper view to identify potential duplicate workouts (same athlete/date/content). Should be empty after migration.';

-- ============================================
-- Verification
-- ============================================

DO $$
DECLARE
    v_index_exists BOOLEAN;
    v_duplicate_count INTEGER;
BEGIN
    -- Check unique index
    SELECT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE indexname = 'workouts_athlete_date_hash_unique'
          AND schemaname = 'zamm'
          AND tablename = 'workouts'
    ) INTO v_index_exists;

    -- Check for existing duplicates
    SELECT COUNT(*) INTO v_duplicate_count
    FROM zamm.v_potential_duplicate_workouts;

    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE 'Workout Idempotency Applied';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE 'Index: workouts_athlete_date_hash_unique   %',
        CASE WHEN v_index_exists THEN '✓' ELSE '✗' END;
    RAISE NOTICE 'Potential duplicates found:                %', v_duplicate_count;

    IF v_duplicate_count > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '⚠  Warning: Found % potential duplicates', v_duplicate_count;
        RAISE NOTICE 'Query: SELECT * FROM zamm.v_potential_duplicate_workouts;';
    ELSE
        RAISE NOTICE '✓ No duplicate workouts detected';
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE 'Status: Workouts are now idempotent at DB level';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;

-- ============================================
-- Test Query (for manual verification)
-- ============================================

-- Test: Try to insert duplicate workout (should fail after function impl)
-- Query to find all workouts with same content:
/*
SELECT
    w.workout_id,
    w.athlete_id,
    w.workout_date,
    w.content_hash_ref,
    w.session_title,
    w.created_at,
    COUNT(*) OVER (
        PARTITION BY w.athlete_id, w.workout_date, w.content_hash_ref
    ) as duplicate_count
FROM zamm.workouts w
WHERE w.athlete_id IS NOT NULL
  AND w.workout_date IS NOT NULL
  AND w.content_hash_ref IS NOT NULL
ORDER BY duplicate_count DESC, w.workout_date DESC;
*/
