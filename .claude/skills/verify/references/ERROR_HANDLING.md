# Error Handling Reference

**Purpose:** Detailed error resolution guidance for verify skill
**Main Skill:** verify

---

## Stage 1: Schema Verification Errors

### Error: Connection Failed

```
❌ ERROR: Cannot connect to database
Details: connection to server at "..." failed
```

**Root Causes:**
1. Invalid `SUPABASE_DB_URL` in `.env.local`
2. Database is offline
3. Network connectivity issues
4. Invalid credentials

**Resolution Steps:**

```bash
# Step 1: Check environment variables
cat .env.local | grep SUPABASE

# Step 2: Test connection
npx supabase status

# Step 3: Re-authenticate if needed
npx supabase login

# Step 4: Verify network connectivity
ping db.dtzcamerxuonoeujrgsu.supabase.co
```

### Error: Missing Tables

```
❌ ERROR: Expected 33 tables, found 28
Missing tables: workout_blocks, workout_items, ...
```

**Root Cause:** Migrations not applied

**Resolution:**

```bash
# Check pending migrations
npx supabase db diff

# Apply migrations
npx supabase db push

# Verify table count
./scripts/verify_schema.sh
```

### Error: Wrong Schema Version

```
❌ ERROR: Schema version mismatch
Expected: v3.2
Found: v3.0
```

**Root Cause:** Database is behind current migration version

**Resolution:**

```bash
# View migration history
ls -lh supabase/migrations/

# Apply missing migrations
npx supabase db push

# Verify version
psql "$SUPABASE_DB_URL" -c "SELECT version FROM zamm.lib_parser_rulesets WHERE is_active = true;"
```

---

## Stage 2: Golden Set Validation Errors

### Error: JSON Structure Mismatch

```
❌ FAIL: workout_05.json
Expected: {"prescription": {...}, "performed": {...}}
Actual: {"sets": 3, "reps": 5}
```

**Root Cause:** Parser not following CANONICAL_JSON_SCHEMA.md v3.x format

**Resolution:**

1. Review `docs/reference/CANONICAL_JSON_SCHEMA.md`
2. Check parser prompts in `docs/guides/AI_PROMPTS.md`
3. Fix parser logic
4. Update learning examples: `npm run learn`
5. Re-run: `/verify`

### Error: Hallucinated Data

```
❌ FAIL: workout_12.json - Hallucination detected
Original text: "3x5 @ moderate weight"
Parser output: {"target_weight": {"value": 80, "unit": "kg"}}
Problem: Weight value invented (not in source text)
```

**Root Cause:** Parser inferring data instead of extracting

**Resolution:**

1. Review ZAMM principle: **Zero Inference**
2. Update parser prompt to emphasize "no guessing"
3. Fix expected JSON in `data/golden_set/workout_12_expected.json`
4. Re-run: `/verify`

**Correct Output:**
```json
{
  "target_sets": 3,
  "target_reps": 5,
  "notes": "moderate weight"
}
```

### Error: Wrong Block Code

```
❌ FAIL: workout_03.json
Expected: "STR"
Actual: "STRENGTH"
```

**Root Cause:** Parser not using normalized block codes

**Resolution:**

1. Check valid block codes: `SELECT block_code FROM zamm.lib_block_types;`
2. Update parser to use normalized codes: `WU`, `STR`, `PWR`, `METCON`, etc.
3. Use `normalize_block_code()` function in SQL
4. Re-run: `/verify`

### Error: Type Mismatch

```
❌ FAIL: workout_08.json
Field: target_reps
Expected type: number
Actual type: string
Value: "5"
```

**Root Cause:** Parser returning strings instead of numbers

**Resolution:**

Use `/fix-parser` skill to auto-correct type errors, then verify:

```bash
/fix-parser
/verify
```

Or manually fix:
1. Update parser to use numeric types
2. Fix expected JSON files
3. Re-run validation

---

## Stage 3: Block Type System Errors

### Error: Alias Not Resolved

```
❌ FAIL: Hebrew term "חימום" did not resolve to "WU"
Expected: WU
Actual: null
```

**Root Cause:** Missing alias in `lib_block_aliases` table

**Resolution:**

