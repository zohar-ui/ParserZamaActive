# 🔒 Idempotency Guide

**Last Updated:** 2026-01-10
**Status:** Active
**Version:** 1.0

---

## 🎯 What is Idempotency?

**Idempotency** = Performing the same operation multiple times produces the same result.

**In ZAMM:** Importing the same workout text twice should NOT create two workout records.

---

## 🚫 Problem We're Solving

### Before Idempotency

```
User uploads: "Itamar, 2025-12-11, Back Squat 5x5"

Attempt 1: ✓ Creates workout_id=UUID-A
Attempt 2: ✓ Creates workout_id=UUID-B  ← DUPLICATE!
Attempt 3: ✓ Creates workout_id=UUID-C  ← DUPLICATE!

Result: Database polluted with 3 identical workouts
```

### After Idempotency

```
User uploads: "Itamar, 2025-12-11, Back Squat 5x5"

Attempt 1: ✓ Creates workout_id=UUID-A
Attempt 2: ✓ Returns workout_id=UUID-A (same!)
Attempt 3: ✓ Returns workout_id=UUID-A (same!)

Result: Only 1 workout in database (correct!)
```

---

## 🛡️ Two-Layer Defense

### Layer 1: Import Deduplication (Stage 1)

**Location:** `zamm.imports` table

**Mechanism:**
1. Calculate SHA-256 hash of `raw_text`
2. Check if hash already exists
3. If exists → Return existing `import_id` (idempotent)
4. If new → Insert and continue

**Database Constraints:**
```sql
-- Checksum is mandatory
ALTER TABLE imports ALTER COLUMN checksum_sha256 SET NOT NULL;

-- Checksum must be unique (global)
ALTER TABLE imports ADD CONSTRAINT imports_checksum_unique
UNIQUE (checksum_sha256);
```

**Function:**
```sql
SELECT * FROM zamm.import_raw_text_idempotent(
    athlete_id := 'uuid...',
    raw_text := 'Thursday December 11, 2025...',
    source := 'manual_upload',
    source_ref := 'itamar_log.txt'
);

-- Returns:
-- import_id | is_duplicate | message              | checksum
-- uuid-123  | false        | 'New import created' | abc123...

-- Second call with SAME text:
-- uuid-123  | true         | 'Duplicate detected' | abc123...
```

### Layer 2: Workout Deduplication (Stage 4)

**Location:** `zamm.workouts` table

**Mechanism:**
1. Check for existing workout with same:
   - `athlete_id`
   - `workout_date`
   - `content_hash_ref` (from imports)
2. If exists → Return existing `workout_id` (idempotent)
3. If new → Insert and continue

**Database Constraints:**
```sql
-- Add content hash reference
ALTER TABLE workouts ADD COLUMN content_hash_ref TEXT;

-- Unique constraint on logical identity
CREATE UNIQUE INDEX workouts_athlete_date_hash_unique
ON workouts (athlete_id, workout_date, content_hash_ref)
WHERE athlete_id IS NOT NULL
  AND workout_date IS NOT NULL
  AND content_hash_ref IS NOT NULL;
```

**Function:**
```sql
SELECT * FROM zamm.commit_workout_idempotent(
    draft_id := 'uuid...',
    parsed_workout := '{"workout_date": "2025-12-11", ...}'::JSONB
);

-- Returns:
-- workout_id | is_duplicate | message
-- uuid-W1    | false        | 'New workout committed'

-- Second call with SAME athlete/date/content:
-- uuid-W1    | true         | 'Duplicate detected'
```

---

## 📋 Migration Files

### Applied in Order

1. **`20260110200000_backfill_import_checksums.sql`**
   - Calculates checksums for existing imports
   - Identifies and archives duplicates
   - Creates performance indexes

2. **`20260110200100_add_import_unique_constraints.sql`**
   - Makes `checksum_sha256` NOT NULL
   - Adds UNIQUE constraint
   - Adds check constraint for SHA-256 format

3. **`20260110200200_add_workout_idempotency.sql`**
   - Adds `content_hash_ref` column to workouts
   - Backfills from imports
   - Creates unique index on (athlete_id, workout_date, content_hash_ref)

4. **`20260110200300_create_idempotent_functions.sql`**
   - Creates `import_raw_text_idempotent()` function
   - Creates `commit_workout_idempotent()` function
   - Creates helper functions for duplicate checking

---

## 🚀 Usage

### Import Text (Idempotent)

```sql
-- First import
SELECT * FROM zamm.import_raw_text_idempotent(
    'athlete-uuid'::UUID,
    'Thursday December 11, 2025\nBack Squat 5x5 @ 100kg',
    'manual_upload',
    'itamar_workout_log.txt'
);

-- Result:
-- ┌──────────────────────────────────────┬──────────────┬─────────────────────────┬────────────────┐
-- │ import_id                            │ is_duplicate │ message                 │ checksum       │
-- ├──────────────────────────────────────┼──────────────┼─────────────────────────┼────────────────┤
-- │ 123e4567-e89b-12d3-a456-426614174000 │ false        │ New import created      │ abc123def...   │
-- └──────────────────────────────────────┴──────────────┴─────────────────────────┴────────────────┘
```

