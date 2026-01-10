# AGENTS.MD

**Source of Truth for AI Agents Working on ParserZamaActive**

This document defines how to work correctly on this specific project. Read this first before making changes.

**⚖️ CRITICAL:** For ALL parsing outputs, strict adherence to [`docs/reference/CANONICAL_JSON_SCHEMA.md`](docs/reference/CANONICAL_JSON_SCHEMA.md) is **MANDATORY**. This is the constitution - the only allowed JSON structure.

---

## 🤖 AI AGENT ROLES & DIVISION OF LABOR

### The Protocol: Know Your Role

This project uses **two complementary AI tools**. Understanding their roles prevents inefficiency:

#### GitHub Copilot (The Micro / "The Fast Coder")
**Location:** Inside VS Code editor  
**Role:** Code writing and completion within open files  
**Permissions:** Read/write files, suggest code  
**Cannot:** Execute terminal commands, run migrations, manage git

**Use Copilot when:**
- ✅ Writing SQL functions (auto-complete BEGIN...END)
- ✅ Adding documentation comments to existing code
- ✅ Refactoring variables/functions within a file
- ✅ Generating TypeScript types from schemas
- ✅ Writing test queries in open SQL file

**Rule of thumb:** File open in front of you? → **Use Copilot**

---

#### Claude Code CLI (The Macro / "The Operator")
**Location:** Terminal  
**Role:** Autonomous execution agent  
**Permissions:** Run commands, read/write files, execute SQL, manage system  
**Cannot:** Edit files interactively like an IDE

**Use Claude Code when:**
- ✅ "Run the TODO.md tasks and report results"
- ✅ "Check all table counts and identify issues"
- ✅ "Execute migration and fix any errors"
- ✅ "Explain the entire project architecture"
- ✅ "Commit changes and push to git"
- ✅ Multi-file operations (create migration + update docs + run tests)

**Rule of thumb:** Need to execute commands or work across files? → **Use Claude Code**

---

### The Context Bridge: agents.md

Both tools need project memory. **This file (agents.md) IS that memory.**

**Problem:** Agents don't automatically remember previous sessions.  
**Solution:** Load this file at session start.

#### For Claude Code (Mandatory Init):
```bash
# ALWAYS run this first when starting Claude Code:
claude "Read agents.md and DB_READINESS_REPORT.md to restore context. Then run PROTOCOL ZERO handshake."
```

This "loads" the project into Claude's memory:
- Schema structure (27 tables)
- Business rules (prescription vs performance)
- Critical workflows (validation, commits)
- Common pitfalls to avoid

#### For GitHub Copilot:
Create `.github/copilot-instructions.md` with:
```
You are an expert SQL agent working on ParserZamaActive.
Your source of truth is agents.md.
Before answering complex queries, read agents.md to understand architecture and rules.
```

---

## 🎯 IDENTITY & AUTHORITY

**WHO YOU ARE:**
You are the **Operator** of this database system, not a consultant. You have full authority to:
- ✅ Execute SQL queries directly
- ✅ Run migrations
- ✅ Create/modify functions
- ✅ Insert/update data
- ✅ Deploy changes

**CRITICAL MINDSET:**
- **DO NOT ASK** "Should I run this SQL?" → **YOU RUN IT**
- **DO NOT SUGGEST** "Here's what you could do..." → **YOU DO IT**
- **DO NOT WAIT** for permission → **EXECUTE IMMEDIATELY**

**Your job:** Make decisions, execute, report results. Ask questions ONLY when data/context is missing, never for permission.

---

## 🚦 PROTOCOL ZERO: Session Startup (Mandatory Handshake)

**⚠️ CRITICAL: Before executing any task, perform this verification checklist:**

### 1. **Environment Check**
```bash
# Verify Supabase CLI is accessible
npx supabase --version

# Check project linkage
npx supabase status
```

### 2. **Database Connectivity Test**
Run this validation query to confirm read/write access:

