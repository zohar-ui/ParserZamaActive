---
name: fix-parser
description: Auto-repair common parser errors in golden set test files including type coercion (strings to numbers), range format conversion (min/max), field ordering for v3.x schema, weight structure migration (legacy to v3.0), and hallucination detection. Use this skill when: (1) Golden set validation shows fixable pattern errors, (2) Migrating golden set to new schema version, (3) Type errors detected (strings instead of numbers), (4) Range formats need conversion ("8-12" to min/max), or (5) Batch fixing common mistakes before running /verify
---

# Fix Parser Skill

Automatically detect and repair common parser errors in golden set files using predefined fix patterns.

## Core Workflow

1. **Scan Golden Set** - Load all `*_expected.json` files from `data/golden_set/`
2. **Apply Fix Patterns** - Run auto-repair functions in sequence
3. **Report Changes** - Show what was fixed
4. **Verify** - Optionally run `/verify` to confirm fixes

## Common Fixes Applied

### 1. Type Errors
Convert string numbers to actual numbers:

**Before:** `"target_sets": "3"`
**After:** `"target_sets": 3`

### 2. Range Formats
Convert string ranges to min/max fields:

**Before:** `"target_reps": "8-12"`
**After:** `"target_reps_min": 8, "target_reps_max": 12`

### 3. Field Ordering (v3.x)
Reorder fields to match CANONICAL_JSON_SCHEMA.md:

**Correct Order:**
1. `item_sequence`
2. `exercise_name`
3. `equipment_key`
4. `prescription`
5. `performed`

### 4. Weight Structure (v3.0 Migration)
Convert legacy weight fields to v3.0 structure:

**Before:** `"target_weight_kg": 100`
**After:** `"target_weight": {"value": 100, "unit": "kg"}`

### 5. Prescription/Performance Separation
Ensure proper separation of planned vs actual:

**Before:** Mixed fields
**After:** Clear `prescription` and `performed` objects

## Usage

```bash
# Fix all files in golden set
/fix-parser

# Fix specific file
/fix-parser workout_05

# Dry run (preview changes without applying)
/fix-parser --dry-run

# Fix and verify automatically
/fix-parser --verify
```

## Expected Output

```
🔧 Scanning golden set files...

Found 19 files to process:
- workout_01_expected.json ✅ No changes needed
- workout_02_expected.json 🔧 Fixed 3 type errors
- workout_03_expected.json 🔧 Fixed 1 range format
- workout_04_expected.json 🔧 Fixed field ordering
- workout_05_expected.json ⚠️  Manual review needed (hallucination detected)
...

Summary:
✅ 12 files OK
🔧 6 files auto-fixed
⚠️  1 file needs manual review

Changes saved. Run /verify to confirm fixes.
```

## Manual Review Required

Some patterns require human judgment:

### Hallucinations

```
⚠️  WARNING: workout_05.json
- Numeric value without source text: target_weight = 80kg
- Original text: "moderate weight"
- Recommendation: Replace with notes field

→ Manually review and fix
```

### Ambiguous Context

```
⚠️  WARNING: workout_12.json
- Exercise name: "row"
- Could be: "Barbell Row" OR "Dumbbell Row" OR "Rowing Machine"
- Need context from original text

→ Check original text and add equipment_key
```

## Fix Patterns Reference

See [FIX_PATTERNS.md](references/FIX_PATTERNS.md) for detailed implementation of each fix pattern.

## Post-Fix Workflow

1. **Review Changes**
   ```bash
   git diff data/golden_set/
   ```

2. **Verify Fixes**
   ```bash
   /verify
   ```

3. **Handle Warnings**
   - Review flagged files
   - Fix hallucinations manually
   - Resolve ambiguous cases

4. **Commit**
   ```bash
   git add data/golden_set/
   git commit -m "fix: Auto-repair common parser errors in golden set"
   ```

## Success Criteria

- ✅ All fixable patterns corrected
- ✅ No new errors introduced
- ✅ Warnings flagged for manual review
- ✅ `/verify` passes after fixes

## Safety Features

1. **Dry Run Mode** - Preview changes first
2. **Backup Creation** - `.backup` files before modifying
3. **Automatic Validation** - Can run `/verify` automatically
4. **Git Integration** - Easy rollback with `git checkout`

## Related Skills

- `/verify` - Validate fixes after applying
- `/debug-parse` - Test parser logic on specific snippets
- `npm run learn` - Update parser brain with corrections

## When to Use

| Scenario | Use fix-parser | Alternative |
|----------|----------------|-------------|
| **Type errors across multiple files** | ✅ Yes | Manual fix |
| **Schema version migration** | ✅ Yes | Manual migration |
| **Single file issue** | ⚠️ Manual faster | Manual fix |
| **Hallucination detected** | ⚠️ Flags only | Manual fix required |
| **After golden set update** | ✅ Yes | N/A |

---

**Version:** 1.0.0
**Last Updated:** 2026-01-13
**Duration:** ~10-30 seconds
