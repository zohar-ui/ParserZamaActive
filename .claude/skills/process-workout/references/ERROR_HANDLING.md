# Error Handling Reference

**Purpose:** Comprehensive error resolution for process-workout pipeline
**Main Skill:** process-workout

---

## Stage 1: Ingestion Errors

### Athlete Not Found

```
❌ Error: Athlete "John Doe" not found in database

Suggestions:
- Check spelling: "John Doe" vs "Jon Doe"
- Search by email: john@example.com
- Create athlete: npm run create-athlete

Similar athletes found:
- John Smith (john.smith@example.com)
- Jane Doe (jane.doe@example.com)

Action: Should I create a new athlete or use an existing one?
```

**Resolution:**
```sql
-- Option 1: Create new athlete
INSERT INTO zamm.lib_athletes (athlete_id, name, email)
VALUES (gen_random_uuid(), 'John Doe', 'john@example.com');

-- Option 2: Use existing athlete
-- Select from similar matches above
```

### Duplicate Import

```
⚠️  Warning: This workout was already imported

Import details:
- Import ID: abc-123
- Imported at: 2025-11-02 14:30:00
- Draft ID: def-456
- Status: approved

Action:
1. Skip (already processed)
2. Re-parse (creates new draft)
3. View existing (show original JSON)
```

**Resolution:**
- If same file → Skip
- If updated file → Re-parse
- If investigating → View existing

---

## Stage 2: Parsing Errors

### Exercise Not Found

```
⚠️  Warning: Exercise "Romanian Deadlifts" not found in catalog

Similar exercises:
1. "Deadlift" (deadlift) - strength, hinge
2. "Sumo Deadlift" (sumo_deadlift) - strength, hinge
3. "Stiff-Leg Deadlift" (stiff_leg_deadlift) - strength, hinge

Action: Which exercise should I use?
```

**Resolution:**
```bash
# Option 1: Use existing exercise
# Select from list above

# Option 2: Add new exercise
/add-entity exercise "Romanian Deadlift"

# Then re-parse
/process-workout --resume
```

### Equipment Alias Unknown

```
⚠️  Warning: Equipment "DBs" not recognized

Known aliases for dumbbells:
- DB, db, dumbbell, dumbbells

Did you mean: "dumbbell"?
```

**Resolution:**
```sql
-- Add alias
INSERT INTO zamm.lib_equipment_aliases (alias, equipment_key, locale, is_common)
VALUES ('DBs', 'dumbbell', 'en', true);

-- Or use existing alias
-- Parser should use "dumbbell" instead
```

### Block Code Not Normalized

```
❌ Error: Block code "STRENGTH" is invalid

Valid codes:
- STR (Strength)
- PWR (Power)
- METCON (Metabolic Conditioning)
- WU (Warmup)

Action: Update parser to use "STR" instead of "STRENGTH"
```

**Resolution:**
Update parser prompt to use normalized block codes from `lib_block_types` table.

---

## Stage 3: Validation Errors

### Critical Validation Failure

```
❌ Validation Failed: Cannot commit to database

Errors:
1. Block code "STRENGTH" is invalid
   → Valid codes: STR, WU, METCON, PWR, etc.
   → Suggestion: Use "STR" instead

2. Exercise key "deadlift_romanian" does not exist
   → Found in catalog: "deadlift", "sumo_deadlift"
   → Add this exercise first or use existing key

3. Negative reps: Set 2 has reps = -5
   → Check if this is a typo

Action: Fix these errors manually or let me auto-correct?
```

**Resolution:**

```bash
# Option 1: Auto-correct (if possible)
/fix-parser

# Option 2: Manual fixes
# Edit stg_parse_drafts table directly
# OR edit source file and re-parse

# Then re-validate
/process-workout --resume --from-stage=3
```

### Non-Critical Warnings

```
⚠️  Validation Warnings: Review before committing

Warnings:
1. Set 3: actual_reps (4) < target_reps (5)
   → Athlete did not complete full set

2. Load is high: 250kg deadlift
   → Verify this is correct (not a typo)

3. Missing performance data for Block B
   → Prescription exists but no performance recorded

Action:
- Approve and commit anyway
- Edit draft in stg_draft_edits
- Cancel and fix source file
```

**Resolution:**
- Review each warning
- Approve if intentional
- Fix if incorrect