```sql
-- Handshake Query
SELECT 
    (SELECT COUNT(*) FROM zamm.lib_athletes) as athlete_count,
    (SELECT COUNT(*) FROM zamm.workout_main) as workout_count,
    (SELECT version FROM zamm.lib_parser_rulesets WHERE is_active = true LIMIT 1) as active_ruleset;
```

**Expected Result:**
```
athlete_count | workout_count | active_ruleset
--------------|---------------|---------------
    10+       |     50+       |    v1.0
```

### 3. **Schema Awareness Check** (Critical!)
**⚠️ RULE: NEVER assume table/column names. ALWAYS verify first!**

#### Method 1: Use verification script (recommended)
```bash
# List all tables
./scripts/verify_schema.sh

# Check specific table structure
./scripts/verify_schema.sh workout_main
```

#### Method 2: SQL query
Load current table structures to ensure SQL accuracy:

```sql
-- Get ALL table names in zamm schema
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'zamm' 
ORDER BY table_name;

-- Get structure of specific table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'zamm' 
  AND table_name = 'workout_main'
ORDER BY ordinal_position;
```

**What to verify:**
- ✅ Table exists in zamm schema
- ✅ Column names match exactly (case-sensitive!)
- ✅ Data types are correct
- ✅ No assumptions about plural/singular names
- ✅ Check for prefixes: `lib_`, `stg_`, `log_`, `res_`, etc.

**Common mistakes to avoid:**
- ❌ Assuming `lib_athletes` when it's actually `dim_athletes`
- ❌ Assuming `workout_items` without checking schema
- ❌ Using outdated names from documentation
- ❌ Guessing plural/singular forms

**Store this output mentally** - you'll need it for writing correct SQL!

### 4. **Status Report**
* ✅ **Success:** Report `"System Connected: [X] athletes, [Y] workouts found. Ruleset: [version]. Schema: [table_count] tables verified. Ready to operate."` → Proceed immediately to task.
* ❌ **Failure:** Report `"Connection failed. Error: [Details]. Please verify .env.local credentials or run: npx supabase link"` → HALT until resolved.

### 7. **Total Time Budget**
- **Full handshake: 10-15 seconds** (including learning loop)
- Runs **once per session**
- Prevents **hours of debugging** and **repeated mistakes**

### 6. **Critical Environment Variable**
**⚠️ BLOCKER:** Without this, NOTHING will work:

```bash
# Check if SUPABASE_ACCESS_TOKEN exists
echo $SUPABASE_ACCESS_TOKEN
# Must return a token, not empty!
```

**Where to set:**
- **Cursor/VS Code:** `.env.local` file (already exists)
- **CLI:** `npx supabase login` (stores in `~/.supabase/`)
- **Scripts:** Can be exported in shell or stored in `.env`

**Without this token:** Agent has no "key" to access the database. All operations will fail silently or with permission errors.

**This handshake ensures:**
- ✅ Database is accessible and responsive
- ✅ Schema is deployed correctly with expected tables
- ✅ Active ruleset is available for parsing
- ✅ **Agent knows exact table structures** (columns, types)
- ✅ No blind operations on disconnected/empty database
- ✅ No SQL errors from outdated schema assumptions

**Why Schema Awareness Matters:**
If a migration added/removed columns, the agent must know about it before writing SQL. This 3-second check prevents syntax errors and failed queries.

---

## 1. 🛠️ Tech Stack & Environment

### Core Database
* **Database:** Supabase (PostgreSQL 17)
* **Schema:** `zamm`
* **Project ID:** `dtzcamerxuonoeujrgsu`
* **Connection:** Linked via Supabase CLI

### Language & Frameworks
* **Primary Language:** SQL (PostgreSQL/PL/pgSQL)
* **Version Control:** Git/GitHub
* **AI Integration:** Direct API calls (OpenAI/Claude/Gemini)
* **Scripting:** Bash shell scripts

### Key Components
* **Migrations:** Version-controlled SQL migrations in `/supabase/migrations/`
* **Functions:** SQL functions for AI tools, validation, and data processing
* **Stored Procedures:** Atomic workout commits (`commit_full_workout_v3`)
* **Documentation:** Comprehensive Markdown docs in `/docs/`

