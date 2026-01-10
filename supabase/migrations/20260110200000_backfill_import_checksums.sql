-- ============================================
-- Backfill Import Checksums
-- ============================================
-- Purpose: Calculate SHA-256 checksums for existing imports
-- Part of: Idempotency implementation (1/4)
-- Date: 2026-01-10
-- Version: 1.0

-- ============================================
-- Step 1: Calculate checksums for existing imports
-- ============================================

-- Update imports that don't have checksums yet
UPDATE zamm.imports
SET checksum_sha256 = encode(digest(raw_text, 'sha256'), 'hex')
WHERE checksum_sha256 IS NULL;

-- ============================================
-- Step 2: Check for duplicates (report only)
-- ============================================

-- Create temporary view to identify duplicates
CREATE TEMP VIEW duplicate_imports AS
SELECT
    checksum_sha256,
    COUNT(*) as duplicate_count,
    array_agg(import_id ORDER BY received_at) as import_ids,
    MIN(received_at) as first_received,
    MAX(received_at) as last_received
FROM zamm.imports
WHERE checksum_sha256 IS NOT NULL
GROUP BY checksum_sha256
HAVING COUNT(*) > 1;

-- Log duplicate count
DO $$
DECLARE
    v_duplicate_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_duplicate_count FROM duplicate_imports;

    IF v_duplicate_count > 0 THEN
        RAISE NOTICE '⚠  Found % duplicate import groups', v_duplicate_count;
        RAISE NOTICE 'These will need to be handled before adding unique constraint';
    ELSE
        RAISE NOTICE '✓ No duplicate imports found - safe to add unique constraint';
    END IF;
END $$;

-- ============================================
-- Step 3: Archive duplicate imports (keep oldest)
-- ============================================

-- Add 'duplicate_archived' tag to newer duplicates
UPDATE zamm.imports i
SET tags = array_append(tags, 'duplicate_archived')
WHERE i.import_id IN (
    SELECT unnest(import_ids[2:]) -- All except first (oldest)
    FROM duplicate_imports
)
AND NOT ('duplicate_archived' = ANY(i.tags)); -- Don't add tag twice

-- Log archived count
DO $$
DECLARE
    v_archived_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_archived_count
    FROM zamm.imports
    WHERE 'duplicate_archived' = ANY(tags);

    IF v_archived_count > 0 THEN
        RAISE NOTICE '✓ Archived % duplicate imports with tag', v_archived_count;
    END IF;
END $$;

-- ============================================
-- Step 4: Create index for performance
-- ============================================

-- Index on checksum for fast duplicate detection
CREATE INDEX IF NOT EXISTS idx_imports_checksum
ON zamm.imports(checksum_sha256);

-- Partial index for athlete-specific lookups
CREATE INDEX IF NOT EXISTS idx_imports_athlete_checksum
ON zamm.imports(athlete_id, checksum_sha256)
WHERE athlete_id IS NOT NULL;

-- ============================================
-- Verification
-- ============================================

-- Count total imports
DO $$
DECLARE
    v_total_imports INTEGER;
    v_with_checksum INTEGER;
    v_null_checksum INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_total_imports FROM zamm.imports;
    SELECT COUNT(*) INTO v_with_checksum FROM zamm.imports WHERE checksum_sha256 IS NOT NULL;
    SELECT COUNT(*) INTO v_null_checksum FROM zamm.imports WHERE checksum_sha256 IS NULL;

    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE 'Import Checksum Backfill Complete';
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE 'Total imports:        %', v_total_imports;
    RAISE NOTICE 'With checksum:        %', v_with_checksum;
    RAISE NOTICE 'NULL checksums:       %', v_null_checksum;

    IF v_null_checksum = 0 THEN
        RAISE NOTICE '✓ All imports have checksums';
    ELSE
        RAISE WARNING '⚠  Some imports still missing checksums';
    END IF;
    RAISE NOTICE '═══════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;

-- Add comments
COMMENT ON COLUMN zamm.imports.checksum_sha256 IS
'SHA-256 hash of raw_text. Used for duplicate detection and idempotency.';

COMMENT ON INDEX zamm.idx_imports_checksum IS
'Performance index for duplicate import detection by checksum.';

COMMENT ON INDEX zamm.idx_imports_athlete_checksum IS
'Performance index for athlete-specific duplicate detection.';
