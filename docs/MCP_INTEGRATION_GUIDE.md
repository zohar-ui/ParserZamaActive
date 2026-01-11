# MCP Integration Guide

**Purpose:** Explain the Model Context Protocol (MCP) integration and how it replaces manual bash scripts for database operations.

**Last Updated:** 2026-01-11

---

## Overview

The ParserZamaActive project now uses **Supabase MCP** as the **primary method** for database schema verification and queries. Manual bash scripts are maintained as fallback for CI/CD pipelines and environments where MCP is not available.

## What Changed

### Before (Manual Scripts Only)
```bash
# Every database operation required manual bash commands
./scripts/utils/inspect_db.sh workout_main
psql "$SUPABASE_DB_URL" -c "SELECT * FROM zamm.lib_athletes LIMIT 5"
```

### After (MCP-First Approach)
```
# AI agent uses MCP tools directly
"Show me the structure of workout_main table"
"Query the first 5 records from lib_athletes"
```

## Why MCP?

### Benefits

1. **Faster** - No environment setup, no connection string management
2. **Simpler** - Natural language queries instead of bash commands
3. **Safer** - Built-in validation and error handling
4. **Smarter** - Schema-aware query generation
5. **Interactive** - Real-time feedback during development

### Comparison

| Feature | MCP | Bash Scripts |
|---------|-----|--------------|
| **Speed** | Instant | Requires shell execution |
| **Setup** | None (built-in) | Requires SUPABASE_DB_URL |
| **Interface** | Natural language | Command-line |
| **Error handling** | Automated | Manual |
| **CI/CD support** | ❌ No | ✅ Yes |
| **Offline mode** | ❌ No | ❌ No |

## When to Use What

### Use MCP (Primary Method)

✅ During development in VS Code
✅ For schema verification before writing SQL
✅ For exploratory queries
✅ For data verification
✅ For debugging database issues

### Use Bash Scripts (Fallback)

✅ In CI/CD pipelines
✅ In automated test suites
✅ When MCP is not configured
✅ For scripted database operations
✅ For bulk operations in scripts

## Configuration

### MCP Setup (Already Done)

File: `.vscode/mcp.json`
```json
{
  "servers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=dtzcamerxuonoeujrgsu"
    }
  }
}
```

### Bash Scripts Setup (For Fallback)

File: `.env.local`
```bash
SUPABASE_DB_URL=postgresql://postgres:PASSWORD@db.dtzcamerxuonoeujrgsu.supabase.co:5432/postgres
```

## Usage Examples

### Schema Inspection

**With MCP:**
```
User: "Show me the structure of the workout_main table"
AI: [Uses MCP to query and display table structure]
```

**With Bash (Fallback):**
```bash
./scripts/utils/inspect_db.sh workout_main
```

### Verify Table Exists

**With MCP:**
```
User: "Does the lib_athletes table exist in zamm schema?"
AI: [Uses MCP to verify and confirm]
```

**With Bash (Fallback):**
```bash
./scripts/utils/inspect_db.sh lib_athletes
```

### List All Tables

**With MCP:**
```
User: "List all tables in the zamm schema"
AI: [Uses MCP to query and list all 33 tables]
```

**With Bash (Fallback):**
```bash
psql "$SUPABASE_DB_URL" -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'zamm'
ORDER BY table_name;
"
```

### Count Records

**With MCP:**
```
User: "How many workouts are in the database?"
AI: [Uses MCP to query: SELECT COUNT(*) FROM zamm.workout_main]
```

**With Bash (Fallback):**
```bash
psql "$SUPABASE_DB_URL" -c "SELECT COUNT(*) FROM zamm.workout_main;"
```

## AI Agent Decision Logic

```
┌─────────────────────────────────────┐
│ AI Agent receives database task     │
└─────────────────┬───────────────────┘
                  │
                  ▼
         ┌────────────────┐
         │ Is MCP available? │
         └────────┬───────────┘
                  │
          ┌───────┴───────┐
          │               │
        YES              NO
          │               │
          ▼               ▼
┌──────────────────┐  ┌──────────────────┐
│ Use MCP tools    │  │ Check environment │
│ - Schema inspect │  └────────┬─────────┘
│ - Direct queries │           │
│ - Verification   │     ┌─────┴─────┐
└──────────────────┘     │           │
                      CI/CD      Local Dev
                         │           │
                         ▼           ▼
                  ┌──────────┐  ┌──────────┐
                  │Use bash  │  │Configure │
                  │scripts   │  │MCP or use│
                  │          │  │scripts   │
                  └──────────┘  └──────────┘
```

## Migration Path

### For Developers

1. ✅ MCP is already configured in `.vscode/mcp.json`
2. ✅ Start using natural language for database queries
3. ✅ Bash scripts remain available as fallback
4. ✅ No action required - works immediately

### For CI/CD

1. ✅ Continue using bash scripts (MCP not available)
2. ✅ Scripts remain unchanged and fully supported
3. ✅ No migration needed

### For Documentation

1. ✅ CLAUDE.md updated to prefer MCP
2. ✅ MCP usage examples added
3. ✅ Fallback strategies documented
4. ✅ Decision logic clearly defined

## Backward Compatibility

All bash scripts are **fully maintained** and **will not be removed**:

- `scripts/utils/inspect_db.sh` - Table inspection
- `scripts/verify_schema.sh` - Schema verification
- `scripts/docs/update_schema_docs.js` - Documentation updater
- All test scripts remain unchanged

These scripts are essential for:
- CI/CD pipelines
- Automated testing
- Deployment workflows
- Environments without MCP

## Troubleshooting

### MCP Not Working?

1. **Check configuration:** Verify `.vscode/mcp.json` exists
2. **Check VS Code:** Ensure using VS Code with Claude Code extension
3. **Check connection:** Test by asking "List tables in zamm schema"
4. **Fallback:** Use bash scripts as temporary workaround

### Scripts Not Working?

1. **Check environment:** Ensure `SUPABASE_DB_URL` is set
2. **Check connection:** Run `npx supabase status`
3. **Check permissions:** Verify database credentials
4. **Load env:** Run `source .env.local` before scripts

## Related Documentation

- [.vscode/README.md](../.vscode/README.md) - MCP configuration details
- [.claude/CLAUDE.md](../.claude/CLAUDE.md) - Updated AI agent protocols
- [docs/VERIFICATION_SUMMARY.md](VERIFICATION_SUMMARY.md) - Verification system overview

---

## Summary

✅ **MCP is now the primary method** for database operations during development
✅ **Bash scripts remain as fallback** for CI/CD and non-MCP environments
✅ **No breaking changes** - everything works as before, but better
✅ **AI agents prefer MCP** when available, automatically fall back to scripts
✅ **Developers benefit** from faster, simpler database interactions

**Key Principle:** Use the best tool for the job - MCP for interactive development, scripts for automation.

---

**Last Updated:** 2026-01-11
**Maintained By:** AI Development Team
