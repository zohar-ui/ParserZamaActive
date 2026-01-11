# Verified Table Names (zamm Schema)

**Last Verified:** 2026-01-11
**Method:** Automated query via update_schema_docs.js
**Total Tables:** 33

---

## ✅ ACTUAL TABLE NAMES

### Configuration Tables (1)
- `cfg_parser_rules` ✅ (9 columns)

### Dimension/Backup Tables (1)
- `dim_athletes_backup` ✅ (15 columns)

### Event Tables (1)
- `evt_athlete_personal_records` ✅ (19 columns)

### Library/Catalog Tables (17)
- `lib_athletes` ✅ (11 columns)
- `lib_benchmark_blocks` ✅ (7 columns)
- `lib_benchmark_exercises` ✅ (7 columns)
- `lib_benchmarks` ✅ (8 columns)
- `lib_block_aliases` ✅ (5 columns)
- `lib_block_types` ✅ (10 columns)
- `lib_coaches` ✅ (7 columns)
- `lib_equipment_aliases` ✅ (3 columns)
- `lib_equipment_catalog` ✅ (4 columns)
- `lib_equipment_config_templates` ✅ (2 columns)
- `lib_exercise_aliases` ✅ (6 columns)
- `lib_exercise_catalog` ✅ (16 columns)
- `lib_movement_patterns` ✅ (12 columns)
- `lib_muscle_groups` ✅ (11 columns)
- `lib_parser_rulesets` ✅ (10 columns)
- `lib_prescription_schemas` ✅ (10 columns)
- `lib_result_models` ✅ (8 columns)

### Logging Tables (2)
- `log_learning_examples` ✅ (16 columns)
- `log_validation_reports` ✅ (7 columns)

### Result Tables (3)
- `res_blocks` ✅ (19 columns)
- `res_intervals` ✅ (13 columns)
- `res_item_sets` ✅ (18 columns)

### Staging/Import Tables (3)
- `stg_draft_edits` ✅ (6 columns)
- `stg_imports` ✅ (9 columns)
- `stg_parse_drafts` ✅ (17 columns)

### Core Workout Tables (5)
- `workout_blocks` ✅ (22 columns)
- `workout_item_set_results` ✅ (10 columns)
- `workout_items` ✅ (29 columns)
- `workout_main` ✅ (23 columns)
- `workout_sessions` ✅ (12 columns)

---

## ❌ COMMON MISTAKES (Tables That DON'T Exist)

| WRONG Name | CORRECT Name |
|------------|--------------|
| `workouts` | `workout_main` |
| `block_type_catalog` | `lib_block_types` |
| `block_code_aliases` | `lib_block_aliases` |
| `workout_block_results` | `res_blocks` |
| `item_set_results` | `res_item_sets` |

---

## 🔍 Verification Commands

### Verify a specific table:
```bash
./scripts/utils/inspect_db.sh <table_name>
```

### List all tables:
```bash
psql "$SUPABASE_DB_URL" -c "SELECT tablename FROM pg_tables WHERE schemaname = 'zamm' ORDER BY tablename;"
```

### Update this documentation:
```bash
npm run update-docs
```

---

## 📊 Sample Table Structures

### workout_main (23 columns)
```
workout_id, import_id, draft_id, ruleset_id, athlete_id, workout_date, session_title, session_type, status, estimated_duration_min, created_at, approved_at, approved_by, coach_id, program_name, ... (8 more)
```

### lib_block_types (10 columns)
```
block_code, block_type, category, result_model, ui_hint, display_name, description, sort_order, is_active, created_at
```

### res_blocks (19 columns)
```
block_result_id, block_id, did_complete, total_time_sec, score_time_sec, score_text, distance_m, avg_hr_bpm, calories, athlete_notes, created_at, result_model_id, result_model_version, canonical, computed, ... (4 more)
```

### stg_imports (9 columns)
```
import_id, source, source_ref, athlete_id, raw_text, raw_payload, received_at, checksum_sha256, tags
```

---

**IMPORTANT:** This documentation is automatically generated. Always verify table names using the inspection tool before writing SQL.

**Last Updated:** 2026-01-11 (automated)