```sql
-- Check if alias exists
SELECT * FROM zamm.lib_block_aliases
WHERE alias = 'חימום';

-- Add missing alias
INSERT INTO zamm.lib_block_aliases (block_code, alias, locale, is_common)
VALUES ('WU', 'חימום', 'he', true);

-- Re-run test
./scripts/test_block_types.sh
```

### Error: Wrong Block Code Mapping

```
❌ FAIL: "warmup" resolved to "ACT" instead of "WU"
```

**Root Cause:** Incorrect mapping in alias table

**Resolution:**

```sql
-- Find incorrect mapping
SELECT * FROM zamm.lib_block_aliases
WHERE alias = 'warmup';

-- Fix mapping
UPDATE zamm.lib_block_aliases
SET block_code = 'WU'
WHERE alias = 'warmup';

-- Re-run test
./scripts/test_block_types.sh
```

### Error: Case Sensitivity Issue

```
❌ FAIL: "WARMUP" not resolved (case mismatch)
```

**Root Cause:** Alias lookup is case-sensitive

**Resolution:**

```sql
-- Add uppercase variant
INSERT INTO zamm.lib_block_aliases (block_code, alias, locale, is_common)
VALUES ('WU', 'WARMUP', 'en', true);

-- Or update normalize function to handle case-insensitive lookup
```

---

## Multiple Test Failures

### When Multiple Stages Fail

If 2+ test suites fail, prioritize in this order:

1. **Fix Schema First** - Database must be correct
2. **Fix Block Types** - Parser depends on valid codes
3. **Fix Golden Set** - End-to-end validation

### Example Multi-Failure Resolution

```
❌ Schema: 3 tables missing
❌ Golden Set: 5/19 tests failed
❌ Block Types: 12/60 aliases unresolved
```

**Resolution Plan:**

```bash
# Step 1: Fix schema (highest priority)
npx supabase db push
./scripts/verify_schema.sh  # Verify fix

# Step 2: Fix block types
# Add missing aliases to lib_block_aliases
./scripts/test_block_types.sh  # Verify fix

# Step 3: Fix parser issues
npm run learn
./scripts/validate_golden_set.sh  # Verify fix

# Step 4: Run full verification
/verify
```

---

## Warnings vs Errors

### Non-Critical Warnings ⚠️

Some warnings are informational and don't block commits:

```
⚠️  WARNING: Large weight detected: 250kg deadlift
⚠️  WARNING: Set 3: actual_reps (4) < target_reps (5)
```

**Action:** Review warnings, but can proceed if intentional.

### Critical Errors ❌

These MUST be fixed before committing:

```
❌ ERROR: Exercise key "unknown_exercise" not in catalog
❌ ERROR: Invalid JSON structure
❌ ERROR: Foreign key violation
```

**Action:** Cannot proceed. Fix immediately.

---

## Emergency Procedures

### Complete System Reset (Last Resort)

If verify consistently fails with unclear errors:

```bash
# 1. Save your work
git stash

# 2. Reset to known good state
git checkout main
git pull origin main

# 3. Verify clean state works
/verify

# 4. Re-apply your changes incrementally
git stash pop
# Test after each change
```

### Database Reset (Extreme Last Resort)

⚠️ **WARNING:** This deletes all data!

```bash
# Only do this on development database
npx supabase db reset

# Re-apply migrations
npx supabase db push

# Re-populate test data
npm run seed-test-data
```

---

## Prevention Best Practices

### Before Making Changes

1. Run `/verify` to establish baseline
2. Make one logical change at a time
3. Run `/verify` after each change
4. Commit frequently with passing tests

### After Making Changes

1. Run `/verify` before committing
2. Review all diffs carefully
3. Fix errors immediately
4. Don't accumulate technical debt

### Golden Set Maintenance

1. Keep expected JSON files up to date
2. Add new test cases for edge cases
3. Review parser changes against golden set
4. Run `npm run learn` after corrections

---

## Getting More Help

If errors persist:

1. Check `docs/context/agents.md` for system context
2. Review `docs/architecture/ARCHITECTURE.md` for design patterns
3. Run `/db-status` for database health
4. Use `/inspect-table` to verify schema
5. Check `supabase/migrations/` for recent changes

---

**Last Updated:** 2026-01-13
**Version:** 1.0.0