```sql
-- Second import (SAME TEXT)
SELECT * FROM zamm.import_raw_text_idempotent(
    'athlete-uuid'::UUID,
    'Thursday December 11, 2025\nBack Squat 5x5 @ 100kg',  -- IDENTICAL
    'manual_upload',
    'itamar_workout_log.txt'
);

-- Result:
-- ┌──────────────────────────────────────┬──────────────┬──────────────────────────────────────┬────────────────┐
-- │ import_id                            │ is_duplicate │ message                              │ checksum       │
-- ├──────────────────────────────────────┼──────────────┼──────────────────────────────────────┼────────────────┤
-- │ 123e4567-e89b-12d3-a456-426614174000 │ true         │ Duplicate import detected. Returning │ abc123def...   │
-- │                                      │              │ existing import from 2026-01-10...   │                │
-- └──────────────────────────────────────┴──────────────┴──────────────────────────────────────┴────────────────┘
--   ↑ SAME import_id!
```

### Commit Workout (Idempotent)

```sql
-- First commit
SELECT * FROM zamm.commit_workout_idempotent(
    'draft-uuid'::UUID,
    '{"workout_date": "2025-12-11", "athlete_id": "...", "title": "Strength"}'::JSONB
);

-- Result:
-- ┌──────────────────────────────────────┬──────────────┬───────────────────────────┐
-- │ workout_id                           │ is_duplicate │ message                   │
-- ├──────────────────────────────────────┼──────────────┼───────────────────────────┤
-- │ 987f6543-e21c-45d6-b789-123456789abc │ false        │ New workout committed     │
-- └──────────────────────────────────────┴──────────────┴───────────────────────────┘
```

```sql
-- Second commit (SAME ATHLETE/DATE/CONTENT)
SELECT * FROM zamm.commit_workout_idempotent(
    'draft-uuid'::UUID,
    '{"workout_date": "2025-12-11", "athlete_id": "...", ...}'::JSONB
);

-- Result:
-- ┌──────────────────────────────────────┬──────────────┬─────────────────────────────────────┐
-- │ workout_id                           │ is_duplicate │ message                             │
-- ├──────────────────────────────────────┼──────────────┼─────────────────────────────────────┤
-- │ 987f6543-e21c-45d6-b789-123456789abc │ true         │ Duplicate workout detected. Same    │
-- │                                      │              │ athlete/date/content already exists │
-- └──────────────────────────────────────┴──────────────┴─────────────────────────────────────┘
--   ↑ SAME workout_id!
```

### Check for Duplicates (Before Import)

```sql
-- Calculate hash
SELECT encode(digest('my workout text', 'sha256'), 'hex') as checksum;

-- Check if exists
SELECT * FROM zamm.check_import_duplicate('abc123def...');

-- Result:
-- ┌────────┬─────────────────┬──────────────────────┬─────────────┬───────────────┐
-- │ exists │ import_id       │ received_at          │ athlete_id  │ source        │
-- ├────────┼─────────────────┼──────────────────────┼─────────────┼───────────────┤
-- │ true   │ uuid-123        │ 2026-01-10 10:30:00  │ uuid-athlete│ manual_upload │
-- └────────┴─────────────────┴──────────────────────┴─────────────┴───────────────┘
```

---

## 🧪 Test Scenarios

### Test 1: Exact Duplicate Text

```sql
-- Import same text twice
DO $$
DECLARE
    v_result1 RECORD;
    v_result2 RECORD;
BEGIN
    -- First import
    SELECT * INTO v_result1
    FROM zamm.import_raw_text_idempotent(
        'athlete-1'::UUID,
        'Test Workout A',
        'test'
    );

    -- Second import (identical text)
    SELECT * INTO v_result2
    FROM zamm.import_raw_text_idempotent(
        'athlete-1'::UUID,
        'Test Workout A',
        'test'
    );

    -- Assertions
    ASSERT v_result1.is_duplicate = false, 'First import should not be duplicate';
    ASSERT v_result2.is_duplicate = true, 'Second import should be duplicate';
    ASSERT v_result1.import_id = v_result2.import_id, 'Should return same import_id';

    RAISE NOTICE '✓ Test 1 passed: Exact duplicate correctly detected';
END $$;
```

### Test 2: Same Content, Different Athlete

```sql
-- Different athletes can import same text
DO $$
DECLARE
    v_result1 RECORD;
    v_result2 RECORD;
BEGIN
    SELECT * INTO v_result1
    FROM zamm.import_raw_text_idempotent(
        'athlete-1'::UUID,
        'Shared Workout Template',
        'test'
    );

    SELECT * INTO v_result2
    FROM zamm.import_raw_text_idempotent(
        'athlete-2'::UUID,  -- DIFFERENT ATHLETE
        'Shared Workout Template',
        'test'
    );

    -- Both should succeed (different athletes)
    ASSERT v_result1.is_duplicate = false, 'Athlete 1 first import';
    ASSERT v_result2.is_duplicate = false, 'Athlete 2 first import';
    ASSERT v_result1.import_id != v_result2.import_id, 'Should have different import_ids';

    RAISE NOTICE '✓ Test 2 passed: Different athletes can have same content';
END $$;
```

