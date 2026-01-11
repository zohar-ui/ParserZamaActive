# CLAUDE.md

**Version:** 2.1.0
**Purpose:** STRICT PROTOCOL (not recommendations) for AI agents working on ParserZamaActive
**Last Updated:** January 11, 2026
**Breaking Changes:** Automatic documentation system now in place - docs auto-update after migrations

---

## 🚨 CRITICAL: This is Not a Suggestion Document

**This document contains MANDATORY PROTOCOLS, not recommendations.**

Failure to follow these protocols will result in:
- Writing code that references non-existent tables
- Documentation with incorrect schema information
- SQL queries that fail in production
- Data integrity violations

**When this document says "NEVER" or "ALWAYS" → it means exactly that.**

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

5. **Update Documentation** (Automatic)
   - After applying migrations: `npm run post-migration`
   - Or manually: `npm run update-docs`
   - Post-merge hook auto-updates docs when pulling migrations
   - Verify docs match database: check `VERIFIED_TABLE_NAMES.md`

6. **Commit**
   - Only after all tests pass
   - Write descriptive commit messages
   - Update `CHANGELOG.md` for user-facing changes
   - Commit auto-generated doc updates if present

---

## Verification Commands

**🎯 Note:** For database operations, prefer using **Supabase MCP tools** over bash scripts when available. Scripts are maintained for CI/CD and fallback scenarios.

### Quick Checks

**Database Verification:**
- **With MCP (Preferred):** Ask AI to inspect schema and verify table names
- **With Scripts (Fallback):** `./scripts/verify_schema.sh`

**Parser Validation:**
```bash
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
- `/inspect-table <table_name>` - **CRITICAL**: Show complete table structure including ALL constraints (CHECK, FK, UNIQUE, ENUMs). Use BEFORE every INSERT/UPDATE!
- `/fix` - Auto-repair common issues (if available)

---

## Automatic Documentation System

**Purpose:** Keep schema documentation synchronized with the database automatically.

### How It Works

1. **After Migrations:** Post-merge git hook detects migration changes and auto-updates docs
2. **Manual Trigger:** Run `npm run update-docs` or `npm run post-migration`
3. **Verification:** Always check `docs/reference/VERIFIED_TABLE_NAMES.md` for actual table names

### Commands

```bash
# Update documentation manually
npm run update-docs

# Run after applying migrations
npm run post-migration

# Or use the wrapper script
./scripts/docs/update_docs_after_migration.sh
```

### Git Hooks (Installed Automatically)

- **post-merge:** Auto-updates docs after pulling migrations
- **pre-commit:** Verifies schema version before commits

Install/reinstall hooks:
```bash
npm run install:hooks
# or
./scripts/install_hooks.sh
```

### ⚠️ Important Notes

1. **ALWAYS verify table names** using `inspect_db.sh` before writing SQL
2. **NEVER trust outdated docs** - use the verification tool as single source of truth
3. **Auto-update runs automatically** after `git pull` if migrations changed
4. **Commit doc changes** when they appear after running updater
5. **Database must be accessible** for auto-updates to work (requires `SUPABASE_DB_URL`)

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

## 🛑 MIGRATION PROTOCOL

**BEFORE creating, replacing, or modifying ANY database function or stored procedure:**

### Step 1: Check if Function Exists
```sql
SELECT
    proname as function_name,
    pg_get_function_identity_arguments(oid) as arguments,
    pg_get_functiondef(oid) as definition
FROM pg_proc
WHERE proname = 'your_function_name'
  AND pronamespace = 'zamm'::regnamespace;
```

### Step 2: If Function Exists with Different Arguments
**YOU MUST DROP IT FIRST:**
```sql
-- Drop with exact signature
DROP FUNCTION IF EXISTS zamm.function_name(UUID, UUID, JSONB);

-- Only then create new version
CREATE OR REPLACE FUNCTION zamm.function_name(...)
```

### Step 3: Version Functions Instead of Breaking Changes
**Preferred Approach:**
- Keep old version: `commit_full_workout_v3`
- Create new version: `commit_full_workout_v4`
- Update alias: `commit_full_workout_latest` → points to v4

**Why:** Backward compatibility + easy rollback

### Step 4: Test Before Committing
```sql
-- Test function compiles
SELECT zamm.your_function_name(test_params);

