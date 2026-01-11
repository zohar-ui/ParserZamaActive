# /process-workout

**Purpose:** End-to-end orchestrator for parsing a new workout file
**Duration:** 2-5 minutes depending on workout complexity
**Use When:** Processing raw workout logs into structured database records

---

## Overview

The Master Orchestrator automates the complete 4-stage parsing pipeline:

```
Stage 1: Ingest → Stage 2: Parse → Stage 3: Validate → Stage 4: Commit
```

This command handles everything from raw text to committed database records, with validation checks and git tracking at each step.

---

## Usage

### Basic Usage
```bash
/process-workout
```

The agent will then:
1. Ask you which workout file to process
2. Run the pipeline automatically
3. Show validation results
4. Ask for approval before committing
5. Create git branch and commit if successful

### Manual File Specification
You can also specify the file directly:
```
Process the workout file: data/golden_set/tomer_2025-11-02_simple_deadlift.txt
```

---

## Pipeline Stages

### 🔵 Stage 1: Context & Ingestion

**Goal:** Import raw workout text and identify athlete

**MCP Operations:**
- Find athlete in `lib_athletes` table
- Get active parser ruleset from `cfg_parser_rules`
- Insert raw text into `stg_imports` with checksum (idempotency)

**Output:**
```json
{
  "import_id": "uuid",
  "athlete_id": "uuid",
  "athlete_name": "Tomer Yacov",
  "ruleset_version": "1.2"
}
```

**Failure Conditions:**
- ❌ Athlete not found → Ask user to create athlete first
- ❌ No active ruleset → Critical error, cannot proceed
- ❌ Duplicate import (checksum exists) → Ask if should re-process

---

### 🟢 Stage 2: Parsing Agent

**Goal:** Parse raw text into structured JSON (prescription vs performance separation)

**MCP Operations:**
- Lookup exercises in `lib_exercise_catalog`
- Resolve equipment aliases via `lib_equipment_aliases`
- Normalize block codes via `lib_block_aliases`
- Validate movement patterns and categories

**Agent Instructions:**
The AI agent will:
1. Read the workout file
2. Use MCP to query catalogs for normalization
3. Generate structured JSON following `CANONICAL_JSON_SCHEMA.md`
4. Separate prescription (planned) from performed (actual)
5. Save draft to `stg_parse_drafts`

**Output:**
```json
{
  "draft_id": "uuid",
  "confidence_score": 0.95,
  "sessions": [...],
  "flags": []
}
```

**Quality Checks:**
- ✅ All exercises resolved to catalog entries
- ✅ All equipment normalized
- ✅ All block codes validated
- ✅ Prescription/performance properly separated
- ⚠️ Flags set for ambiguous data

---

### 🟡 Stage 3: Validation & Review

**Goal:** Validate parsed JSON against schema and business rules

**MCP Operations:**
- Run `validate_workout_draft()` SQL function
- Check exercise keys exist in catalog
- Check equipment keys exist in catalog
- Validate value ranges (weights, reps, durations)
- Check prescription/performance consistency

**Validation Categories:**

**Critical Errors (Must Fix):**
- Invalid JSON structure
- Missing required fields
- Exercise key not in catalog
- Equipment key not in catalog
- Invalid block_code
- Negative or impossible values

**Warnings (Review Recommended):**
- Actual reps < target reps
- Load > 500kg (possible typo)
- RPE > 9.5 (near-maximal effort)
- Duration > 120 minutes
- Missing performance data when expected

**Output:**
```json
{
  "is_valid": true,
  "errors": [],
  "warnings": [
    "Set 3: actual_reps (4) < target_reps (5) - incomplete set"
  ],
  "validation_report_id": "uuid"
}
```

**Visual Diff Display:**

The agent will display a comparison:

