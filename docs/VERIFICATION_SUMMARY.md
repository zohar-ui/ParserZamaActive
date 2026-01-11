# Database Table Name Verification Summary

**Date:** 2026-01-11
**Status:** ✅ COMPLETE

## What Was Done

### 1. Created Inspection Tool
**File:** `scripts/utils/inspect_db.sh`
- Queries actual database schema for table structure
- Shows column names, data types, and defaults
- Warns when tables don't exist
- Lists all available tables

### 2. Verified Table Names
**Method:** Direct query to remote Supabase database
```bash
psql "postgresql://postgres:PASSWORD@db.dtzcamerxuonoeujrgsu.supabase.co:5432/postgres" \
  -c "SELECT tablename FROM pg_tables WHERE schemaname = 'zamm' ORDER BY tablename;"
```

**Result:** Found 33 tables in `zamm` schema

### 3. Updated Documentation

#### A. Created VERIFIED_TABLE_NAMES.md
- Complete list of all 33 tables
- Organized by category
- Lists common naming mistakes
- Provides verification commands

#### B. Updated CLAUDE.md (v2.0.0)
- Added "FORBIDDEN: Documentation Trust" section
- Added "MANDATORY: Database Verification Protocol"
- Updated Protocol Zero with verification steps
- Fixed example workflows
- Updated Database Structure section with verified names

#### C. Updated BLOCK_TYPES_REFERENCE.md (v2.2.0)
- Updated all SQL table references
- Added ✅ verification markers
- Fixed schema examples
- Updated troubleshooting section
- Changed version from 2.1.0 → 2.2.0

## Key Findings

### ✅ CORRECT Table Names (Verified)
- `workout_main` (NOT `workouts`)
- `lib_block_types` (NOT `block_type_catalog`)
- `lib_block_aliases` (NOT `block_code_aliases`)
- `res_blocks` (NOT `workout_block_results`)
- `res_item_sets` ✅
- `workout_item_set_results` (NOT `item_set_results`)
- `lib_athletes`, `lib_coaches`, `lib_parser_rulesets` (all with `lib_` prefix)
- `stg_imports`, `stg_parse_drafts`, `stg_draft_edits` (all with `stg_` prefix)
- `log_validation_reports`, `log_learning_examples` (all with `log_` prefix)

### ❌ Tables That DON'T Exist
- `workouts` → use `workout_main`
- `block_type_catalog` → use `lib_block_types`
- `block_code_aliases` → use `lib_block_aliases`
- `workout_block_results` → use `res_blocks`
- `item_set_results` → use `workout_item_set_results`

## Verification Protocol

### Step 1: Test inspect tool
```bash
export SUPABASE_DB_URL="postgresql://postgres:PASSWORD@HOST:5432/postgres"
./scripts/utils/inspect_db.sh workout_main
```

### Step 2: Verify specific table
```bash
./scripts/utils/inspect_db.sh <table_name>
```

### Step 3: List all tables
```bash
psql "$SUPABASE_DB_URL" -c "SELECT tablename FROM pg_tables WHERE schemaname = 'zamm' ORDER BY tablename;"
```

## Files Modified

1. `scripts/utils/inspect_db.sh` (NEW)
2. `.claude/CLAUDE.md` (UPDATED v1.0.0 → v2.0.0)
3. `docs/reference/BLOCK_TYPES_REFERENCE.md` (UPDATED v2.1.0 → v2.2.0)
4. `docs/reference/VERIFIED_TABLE_NAMES.md` (NEW)

## Testing Results

### Test 1: Existing Table ✅
```bash
$ ./scripts/utils/inspect_db.sh workout_main
Inspecting table: zamm.workout_main
================================================
       column_name        | data_type | ...
--------------------------+-----------+-----
 workout_id               | uuid      | ...
 ... (23 columns total)
```

### Test 2: Non-Existent Table ✅
```bash
$ ./scripts/utils/inspect_db.sh workouts
⚠️  WARNING: Table 'zamm.workouts' does NOT exist!
Available tables in zamm schema:
...
```

### Test 3: Block Types Table ✅
```bash
$ ./scripts/utils/inspect_db.sh lib_block_types
Inspecting table: zamm.lib_block_types
================================================
 column_name  | data_type | ...
--------------+-----------+-----
 block_code   | text      | ...
 ... (10 columns total)
```

## Before & After Comparison

| What I Initially Thought | What Actually Exists |
|-------------------------|---------------------|
| `workouts` | `workout_main` ✅ |
| `block_type_catalog` | `lib_block_types` ✅ |
| `workout_block_results` | `res_blocks` ✅ |
| `item_set_results` | `workout_item_set_results` ✅ |

**Lesson:** Never trust migration files or documentation. Always verify against the live database.

## Next Steps

1. ✅ Always run `./scripts/utils/inspect_db.sh <table>` before writing SQL
2. ✅ Refer to `docs/reference/VERIFIED_TABLE_NAMES.md` for complete list
3. ✅ Follow protocols in `.claude/CLAUDE.md` for database operations
4. ✅ Update documentation when schema changes occur (AUTO-UPDATE SYSTEM 2026-01-11)
5. ✅ Re-verify table names monthly or after major migrations (GIT HOOK AUTO-RUNS 2026-01-11)


---

**Verification Complete!** All documentation now uses actual database table names verified on 2026-01-11.