-- Verify it returns expected type
\df zamm.your_function_name
```

---

## 🔍 CONSTRAINT INSPECTION PROTOCOL

**CRITICAL:** PostgreSQL enforces constraints that are often invisible in documentation. Violating them causes cryptic errors.

### Rule: ALWAYS Run `/inspect-table` Before INSERT/UPDATE

**Example Failures Prevented:**
- ❌ `status = 'pending_review'` → Constraint only allows `['draft', 'completed', ...]`
- ❌ `checksum = 'abc123'` → Constraint requires exactly 64 hex characters (SHA-256)
- ❌ `approved_at = NULL` → Column has NOT NULL constraint
- ❌ `athlete_id = 'random-uuid'` → Foreign key requires existing record in `lib_athletes`

### Workflow for Writing INSERT/UPDATE:

```bash
# Step 1: Inspect target table (MANDATORY)
/inspect-table workout_main

# Step 2: Read output carefully
# - Check constraints (status values, format rules)
# - NOT NULL columns (must provide value)
# - Foreign keys (must reference existing records)
# - Unique constraints (cannot duplicate)
# - Enum types (only specific values allowed)

# Step 3: ONLY THEN write SQL using verified constraints
INSERT INTO zamm.workout_main (
    status,           -- ✅ Use value from CHECK constraint list
    approved_at,      -- ✅ NOT NULL - must provide timestamp
    athlete_id        -- ✅ Must exist in lib_athletes
) VALUES (
    'draft',          -- ✅ Valid per constraint
    NOW(),            -- ✅ Satisfies NOT NULL
    '<existing-uuid>' -- ✅ Verified via FK
);
```

### Why This Matters

**Before `/inspect-table` protocol:**
```
Try 1: INSERT with status='pending_review' → ❌ Constraint violation
Try 2: INSERT with status='draft', approved_at=NULL → ❌ NOT NULL violation
Try 3: INSERT with status='draft', approved_at=NOW() → ✅ Finally works
Result: 3 attempts, wasted time, frustration
```

**After `/inspect-table` protocol:**
```
Step 1: /inspect-table workout_main
Step 2: See constraints: status must be 'draft'|'completed'|..., approved_at NOT NULL
Step 3: INSERT with correct values → ✅ Works first time
Result: 1 attempt, no errors, efficient
```

---

## Common Pitfalls

### ❌ FORBIDDEN (These Will Cause Failures)
1. **NEVER trust documentation for table names** - Always verify with `inspect_db.sh`
2. **NEVER write SQL without verification** - Run inspection tool FIRST
3. **NEVER use `public` schema** - Always use `zamm`
4. **NEVER assume table names:**
   - Not `workout_main` → actual is `workouts`
   - Not `res_blocks` → actual is `workout_block_results`
   - Not `res_item_sets` → actual is `item_set_results`
   - Not `lib_block_types` → actual is `block_type_catalog`
5. **NEVER assume `session_code`** - Only use `"AM"`, `"PM"`, or `null`
6. **NEVER hardcode UUIDs** - Use catalog lookup functions
7. **NEVER mix prescription/performance** - Keep them strictly separated
8. **NEVER edit old migrations** - Create new ones instead
9. **NEVER skip validation** - Always run `/verify` before committing
10. **NEVER insert workouts manually** - Use `commit_full_workout_v3` procedure

### ✅ MANDATORY (Follow These Exactly)
1. **ALWAYS verify schema first** - Run `./scripts/utils/inspect_db.sh <table_name>` BEFORE any SQL
2. **ALWAYS inspect constraints** - Run `/inspect-table <table_name>` BEFORE any INSERT/UPDATE
3. **ALWAYS check function signatures** - Before DROP/CREATE OR REPLACE, verify existing definition
4. **ALWAYS use catalog lookups** - `check_exercise_exists`, `check_athlete_exists`
5. **ALWAYS normalize block types** - Via `normalize_block_code` function
6. **ALWAYS comment heavily** - SQL can be cryptic, explain complex logic
7. **ALWAYS verify docs against database** - Documentation may be outdated
8. **ALWAYS test with real data** - Use files from `/data/` directory
9. **ALWAYS preserve audit trail** - Never delete from `stg_*` tables
10. **ALWAYS use verified table names** - From inspection tool output only

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

## ⛔ FORBIDDEN: Documentation Trust

**CRITICAL WARNING:** Documentation files like `ARCHITECTURE.md`, `SCHEMA_REFERENCE.md`, and even `BLOCK_TYPES_REFERENCE.md` MAY BE OUTDATED OR INCORRECT.

### Rules (Strict Enforcement)

1. **NEVER assume table names from documentation**
   - Documentation says `workout_main`? → Might actually be `workouts`
   - Documentation says `res_blocks`? → Might actually be `workout_block_results`
   - Documentation says `lib_block_types`? → Might actually be `block_type_catalog`

2. **NEVER write SQL without verification**
   - Do NOT trust migration files older than current date
   - Do NOT trust inline documentation comments
   - Do NOT trust README files or architecture docs

3. **ALWAYS verify against live database**
   - **Preferred:** Use Supabase MCP tools to inspect schema
   - **Fallback:** Use `scripts/utils/inspect_db.sh <table_name>` if MCP unavailable
   - If verification returns "table does NOT exist" → find actual table name
   - Only use table/column names confirmed by verification (MCP or script)

---

## ✅ MANDATORY: Database Verification Protocol

**BEFORE writing ANY SQL code, documentation, or migration:**

### Method A: Using MCP (PREFERRED when available)

**Step 1: Verify Table Exists**
- Use Supabase MCP tool to inspect table schema
- Ask: "Show me the structure of the <table_name> table in zamm schema"
- Verify columns, data types, and constraints

**Step 2: Verify Column Names**
- Use MCP query to check specific columns
- Ask: "Does the workout_blocks table have a ui_hint column?"
- Confirm column exists before using in SQL

**Step 3: List All Available Tables**
- Use MCP to list all tables in zamm schema
- Ask: "List all tables in the zamm schema"
- Find actual table name if documentation is unclear

**Step 4: Write Code with Verified Names**
- Only use table/column names confirmed by MCP
- Never trust documentation without verification

### Method B: Using Bash Scripts (FALLBACK when MCP unavailable)

**Step 1: Verify Table Exists**
```bash
./scripts/utils/inspect_db.sh <table_name>
```
**Required Output:** Column list with data types
**If fails:** Table does not exist → search for actual name

**Step 2: Verify Column Names**
```bash
# Example: Check if workout_blocks has 'ui_hint' column
./scripts/utils/inspect_db.sh workout_blocks | grep ui_hint
```
**Required Output:** Column must appear in list
**If fails:** Column does not exist → check migration status

**Step 3: List All Available Tables**
```bash
psql "$SUPABASE_DB_URL" -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'zamm'
ORDER BY table_name;
"
```
**Use this when:** You need to find the actual table name

**Step 4: Only Then Write Code**

### Example Workflow

```bash
# ❌ WRONG - Trust documentation or guess
echo "SELECT * FROM zamm.workouts" > query.sql  # This table doesn't exist!

