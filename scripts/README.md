# Scripts

Utility scripts for testing, automation, and development.

---

## 🚀 Quick Start (New!)

### Load AI Session Aliases
```bash
# From project root
source .claude_aliases

# Then use shortcuts:
cld-admin        # Full admin session
cld-dev          # Developer mode
cld-db-status    # Quick DB check
```

---

## 📂 Available Scripts

### ⭐ New (January 10, 2026)

**`schema_change_checklist.sh`** - Interactive checklist for schema changes
```bash
./scripts/schema_change_checklist.sh
```
Shows which docs need updating after schema changes:
- ✅ Files updated in last 5 minutes
- ⏸️  Files that need review
- ❌ Missing files

**`validate_golden_set_schema_v2.sh`** - Validate Schema v2 compliance
```bash
./scripts/validate_golden_set_schema_v2.sh
```
Checks:
- ✅ No `prescription_if_*` patterns
- ✅ No `target_rounds` in item prescriptions
- ✅ `exercise_options` are array of objects
- ✅ `circuit_config` has required fields

**Exit codes:**
- `0` - All validations passed
- `1` - Schema violations found

---

### 📅 January 9, 2026

**`cleanup_test_data.sql`** - Remove test data before production
```bash
PGPASSWORD="xxx" psql -h db... -f scripts/cleanup_test_data.sql
```

**`update_agents_md.sh`** - Auto-sync schema with agents.md
```bash
./scripts/update_agents_md.sh
```

**`test_parser_accuracy.sh`** - Golden set regression testing
```bash
./scripts/test_parser_accuracy.sh
# Requires: data/golden_set/*.json files
```

**`git-hooks/pre-commit`** - Auto-update schema on migration commits
```bash
# Install once
cp scripts/git-hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

---

### Testing Scripts

### test_block_types.sh
Tests the block type system functionality.

**Usage:**
```bash
cd /workspaces/ParserZamaActive
./scripts/test_block_types.sh
```

**What it tests:**
1. Count of block types (should be 17)
2. Count of aliases (should be 60+)
3. Block types grouped by category
4. `normalize_block_code()` function with various inputs:
   - English: "strength", "wod", "metcon"
   - Hebrew: "כוח"
   - Aliases: Various abbreviations
5. UI hints validation

**Requirements:**
- Supabase CLI installed and configured
- Connected to the project (`supabase status` should show linked project)
- Block type migration deployed (`20260104140000_block_type_system.sql`)

---

### Database Scripts

**`check_all_tables.sql`** - Count rows in all tables (older version)  
**`check_all_tables_v2.sql`** - Updated with correct table names  
**`check_tables_simple.sql`** - Quick table check  
**`list_tables.sql`** - List all zamm schema tables

**`verify_schema.sh`** - Verify table structures

---

### Templates

**`sql_template.sql`** - Template for new SQL functions

---

## 🎯 Usage Patterns

### Daily Development
```bash
# 1. Load aliases
source .claude_aliases

# 2. Start admin session
cld-admin

# 3. Check DB health
cld-counts
```

### Before Production
```bash
# 1. Clean test data
psql -f scripts/cleanup_test_data.sql

# 2. Update schema docs
./scripts/update_agents_md.sh

# 3. Test parser
./scripts/test_parser_accuracy.sh
```

---

## Future Scripts

Planned utility scripts:
- `test_ai_tools.sh` - Test all 5 AI SQL tools
- `test_validation.sh` - Test validation functions
- `seed_sample_data.sh` - Load sample workouts into database
- `verify_migrations.sh` - Verify all migrations are applied
- `generate_types.sh` - Generate TypeScript types from schema

## Contributing

When adding new scripts:
1. Add shebang: `#!/bin/bash`
2. Make executable: `chmod +x scripts/yourscript.sh`
3. Add comments explaining purpose
4. Update this README
5. Add error handling
6. Test before committing

---

**Last Updated:** January 9, 2026  
**Script Count:** 13+ total
