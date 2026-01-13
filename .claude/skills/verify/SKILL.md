---
name: verify
description: Run the full ParserZamaActive validation suite to ensure database schema is synchronized, parser logic matches golden set expectations, and block type classification is accurate. CRITICAL - Use this skill BEFORE committing any code changes to git. Use when you need to: (1) Validate database schema version and table structure, (2) Test parser accuracy against golden set truth data, (3) Verify block type normalization and classification, (4) Ensure system integrity after migrations or parser changes, or (5) Prepare for git commit with confidence that all tests pass
---

# Verify Skill

Executes all three validation test suites to ensure complete system integrity before committing changes.

## Core Workflow

Run all three test suites in sequence:

1. **Schema Verification** - `./scripts/verify_schema.sh`
   - Validates database connection
   - Checks table structure and column names
   - Verifies expected table count

2. **Golden Set Validation** - `./scripts/validate_golden_set.sh`
   - Tests parser output against approved truth data
   - Validates JSON structure and field types
   - Checks for hallucinated data

3. **Block Type System Test** - `./scripts/test_block_types.sh`
   - Verifies block code normalization
   - Tests Hebrew and English term resolution
   - Validates alias lookup functions

## Expected Output

### Success ✅

```
Schema Verification:
✅ Connected to database
✅ Found 33 tables in zamm schema
✅ All required tables exist

Golden Set Validation:
✅ 19/19 tests passed
✅ No hallucinated data detected
✅ Block codes normalized correctly

Block Type System:
✅ 60/60 aliases resolved
✅ Hebrew terms mapped correctly
✅ English terms mapped correctly

ALL TESTS PASSED - Safe to commit
```

### Failure ❌

If ANY test fails:

1. **STOP IMMEDIATELY** - Do not commit changes
2. **Review the diff output** - Compare expected vs actual
3. **Fix the root cause** - Not just the symptom
4. **Re-run /verify** - Must pass before proceeding

## Failure Handling

See [ERROR_HANDLING.md](references/ERROR_HANDLING.md) for detailed error resolution guidance.

### Quick Reference

**Schema Errors:**
- Check `.env.local` has correct `SUPABASE_DB_URL`
- Verify `npx supabase status` shows connection
- Check if migrations are pending

**Parser Errors:**
- Review diff (shows expected vs actual)
- Check if `CANONICAL_JSON_SCHEMA.md` was updated
- Run `npm run learn` to update parser brain

**Block Type Errors:**
- Check if new block type aliases were added
- Verify `lib_block_aliases` table is populated
- Review `normalize_block_code` function

## Success Criteria

All three validation suites must pass:

- ✅ Database schema synchronized with migrations
- ✅ Parser output matches golden set expectations
- ✅ Block type classification accurate for all aliases

## Post-Verification Actions

### On Success ✅

```bash
# Safe to commit
git add .
git commit -m "Descriptive message explaining changes"
git push origin main
```

### On Failure ❌

```bash
# Review changes
git diff

# Fix the issue, then re-run
/verify
```

## Related Skills

- `/db-status` - Quick database health check (faster, less comprehensive)
- `/fix-parser` - Auto-repair common parser issues
- `/sync-docs` - Update schema documentation after migrations

## Tips

1. **Run frequently** - Don't wait until end of session
2. **One change at a time** - Easier to isolate failures
3. **Read the diffs** - Don't just look at pass/fail
4. **Trust the golden set** - It's the source of truth

---

**Version:** 1.0.0
**Last Updated:** 2026-01-13
**Duration:** ~30-60 seconds