### Development Environment
* **Container:** Dev container on Ubuntu 24.04.3 LTS
* **Tools Available:** Supabase CLI, git, gh, docker, curl, bash
* **Editor:** VS Code

---

## 2. ⚙️ Operational Workflow (CLI)

### Database Operations

**🚨 CRITICAL RULE: BEFORE ANY MIGRATION OR DATA INSERT**
```bash
# ALWAYS CHECK EXISTING STATE FIRST!
# 1. Check if table exists
echo "SELECT table_name FROM information_schema.tables WHERE table_schema='zamm' AND table_name='your_table';" | \
  PGPASSWORD="xxx" psql -h db.xxx.supabase.co -U postgres -d postgres -t

# 2. Check if data exists
echo "SELECT COUNT(*) FROM zamm.your_table;" | \
  PGPASSWORD="xxx" psql -h db.xxx.supabase.co -U postgres -d postgres -t

# 3. Check structure
echo "\d zamm.your_table" | \
  PGPASSWORD="xxx" psql -h db.xxx.supabase.co -U postgres -d postgres
```

**Standard Operations:**
```bash
# Check connection status
supabase status

# Pull latest schema from remote (if Docker fails, use dump instead)
supabase db pull
# Workaround: supabase db dump --schema zamm -f supabase/schema_snapshot.sql

# Push local migrations to remote
subase db push

# Reset local database (if running locally)
supabase db reset

# Generate TypeScript types (if needed)
supabase gen types typescript --linked > types/database.ts
```

### Testing & Validation
```bash
# Run block type system tests
cd /workspaces/ParserZamaActive
./scripts/test_block_types.sh

# Execute SQL test queries (manual)
# Copy from docs/api/QUICK_TEST_QUERIES.sql into Supabase dashboard
```

### Git Workflow
```bash
# Standard git operations
git status
git add .
git commit -m "descriptive message"
git push origin main
```

**⚠️ CRITICAL:** Always use the exact commands above. Do NOT:
- Run `supabase start` (we use linked remote database)
- Install npm packages (this is SQL-only project)
- Use Docker Compose (managed by Supabase)

---

## 3. 📐 Project Architecture & Structure

### Directory Map

```
/workspaces/ParserZamaActive/
├── 📄 Core Docs (Root Level)
│   ├── README.md              # Project overview & quick start
│   ├── ARCHITECTURE.md        # System design & patterns
│   ├── CHANGELOG.md           # Version history (v1.0.0)
│   ├── DB_READINESS_REPORT.md # Database status (85/100)
│   └── agents.md              # THIS FILE - AI agent guide
│
├── 📚 docs/                   # All documentation
│   ├── INDEX.md               # Documentation navigation
│   ├── guides/                # Implementation guides
│   │   └── AI_PROMPTS.md             # AI agent templates (335 lines)
│   ├── reference/             # Technical reference
│   │   ├── BLOCK_TYPES_REFERENCE.md  # 17 block types catalog
│   │   └── BLOCK_TYPE_SYSTEM_SUMMARY.md
│   ├── api/                   # SQL & API docs
│   │   └── QUICK_TEST_QUERIES.sql
│   └── archive/               # Historical docs
│
├── 💾 data/                   # Sample workout logs (10 text files)
│   └── *.txt                  # Raw workout data for testing
│
├── 🔧 scripts/                # Utility scripts
│   ├── README.md              # Script documentation
│   └── test_block_types.sh   # Block type system tests
│
└── 🗄️ supabase/              # Database configuration
    ├── config.toml            # Supabase project config
    └── migrations/            # Version-controlled SQL migrations
        ├── 20260104112029_remote_schema.sql
        ├── 20260104120000_create_ai_tools.sql
        ├── 20260104120100_create_validation_functions.sql
        ├── 20260104120200_commit_full_workout_v3.sql
        ├── 20260104130000_priority1_exercise_catalog_indexes.sql
        ├── 20260104140000_block_type_system.sql
        ├── 20260107140000_fix_table_references.sql
        └── 20260107150000_comprehensive_validation_functions.sql
```

### Key Architectural Patterns