# ✅ CORRECT - Verify first (Method A: MCP)
# Ask AI: "Show me the structure of workout_main table"
# Confirm table exists and has expected columns
echo "SELECT * FROM zamm.workout_main" > query.sql

# ✅ CORRECT - Verify first (Method B: Bash fallback)
./scripts/utils/inspect_db.sh workout_main  # Check if 'workout_main' exists
# If success (shows columns):
echo "SELECT * FROM zamm.workout_main" > query.sql
```

### Step 5: Update Documentation (Automatic)

After applying migrations or making schema changes:
```bash
# Automatic (runs via git hook after pull)
git pull  # Automatically updates docs if migrations changed

# Manual (run after applying migrations)
npm run post-migration

# Or if you just want to refresh docs
npm run update-docs
```

**Note:** The documentation at `docs/reference/VERIFIED_TABLE_NAMES.md` is automatically maintained, but verification via **MCP (preferred)** or `inspect_db.sh` (fallback) remains the single source of truth. Always verify against live database before writing SQL.

---

## Database Structure (✅ VERIFIED 2026-01-11)

**Source:** Direct query to remote Supabase database
**Full List:** See `docs/reference/VERIFIED_TABLE_NAMES.md`
**Total:** 33 tables in `zamm` schema

### Core Workout Tables
- `workout_main` ✅ (NOT `workouts`)
- `workout_sessions` ✅
- `workout_blocks` ✅
- `workout_items` ✅
- `workout_item_set_results` ✅ (NOT `item_set_results`)

### Result Tables
- `res_blocks` ✅ (NOT `workout_block_results`)
- `res_intervals` ✅
- `res_item_sets` ✅

### Block Type System
- `lib_block_types` ✅ (NOT `block_type_catalog`)
- `lib_block_aliases` ✅ (NOT `block_code_aliases`)

### Exercise & Equipment Catalog
- `lib_exercise_catalog` ✅
- `lib_exercise_aliases` ✅
- `lib_equipment_catalog` ✅
- `lib_equipment_aliases` ✅
- `lib_equipment_config_templates` ✅

### Infrastructure
- `lib_athletes` ✅
- `lib_coaches` ✅
- `lib_parser_rulesets` ✅
- `cfg_parser_rules` ✅

### Staging/Import
- `stg_imports` ✅
- `stg_parse_drafts` ✅
- `stg_draft_edits` ✅

### Validation & Learning
- `log_validation_reports` ✅
- `log_learning_examples` ✅

### ❌ COMMON MISTAKES (Tables That DON'T Exist!)

| WRONG Name | CORRECT Name |
|------------|--------------|
| `workouts` | `workout_main` |
| `block_type_catalog` | `lib_block_types` |
| `block_code_aliases` | `lib_block_aliases` |
| `workout_block_results` | `res_blocks` |
| `item_set_results` | `res_item_sets` |

### 17 Block Types (Fixed Constants - Safe to Use)
**PREPARATION:** `WU`, `ACT`, `MOB`
**STRENGTH:** `STR`, `ACC`, `HYP`
**POWER:** `PWR`, `WL`
**SKILL:** `SKILL`, `GYM`
**CONDITIONING:** `METCON`, `INTV`, `SS`, `HYROX`
**RECOVERY:** `CD`, `STRETCH`, `BREATH`

---

## AI Agent Protocols

### MCP (Model Context Protocol) - PRIMARY METHOD

**Supabase MCP Server:** Configured in `.vscode/mcp.json`

**🎯 PREFERRED METHOD:** When MCP is available, use it INSTEAD of bash scripts for database operations.

#### MCP Capabilities (Use These First)

The Supabase MCP provides built-in tools:
- **Schema Inspection** - View table structures, columns, data types
- **Direct Queries** - Execute SQL directly without psql
- **Data Verification** - Check actual database content
- **Real-time Access** - No environment setup required

#### When to Use MCP vs Scripts

| Task | MCP (Preferred) | Bash Scripts (Fallback) |
|------|-----------------|-------------------------|
| **Inspect table schema** | ✅ Use MCP tools | ⚠️ Use if MCP unavailable |
| **Query database** | ✅ Use MCP tools | ⚠️ Use in CI/CD only |
| **Verify table exists** | ✅ Use MCP tools | ⚠️ Use if MCP unavailable |
| **List all tables** | ✅ Use MCP tools | ⚠️ Use if MCP unavailable |
| **CI/CD pipelines** | ❌ Not available | ✅ Always use scripts |
| **Automated tests** | ❌ Not available | ✅ Always use scripts |

See `.vscode/README.md` for MCP usage examples.

#### Decision Logic: MCP vs Bash Scripts

```
Is MCP available in current environment?
├─ YES → Use MCP for ALL database operations
│         (schema inspection, queries, verification)
│
└─ NO → Check why:
    ├─ In CI/CD pipeline → Use bash scripts
    ├─ In automated tests → Use bash scripts
    ├─ MCP not configured → Configure `.vscode/mcp.json` OR use scripts
    └─ Database offline → Cannot proceed (both methods need DB access)
