# CLAUDE.md

**Version:** 1.0.0  
**Purpose:** Core principles and workflow for AI agents working on ParserZamaActive  
**Last Updated:** January 10, 2026

---

## Core Principles (The "ZAMM" Way)

### 1. Zero Inference
**Never invent data. If it's not in the text → NULL.**

```json
// ✅ CORRECT - Unknown data is null
{
  "prescription": { "target_reps": 5 },
  "performed": null  // No performance data in text
}

// ❌ WRONG - Hallucinated data
{
  "prescription": { "target_reps": 5 },
  "performed": { "actual_reps": 5 }  // Assumed they did exactly as planned
}
```

### 2. Prescription vs Performance
**Always separate what was PLANNED from what was DONE.**

This is the single most important architectural principle in the system.

```json
{
  "prescription": { "target_sets": 3, "target_reps": 5 },
  "performed": { "actual_sets": 3, "actual_reps": [5, 5, 4] }
}
```

### 3. Atomic Commits
**NEVER manually INSERT into `workout_*` tables. ALWAYS use stored procedures.**

```sql
-- ✅ CORRECT
SELECT zamm.commit_full_workout_v3(
    import_id, draft_id, ruleset_id, athlete_id, normalized_json
);

-- ❌ WRONG - Will break data integrity
INSERT INTO zamm.workout_main ...
INSERT INTO zamm.workout_sessions ...
```

### 4. Canonical Names
**Always normalize exercises and equipment via catalog lookups.**

```sql
-- ✅ CORRECT - Always validate first
SELECT zamm.check_exercise_exists('bench press');
-- Returns: canonical exercise_key

-- ❌ WRONG - Free text will create data inconsistency
INSERT INTO workout_items (exercise_name) VALUES ('bench');
```

### 5. Schema Namespace
**Use `zamm` schema exclusively. NEVER `public`.**

```sql
-- ✅ CORRECT
SELECT * FROM zamm.lib_athletes;

-- ❌ WRONG
SELECT * FROM public.athletes;
```

---

## Repository Workflow

### Standard Development Flow

1. **Fetch Context**
   - Read `docs/context/agents.md` to restore project memory
   - Run `/db-status` to check current state
   - Review relevant docs in `/docs/`

2. **Plan**
   - Review `ARCHITECTURE.md` before schema changes
   - Check `CANONICAL_JSON_SCHEMA.md` before parser changes
   - Look for similar patterns in existing code

3. **Modify**
   - Make changes (SQL migrations, JS scripts, or documentation)
   - Follow naming conventions (see below)
   - Add comprehensive comments

4. **Verify**
   - Run `/verify` immediately after changes
   - Check all three test suites pass
   - Review diffs carefully

5. **Commit**
   - Only after all tests pass
   - Write descriptive commit messages
   - Update `CHANGELOG.md` for user-facing changes

---

## Verification Commands

### Quick Checks
```bash
# Database connectivity and table count
./scripts/verify_schema.sh

# Parser logic against golden set
./scripts/validate_golden_set.sh

# Block type classification
./scripts/test_block_types.sh

# Parser accuracy metrics
./scripts/test_parser_accuracy.sh
```

### Slash Commands
- `/verify` - Run full test suite (all three checks above)
- `/db-status` - Check database connection and table counts
- `/fix` - Auto-repair common issues (if available)

---

## Naming Conventions

### SQL
- **Tables:** `lowercase_with_underscores` (e.g., `workout_main`, `lib_athletes`)
- **Functions:** `lowercase_with_underscores` (e.g., `check_exercise_exists`)
- **Columns:** `lowercase_with_underscores` (e.g., `workout_id`, `exercise_key`)
- **Primary Keys:** `{table_singular}_id` (e.g., `workout_id`, `athlete_id`)

### Migrations
- **Format:** `YYYYMMDDHHMMSS_descriptive_name.sql`
- **Example:** `20260110140000_add_equipment_keys.sql`

### JavaScript/Node
- **Files:** `kebab-case.js` (e.g., `update-parser-brain.js`)
- **Functions:** `camelCase` (e.g., `fetchLearningExamples`)
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `MAX_RETRIES`)

---

## Common Pitfalls

### ❌ DON'T
1. **Use `public` schema** - Always use `zamm`
2. **Assume `session_code`** - Only use `"AM"`, `"PM"`, or `null` (never guess)
3. **Hardcode UUIDs** - Use catalog lookup functions
4. **Mix prescription/performance** - Keep them strictly separated
5. **Edit old migrations** - Create new ones instead
6. **Skip validation** - Always run `/verify` before committing
7. **Insert workouts manually** - Use `commit_full_workout_v3` procedure