### Value Range Violations

```
❌ Error: Invalid value detected

Field: target_reps
Value: 500
Problem: Exceeds maximum expected value (100)

Field: target_weight.value
Value: -50
Problem: Negative weight not allowed
```

**Resolution:**
```sql
-- Fix in draft
UPDATE zamm.stg_parse_drafts
SET normalized_json = jsonb_set(
  normalized_json,
  '{sessions,0,blocks,0,items,0,prescription,target_reps}',
  '50'
)
WHERE draft_id = '...';

-- Then re-validate
```

---

## Stage 4: Commit Errors

### Foreign Key Violation

```
❌ Commit Failed: Database transaction rolled back

Error: Foreign key constraint violated
- Table: workout_items
- Column: exercise_key
- Value: "unknown_exercise"
- Constraint: Exercise must exist in lib_exercise_catalog

Root Cause: Validation passed but exercise was deleted after validation

Action: Re-run validation to catch this issue
```

**Resolution:**
```bash
# Check if exercise exists
SELECT * FROM zamm.lib_exercise_catalog WHERE exercise_key = 'unknown_exercise';

# If missing, add it
/add-entity exercise "Exercise Name"

# Then re-commit
/process-workout --resume --from-stage=4
```

### Stored Procedure Failure

```
❌ Commit Failed: Stored procedure error

Error: null value in column "approved_at" violates not-null constraint
Detail: Failing row contains (workout_id, ..., null, ...)

Root Cause: commit_full_workout_v3() expects approved_at timestamp
```

**Resolution:**
```sql
-- Check stored procedure signature
\df zamm.commit_full_workout_v3

-- Verify all required parameters are provided
-- Update call to include missing parameters
```

### Transaction Timeout

```
❌ Commit Failed: Transaction timeout

Error: canceling statement due to statement timeout
Detail: Transaction took longer than 30 seconds

Root Cause: Large workout or slow database
```

**Resolution:**
```sql
-- Increase timeout for this session
SET statement_timeout = '60s';

-- Then retry commit
/process-workout --resume --from-stage=4
```

---

## Multi-Stage Failures

### Pipeline Completely Failed

If multiple stages fail:

1. **Stop immediately**
2. **Run `/verify`** - Check system health
3. **Run `/db-status`** - Check database connection
4. **Review recent changes** - What was modified?
5. **Test with known-good file** - Use golden set

### Recovery Steps

```bash
# 1. Verify system health
/verify

# 2. Check database
/db-status

# 3. Test with simple file
/process-workout data/golden_set/workout_01.txt --dry-run

# 4. If works, try original file again
/process-workout path/to/problematic/file.txt
```

---

## Prevention Best Practices

### Before Processing

1. Run `/verify` to ensure system health
2. Run `/db-status` to check database
3. Validate golden set passes
4. Check recent migrations applied

### During Processing

1. Watch for warnings at each stage
2. Don't ignore validation errors
3. Verify athlete/exercise/equipment exist
4. Review visual diffs carefully

### After Processing

1. Verify workout in database
2. Run learning loop if corrections made
3. Update golden set if new patterns found
4. Document any manual fixes required

---

## Emergency Rollback

### Undo Last Commit

```sql
-- Find workout
SELECT workout_id, workout_date, athlete_id
FROM zamm.workout_main
ORDER BY created_at DESC
LIMIT 1;

-- Delete (cascades to all related tables)
DELETE FROM zamm.workout_main
WHERE workout_id = '...';

-- Verify deleted
SELECT COUNT(*) FROM zamm.workout_sessions WHERE workout_id = '...';
-- Should return 0
```

### Restore from Backup

```bash
# If git tracked
git checkout HEAD~1 -- data/processed/athlete/date_parsed.json

# Restore from backup table (if enabled)
SELECT * FROM zamm.workout_main_backup
WHERE workout_id = '...';
```

---

## Getting Help

If errors persist after following these steps:

1. Check `docs/context/agents.md` for system overview
2. Review `docs/architecture/ARCHITECTURE.md` for data flow
3. Use `/inspect-table` to verify schema
4. Check `supabase/migrations/` for recent schema changes
5. Review `docs/reference/CANONICAL_JSON_SCHEMA.md` for output format

---

**Last Updated:** 2026-01-13
**Version:** 1.0.0
