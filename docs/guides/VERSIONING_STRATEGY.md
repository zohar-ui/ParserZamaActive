# 📋 Versioning Strategy

**Last Updated:** 2026-01-10
**Status:** Active

---

## 🎯 Problem Statement

Documentation (`.md`) and code (`.sql`, `.js`) can drift out of sync, causing:
- AI agents to work with outdated assumptions
- Validators to reject valid data
- Commits to fail mysteriously
- Developers to waste time debugging

**Solution:** Semantic Versioning + Automated Compatibility Checks

---

## 🔢 Version Components

### 1. Schema Document Version (`CANONICAL_JSON_SCHEMA.md`)

**Location:** `docs/reference/CANONICAL_JSON_SCHEMA.md`

**Format:** YAML frontmatter at top of file

```yaml
---
version: "3.2.0"
last_updated: "2026-01-10"
status: "LOCKED"
compatible_db_migration: "20260104120200"
parser_ruleset_version: "v3.2"
breaking_changes_from: "3.1.0"
---
```

**Fields:**
- `version` - Semantic version (MAJOR.MINOR.PATCH)
- `last_updated` - Date of last modification (YYYY-MM-DD)
- `status` - `LOCKED` | `DRAFT` | `DEPRECATED`
- `compatible_db_migration` - Migration file that implements this version
- `parser_ruleset_version` - Version stored in `zamm.parser_rulesets`
- `breaking_changes_from` - Last version before breaking changes

### 2. Database Ruleset Version

**Location:** `zamm.parser_rulesets` table

**Query:**
```sql
SELECT version, is_active
FROM zamm.parser_rulesets
WHERE is_active = true
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Output:**
```
 version | is_active
---------+-----------
 v3.2    | t
```

---

## 🔍 Compatibility Check

### Automated Script: `verify_schema_version.sh`

**Usage:**
```bash
# Direct execution
./scripts/verify_schema_version.sh

# Via npm
npm run verify:schema
```

**What it checks:**
1. ✓ Extracts version from CANONICAL_JSON_SCHEMA.md YAML frontmatter
2. ✓ Queries active parser_ruleset version from database
3. ✓ Compares normalized versions (removes 'v' prefix)
4. ✓ Reports match/mismatch with actionable guidance

**Exit codes:**
- `0` - Versions match (or DB offline, graceful skip)
- `1` - Version mismatch detected
- `2` - Error reading schema document

**Example Output (Match):**
```
╔════════════════════════════════════════════════════════════╗
║       Schema Version Compatibility Check                  ║
╚════════════════════════════════════════════════════════════╝

[1/4] Reading schema document version...
  ✓ Schema document version: 3.2.0
  ✓ Compatible migration: 20260104120200
  ✓ Parser ruleset: v3.2

[2/4] Checking database connection...
  ✓ Database connected

[3/4] Querying parser_rulesets table...
  ✓ Active ruleset version: v3.2

[4/4] Comparing versions...

═══════════════════════════════════════════════════════════
✓ COMPATIBLE
  Schema Doc:  3.2.0 (ruleset: v3.2)
  Database:    v3.2
═══════════════════════════════════════════════════════════
```

**Example Output (Mismatch):**
```
═══════════════════════════════════════════════════════════
✗ VERSION MISMATCH!
  Schema Doc:  3.3.0 (ruleset: v3.3)
  Database:    v3.2

⚠  ACTION REQUIRED:
  → Schema document is AHEAD of database implementation
  Fix: Run migrations to update database to v3.3
       npx supabase db push
═══════════════════════════════════════════════════════════
```

---

## 🔄 Semantic Versioning Rules

### MAJOR version (`X.0.0`)
**Breaking changes** to JSON structure that invalidate old parsers

**Examples:**
- Renaming top-level fields
- Changing required vs optional fields
- Restructuring nested objects

**Actions Required:**
1. Update schema document frontmatter
2. Create new migration file
3. Update all parsers/validators
4. Add migration guide in CHANGELOG.md

### MINOR version (`x.Y.0`)
**Backward-compatible additions** - old parsers still work

**Examples:**
- Adding optional fields
- New block types
- Extended enums

**Actions Required:**
1. Update schema document frontmatter
2. Create migration file (if DB changes needed)
3. Update parser to support new fields (optional)

### PATCH version (`x.x.Z`)
**Bug fixes and clarifications** - no structural changes

**Examples:**
- Documentation fixes
- Value constraint clarifications
- Example corrections

**Actions Required:**
1. Update schema document frontmatter
2. No migration needed
3. No parser changes needed

---

## 📅 Version Update Workflow

### When updating CANONICAL_JSON_SCHEMA.md:

1. **Update YAML frontmatter:**
   ```yaml
   version: "3.3.0"  # Increment appropriately
   last_updated: "2026-01-15"  # Today's date
   compatible_db_migration: "20260115100000"  # New migration file
   parser_ruleset_version: "v3.3"  # Match version
   breaking_changes_from: "3.2.0"  # Previous version if breaking
   ```

2. **Create corresponding migration:**
   ```bash
   npx supabase migration new update_parser_ruleset_v3_3
   ```

3. **Update parser_rulesets table:**
   ```sql
   -- In new migration file
   UPDATE zamm.parser_rulesets SET is_active = false;

   INSERT INTO zamm.parser_rulesets (
       name, version, is_active,
       units_catalog, units_metadata,
       parser_mapping_rules, value_unit_schema
   ) VALUES (
       'ZAMM Schema v3.3',
       'v3.3',
       true,
       -- ... JSON configs
   );
   ```

4. **Run migration:**
   ```bash
   npx supabase db push
   ```

5. **Verify compatibility:**
   ```bash
   npm run verify:schema
   ```

6. **Update CHANGELOG.md:**
   ```markdown
   ## [3.3.0] - 2026-01-15
   ### Added
   - New optional field: workout_intensity_score

   ### Breaking Changes
   - None (backward compatible)
   ```

---

## 🚨 When Mismatch Detected

### Scenario 1: Schema Doc Ahead of DB
**Cause:** Schema updated but migrations not run

**Fix:**
```bash
# Check pending migrations
npx supabase migration list