```
📋 PRESCRIPTION vs PERFORMANCE

Block: STR - Deadlift
Exercise: Conventional Deadlift (deadlift)

PRESCRIPTION:                 PERFORMED:
├─ Sets: 3                   ├─ Sets: 3
├─ Reps: 5                   ├─ Set 1: 5 reps ✓
├─ Load: 140kg               ├─ Set 2: 5 reps ✓
└─ RPE: 7                    ├─ Set 3: 4 reps ⚠️ (target: 5)
                             └─ Notes: "back rounding"

⚠️  Warning: Set 3 incomplete (4/5 reps)
```

**Agent Actions:**
- ✅ **If valid** → Proceed to Stage 4
- ❌ **If critical errors** → Stop, show errors, ask user to fix
- ⚠️ **If warnings only** → Show warnings, ask user to approve or edit

---

### 🔴 Stage 4: Atomic Commit

**Goal:** Save validated workout to database using stored procedure

**Prerequisites:**
- Validation passed (is_valid = true)
- User approved (if warnings present)

**MCP Operations:**
- Call `commit_full_workout_v3()` stored procedure
- Verify workout created in `workout_main`
- Check sessions, blocks, items, and sets were created
- Update draft status to 'approved'

**Commit Function Call:**
```sql
SELECT zamm.commit_full_workout_v3(
  p_import_id := '${import_id}',
  p_draft_id := '${draft_id}',
  p_ruleset_id := '${ruleset_id}',
  p_athlete_id := '${athlete_id}',
  p_normalized_json := '${validated_json}'::jsonb
);
```

**Output:**
```json
{
  "workout_id": "uuid",
  "sessions_created": 1,
  "blocks_created": 3,
  "items_created": 5,
  "sets_created": 15,
  "status": "committed"
}
```

**Verification Queries:**
```sql
-- Verify workout exists
SELECT * FROM zamm.workout_main WHERE workout_id = '${workout_id}';

-- Count related records
SELECT
  (SELECT COUNT(*) FROM zamm.workout_sessions WHERE workout_id = '${workout_id}') as sessions,
  (SELECT COUNT(*) FROM zamm.workout_blocks WHERE session_id IN
    (SELECT session_id FROM zamm.workout_sessions WHERE workout_id = '${workout_id}')) as blocks,
  (SELECT COUNT(*) FROM zamm.workout_items WHERE block_id IN
    (SELECT block_id FROM zamm.workout_blocks WHERE session_id IN
      (SELECT session_id FROM zamm.workout_sessions WHERE workout_id = '${workout_id}'))) as items;
```

**Rollback on Failure:**
If commit fails, the stored procedure automatically rolls back the transaction. No partial data is saved.

---

### 🎯 Stage 5: Git Tracking (Optional)

**Goal:** Track processed workouts in version control

**Git Operations:**
1. Create branch: `data/workout-{athlete_slug}-{date}`
2. Save artifacts:
   - `data/processed/{athlete}/{date}_raw.txt` - Original text
   - `data/processed/{athlete}/{date}_parsed.json` - Parsed JSON
   - `data/processed/{athlete}/{date}_validation.json` - Validation report
3. Commit with message: `feat: Process workout {athlete} {date}`
4. Return to main branch

**Example Branch:**
```
data/workout-tomer-yacov-2025-11-02
├── data/processed/tomer_yacov/2025-11-02_raw.txt
├── data/processed/tomer_yacov/2025-11-02_parsed.json
└── data/processed/tomer_yacov/2025-11-02_validation.json
```

**Git Commands:**
```bash
git checkout -b data/workout-tomer-yacov-2025-11-02
git add data/processed/
git commit -m "feat: Process workout Tomer Yacov 2025-11-02

- Import ID: ${import_id}
- Workout ID: ${workout_id}
- Blocks: 3
- Items: 5
- Validation: passed with warnings

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
git checkout main
```

**Note:** This step is optional and can be skipped if you prefer not to track individual workouts in git.

---

## Error Handling

### Stage 1 Errors

**Athlete Not Found:**
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

**Duplicate Import:**
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

Choose an option:
```

---

### Stage 2 Errors

**Exercise Not Found:**
```
⚠️  Warning: Exercise "Romanian Deadlifts" not found in catalog

