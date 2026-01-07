# AGENTS.MD

**Source of Truth for AI Agents Working on ParserZamaActive**

This document defines how to work correctly on this specific project. Read this first before making changes.

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
    (SELECT COUNT(*) FROM zamm.dim_athletes) as athlete_count,
    (SELECT COUNT(*) FROM zamm.workouts) as workout_count,
    (SELECT version FROM zamm.parser_rulesets WHERE is_active = true LIMIT 1) as active_ruleset;
```

**Expected Result:**
```
athlete_count | workout_count | active_ruleset
--------------|---------------|---------------
    10+       |     50+       |    v1.0
```

### 3. **Status Report**
* ✅ **Success:** Report `"System Connected: [X] athletes, [Y] workouts found. Ruleset: [version]. Ready to operate."` → Proceed immediately to task.
* ❌ **Failure:** Report `"Connection failed. Error: [Details]. Please verify .env.local credentials or run: npx supabase link"` → HALT until resolved.

### 4. **Schema Verification** (Optional, for complex operations)
```sql
-- Verify zamm schema exists and has expected tables
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'zamm';
-- Expected: 20+ tables
```

**This handshake ensures:**
- Database is accessible
- Schema is deployed correctly
- Active ruleset is available for parsing
- No blind operations on disconnected/empty database

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
* **AI Integration:** n8n workflows (OpenAI/Claude/Gemini)
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
```bash
# Check connection status
supabase status

# Pull latest schema from remote
supabase db pull

# Push local migrations to remote
supabase db push

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
│   │   ├── N8N_INTEGRATION_GUIDE.md  # Complete n8n setup (572 lines)
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
        └── 20260104140000_block_type_system.sql
```

### Key Architectural Patterns

#### 1. **4-Stage Data Flow**
```
Raw Text → Draft JSON → Normalized JSON → Relational Tables
   ↓           ↓              ↓                ↓
imports   parse_drafts   validation      workout_*
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
workouts (header)
  └─ workout_sessions (AM/PM)
      └─ workout_blocks (A, B, C)
          └─ workout_items (exercises)
              └─ item_set_results (individual sets)
```

#### 5. **AI Tools Pattern**
SQL functions callable by AI agents:
- `check_athlete_exists(name)` - Athlete lookup
- `check_equipment_exists(name)` - Equipment validation
- `get_active_ruleset()` - Parser rules
- `get_athlete_context(id)` - Full context
- `normalize_block_type(type)` - Type normalization

---

## 4. 📝 Coding Standards & Rules

### SQL Style
* **Function Names:** `lowercase_with_underscores`
* **Schema Prefix:** Always use `zamm.` prefix (e.g., `zamm.workouts`)
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
* **Tables:** `lowercase_plural` (e.g., `workouts`, `workout_blocks`)
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
1. **NO TypeScript/JavaScript:** This is a SQL-only backend project
2. **NO package.json:** We don't use Node.js or npm
3. **NO local database:** Always work with linked Supabase remote
4. **NO .env files:** Secrets managed by Supabase CLI
5. **Schema is `zamm`:** Never use `public` schema

### Critical Business Rules
1. **Prescription vs Performance:** NEVER mix these concepts
   - Prescription = Plan (what should happen)
   - Performance = Reality (what did happen)
   - Store separately in every table/JSON structure

2. **Block Type System:** Use only the 17 standardized types
   - Categories: PREPARATION, STRENGTH, POWER, SKILL, CONDITIONING, RECOVERY
   - Always normalize via `normalize_block_code()` function
   - Support Hebrew, English, and abbreviations

3. **Data Quality:** All data goes through validation
   - Stage 1: Ingestion (imports table)
   - Stage 2: Parsing (parse_drafts table)
   - Stage 3: Validation (validation_reports table)
   - Stage 4: Commit (workout_* tables)

4. **Atomic Commits:** Use stored procedures for multi-table inserts
   - `commit_full_workout_v3` is current version
   - Never insert into workout tables directly
   - All-or-nothing transaction semantics

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
1. `ARCHITECTURE.md` - Understand system design
2. `docs/guides/AI_PROMPTS.md` - Agent prompt templates
3. `docs/reference/BLOCK_TYPES_REFERENCE.md` - Block types catalog
4. `supabase/migrations/20260104120200_commit_full_workout_v3.sql` - Current commit function

### Key Database Tables
* **Infrastructure:** `dim_athletes`, `parser_rulesets`, `equipment_catalog`, `exercise_catalog`
* **Staging:** `imports`, `parse_drafts`, `validation_reports`
* **Workout Core:** `workouts`, `workout_sessions`, `workout_blocks`, `workout_items`
* **Results:** `item_set_results`, `workout_block_results`, `interval_segments`

### 17 Block Types (Memorize These)
**PREPARATION:** WU, ACT, MOB  
**STRENGTH:** STR, ACC, HYP  
**POWER:** PWR, WL  
**SKILL:** SKILL, GYM  
**CONDITIONING:** METCON, INTV, SS, HYROX  
**RECOVERY:** CD, STRETCH, BREATH

---

## 7. 🎯 Project Status

**Version:** 1.0.0  
**Status:** Database structure complete (85/100)  
**Date:** January 2026  
**Next Phase:** Frontend development and real-time validation

### What's Working
✅ Complete database schema  
✅ AI tools (5 functions)  
✅ Validation functions (5 functions)  
✅ Block type system (17 types, 60+ aliases)  
✅ Exercise catalog (14 seed exercises)  
✅ Atomic workout commit procedure  
✅ Comprehensive documentation

### What's Missing
⏳ Frontend UI  
⏳ Real-time validation during parsing  
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

### Phase 1: Context Loading
- [ ] Read this entire file (agents.md)
- [ ] Read `ARCHITECTURE.md` for system design
- [ ] Review `docs/guides/AI_PROMPTS.md` for AI agent templates
- [ ] Check `CHANGELOG.md` for recent changes

### Phase 2: Environment Setup
- [ ] Run `npx supabase status` to verify connection
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