### ✅ DO
1. **Check schema first** - Run `verify_schema.sh` before SQL changes
2. **Use catalog lookups** - `check_exercise_exists`, `check_athlete_exists`
3. **Normalize block types** - Via `normalize_block_code` function
4. **Comment heavily** - SQL can be cryptic, explain complex logic
5. **Update docs** - Keep `SCHEMA_REFERENCE.md` in sync with migrations
6. **Test with real data** - Use files from `/data/` directory
7. **Preserve audit trail** - Never delete from `stg_*` tables

---

## File Organization

### Critical Files (Read First)
1. **`docs/reference/CANONICAL_JSON_SCHEMA.md`** ⚖️ - The Constitution (parser output rules)
2. **`docs/context/agents.md`** - AI agent instructions and project memory
3. **`docs/architecture/ARCHITECTURE.md`** - System design and patterns
4. **`docs/guides/AI_PROMPTS.md`** - Parser prompt templates (auto-updated)

### Key Directories
```
/workspaces/ParserZamaActive/
├── .claude/              # This directory - AI agent configuration
├── docs/                 # All documentation
│   ├── reference/        # Technical specifications
│   ├── guides/           # Implementation guides
│   └── api/              # SQL query examples
├── data/                 # Sample workout logs
│   └── golden_set/       # Parser test cases
├── scripts/              # Utility scripts
└── supabase/             # Database configuration
    └── migrations/       # Version-controlled SQL
```

---

## Database Quick Reference

### 32 Tables in `zamm` Schema

**Infrastructure (6)**
- `lib_athletes`, `lib_coaches`, `lib_parser_rulesets`
- `lib_equipment_catalog`, `lib_equipment_aliases`
- `lib_block_types`, `lib_block_type_aliases`

**Exercise Catalog (2)**
- `lib_exercise_catalog`, `lib_exercise_aliases`

**Staging (3)**
- `stg_imports`, `stg_parse_drafts`, `stg_draft_edits`

**Validation (1)**
- `log_validation_reports`

**Workout Core (5)**
- `workout_main`, `workout_sessions`, `workout_blocks`
- `workout_items`, `workout_item_set_results`

**Results (3)**
- `res_blocks`, `res_intervals`, `res_item_sets`

**Events (1)**
- `evt_athlete_personal_records`

**Learning System (1)**
- `log_learning_examples`

### 17 Block Types (Memorize These)
**PREPARATION:** `WU`, `ACT`, `MOB`  
**STRENGTH:** `STR`, `ACC`, `HYP`  
**POWER:** `PWR`, `WL`  
**SKILL:** `SKILL`, `GYM`  
**CONDITIONING:** `METCON`, `INTV`, `SS`, `HYROX`  
**RECOVERY:** `CD`, `STRETCH`, `BREATH`

---

## AI Agent Protocols

### Protocol Zero: Session Handshake (MANDATORY)
Before executing ANY task:

```bash
# 1. Verify database connectivity
npx supabase status

# 2. Run handshake query
# Should return athlete_count > 0, workout_count > 0
echo "SELECT 
    (SELECT COUNT(*) FROM zamm.lib_athletes) as athlete_count,
    (SELECT COUNT(*) FROM zamm.workout_main) as workout_count,
    (SELECT version FROM zamm.lib_parser_rulesets WHERE is_active = true LIMIT 1) as active_ruleset;" | \
  PGPASSWORD="..." psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres

# 3. Verify schema awareness
./scripts/verify_schema.sh
```

**Only proceed after successful handshake.**

---

## Active Learning System

The parser improves automatically from corrections:

1. **Corrections Logged:** Stored in `log_learning_examples` table
2. **Script Extracts:** `npm run learn` fetches high-priority examples
3. **Prompts Updated:** Examples injected into `AI_PROMPTS.md`
4. **Parser Learns:** Future parses avoid past mistakes

**Run after fixing parser bugs:** `npm run learn`

---

## Emergency Commands

### Database Issues
```bash
# Check connection
npx supabase status

# View recent migrations
ls -lh supabase/migrations/ | tail -5

# Check table counts
./scripts/verify_schema.sh
```

### Parser Issues
```bash
# Validate against golden set
./scripts/validate_golden_set.sh

# Check specific workout
cat data/golden_set/workout_01.txt | # process through parser

# Update learning examples
npm run learn
```

### Git Issues
```bash
# Check status
git status

# View changes
git diff

# Discard changes (careful!)
git checkout -- <file>
```

---

## Related Documents

- [agents.md](../docs/context/agents.md) - Full AI agent instructions
- [ARCHITECTURE.md](../docs/architecture/ARCHITECTURE.md) - System architecture
- [CANONICAL_JSON_SCHEMA.md](../docs/reference/CANONICAL_JSON_SCHEMA.md) - Parser output spec
- [VALIDATION_SYSTEM_SUMMARY.md](../docs/VALIDATION_SYSTEM_SUMMARY.md) - Validation rules
- [BLOCK_TYPES_REFERENCE.md](../docs/reference/BLOCK_TYPES_REFERENCE.md) - Block type catalog

---

**Last Updated:** January 10, 2026  
**Maintained By:** AI Development Team