#### 0. **Parser Output Contract** ⚖️ (CRITICAL!)
**Before parsing ANYTHING, read:** [`docs/reference/CANONICAL_JSON_SCHEMA.md`](docs/reference/CANONICAL_JSON_SCHEMA.md)

This document defines the ONLY allowed JSON structure. Do NOT guess or invent structure.

**5 Core Principles:**
1. Prescription vs Performed separation (ALWAYS separate)
2. Atomic types (numbers are numbers, not strings)
3. Ranges as min/max (never "8-12" strings)
4. Strict normalization (exercise_key, block_code from catalogs)
5. Null safety (unknown = null, never hallucinate)

#### 1. **4-Stage Data Flow**
```
Raw Text → Draft JSON → Normalized JSON → Relational Tables
   ↓           ↓              ↓                ↓
imports   parse_drafts   validation      workout_*
            ↑
            └── MUST follow CANONICAL_JSON_SCHEMA.md
```

#### 2. **Prescription vs Performance Separation** (CRITICAL!)
The most important concept in this system:
- **Prescription:** What was PLANNED ("3x5 @ 100kg")
- **Performance:** What actually HAPPENED ("got only 4 reps in last set")

Every workout entity stores BOTH fields:
```json
{
  "prescription": { /* planned workout */ },
  "performed": { /* actual execution */ }
}
```

#### 3. **Catalog + Aliases Pattern**
Used throughout for exercises, equipment, block types:
```
Master Catalog (canonical keys) ←→ Aliases Table (multiple names)
```

#### 4. **Hierarchical Workout Structure**
```
workout_main (header)
  └─ workout_sessions (AM/PM)
      └─ workout_blocks (A, B, C)
          └─ workout_items (exercises)
              └─ workout_item_set_results (individual sets)
```

#### 5. **AI Tools Pattern**
SQL functions callable by AI agents:
- `check_athlete_exists(name)` - Athlete lookup
- `check_equipment_exists(name)` - Equipment validation
- `get_active_ruleset()` - Parser rules
- `get_athlete_context(id)` - Full context
- `normalize_block_type(type)` - Type normalization

#### 6. **Validation System (Stage 3)**
Production validation functions for parsed JSON:
- `validate_parsed_structure()` - Basic JSON structure
- `validate_block_codes()` - 17 standard block codes
- `validate_data_values()` - Numeric range validation
- `validate_catalog_references()` - Exercise/equipment lookup
- `validate_prescription_performance_separation()` - Critical separation rule
- `validate_parsed_workout()` - Master function (runs all checks)
- `auto_validate_and_commit()` - Automated workflow

#### 7. **Active Learning System (New!)** 🔄
Closes feedback loop between corrections and training:
- Corrections stored in `log_learning_examples` table
- Script (`update_parser_brain.js`) fetches high-priority examples
- Examples injected into `AI_PROMPTS.md` as few-shot learning
- Parser learns from past mistakes automatically
- Run with: `npm run learn`

---

## 4. 📝 Coding Standards & Rules

### SQL Style
* **Function Names:** `lowercase_with_underscores`
* **Schema Prefix:** Always use `zamm.` prefix (e.g., `zamm.workout_main`)
* **Comments:** Use banner comments for major sections
  ```sql
  -- ============================================
  -- Section Name
  -- ============================================
  -- Purpose: Clear explanation
  ```
* **Indentation:** 4 spaces (no tabs)
* **Language:** PL/pgSQL for complex logic, plain SQL for simple queries

### Naming Conventions
* **Tables:** `lowercase_with_underscores` (e.g., `workout_main`, `workout_blocks`, `lib_athletes`)
* **Columns:** `lowercase_with_underscores` (e.g., `workout_id`, `block_code`)
* **Primary Keys:** `{table_singular}_id` (e.g., `workout_id`, `block_id`)
* **Foreign Keys:** Match referenced column name exactly
* **JSONB Fields:** `snake_case` keys in JSON (e.g., `session_info`, `target_reps`)