### Test 3: Same Day, Different Workout

```sql
-- Athlete can have multiple workouts same day
DO $$
DECLARE
    v_workout1 UUID;
    v_workout2 UUID;
BEGIN
    -- Morning workout
    INSERT INTO zamm.workouts (athlete_id, workout_date, content_hash_ref, session_title)
    VALUES ('athlete-1', '2026-01-10', 'hash-morning', 'AM Strength')
    RETURNING workout_id INTO v_workout1;

    -- Evening workout (different content)
    INSERT INTO zamm.workouts (athlete_id, workout_date, content_hash_ref, session_title)
    VALUES ('athlete-1', '2026-01-10', 'hash-evening', 'PM Conditioning')
    RETURNING workout_id INTO v_workout2;

    ASSERT v_workout1 != v_workout2, 'Different workouts should have different IDs';

    RAISE NOTICE '✓ Test 3 passed: Multiple workouts same day allowed';
END $$;
```

### Test 4: Whitespace Normalization

```sql
-- Whitespace differences should be normalized
DO $$
DECLARE
    v_result1 RECORD;
    v_result2 RECORD;
BEGIN
    -- With single space
    SELECT * INTO v_result1
    FROM zamm.import_raw_text_idempotent(
        'athlete-1'::UUID,
        'Workout A',
        'test'
    );

    -- With double space (should normalize to single)
    SELECT * INTO v_result2
    FROM zamm.import_raw_text_idempotent(
        'athlete-1'::UUID,
        'Workout  A',  -- DOUBLE SPACE
        'test'
    );

    ASSERT v_result2.is_duplicate = true, 'Whitespace differences should be normalized';
    ASSERT v_result1.import_id = v_result2.import_id, 'Should return same import_id';

    RAISE NOTICE '✓ Test 4 passed: Whitespace normalized correctly';
END $$;
```

---

## 📊 Monitoring & Debugging

### Check for Duplicates in Production

```sql
-- Find imports with duplicate checksums
SELECT
    checksum_sha256,
    COUNT(*) as duplicate_count,
    array_agg(import_id ORDER BY received_at) as import_ids,
    MIN(received_at) as first_import,
    MAX(received_at) as last_import
FROM zamm.imports
WHERE NOT ('duplicate_archived' = ANY(tags))
GROUP BY checksum_sha256
HAVING COUNT(*) > 1;
```

```sql
-- Find workouts with duplicate athlete/date/content
SELECT * FROM zamm.v_potential_duplicate_workouts;
```

### Verify Idempotency Coverage

```sql
-- Imports without checksums (should be 0)
SELECT COUNT(*) as imports_missing_checksum
FROM zamm.imports
WHERE checksum_sha256 IS NULL;

-- Workouts without content_hash_ref
SELECT COUNT(*) as workouts_missing_hash
FROM zamm.workouts
WHERE content_hash_ref IS NULL;
```

### Performance Impact

```sql
-- Check index usage
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'zamm'
  AND indexname LIKE '%checksum%'
ORDER BY idx_scan DESC;
```

---

## 🚨 Edge Cases

### 1. Manual Corrections

**Scenario:** User imports, finds typo, corrects and re-imports

**Behavior:**
- Different text → Different hash → New import ✅
- Original import preserved (audit trail)

### 2. Partial Imports

**Scenario:** Day 1: "Workout A", Day 2: "Workout A + Workout B"

**Behavior:**
- Different content → Different hash → Both allowed ✅

### 3. Re-processing Failed Imports

**Scenario:** Import failed validation, user retries

**Behavior:**
- Same text → Same import_id returned
- User can create new draft from same import
- Draft table allows multiple drafts per import ✅

### 4. Archived Duplicates

**Scenario:** Historical duplicates exist before migration

**Behavior:**
- Tagged with `'duplicate_archived'`
- Excluded from unique constraint
- Preserved for audit trail

---

## 📚 Related Documentation

- [IDEMPOTENCY_DESIGN.md](../architecture/IDEMPOTENCY_DESIGN.md) - Full design document
- [ARCHITECTURE.md](../architecture/ARCHITECTURE.md) - 4-stage pipeline
- [VALIDATION_SYSTEM_SUMMARY.md](../VALIDATION_SYSTEM_SUMMARY.md) - Stage 3 validation

---

## ✅ Success Criteria

After implementation, verify:

- [ ] Same text twice → Same `import_id` returned
- [ ] Same workout twice → Same `workout_id` returned
- [ ] Different workouts same day → Both allowed
- [ ] `is_duplicate` flag accurately reported
- [ ] No performance degradation (< 100ms overhead)
- [ ] Zero duplicate imports in production DB
- [ ] Zero duplicate workouts for same athlete/date/content

---

**Status:** ✅ Idempotency System Active
**Last Migration:** 20260110200300
**Next Review:** 2026-02-10