Similar exercises:
1. "Deadlift" (deadlift) - strength, hinge
2. "Sumo Deadlift" (sumo_deadlift) - strength, hinge
3. "Stiff-Leg Deadlift" (stiff_leg_deadlift) - strength, hinge

Action: Which exercise should I use?
```

**Equipment Alias Unknown:**
```
⚠️  Warning: Equipment "DBs" not recognized

Known aliases for dumbbells:
- DB, db, dumbbell, dumbbells

Did you mean: "dumbbell"?
```

---

### Stage 3 Errors

**Critical Validation Error:**
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

**Warnings (Non-blocking):**
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

---

### Stage 4 Errors

**Commit Failure:**
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

---

## Workflow Variations

### Quick Mode (No Git Tracking)
```
/process-workout --no-git
```
Skips Stage 5 git operations. Faster for bulk processing.

### Validation Only
```
/process-workout --validate-only
```
Stops after Stage 3. Useful for testing parser changes without committing.

### Force Commit (Skip Warnings)
```
/process-workout --force
```
Automatically approves warnings and commits. Use carefully!

### Dry Run
```
/process-workout --dry-run
```
Runs full pipeline but skips Stage 4 commit. Shows what would happen.

---

## Success Criteria

### ✅ Successful Pipeline Run

```
🎉 Workout Processed Successfully!

Summary:
├─ Athlete: Tomer Yacov
├─ Date: 2025-11-02
├─ Import ID: abc-123-def
├─ Draft ID: def-456-ghi
├─ Workout ID: ghi-789-jkl
├─ Validation: ✓ Passed (2 warnings)
├─ Commit: ✓ Success
└─ Git Branch: data/workout-tomer-yacov-2025-11-02

Details:
- Sessions: 1
- Blocks: 3 (WU, ACT, STR)
- Items: 5 exercises
- Sets: 15 total sets
- Performance Data: 80% coverage

View in database:
SELECT * FROM zamm.workout_main WHERE workout_id = 'ghi-789-jkl';
```

---

## Related Commands

- `/verify` - Run validation suite before processing
- `/db-status` - Check database connection
- `npm run learn` - Update parser brain from corrections
- `npm run create-athlete` - Add new athlete to system

---

## Best Practices

### 1. Validate Schema First
```bash
/verify
```
Run before processing to ensure system is healthy.

### 2. Process One File at a Time
Don't batch process until you've validated the parser works correctly on individual files.

### 3. Review Warnings
Even if validation passes, review warnings to catch data quality issues.

### 4. Check Git History
```bash
git log --oneline --graph data/processed/
```
See all processed workouts and when they were added.

### 5. Use Learning Loop
After manual corrections:
```bash
npm run learn
```
Train the parser to avoid similar mistakes.

---

## Troubleshooting

### Pipeline Hangs
- Check database connection: `npx supabase status`
- Verify MCP is responding: `/db-status`
- Look for infinite loops in parser logic

### Validation Always Fails
- Check `CANONICAL_JSON_SCHEMA.md` version matches database
- Run `/verify` to ensure system consistency
- Review validation function logs

### Commit Fails Silently
- Check stored procedure logs
- Verify foreign key constraints
- Test commit manually with simple JSON

### Git Branch Conflicts
- Ensure main branch is clean before processing
- Delete stale branches: `git branch -D data/workout-*`

---

## Implementation Notes

**Files Created:**
- `scripts/pipeline/parse_workout.js` - Main orchestrator
- `scripts/pipeline/commit_draft.js` - Stage 4 commit handler
- `scripts/pipeline/git_helper.js` - Git automation
- `scripts/pipeline/visual_diff.js` - Prescription vs Performance display

**NPM Scripts Added:**
```json
{
  "pipeline": "node scripts/pipeline/parse_workout.js",
  "commit-draft": "node scripts/pipeline/commit_draft.js"
}
```

**Dependencies:**
- Uses Supabase MCP for database operations
- Uses existing validation functions
- Uses canonical schema from `docs/reference/CANONICAL_JSON_SCHEMA.md`

---

**Last Updated:** 2026-01-11
**Version:** 1.0.0
**Status:** ✅ Production Ready