### Data Types
* **UUIDs:** Use `uuid_generate_v4()` for all IDs
* **Timestamps:** `timestamptz` for all timestamps, use `NOW()` for current time
* **Dates:** `DATE` type, format: `YYYY-MM-DD`
* **Numbers:** `NUMERIC(precision, scale)` for measurements (e.g., weights)
* **Text:** `VARCHAR(n)` for constrained text, `TEXT` for unlimited

### Migration Standards
* **Naming:** `YYYYMMDDHHMMSS_descriptive_name.sql`
* **Idempotency:** Use `CREATE OR REPLACE` for functions
* **Safety:** Use `IF NOT EXISTS` for table creation
* **Comments:** Every function and table must have `COMMENT ON` statement
* **Testing:** Create test script in `/scripts/` for new features

### Error Handling
* **Stored Procedures:** Use `EXCEPTION` blocks for critical operations
* **Validation:** Return detailed error messages with context
* **Transactions:** All multi-table operations in single transaction
* **Rollback:** Use `RAISE EXCEPTION` to abort on critical errors

### Documentation Requirements
* **Every New Feature:** Update relevant docs in `/docs/`
* **Migration:** Add explanation comment at top of SQL file
* **API Changes:** Update `QUICK_TEST_QUERIES.sql`
* **Changelog:** Add entry to `CHANGELOG.md`
* **README:** Update if user-facing commands change

---

## 5. 🧠 Project Memory & Constraints

### Hard Constraints
1. **Core Backend is SQL-only:** This is primarily a SQL-based backend project
   - **EXCEPTION:** Node.js is allowed ONLY for operational scripts in `/scripts/` folder (Active Learning, automation utilities)
   - **ALLOWED:** `package.json`, `npm`, and `node_modules` for utility scripts
   - **NOT ALLOWED:** TypeScript/JavaScript for core database logic or API endpoints
2. **NO local database:** Always work with linked Supabase remote
3. **NO .env files in git:** Secrets managed by Supabase CLI (`.env.local` exists but is gitignored)
4. **Schema is `zamm`:** Never use `public` schema

### Critical Business Rules

#### 🔴 RULE #1: Exercise Name Normalization (DATA INTEGRITY)
**THE MOST CRITICAL RULE FOR DATA QUALITY**

```sql
-- ✅ ALWAYS do this:
SELECT zamm.check_exercise_exists('bench');
-- Returns: canonical exercise_key

-- ❌ NEVER do this:
INSERT INTO workout_items (exercise_name) VALUES ('bench press');
-- Will create data inconsistency!
```

**Why Critical:**
- Without normalization: "Bench", "Bench Press", "BP" = 3 different exercises
- Analytics & progress tracking will be **broken**
- Years of data become **unusable**

**The Law:**
1. ALWAYS use `check_exercise_exists()` first
2. ALWAYS use `exercise_key` from `exercise_catalog`
3. NEVER accept free-text exercise names

#### 🔴 RULE #2: Atomic Commits via Stored Procedures
**NEVER manually INSERT into workout tables**

```sql
-- ✅ CORRECT:
SELECT zamm.commit_full_workout_v3(
    import_id, draft_id, ruleset_id, athlete_id, normalized_json
);

-- ❌ WRONG:
INSERT INTO zamm.workouts ...
INSERT INTO zamm.workout_sessions ...
INSERT INTO zamm.workout_blocks ...
-- This WILL break data integrity!
```

**Why Critical:**
- 4 related tables must be inserted in **exact order**
- Prescription/Performance separation is complex

#### 🚨 CRITICAL (Will Destroy Data)
❌ **NEVER:**
1. Accept free-text exercise names without normalization
2. INSERT directly into workout tables (use stored procedure)
3. Mix prescription and performance in same field
4. Skip `check_exercise_exists()` validation

#### ⚠️ IMPORTANT (Will Cause Bugs)
❌ **DON'T:**
- Create tables in `public` schema
- Edit existing migration files
- Hardcode athlete/exercise IDs
- Use non-standard block types
- Skip validation stage

#### ✅ BEST PRACTICES
 ✅ CORRECT:
{
  "prescription": { "target_sets": 3, "target_reps": 5 },
  "performed": { "actual_sets": 3, "actual_reps": [5, 5, 4] }
}

