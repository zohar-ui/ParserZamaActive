# /verify

**Purpose:** Run the full ParserZamaActive validation suite  
**Duration:** ~30-60 seconds  
**Use Before:** Committing any code changes

---

## Goal

Execute all three test suites to ensure:
1. Database schema is synchronized
2. Parser logic matches golden set expectations
3. Block type classification is accurate

---

## Steps

### Step 1: Schema Verification
**Validates:** Database connection, table structure, column names

```bash
./scripts/verify_schema.sh
```

**Expected Output:**
```
✅ Connected to database
✅ Found 32 tables in zamm schema
✅ All required tables exist
```

**On Failure:**
- Check `.env.local` has correct `SUPABASE_ACCESS_TOKEN`
- Verify `npx supabase status` shows connection
- Check if migrations are pending

---

### Step 2: Golden Set Validation
**Validates:** Parser output against approved truth data

```bash
./scripts/validate_golden_set.sh
```

**Expected Output:**
```
Testing: workout_01.txt
✅ PASS - JSON structure matches golden
✅ PASS - Block codes normalized
✅ PASS - No hallucinated data

Summary: 19/19 tests passed
```

**On Failure:**
- Review the diff output (shows expected vs actual)
- Check if `CANONICAL_JSON_SCHEMA.md` was updated
- Verify parser prompts in `AI_PROMPTS.md` are current
- Run `npm run learn` to update parser brain

---

### Step 3: Block Type System Test
**Validates:** Block code normalization and classification

```bash
./scripts/test_block_types.sh
```

**Expected Output:**
```
Testing Hebrew terms...
✅ "חימום" → WU
✅ "כוח" → STR
✅ "מטקון" → METCON

Testing English terms...
✅ "warmup" → WU
✅ "strength" → STR

Summary: 60/60 aliases resolved
```

**On Failure:**
- Check if new block type aliases were added
- Verify `lib_block_type_aliases` table is populated
- Review `normalize_block_code` function

---

## Failure Handling

### Critical Failure (Stop Work)
If ANY step fails with ERROR, **STOP immediately:**

1. **Do NOT commit** - Changes break existing functionality
2. **Analyze the diff** - Compare expected vs actual output
3. **Fix the root cause** - Not the symptom
4. **Re-run `/verify`** - Must pass before proceeding

### Warning (Review Required)
If tests pass with WARNINGS:

1. **Review the warnings** - May indicate edge cases
2. **Decide if acceptable** - Some warnings are expected (e.g., large weights)
3. **Document if intentional** - Add comment explaining why

---

## Post-Verification

### On Success ✅
```bash
# All tests passed - safe to commit
git add .
git commit -m "Descriptive message explaining changes"
git push origin main
```

### On Failure ❌
```bash
# Review changes
git diff

# Discard if needed (careful!)
git checkout -- <file>

# Or create a fix commit
# (fix the issue, then re-run /verify)
```

---

## Related Commands

- `/db-status` - Quick database health check (faster than full verify)
- `/fix-parser` - Auto-repair common parser issues
- `npm run learn` - Update parser with latest corrections

---

## Tips

1. **Run frequently** - Don't wait until end of session
2. **One change at a time** - Easier to isolate failures
3. **Read the diffs** - Don't just look at pass/fail
4. **Trust the golden set** - It's the source of truth

---

**Last Updated:** January 10, 2026
