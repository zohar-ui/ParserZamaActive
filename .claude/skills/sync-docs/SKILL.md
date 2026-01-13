---
name: sync-docs
description: Updates schema documentation to synchronize with live database state after migrations or schema changes, preventing documentation drift by querying actual table structures, column definitions, and constraints to update VERIFIED_TABLE_NAMES.md and schema reference files. Use this skill when: (1) After applying database migrations to sync docs with new schema, (2) After pulling migrations from git to update local documentation, (3) When documentation seems outdated or incorrect, (4) Before writing SQL to verify current table names and structure, or (5) To ensure single source of truth between database and documentation
---

# Sync Docs Skill

## Purpose
Keep schema documentation synchronized with database reality by:
- Detecting new or modified migrations
- Querying live database for actual table structures
- Updating `docs/reference/VERIFIED_TABLE_NAMES.md`
- Preventing documentation drift

## Usage
```
/sync-docs
```

**When to use:**
- ✅ After applying database migrations
- ✅ After pulling migrations from git
- ✅ When documentation seems outdated
- ✅ Before writing SQL (to verify table names)

## What It Does

1. **Checks for recent migrations** in `supabase/migrations/`
2. **Runs automatic documentation updater** (`npm run update-docs`)
3. **Verifies database connectivity** before updating
4. **Reports what changed** in the documentation
5. **Suggests git commit** if docs were modified

---

## Instructions for Claude

### Step 1: Check Database Connectivity

Before syncing docs, verify database is accessible:

```sql
-- Quick connectivity test
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'zamm';
```

**If fails:**
```
❌ Cannot sync docs - database not accessible

Possible issues:
1. SUPABASE_DB_URL not set
2. Database is offline
3. Network connectivity issues

Fix: Check .env.local and verify connection with /db-status
```

### Step 2: Check for Recent Migrations

```bash
# List migrations from last 24 hours
find supabase/migrations -name "*.sql" -mtime -1 -type f | sort
```

**If migrations found:**
```
📋 Recent migrations detected:
- 20260111120000_add_quality_gates.sql
- 20260111140000_update_commit_function.sql

These may have changed the schema. Running doc sync...
```

**If no recent migrations:**
```
ℹ️ No recent migrations found, but syncing docs anyway to ensure accuracy...
```

### Step 3: Run Documentation Updater

```bash
npm run update-docs
```

**This script:**
- Connects to live database via Supabase MCP
- Queries all tables in `zamm` schema
- Extracts column names, types, constraints
- Updates `docs/reference/VERIFIED_TABLE_NAMES.md`
- Updates `docs/reference/SCHEMA_REFERENCE.md` (if exists)

### Step 4: Check What Changed

```bash
# Show git diff for documentation files
git diff --stat docs/
```

**If changes detected:**
```
📝 Documentation updated:

Modified files:
 docs/reference/VERIFIED_TABLE_NAMES.md | 15 ++++++++-------
 1 file changed, 8 insertions(+), 7 deletions(-)

Key changes:
- Added 2 new tables
- Updated column definitions for workout_main
- Removed deprecated table references
```

**If no changes:**
```
✅ Documentation is already up-to-date (no changes needed)
```

### Step 5: Review Changes and Suggest Commit

**If docs were modified:**
```bash
# Show detailed diff
git diff docs/reference/VERIFIED_TABLE_NAMES.md
```

Then suggest:
```
📋 Documentation has been updated to match database reality.

Next steps:
1. Review the changes above
2. If correct, commit them:
   git add docs/reference/
   git commit -m "docs: sync schema documentation with database"

Or run: npm run post-migration (does this automatically)
```

---

## Automatic Triggers (Already Configured)

The project has **automatic doc sync** via git hooks:

### Post-Merge Hook
**Triggers:** After `git pull` or `git merge`
**Action:** Detects migration changes and runs `npm run update-docs`

**Example:**
```bash
git pull origin main
# → Hook detects new migrations
# → Automatically runs npm run update-docs
# → Updates docs/reference/VERIFIED_TABLE_NAMES.md
```

### Manual Trigger
**After applying migration manually:**
```bash
npm run post-migration
```

**What it does:**
1. Runs `npm run update-docs`
2. Updates all schema documentation
3. Stages changes for commit

---

## File Locations