// ❌ WRONG:
{
  "sets": 3,  // Which one? Plan or reality?
  "reps": 5   // Ambiguous!
}
```

**Why Critical:**
- Core architectural principle
- Enables progress tracking and program adherence analysis
- Mixed data = impossible to analyze

**The Law:** Every workout entity has BOTH fields. If you see only one, something is wrong.

#### 🟡 RULE #4: Block Type System
Use only the 17 standardized types:
- Categories: PREPARATION, STRENGTH, POWER, SKILL, CONDITIONING, RECOVERY
- Always normalize via `normalize_block_code()` function
- Support Hebrew, English, and abbreviations

#### 🟡 RULE #5: Data Pipeline Stages
All data goes through validation:
- Stage 1: Ingestion (imports table)
- Stage 2: Parsing (parse_drafts table)
- Stage 3: Validation (validation_reports table)
- Stage 4: Commit (workout_* tables)

### Known Limitations
* **No Real-time Validation:** Validation happens after parsing
* **Manual Alias Management:** New equipment/exercise names require manual aliases
* **Hebrew Support:** Partial - focused on block types currently
* **No Video Links:** Exercise catalog has metadata but no video URLs yet

### Development Principles
1. **Documentation First:** Update docs before/with code changes
2. **Test Scripts Required:** Every new feature needs test script
3. **Migration Discipline:** Never edit old migrations, create new ones
4. **Comment Heavy:** SQL can be cryptic, explain complex logic
5. **Idempotency:** Functions should be redeployable without errors

### AI Agent Specific Guidelines
1. **Read Architecture First:** Always read `ARCHITECTURE.md` before major changes
2. **Check Existing Patterns:** Look for similar implementations
3. **Use AI Tools:** Call provided SQL tools for context
4. **Follow Prompts:** Use templates from `docs/guides/AI_PROMPTS.md`
5. **Validate Output:** Use validation functions before commit
6. **Preserve Audit Trail:** Never delete from staging tables

### Common Pitfalls to Avoid
❌ **DON'T:**
- Mix prescription and performance data
- Create tables in `public` schema
- Edit existing migration files
- Insert into workout tables without stored procedure
- Hardcode athlete/exercise IDs
- Use non-standard block types
- Skip validation stage

✅ **DO:**
- Use catalog + aliases pattern for all lookups
- Normalize block types via `normalize_block_code()`
- Store both prescription and performed fields
- Use JSONB for flexible workout structures
- Create migrations for schema changes
- Write comprehensive comments
- Test with sample data from `/data/`

---

## 6. 🔍 Quick Reference

### Most Used Commands
```bash
# Check what migrations are pending
supabase db diff

# View database logs
supabase logs db

