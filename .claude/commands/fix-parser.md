# /fix-parser

**Purpose:** Auto-repair common parser errors  
**Duration:** ~10-30 seconds  
**Use When:** Golden set validation shows common fixable patterns

---

## Goal

Automatically detect and fix common parser errors:
1. **Type Errors** - Strings that should be numbers
2. **Range Formats** - String ranges that should be min/max
3. **Field Ordering** - Incorrect field order in BlockItems
4. **Weight Structure** - Legacy `*_kg` fields → v3.0 `{value, unit}`
5. **Null Hallucinations** - Remove invented data

---

## Usage

```bash
# Fix all common errors in golden set
/fix-parser

# Fix specific file
/fix-parser workout_05

# Dry run (show what would be fixed)
/fix-parser --dry-run
```

---

## What Gets Fixed

### Fix 1: Type Errors

**Before:**
```json
{
  "target_sets": "3",
  "target_reps": "5",
  "target_weight": {"value": "100", "unit": "kg"}
}
```

**After:**
```json
{
  "target_sets": 3,
  "target_reps": 5,
  "target_weight": {"value": 100, "unit": "kg"}
}
```

---

### Fix 2: Range Formats

**Before:**
```json
{
  "target_reps": "8-12"
}
```

**After:**
```json
{
  "target_reps_min": 8,
  "target_reps_max": 12
}
```

---

### Fix 3: Field Ordering (v3.0)

**Before:**
```json
{
  "prescription": {...},
  "exercise_name": "Squat",
  "item_sequence": 1,
  "equipment_key": "barbell",
  "performed": null
}
```

**After:**
```json
{
  "item_sequence": 1,
  "exercise_name": "Squat",
  "equipment_key": "barbell",
  "prescription": {...},
  "performed": null
}
```

---

### Fix 4: Weight Structure (v3.0 Migration)

**Before:**
```json
{
  "target_weight_kg": 100,
  "actual_weight_kg": 95
}
```

**After:**
```json
{
  "target_weight": {"value": 100, "unit": "kg"},
  "actual_weight": {"value": 95, "unit": "kg"}
}
```

---

### Fix 5: Remove Hallucinations

**Before:**
```json
// Original text: "3x5 @ moderate weight"
{
  "prescription": {
    "target_sets": 3,
    "target_reps": 5,
    "target_weight": {"value": 80, "unit": "kg"}  // ← Invented!
  }
}
```

**After:**
```json
{
  "prescription": {
    "target_sets": 3,
    "target_reps": 5,
    "notes": "moderate weight"
  }
}
```

---

### Fix 6: Prescription/Performance Separation

**Before:**
```json
{
  "sets": 3,
  "reps": [5, 5, 4]
}
```

**After:**
```json
{
  "prescription": {"target_sets": 3, "target_reps": 5},
  "performed": {"actual_reps": [5, 5, 4]}
}
```

---

## Implementation

The fix script should:

1. **Load Files**
   ```javascript
   const goldenSetDir = 'data/golden_set/';
   const files = fs.readdirSync(goldenSetDir)
     .filter(f => f.endsWith('_expected.json'));
   ```

2. **Apply Fixes**
   ```javascript
   for (const file of files) {
     let json = JSON.parse(fs.readFileSync(file));
     
     // Fix 1: Type coercion
     json = fixTypeErrors(json);
     
     // Fix 2: Range formats
     json = fixRangeFormats(json);
     
     // Fix 3: Field ordering
     json = fixFieldOrdering(json);
     
     // Fix 4: Weight structure
     json = fixWeightStructure(json);
     
     // Fix 5: Hallucinations (manual review needed)
     json = detectHallucinations(json);
     
     fs.writeFileSync(file, JSON.stringify(json, null, 2));
   }
   ```

3. **Verify**
   ```bash
   ./scripts/validate_golden_set.sh
   ```

---

## Auto-Fix Patterns

### Pattern: String Numbers
```javascript
function fixTypeErrors(obj) {
  const numericFields = [
    'target_sets', 'target_reps', 'target_duration_sec',
    'actual_sets', 'actual_reps', 'set_index'
  ];
  
  for (const field of numericFields) {
    if (typeof obj[field] === 'string' && !isNaN(obj[field])) {
      obj[field] = parseFloat(obj[field]);
    }
  }
  
  // Recursive for nested objects
  for (const key in obj) {
    if (typeof obj[key] === 'object' && obj[key] !== null) {
      obj[key] = fixTypeErrors(obj[key]);
    }
  }
  
  return obj;
}
```

