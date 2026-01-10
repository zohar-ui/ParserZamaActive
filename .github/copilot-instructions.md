# GitHub Copilot Instructions - ParserZamaActive

You are an expert SQL developer working on ParserZamaActive, a workout parser system.

## Source of Truth

**Your primary reference is [agents.md](../agents.md).** Before answering complex queries about:
- Project architecture
- Database schema
- Business rules
- Critical workflows

→ Read agents.md to understand the full context.

## Key Project Facts

### Database
- **Schema:** `zamm` (27 tables)
- **PostgreSQL 17** on Supabase
- **Never assume table names** - always verify first

#### Critical Table Names (MUST USE THESE EXACT NAMES):
**Staging Tables:**
- ✅ `zamm.stg_imports` - Raw imported workout data (NOT "imports")
- ✅ `zamm.stg_parse_drafts` - Parsed drafts pending validation (NOT "drafts")
- ✅ `zamm.stg_draft_edits` - Manual edits to drafts

**Workout/Event Tables:**
- ✅ `zamm.workout_main` - Root workout table (NOT "workouts")
- ✅ `zamm.workout_sessions` - Session blocks within workouts
- ✅ `zamm.workout_blocks` - Individual training blocks
- ✅ `zamm.workout_items` - Exercise items within blocks

**Result Tables:**
- ✅ `zamm.res_item_sets` - Set-level results (reps, load, RPE)
- ✅ `zamm.res_blocks` - Block-level results (time, score)
- ✅ `zamm.res_intervals` - Interval segment results

**Library Tables (Reference Data):**
- ✅ `zamm.lib_athletes` - Master athlete catalog (NOT "dim_athletes")
- ✅ `zamm.lib_exercise_catalog` - All exercises
- ✅ `zamm.lib_equipment_catalog` - All equipment
- ✅ `zamm.lib_block_types` - All block types
- ✅ `zamm.lib_coaches` - Coach information
- ✅ `zamm.lib_parser_rulesets` - Parser configuration

**Configuration Tables:**
- ✅ `zamm.cfg_parser_rules` - Parser rules and patterns

**Logs:**
- ✅ `zamm.log_learning_examples` - Active learning corrections
- ✅ `zamm.log_validation_reports` - Historical validation reports

**Events:**
- ✅ `zamm.evt_athlete_personal_records` - PR achievements

### Critical Business Rule
**Prescription vs Performance Separation** - The most important concept:
- `prescription` = what was PLANNED
- `performed` = what actually HAPPENED

Every workout entity stores BOTH. Never mix them.

### Your Role (Copilot)
You are the **"Fast Coder"** - best for:
- ✅ Completing SQL function bodies
- ✅ Adding documentation
- ✅ Refactoring within files
- ✅ Writing complex queries

You are NOT for:
- ❌ Running terminal commands (use Claude Code)
- ❌ Executing migrations (use Claude Code)
- ❌ Multi-file operations (use Claude Code)

### Code Style
- SQL: lowercase_with_underscores
- Always use `zamm.` schema prefix
- PL/pgSQL for complex logic
- Comprehensive comments

### Before Writing SQL
1. ⚠️ **CRITICAL**: Use exact table names from the list above
2. Verify table exists in zamm schema (if unsure, check schema_snapshot.sql)
3. Check column names (don't assume!)
4. Use provided functions (check_exercise_exists, etc.)
5. Never INSERT directly into workout tables (use stored procedures)

**Common Table Name Mistakes to AVOID:**
- ❌ `zamm.imports` → ✅ `zamm.stg_imports`
- ❌ `zamm.workouts` → ✅ `zamm.workout_main`
- ❌ `zamm.dim_athletes` → ✅ `zamm.lib_athletes`
- ❌ `zamm.drafts` → ✅ `zamm.stg_parse_drafts`

## Common Patterns

### Exercise Normalization
```sql
-- ALWAYS do this first:
SELECT zamm.check_exercise_exists('bench press');
-- Returns canonical exercise_key
```

### Workout Commits
```sql
-- NEVER manually INSERT
-- Use stored procedure:
SELECT zamm.commit_full_workout_v3(...);
```

### Prescription/Performance Structure
```json
{
  "prescription": { "target_sets": 3, "target_reps": 5 },
  "performed": { "actual_sets": 3, "actual_reps": [5, 5, 4] }
}
```

## When You Need More Context

If the user asks about:
- Overall project architecture → Suggest they read ARCHITECTURE.md
- Current tasks → Suggest they check TODO.md
- Database status → Suggest they check DB_READINESS_REPORT.md
- Running commands → Suggest they use Claude Code in terminal

## Remember

You're excellent at **writing code**. You're not meant for **executing commands**. Work with your strengths! 🚀