### Source of Truth (Live Database)
- **Database:** Remote Supabase database
- **Access:** Via MCP or `SUPABASE_DB_URL` environment variable

### Auto-Generated Documentation (Never Edit Manually)
- `docs/reference/VERIFIED_TABLE_NAMES.md` - ✅ **Always trust this**
- Updated automatically by scripts
- Single source of truth for table/column names

### Migration Files (Version History)
- `supabase/migrations/*.sql` - SQL DDL statements
- Applied in chronological order
- Never edited after creation

### Manual Documentation (Human-Maintained)
- `docs/architecture/ARCHITECTURE.md` - High-level system design
- `docs/reference/CANONICAL_JSON_SCHEMA.md` - Parser output format
- `docs/guides/AI_PROMPTS.md` - Parser prompt templates

---

## Error Handling

### Error: "Database connection failed"

```
❌ Error: Cannot connect to database

Details: connection to server at "..."

Solution:
1. Check SUPABASE_DB_URL in .env.local
2. Verify database is online (run: npx supabase status)
3. Check network connectivity
```

**Do NOT proceed** if database is inaccessible - docs will be wrong!

### Error: "Migration file corrupted"

```
❌ Error: Syntax error in migration file
File: 20260111120000_add_quality_gates.sql
Line: 45

Solution:
1. Open the migration file
2. Fix SQL syntax error
3. Re-run sync-docs
```

### Warning: "Docs modified but not committed"

```
⚠️ Warning: Documentation files have uncommitted changes

Modified:
  docs/reference/VERIFIED_TABLE_NAMES.md

This means the docs were out of sync!

Action: Commit these changes before proceeding.
```

---

## Verification Protocol

After syncing docs, **verify accuracy** by spot-checking:

### Test 1: Check Known Table
```sql
-- Pick a table you know exists
SELECT COUNT(*) FROM zamm.workout_main;
```

**Then check docs:**
```bash
grep "workout_main" docs/reference/VERIFIED_TABLE_NAMES.md
```

**Expected:** Table name appears in docs ✅

### Test 2: Check Recently Added Table
If you just applied migration `20260111_add_new_table.sql`:

```bash
# Check if new table appears in docs
grep "new_table" docs/reference/VERIFIED_TABLE_NAMES.md
```

**Expected:** New table appears in docs ✅

### Test 3: Count Total Tables
```sql
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'zamm';
```

**Then check docs:**
```bash
grep -c "^- " docs/reference/VERIFIED_TABLE_NAMES.md
```

**Expected:** Counts match (e.g., both show 33 tables) ✅

---

## Example Session

```
User: /sync-docs

Claude: Checking database connectivity...
✅ Connected to Supabase database (33 tables in zamm schema)

Checking for recent migrations...
📋 Found 1 recent migration:
- 20260111140000_update_commit_function.sql (modified 2 hours ago)

Running documentation updater...
$ npm run update-docs

> update-docs
> node scripts/docs/update_schema_docs.js

✅ Updated VERIFIED_TABLE_NAMES.md
   - Modified: workout_main (added quality_score column)
   - Modified: stg_parse_drafts (added quality_metadata column)

Checking for documentation changes...
📝 Documentation updated:

 docs/reference/VERIFIED_TABLE_NAMES.md | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

Changes:
+ workout_main: added quality_score (numeric)
+ stg_parse_drafts: added quality_metadata (jsonb)

✅ Sync complete!

Next steps:
1. Review changes above
2. Commit updated documentation:
   git add docs/reference/
   git commit -m "docs: sync schema after quality gate migration"
```

---

## Best Practices

### DO:
✅ Run `/sync-docs` after every migration
✅ Verify docs match database before writing SQL
✅ Commit doc changes immediately after sync
✅ Use MCP to query database directly when in doubt

### DON'T:
❌ Manually edit `VERIFIED_TABLE_NAMES.md` (auto-generated)
❌ Trust cached documentation (always verify)
❌ Skip syncing after pulling migrations
❌ Assume table names from old docs

---

## Notes

- This skill leverages the **existing automatic documentation system** already in the project
- The `npm run update-docs` script is maintained and tested
- Git hooks automatically trigger this on `git pull` if migrations changed
- **MCP is the preferred method** for live database queries
- The skill is a **smart wrapper** that handles verification and reporting