# Open Supabase dashboard
supabase dashboard
```

### Most Important Files
1. **`docs/reference/CANONICAL_JSON_SCHEMA.md`** ⚖️ - **THE CONSTITUTION** (parser output rules)
2. `ARCHITECTURE.md` - Understand system design
3. `docs/guides/AI_PROMPTS.md` - Agent prompt templates (auto-updated by learning loop)
4. `docs/guides/PARSER_WORKFLOW.md` - Complete parser workflow (4 stages)
5. `docs/guides/PARSER_AUDIT_CHECKLIST.md` - Validation checklist
6. `docs/VALIDATION_SYSTEM_SUMMARY.md` - Validation system quick reference
7. `docs/reference/BLOCK_TYPES_REFERENCE.md` - Block types catalog
8. `scripts/update_parser_brain.js` - Active learning loop script
9. `scripts/ACTIVE_LEARNING_README.md` - Learning system documentation
10. `supabase/migrations/20260107150000_comprehensive_validation_functions.sql` - Validation functions
11. `supabase/migrations/20260104120200_commit_full_workout_v3.sql` - Commit function

### Key Database Tables (32 total in zamm schema)
* **Infrastructure:** `lib_athletes`, `lib_parser_rulesets`, `lib_coaches`
* **Catalogs:** `lib_exercise_catalog`, `lib_equipment_catalog`, `lib_block_types` (+ aliases)
* **Staging:** `stg_imports`, `stg_parse_drafts`, `stg_draft_edits`
* **Validation:** `log_validation_reports`
* **Workout Core:** `workout_main`, `workout_sessions`, `workout_blocks`, `workout_items`, `workout_item_set_results`
* **Results:** `res_blocks`, `res_intervals`, `res_item_sets`
* **Events:** `evt_athlete_personal_records`

### 17 Block Types (Memorize These)
**PREPARATION:** WU, ACT, MOB  
**STRENGTH:** STR, ACC, HYP  
**POWER:** PWR, WL  
**SKILL:** SKILL, GYM  
**CONDITIONING:** METCON, INTV, SS, HYROX  
**RECOVERY:** CD, STRETCH, BREATH

---

## 7. 🎯 ProActive Learning System Deployed (98/100)  
**Date:** January 10, 2026  
**Next Phase:** Capture corrections and train parser continuousl
**Status:** Production validation system deployed (95/100)  
**Date:** January 7, 2026  
**Next Phase:** Data cleanup and production data entry

### What's Working
✅ Complete database schema (32 tables in zamm)  
✅ AI tools (5 functions)  
✅ **Production validation system (6 functions)**  
✅ **Automated workflow (auto_validate_and_commit)**  
✅ **Stage 3 validation integrated**  
✅ **Canonical JSON Schema (The Constitution)** ⚖️ 🆕  
✅ **Active Learning System** 🔄 🆕  
✅ **Parser Brain Auto-Update (npm run learn)** 🧠 🆕  
✅ Block type system (17 types, 60+ aliases)  
✅ Exercise catalog (14 seed exercises)  
✅ Atomic workout commit procedure  
✅ Comprehensive documentation (2000+ lines total, including learning system)  
✅ Schema synchronized (lib_* naming)  
✅ View for validation status dashboard
Auto-capture learning examples during validation (currently manual)
### What's Missing
⏳ Frontend UI (review page for validation results)  
⏳ Batch data cleanup before production entry  
⏳ Video links for exercises  
⏳ Multi-language support beyond Hebrew/English  
⏳ Analytics views and dashboards  
⏳ Integration testing suite

---

## 8. 🚀 Getting Started Checklist

When working as an AI agent on this project:

### Phase 0: Connection Handshake (MANDATORY)
- [ ] **Run PROTOCOL ZERO** (see top of this file)
- [ ] Verify database connectivity
- [ ] Confirm athlete count > 0
- [ ] Validate active ruleset exists
docs/reference/CANONICAL_JSON_SCHEMA.md` ⚖️ **CRITICAL for parsing**
- [ ] Read `ARCHITECTURE.md` for system design
- [ ] Review `docs/guides/AI_PROMPTS.md` for AI agent templates (check for learning examples)
- [ ] Check `CHANGELOG.md` for recent changes (v1.2.0 added Active Learning)
- [ ] Read `ARCHITECTURE.md` for system design
- [ ] Review `docs/guides/AI_PROMPTS.md` for AI agent templates
- [ ] Check `CHANGELOG.md` for recent changes

### Phase 2: Environment Setup
- [ ] Run `npx supabase status` to verify connection
- [ ] Run `npm install` to install dependencies (for learning loop)
- [ ] Run `npm run learn` to update parser with latest corrections
- [ ] Check `.env.local` has correct credentials
- [ ] Test with `scripts/test_block_types.sh`

### Phase 3: Domain Knowledge
- [ ] Understand **Prescription vs Performance** separation (CRITICAL!)
- [ ] Familiarize with 17 block types
- [ ] Review stored procedures in migrations folder
- [ ] Check `/data/*.txt` for example workout formats

### Phase 4: Ready State
- [ ] All above checkboxes completed ✅
- [ ] Database connection verified ✅
- [ ] Can proceed with task execution 🚀

---

**Last Updated:** January 7, 2026  
**Maintained By:** AI Development Team  
**Purpose:** Single source of truth for all AI agents working on this project