```

**AI Agent Rule:** ALWAYS attempt MCP first. Only fall back to bash scripts if MCP tools are not available or the task explicitly requires scripts (CI/CD, testing).

### Protocol Zero: Session Handshake (MANDATORY)

Before executing ANY task involving database, choose your method:

#### Option A: With MCP (PREFERRED)

**Step 1: Verify MCP Connection**
- Check if Supabase MCP is available (configured in `.vscode/mcp.json`)
- Test by asking: "List all tables in the zamm schema"
- If successful, proceed with MCP for all database operations

**Step 2: Verify Actual Table Names (CRITICAL)**
- Use MCP to inspect key tables:
  - "Show structure of lib_athletes table"
  - "Show structure of workout_main table" (NOT workouts!)
  - "Show structure of workout_blocks table"
- DO NOT TRUST DOCUMENTATION - Always verify via MCP

**Step 3: Run Handshake Query**
- Use MCP to verify database state:
  - "Count records in zamm.lib_athletes"
  - "Count records in zamm.workout_main"
  - "Show active ruleset version from zamm.lib_parser_rulesets"

**Step 4: Reference Available Tables**
- Use MCP: "List all 33 tables in zamm schema with their counts"
- Store table names for reference during session

#### Option B: With Bash Scripts (FALLBACK when MCP unavailable)

**Step 0: Load Environment**
```bash
# Load database connection string
source .env.local  # or wherever SUPABASE_DB_URL is defined
```

**Step 1: Verify Database Connectivity**
```bash
npx supabase status
```

**Step 2: Verify Actual Table Names (CRITICAL)**
```bash
# DO NOT TRUST DOCUMENTATION - Verify actual tables exist:
./scripts/utils/inspect_db.sh lib_athletes
./scripts/utils/inspect_db.sh workout_main  # NOT workouts!
./scripts/utils/inspect_db.sh workout_blocks
```

**Step 3: Run Handshake Query (Use Verified Names)**
```bash
# ⚠️  ONLY use table names verified in Step 2
psql "$SUPABASE_DB_URL" -c "
SELECT
    (SELECT COUNT(*) FROM zamm.lib_athletes) as athlete_count,
    (SELECT COUNT(*) FROM zamm.workout_main) as workout_count,
    (SELECT version FROM zamm.lib_parser_rulesets WHERE is_active = true LIMIT 1) as active_ruleset;
