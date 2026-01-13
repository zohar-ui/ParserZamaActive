---
name: process-workout
description: End-to-end orchestrator for parsing raw workout logs through the complete 4-stage pipeline (ingest, parse, validate, commit) with quality gates and git tracking. Use this skill when: (1) Processing new workout files into structured database records, (2) Running the complete Master Orchestrator pipeline from text to database, (3) Validating workout data before committing to production tables, (4) Testing parser changes against real workout data, or (5) Automating the full workflow from raw text ingestion through atomic database commit with validation checks at each stage
---

# Process Workout Skill

Master orchestrator that automates the complete 4-stage parsing pipeline from raw workout text to committed database records.

## Pipeline Overview

```
Stage 1: Ingest → Stage 2: Parse → Stage 3: Validate → Stage 4: Commit
```

Each stage has validation checks, error handling, and optional git tracking.

## Core Workflow

### Basic Usage

```bash
/process-workout
```

The skill will:
1. Ask which workout file to process
2. Run the pipeline automatically
3. Show validation results at each stage
4. Request approval before database commit
5. Optionally create git branch and commit

### Manual File Specification

```bash
# Process specific file
/process-workout data/golden_set/tomer_2025-11-02_simple_deadlift.txt

# With options
/process-workout --no-git           # Skip git tracking
/process-workout --validate-only    # Stop after validation
/process-workout --dry-run          # Preview without committing
```

## Four Stages

### Stage 1: Context & Ingestion

**Goal:** Import raw workout text and identify athlete

**Actions:**
- Find athlete in `lib_athletes` table
- Get active parser ruleset from `cfg_parser_rules`
- Insert raw text into `stg_imports` with checksum (idempotency)

**Output:** `import_id`, `athlete_id`, `ruleset_version`

See [STAGE_1_INGEST.md](references/STAGE_1_INGEST.md) for details.

### Stage 2: Parsing Agent

**Goal:** Parse raw text into structured JSON (prescription vs performance separation)

**Actions:**
- Lookup exercises in `lib_exercise_catalog`
- Resolve equipment via `lib_equipment_aliases`
- Normalize block codes via `lib_block_aliases`
- Generate structured JSON following CANONICAL_JSON_SCHEMA.md
- Save draft to `stg_parse_drafts`

**Output:** `draft_id`, `confidence_score`, structured JSON

See [STAGE_2_PARSE.md](references/STAGE_2_PARSE.md) for details.

### Stage 3: Validation & Review

**Goal:** Validate parsed JSON against schema and business rules

**Actions:**
- Run `validate_workout_draft()` SQL function
- Check exercise/equipment keys exist in catalogs
- Validate value ranges (weights, reps, durations)
- Check prescription/performance consistency
- Display visual diff (prescription vs performed)

**Output:** `is_valid`, `errors[]`, `warnings[]`, `validation_report_id`

See [STAGE_3_VALIDATE.md](references/STAGE_3_VALIDATE.md) for details.

### Stage 4: Atomic Commit

**Goal:** Save validated workout to database using stored procedure

**Actions:**
- Call `commit_full_workout_v3()` stored procedure
- Verify workout created in `workout_main`
- Check sessions, blocks, items, sets were created
- Update draft status to 'approved'

**Output:** `workout_id`, counts of created records

See [STAGE_4_COMMIT.md](references/STAGE_4_COMMIT.md) for details.

## Success Output

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

## Error Handling

See [ERROR_HANDLING.md](references/ERROR_HANDLING.md) for comprehensive error resolution guidance.

### Quick Reference

**Stage 1 Errors:**
- Athlete not found → Create athlete or select existing
- Duplicate import → Skip, re-parse, or view existing

**Stage 2 Errors:**
- Exercise not found → Select from catalog or add new
- Equipment alias unknown → Use known alias or add new

**Stage 3 Errors:**
- Critical validation errors → Fix and re-validate
- Warnings only → Approve or edit draft

**Stage 4 Errors:**
- Commit failure → Transaction rolled back, fix and retry

## Options

### Workflow Variations

```bash
# Quick mode (no git tracking)
/process-workout --no-git

# Validation only (stop after Stage 3)
/process-workout --validate-only

# Force commit (skip warning approvals)
/process-workout --force

# Dry run (preview without committing)
/process-workout --dry-run
```

## Success Criteria

All stages must complete:

- ✅ Stage 1: Import created with valid athlete and ruleset
- ✅ Stage 2: Draft created with high confidence score
- ✅ Stage 3: Validation passed (or warnings approved)
- ✅ Stage 4: Workout committed to database successfully

## Related Skills

- `/verify` - Run validation suite before processing
- `/db-status` - Check database connection before starting
- `/inspect-table` - View table structure for troubleshooting
- `/add-entity` - Add missing exercises/equipment during processing
- `npm run learn` - Update parser brain from corrections

## Best Practices

1. **Validate Schema First** - Run `/verify` before processing
2. **Process One File at a Time** - Don't batch until validated
3. **Review Warnings** - Even if validation passes, check quality
4. **Use Learning Loop** - Run `npm run learn` after manual corrections
5. **Check Git History** - Track all processed workouts

## When to Use

| Task | Use process-workout | Alternative |
|------|---------------------|-------------|
| **New workout file** | ✅ Yes | Manual pipeline |
| **Testing parser** | ✅ Yes (--validate-only) | /debug-parse |
| **Bulk processing** | ✅ Yes (loop) | Manual scripts |
| **Single stage test** | ❌ No | Use specific skill |

---

**Version:** 1.0.0
**Last Updated:** 2026-01-13
**Duration:** 2-5 minutes (depends on workout complexity)