### Pattern: Range Strings
```javascript
function fixRangeFormats(obj) {
  const rangeFields = ['target_reps', 'target_weight', 'target_duration'];
  
  for (const field of rangeFields) {
    if (typeof obj[field] === 'string' && obj[field].includes('-')) {
      const [min, max] = obj[field].split('-').map(s => parseFloat(s.trim()));
      delete obj[field];
      obj[`${field}_min`] = min;
      obj[`${field}_max`] = max;
    }
  }
  
  // Recursive
  for (const key in obj) {
    if (typeof obj[key] === 'object' && obj[key] !== null) {
      obj[key] = fixRangeFormats(obj[key]);
    }
  }
  
  return obj;
}
```

### Pattern: Field Order (v3.0)
```javascript
function fixFieldOrdering(item) {
  if (!item.item_sequence) return item;
  
  const correctOrder = [
    'item_sequence',
    'exercise_name',
    'exercise_options',
    'exercises',
    'equipment_key',
    'prescription',
    'performed',
    'circuit_config',
    'notes'
  ];
  
  const ordered = {};
  for (const key of correctOrder) {
    if (key in item) {
      ordered[key] = item[key];
    }
  }
  
  // Add any remaining fields
  for (const key in item) {
    if (!(key in ordered)) {
      ordered[key] = item[key];
    }
  }
  
  return ordered;
}
```

### Pattern: Weight Structure (v3.0)
```javascript
function fixWeightStructure(obj) {
  const weightFields = [
    'target_weight_kg',
    'target_weight_lbs',
    'actual_weight_kg',
    'actual_weight_lbs'
  ];
  
  for (const field of weightFields) {
    if (field in obj) {
      const value = obj[field];
      const unit = field.includes('_kg') ? 'kg' : 'lbs';
      const newField = field.replace(/_kg|_lbs/, '');
      
      delete obj[field];
      obj[newField] = { value, unit };
    }
  }
  
  // Recursive
  for (const key in obj) {
    if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
      obj[key] = fixWeightStructure(obj[key]);
    } else if (Array.isArray(obj[key])) {
      obj[key] = obj[key].map(item => 
        typeof item === 'object' ? fixWeightStructure(item) : item
      );
    }
  }
  
  return obj;
}
```

---

## Manual Review Required

Some fixes need human judgment:

### Hallucinations
```bash
# Script flags suspicious patterns
⚠️ WARNING: workout_05.json
  - Numeric value without source text: target_weight = 80kg
  - Original text: "moderate weight"
  - Recommendation: Replace with notes field

→ Manually review and fix
```

### Ambiguous Context
```bash
# Script can't determine correct interpretation
⚠️ WARNING: workout_12.json
  - Exercise name: "row"
  - Could be: "Barbell Row" OR "Dumbbell Row" OR "Rowing Machine"
  - Need context from original text

→ Check original text and add equipment_key
```

---

## Post-Fix Workflow

1. **Run Fix**
   ```bash
   /fix-parser
   ```

2. **Review Changes**
   ```bash
   git diff data/golden_set/
   ```

3. **Verify**
   ```bash
   /verify
   ```

4. **Manual Fixes** (if warnings)
   - Review flagged files
   - Fix hallucinations
   - Resolve ambiguous cases

5. **Commit**
   ```bash
   git add data/golden_set/
   git commit -m "fix: Auto-repair common parser errors in golden set"
   ```

---

## Script Location

Create new script: `scripts/fix_parser_errors.js`

```javascript
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const GOLDEN_SET_DIR = 'data/golden_set/';

// ... implementation ...

if (require.main === module) {
  const dryRun = process.argv.includes('--dry-run');
  const targetFile = process.argv[2];
  
  fixParserErrors({ dryRun, targetFile });
}
```

Make executable:
```bash
chmod +x scripts/fix_parser_errors.js
```

---

## Safety Features

1. **Dry Run First** - Always preview changes
2. **Backup Original** - Create `.backup` files before modifying
3. **Validation After** - Run golden set tests automatically
4. **Git Integration** - Easy to rollback with `git checkout`

---

## Related Commands

- `/verify` - Validate after fixes
- `npm run learn` - Update parser brain with corrections
- `@golden-set-curator` - Review and approve changes

---

**Last Updated:** January 10, 2026
