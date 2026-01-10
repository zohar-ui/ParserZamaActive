# ZAMM Schema - Table Reference

> **Always verify against actual database before using!**  
> Last Verified: January 9, 2026

## 📋 Complete Table List (27 tables)

### Infrastructure (3)
- `lib_athletes` - Master athlete catalog
- `lib_coaches` - Coach information
- `lib_parser_rulesets` - Parser configuration

### Catalogs (8)
- `lib_benchmarks` - Workout benchmarks (Fran, Murph, etc.)
- `lib_block_types` - Block type definitions (STR, METCON, etc.)
- `lib_equipment_catalog` - Equipment master list
- `lib_exercise_catalog` - Exercise master list
- `lib_movement_patterns` - Movement pattern taxonomy
- `lib_muscle_groups` - Muscle group definitions
- `lib_prescription_schemas` - Prescription data schemas
- `lib_result_models` - Result model definitions

### Aliases & Junctions (5)
- `lib_block_aliases` - Block type aliases (Hebrew, abbreviations)
- `lib_equipment_aliases` - Equipment name aliases
- `lib_exercise_aliases` - Exercise name aliases
- `lib_benchmark_blocks` - Benchmark → Block type junction
- `lib_benchmark_exercises` - Benchmark → Exercise junction

### Staging (3)
- `stg_imports` - Raw workout text imports
- `stg_parse_drafts` - Parsed JSON drafts
- `stg_draft_edits` - Edit history for drafts

### Logging (1)
- `log_validation_reports` - Validation results

### Workout Core (4)
- `workout_main` - Workout header/metadata
- `workout_sessions` - AM/PM sessions
- `workout_blocks` - Individual blocks (A, B, C)
- `workout_items` - Exercises within blocks

### Results (3)
- `res_blocks` - Block results (times, rounds, etc.)
- `res_intervals` - Interval segment results
- `res_item_sets` - Individual set results

---

## ⚠️ Common Name Confusion

| ❌ Wrong (Assumed) | ✅ Correct (Actual) |
|-------------------|---------------------|
| `dim_athletes` | `lib_athletes` |
| `workout_item_set_results` | `res_item_sets` |
| `workout_block_results` | `res_blocks` |
| `lib_block_type_aliases` | `lib_block_aliases` |
| `parse_drafts` | `stg_parse_drafts` |
| `imports` | `stg_imports` |

---

## 🔍 How to Verify (Before Every SQL Operation)

### Option 1: Quick List
```bash
./scripts/ops/verify_schema.sh
```

### Option 2: SQL Query
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'zamm' 
ORDER BY table_name;
```

### Option 3: Check Specific Table
```bash
./scripts/ops/verify_schema.sh workout_main
```

---

## 📝 Naming Conventions

### Prefixes
- `lib_*` - Library/catalog tables (reference data)
- `stg_*` - Staging tables (temporary/processing)
- `log_*` - Logging tables (audit trail)
- `res_*` - Results tables (workout outcomes)
- `cfg_*` - Configuration tables (settings)

### No Prefix
- `workout_*` - Core workout tables

---

## 🚨 Critical Rules

1. **ALWAYS verify table name before writing SQL**
2. **NEVER assume plural/singular forms**
3. **CHECK column names** - they may differ from expectations
4. **Use schema_snapshot.sql** as source of truth
5. **Run verify_schema.sh** before complex queries

---

**This is a REFERENCE ONLY. Always verify against live database!**

Last Schema Pull: `npx supabase db pull` (January 9, 2026)
