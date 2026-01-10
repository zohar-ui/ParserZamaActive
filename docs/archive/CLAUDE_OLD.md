# Claude CLI Configuration - ParserZamaActive

> **Auto-loaded by Claude CLI on startup**  
> Last Updated: January 9, 2026

---

## ⚡ MANDATORY INIT (Run This First!)

**Every time you start Claude Code, run:**

```bash
claude "Read agents.md and DB_READINESS_REPORT.md to restore full project context. Then execute PROTOCOL ZERO handshake to verify database connection and schema."
```

**This loads your memory:**
- Project architecture (4-stage pipeline)
- All 27 table names and structures
- Business rules (prescription vs performance separation)
- Critical workflows (validation, atomic commits)
- Common pitfalls to avoid

**Without this:** You'll make assumptions and break things.  
**With this:** You'll operate with full context from day one.

---

## 🎯 Project Identity

**Name:** ParserZamaActive  
**Type:** SQL-only database backend (Supabase PostgreSQL)  
**Schema:** `zamm`  
**Your Role:** Database Operator with full execution authority

---

## ⚡ Quick Context

This is a **workout parser system** that converts text logs into structured database records.

### Key Concepts
- **Prescription vs Performance**: ALWAYS separate what was planned from what was done
- **4-Stage Pipeline**: Raw Text → Draft JSON → Validated JSON → Relational Tables
- **17 Block Types**: Standard workout block categories (STR, METCON, INTV, etc.)
- **Catalog-Based**: All exercises/equipment use normalized keys

---

## 🚦 First Actions (Every Session)

### Step 1: Verify Connection
```sql
SELECT current_database(), current_schema(), version();
```

### Step 2: **CRITICAL - Verify Table Names** ⚠️
**NEVER assume table names! Always verify first:**

```bash
# List all tables in zamm schema
./scripts/verify_schema.sh

# Or use SQL:
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'zamm' 
ORDER BY table_name;
```

### Step 3: Check Specific Table Structure
```bash
# Before writing SQL for a table, verify its columns:
./scripts/verify_schema.sh workout_main

# Or use SQL:
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'zamm' AND table_name = 'workout_main'
ORDER BY ordinal_position;
```

### Step 4: Connection Test Query
```sql
-- Verify database is accessible
SELECT 
    (SELECT COUNT(*) FROM zamm.lib_athletes) as athletes,
    (SELECT COUNT(*) FROM zamm.workout_main) as workouts,
    (SELECT version FROM zamm.lib_parser_rulesets WHERE is_active = true LIMIT 1) as ruleset;
```

Expected: `athletes > 0`, `workouts >= 0`, `ruleset = 'v1.0'`

---

## 📋 Common Tasks

### Check Database Status
```bash
npx supabase status
```

### Run Migrations
```bash
npx supabase db push
```

### Test Block Types
```bash
./scripts/test_block_types.sh
```

---

## 🔑 Critical Rules

### ❌ NEVER DO
1. Accept free-text exercise names (must normalize via `check_exercise_exists()`)
2. INSERT directly into `workout_*` tables (use `commit_full_workout_v3()`)
3. Mix prescription and performance in same field
4. Create tables in `public` schema (always use `zamm`)
5. Edit existing migration files (create new ones)

### ✅ ALWAYS DO
1. Use stored procedures for complex operations
2. Validate JSON before committing to database
3. Preserve audit trail (never delete from staging tables)
4. Include context in SQL comments
5. Test with sample data from `/data/` folder

---

## 📚 Documentation Hierarchy

**Start here:**
1. This file (CLAUDE.md) - Quick reference
2. [agents.md](./agents.md) - Comprehensive agent guide (600+ lines)
3. [ARCHITECTURE.md](./ARCHITECTURE.md) - System design patterns

**For specific tasks:**
- [TODO.md](./TODO.md) - Current tasks and priorities
- [docs/guides/PARSER_WORKFLOW.md](./docs/guides/PARSER_WORKFLOW.md) - Full 4-stage workflow
- [docs/guides/PARSER_AUDIT_CHECKLIST.md](./docs/guides/PARSER_AUDIT_CHECKLIST.md) - Validation checklist

**Reference:**
- [docs/reference/BLOCK_TYPES_REFERENCE.md](./docs/reference/BLOCK_TYPES_REFERENCE.md) - All 17 block types
- [docs/api/QUICK_TEST_QUERIES.sql](./docs/api/QUICK_TEST_QUERIES.sql) - SQL test queries

---

## 🛠️ Tools Available

### Supabase CLI
```bash
supabase status          # Check connection
supabase db pull         # Sync schema
supabase db push         # Deploy migrations
supabase db reset        # Reset local DB (use with caution!)
```

### SQL Functions (AI Tools)
- `check_athlete_exists(name)` - Athlete lookup
- `check_exercise_exists(name)` - Exercise normalization
- `check_equipment_exists(name)` - Equipment lookup
- `get_active_ruleset()` - Parser configuration
- `normalize_block_type(code)` - Block type normalization

### Validation Functions
- `validate_parsed_workout(draft_id, json)` - Full validation
- `auto_validate_and_commit(draft_id)` - Automated workflow

---

## 🎬 Example Session

```bash
# 1. Verify connection
claude "Check database connection"

# 2. Check current tasks
claude "Read TODO.md and summarize top priorities"

# 3. Execute specific task
claude "Create SQL script to check row counts in all zamm tables"

# 4. Run validation test
claude "Test validation functions with sample data from /data/bader_workout_log.txt"
```

---

## 💡 Tips for Effective Operation

1. **Read before executing**: Check relevant docs first
2. **Use precise SQL**: Include schema prefix (`zamm.`)
3. **Test incrementally**: Validate each step
4. **Document decisions**: Add comments to SQL
5. **Report results**: Provide clear status updates

---

## 🔗 Quick Links

- **Supabase Dashboard**: Run `npx supabase dashboard`
- **Project ID**: `dtzcamerxuonoeujrgsu`
- **Schema**: `zamm` (32 tables)
- **Version**: v1.2.0 (Validation system deployed)

---

## 📞 When You Need More Context

If task requires deeper understanding, read:
- **agents.md** - Full operational guide (PROTOCOL ZERO, all rules)
- **ARCHITECTURE.md** - System patterns and design decisions
- **TODO.md** - Current work priorities

**Remember:** You are the Operator. Execute with confidence. Ask only when data is missing, never for permission.