# Apply migrations
npx supabase db push

# Verify
npm run verify:schema
```

### Scenario 2: DB Ahead of Schema Doc
**Cause:** Manual DB changes or missing doc update

**Fix:**
1. Check current DB version:
   ```sql
   SELECT version FROM zamm.parser_rulesets
   WHERE is_active = true;
   ```

2. Update CANONICAL_JSON_SCHEMA.md frontmatter to match

3. Verify:
   ```bash
   npm run verify:schema
   ```

### Scenario 3: DB Offline
**Expected:** Script exits gracefully with exit code 0

**No action required** - compatibility check skipped

---

## 🎯 Best Practices

1. **Always update schema doc BEFORE writing migrations**
   - Schema doc is the source of truth
   - Migration implements the schema

2. **Install git hooks (automatic)**
   ```bash
   npm install  # Auto-installs hooks
   # OR manually:
   npm run install:hooks
   ```
   - Pre-commit hook verifies schema version automatically
   - Prevents commits with version mismatches

3. **Version bump checklist:**
   - [ ] Update YAML frontmatter
   - [ ] Create migration file
   - [ ] Update parser_rulesets INSERT
   - [ ] Run migration
   - [ ] Verify compatibility
   - [ ] Update CHANGELOG.md

4. **Document breaking changes clearly**
   - List in CHANGELOG
   - Add migration guide if needed
   - Update all examples

---

## 🪝 Automated Pre-Commit Hook

### What It Does

The pre-commit hook automatically runs **before every `git commit`** and:

1. ✅ Runs `verify:schema` to check version compatibility
2. ✅ Validates YAML frontmatter exists if schema doc changed
3. ✅ Reminds you to update CHANGELOG.md on version changes
4. ✅ Reminds you to apply migrations if migration files detected
5. ❌ **Blocks commit** if schema version mismatch detected

### Installation

**Automatic (recommended):**
```bash
npm install  # Runs postinstall hook
```

**Manual:**
```bash
npm run install:hooks
```

**Files involved:**
- `.git-hooks/pre-commit` - Hook source (committed to repo)
- `.git/hooks/pre-commit` - Active hook (copied by install script)
- `scripts/install_hooks.sh` - Installation script

### Example: Commit Blocked

```bash
$ git commit -m "Update schema to v3.3"

🔍 Running pre-commit checks...

[1/2] Checking schema version compatibility...

╔════════════════════════════════════════════════════════════╗
║           ❌ COMMIT BLOCKED - Version Mismatch            ║
╚════════════════════════════════════════════════════════════╝

Schema document version does not match database version.

Fix options:
  1. Run migrations: npx supabase db push
  2. Update CANONICAL_JSON_SCHEMA.md to match DB version
  3. Re-verify: npm run verify:schema

Commit rejected. Fix the version mismatch first.
```

### Example: Commit Allowed

```bash
$ git commit -m "Add new feature"

🔍 Running pre-commit checks...

[1/2] Checking schema version compatibility...
✓ Schema version check passed

[2/2] Checking for common mistakes...
✓ Pre-commit checks passed

═══════════════════════════════════════════════════════════
✓ All checks passed - proceeding with commit
═══════════════════════════════════════════════════════════
```

### Bypass Hook (Emergency Only)

```bash
# Skip pre-commit hook (NOT RECOMMENDED)
git commit --no-verify -m "Emergency fix"

# Better approach: Fix the issue first
npm run verify:schema
# Then commit normally
```

### Uninstall Hook

```bash
rm .git/hooks/pre-commit
```

---

## 📚 Related Documentation

- [CANONICAL_JSON_SCHEMA.md](../reference/CANONICAL_JSON_SCHEMA.md) - The Constitution
- [CHANGELOG.md](../../CHANGELOG.md) - Version history
- [Schema Migrations](../../supabase/migrations/) - Database versions

---

## 🤖 For AI Agents

**Before parsing or validating:**
```bash
npm run verify:schema
```

**If mismatch detected:**
1. Report to user immediately
2. Do NOT proceed with parsing/validation
3. Suggest fix based on error message

**Acceptable to proceed only when:**
- Exit code 0 (match or DB offline)
- User explicitly overrides

---

**Status:** ✅ Versioning strategy active and enforced
