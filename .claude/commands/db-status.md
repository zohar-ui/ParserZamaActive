# /db-status

**Purpose:** Quick database health check (faster than `/verify`)  
**Duration:** ~5 seconds  
**Use When:** Starting work session or debugging connection issues

---

## Goal

Verify database connectivity and basic state without running full test suite.

---

## Steps

### Step 1: Connection Check

```bash
npx supabase status
```

**Expected Output:**
```
API URL: https://dtzcamerxuonoeujrgsu.supabase.co
DB URL: postgresql://postgres:[PASSWORD]@db.dtzcamerxuonoeujrgsu.supabase.co:5432/postgres
```

**On Failure:**
- Check internet connection
- Verify `.env.local` has `SUPABASE_ACCESS_TOKEN`
- Try `npx supabase login`

---

### Step 2: Handshake Query

```bash
PGPASSWORD="${DB_PASSWORD:-$(grep SUPABASE_DB_PASSWORD .env.local | cut -d'=' -f2)}" \
  psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres \
  -c "SELECT 
    (SELECT COUNT(*) FROM zamm.lib_athletes) as athlete_count,
    (SELECT COUNT(*) FROM zamm.workout_main) as workout_count,
    (SELECT version FROM zamm.lib_parser_rulesets WHERE is_active = true LIMIT 1) as active_ruleset;"
```

**Expected Output:**
```
 athlete_count | workout_count | active_ruleset 
---------------|---------------|----------------
      10       |      50       |     v1.0
```

**On Failure:**
- If "permission denied" → Check `SUPABASE_DB_PASSWORD` in `.env.local`
- If "relation does not exist" → Run migrations (`npx supabase db push`)
- If counts are 0 → Database is empty (expected for fresh setup)

---

### Step 3: Table Count

```bash
./scripts/verify_schema.sh | grep "total_tables"
```

**Expected Output:**
```
✅ Found 32 tables in zamm schema
```

**On Failure:**
- If < 32 tables → Missing migrations
- If 0 tables → Schema not deployed
- Run `npx supabase db push` to deploy

---

## Quick Interpretation

### ✅ All Checks Passed
```
Database Status: HEALTHY
- Connection: ✅ Connected
- Tables: ✅ 32/32 tables
- Data: ✅ Athletes and workouts present
- Ruleset: ✅ v1.0 active

→ Ready to work
```

### ⚠️ Partial Success
```
Database Status: CONNECTED (Empty)
- Connection: ✅ Connected
- Tables: ✅ 32/32 tables
- Data: ⚠️ 0 athletes, 0 workouts
- Ruleset: ✅ v1.0 active

→ Database structure OK, needs data
```

### ❌ Connection Failed
```
Database Status: DISCONNECTED
- Connection: ❌ Failed
- Error: "permission denied" or "connection refused"

→ Check .env.local credentials
→ Run: npx supabase login
```

---

## Related Commands

- `/verify` - Full test suite (slower but comprehensive)
- `npx supabase db diff` - Check pending migrations
- `npx supabase db push` - Deploy migrations

---

**Last Updated:** January 10, 2026
