---
name: db-status
description: Quick database health check and connectivity verification for ParserZamaActive system (faster alternative to full /verify suite). Use this skill when: (1) Starting a new work session to verify database accessibility, (2) Debugging database connection issues before running operations, (3) Checking current data counts (athletes, workouts, rulesets), (4) Verifying active parser ruleset version, or (5) Quick sanity check without running full validation suite (5 seconds vs 30-60 seconds)
---

# Database Status Skill

Fast database health check that verifies connectivity and basic state without running the full validation suite.

## Core Workflow

Execute three quick checks in sequence:

1. **Connection Check** - `npx supabase status`
   - Verifies database is accessible
   - Shows API and DB URLs

2. **Handshake Query** - Query key tables
   - Count athletes in `lib_athletes`
   - Count workouts in `workout_main`
   - Get active parser ruleset version

3. **Table Count** - Quick schema verification
   - Count total tables in `zamm` schema
   - Should return 33 tables

## Expected Output

### ✅ Healthy Database

```
Database Status: HEALTHY

Connection:
✅ API URL: https://dtzcamerxuonoeujrgsu.supabase.co
✅ DB URL: postgresql://postgres:***@db.dtzcamerxuonoeujrgsu.supabase.co:5432/postgres

Data Counts:
✅ Athletes: 10
✅ Workouts: 50
✅ Tables: 33/33 in zamm schema

Active Ruleset:
✅ Version: v1.2

→ Ready to work
```

### ⚠️ Connected but Empty

```
Database Status: CONNECTED (Empty)

Connection: ✅ Connected
Tables: ✅ 33/33 tables
Data: ⚠️ 0 athletes, 0 workouts
Ruleset: ✅ v1.2 active

→ Database structure OK, needs data
```

### ❌ Connection Failed

```
Database Status: DISCONNECTED

Connection: ❌ Failed
Error: "permission denied" or "connection refused"

→ Check .env.local credentials
→ Run: npx supabase login
```

## Handshake Query

Use Supabase MCP or psql to execute:

```sql
SELECT
    (SELECT COUNT(*) FROM zamm.lib_athletes) as athlete_count,
    (SELECT COUNT(*) FROM zamm.workout_main) as workout_count,
    (SELECT version FROM zamm.lib_parser_rulesets WHERE is_active = true LIMIT 1) as active_ruleset;
```

## Troubleshooting

### Connection Failed

```bash
# Check environment
cat .env.local | grep SUPABASE

# Test Supabase CLI
npx supabase status

# Re-authenticate
npx supabase login
```

### Zero Tables Found

```bash
# Apply migrations
npx supabase db push

# Verify
npx supabase db diff
```

### Wrong Table Count

Expected: 33 tables in `zamm` schema

If different:
- Too few → Missing migrations
- Too many → Extra test tables (cleanup needed)

## Success Criteria

All checks pass:

- ✅ Database connection successful
- ✅ 33 tables exist in zamm schema
- ✅ Active ruleset found
- ✅ Data counts > 0 (for production)

## Related Skills

- `/verify` - Full validation suite (more comprehensive, slower)
- `/inspect-table` - Detailed table structure inspection
- `/sync-docs` - Update schema documentation

## When to Use Each

| Task | Use db-status | Use verify |
|------|---------------|------------|
| **Quick connectivity check** | ✅ Yes (5 sec) | ⚠️ Overkill |
| **Starting work session** | ✅ Yes | ⚠️ Not needed |
| **Before committing** | ❌ No | ✅ Yes |
| **After schema changes** | ⚠️ Quick check | ✅ Full validation |
| **Debugging connection** | ✅ Yes | ❌ Too slow |

---

**Version:** 1.0.0
**Last Updated:** 2026-01-13
**Duration:** ~5 seconds