"
```

**Step 4: List All Tables for Reference**
```bash
psql "$SUPABASE_DB_URL" -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'zamm'
ORDER BY table_name;
"
```

**CRITICAL:** Only proceed after ALL steps succeed. If Step 2 fails, do NOT guess table names - find the actual names using Step 4.

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

**With MCP (Preferred):**
- Ask: "Count all records in each table in zamm schema"
- Ask: "Show me the last 5 migrations that were applied"
- Ask: "Verify database connection and list all tables"

**With Bash Scripts (Fallback):**
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

---

## 📋 Task Breakdown Strategy

**Problem:** Complex requests attempted in one shot lead to errors, debugging cycles, and frustration.

**Solution:** Break every non-trivial task into atomic, verifiable steps.

### Example: Database Refactoring

**❌ WRONG - Single Mega-Prompt:**
```
"Refactor the database ingestion layer to handle v3.2 JSON,
add quality gates, create new stored procedure, test it, and
update documentation."
```
**Result:**
- Function signature conflicts
- Constraint violations
- Multiple retry cycles
- 2+ hours of debugging

**✅ CORRECT - Atomic Steps:**

**Prompt 1 (Schema):**
```
"Analyze the gap between JSON v3.2 and current database schema.
Propose ONLY the ALTER TABLE statements needed.
Do not write functions yet."
```
→ Review output → Apply if correct → Verify with `/inspect-table`

**Prompt 2 (Helper Functions):**
```
"Create the extract_measurement_value() helper function.
Test it with sample inputs before proceeding."
```
→ Test function → Verify compilation → Confirm it works

**Prompt 3 (Quality Check):**
```
"Create check_workout_quality() function.
Before writing, inspect stg_parse_drafts table constraints."
```
→ Use `/inspect-table stg_parse_drafts` → Write function → Test

**Prompt 4 (Main Procedure):**
```
"Create commit_full_workout_v4.
Before creating, check if commit_full_workout_latest exists and needs dropping."
```
→ Check existing functions → DROP if needed → CREATE new version

**Prompt 5 (Testing):**
```
"Create test data for v4.
First inspect workout_main constraints, then create valid test records."
```
→ Use `/inspect-table` → Write INSERT with valid values → Test commit

**Result:**
- Each step succeeds on first try
- Easy to debug (know exactly which step failed)
- Can pause/resume at any point
- Total time: Less than "one-shot" approach

### General Principle

**Before:** "Do everything" → ❌ Fails at step 3 of 7 → Redo all 7 steps

**After:** "Do step 1" → ✅ → "Do step 2" → ✅ → ... → All steps succeed

**Time Savings:** 60-80% reduction in debugging cycles

---

**Last Updated:** January 11, 2026
**Version:** 2.2.0 - Added Migration Protocol, Constraint Inspection, Task Breakdown Strategy
**Maintained By:** AI Development Team
