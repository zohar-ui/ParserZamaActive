# Fix Patterns Reference

**Purpose:** Detailed implementation patterns for auto-repair functions
**Main Skill:** fix-parser

---

## Pattern 1: Type Errors

### Problem

Parser outputs string representations of numbers:

```json
{
  "target_sets": "3",
  "target_reps": "5",
  "target_weight": {"value": "100", "unit": "kg"}
}
```

### Solution

```javascript
function fixTypeErrors(obj) {
  const numericFields = [
    'target_sets', 'target_reps', 'target_duration_sec',
    'actual_sets', 'actual_reps', 'set_index',
    'rpe', 'tempo', 'rest_sec'
  ];

  for (const field of numericFields) {
    if (typeof obj[field] === 'string' && !isNaN(obj[field])) {
      obj[field] = parseFloat(obj[field]);
    }
  }

  // Handle nested weight/measurement values
  if (obj.target_weight && typeof obj.target_weight.value === 'string') {
    obj.target_weight.value = parseFloat(obj.target_weight.value);
  }
  if (obj.actual_weight && typeof obj.actual_weight.value === 'string') {
    obj.actual_weight.value = parseFloat(obj.actual_weight.value);
  }

  // Recursive for nested objects
  for (const key in obj) {
    if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
      obj[key] = fixTypeErrors(obj[key]);
    } else if (Array.isArray(obj[key])) {
      obj[key] = obj[key].map(item =>
        typeof item === 'object' ? fixTypeErrors(item) : item
      );
    }
  }

  return obj;
}
```

### Test Cases

```javascript
// Test 1: Simple number strings
assert.equal(fixTypeErrors({target_reps: "5"}).target_reps, 5);

// Test 2: Float strings
assert.equal(fixTypeErrors({rpe: "7.5"}).rpe, 7.5);

// Test 3: Nested values
const result = fixTypeErrors({target_weight: {value: "100", unit: "kg"}});
assert.equal(result.target_weight.value, 100);
```

---

## Pattern 2: Range Formats

### Problem

String ranges instead of separate min/max fields:

```json
{
  "target_reps": "8-12",
  "target_weight": "50-60kg"
}
```

### Solution

```javascript
function fixRangeFormats(obj) {
  const rangeFields = ['target_reps', 'target_duration', 'target_rest'];

  for (const field of rangeFields) {
    if (typeof obj[field] === 'string' && obj[field].includes('-')) {
      const match = obj[field].match(/^(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)$/);
      if (match) {
        const [, min, max] = match;
        delete obj[field];
        obj[`${field}_min`] = parseFloat(min);
        obj[`${field}_max`] = parseFloat(max);
      }
    }
  }

  // Special case: weight ranges with units
  if (typeof obj.target_weight === 'string' && obj.target_weight.includes('-')) {
    const match = obj.target_weight.match(/^(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s*(kg|lb|lbs)?$/i);
    if (match) {
      const [, min, max, unit] = match;
      delete obj.target_weight;
      obj.target_weight_min = {value: parseFloat(min), unit: unit || 'kg'};
      obj.target_weight_max = {value: parseFloat(max), unit: unit || 'kg'};
    }
  }

  // Recursive
  for (const key in obj) {
    if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
      obj[key] = fixRangeFormats(obj[key]);
    } else if (Array.isArray(obj[key])) {
      obj[key] = obj[key].map(item =>
        typeof item === 'object' ? fixRangeFormats(item) : item
      );
    }
  }

  return obj;
}
```

### Test Cases

```javascript
// Test 1: Rep range
const result1 = fixRangeFormats({target_reps: "8-12"});
assert.equal(result1.target_reps_min, 8);
assert.equal(result1.target_reps_max, 12);

// Test 2: Weight range with unit
const result2 = fixRangeFormats({target_weight: "50-60kg"});
assert.deepEqual(result2.target_weight_min, {value: 50, unit: "kg"});
assert.deepEqual(result2.target_weight_max, {value: 60, unit: "kg"});
```

---

## Pattern 3: Field Ordering (v3.x)

### Problem

Fields in wrong order (not matching CANONICAL_JSON_SCHEMA.md):

```json
{
  "prescription": {...},
  "exercise_name": "Squat",
  "item_sequence": 1,
  "equipment_key": "barbell",
  "performed": null
}
```

### Solution

```javascript
function fixFieldOrdering(item) {
  if (!item.item_sequence) return item;  // Not a BlockItem

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

  // Add fields in correct order
  for (const key of correctOrder) {
    if (key in item) {
      ordered[key] = item[key];
    }
  }

  // Add any remaining fields not in the order list
  for (const key in item) {
    if (!(key in ordered)) {
      ordered[key] = item[key];
    }
  }

  return ordered;
}
```

### Test Cases

```javascript
// Test: Reordering
const input = {
  prescription: {target_sets: 3},
  exercise_name: "Squat",
  item_sequence: 1,
  performed: null
};

const result = fixFieldOrdering(input);
const keys = Object.keys(result);
assert.equal(keys[0], 'item_sequence');
assert.equal(keys[1], 'exercise_name');
assert.equal(keys[2], 'prescription');
assert.equal(keys[3], 'performed');
```

---

## Pattern 4: Weight Structure (v3.0 Migration)

### Problem

Legacy flat weight fields:

```json
{
  "target_weight_kg": 100,
  "actual_weight_kg": 95,
  "target_weight_lbs": 220
}
```

### Solution

```javascript
function fixWeightStructure(obj) {
  const weightFields = [
    'target_weight_kg',
    'target_weight_lbs',
    'actual_weight_kg',
    'actual_weight_lbs',
    'load_kg',
    'load_lbs'
  ];

  for (const field of weightFields) {
    if (field in obj) {
      const value = obj[field];
      const unit = field.includes('_kg') || field.includes('kg') ? 'kg' : 'lbs';

      // Determine new field name
      let newField;
      if (field.includes('target_weight')) {
        newField = 'target_weight';
      } else if (field.includes('actual_weight')) {
        newField = 'actual_weight';
      } else if (field.includes('load')) {
        newField = 'load';
      }

      // Replace old field with new structure
      delete obj[field];
      obj[newField] = {value, unit};
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

### Test Cases

```javascript
// Test 1: target_weight_kg migration
const result1 = fixWeightStructure({target_weight_kg: 100});
assert.deepEqual(result1.target_weight, {value: 100, unit: "kg"});

// Test 2: Multiple weight fields
const result2 = fixWeightStructure({
  target_weight_kg: 100,
  actual_weight_kg: 95
});
assert.deepEqual(result2.target_weight, {value: 100, unit: "kg"});
assert.deepEqual(result2.actual_weight, {value: 95, unit: "kg"});
```

---

## Pattern 5: Prescription/Performance Separation

### Problem

Mixed prescription and performance fields:

```json
{
  "sets": 3,
  "reps": [5, 5, 4],
  "weight": 100
}
```

### Solution

```javascript
function separatePrescriptionPerformance(obj) {
  // Detect if already separated
  if ('prescription' in obj && 'performed' in obj) {
    return obj;
  }

  const prescriptionFields = [
    'target_sets', 'target_reps', 'target_reps_min', 'target_reps_max',
    'target_weight', 'target_duration', 'target_rest',
    'rpe', 'tempo', 'intensity_percent'
  ];

  const performanceFields = [
    'actual_sets', 'actual_reps', 'actual_weight',
    'actual_duration', 'actual_rest',
    'completion_status', 'technique_notes'
  ];

  const prescription = {};
  const performed = {};
  let hasPrescription = false;
  let hasPerformance = false;

  for (const key in obj) {
    if (prescriptionFields.includes(key)) {
      prescription[key] = obj[key];
      delete obj[key];
      hasPrescription = true;
    } else if (performanceFields.includes(key)) {
      performed[key] = obj[key];
      delete obj[key];
      hasPerformance = true;
    }
  }

  // Add separated objects
  if (hasPrescription) {
    obj.prescription = prescription;
  }
  if (hasPerformance) {
    obj.performed = performed;
  }

  return obj;
}
```

### Test Cases

```javascript
// Test: Separation
const input = {
  target_sets: 3,
  target_reps: 5,
  actual_reps: [5, 5, 4]
};

const result = separatePrescriptionPerformance(input);
assert.deepEqual(result.prescription, {target_sets: 3, target_reps: 5});
assert.deepEqual(result.performed, {actual_reps: [5, 5, 4]});
```

---

## Pattern 6: Hallucination Detection (Manual Review)

### Problem

Parser invented data not in source text.

### Detection Logic

```javascript
function detectHallucinations(obj, originalText) {
  const warnings = [];

  // Check for specific numeric values without source evidence
  if (obj.prescription && obj.prescription.target_weight) {
    const weight = obj.prescription.target_weight;
    const weightRegex = new RegExp(`${weight.value}\\s*${weight.unit}`, 'i');

    if (!weightRegex.test(originalText)) {
      warnings.push({
        field: 'prescription.target_weight',
        value: weight,
        reason: 'Numeric weight value not found in source text',
        originalText: originalText
      });
    }
  }

  // Check for specific rep counts
  if (obj.prescription && obj.prescription.target_reps) {
    const reps = obj.prescription.target_reps;
    if (!originalText.includes(reps.toString())) {
      warnings.push({
        field: 'prescription.target_reps',
        value: reps,
        reason: 'Specific rep count not found in source text'
      });
    }
  }

  return warnings;
}
```

### Action Required

Cannot auto-fix - requires manual review:

1. Read original source text
2. Verify if value is inferred or explicit
3. If inferred: Remove and add to notes
4. If explicit: Check for parsing error

---

## Complete Auto-Fix Script

### Main Function

```javascript
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const GOLDEN_SET_DIR = 'data/golden_set/';

function autoFixGoldenSet({ dryRun = false, targetFile = null }) {
  const files = fs.readdirSync(GOLDEN_SET_DIR)
    .filter(f => f.endsWith('_expected.json'))
    .filter(f => !targetFile || f.includes(targetFile));

  const results = {
    ok: 0,
    fixed: 0,
    warnings: 0,
    changes: []
  };

  for (const file of files) {
    const filePath = path.join(GOLDEN_SET_DIR, file);
    let json = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const original = JSON.stringify(json);

    // Apply all fix patterns
    json = fixTypeErrors(json);
    json = fixRangeFormats(json);
    json = fixWeightStructure(json);

    // Process all items
    if (json.sessions) {
      json.sessions.forEach(session => {
        if (session.blocks) {
          session.blocks.forEach(block => {
            if (block.items) {
              block.items = block.items.map(item => fixFieldOrdering(item));
            }
          });
        }
      });
    }

    // Check if changes were made
    const modified = JSON.stringify(json);
    if (original !== modified) {
      results.fixed++;
      results.changes.push({
        file: file,
        status: 'fixed'
      });

      if (!dryRun) {
        // Backup original
        fs.writeFileSync(`${filePath}.backup`, original);

        // Save fixed version
        fs.writeFileSync(filePath, JSON.stringify(json, null, 2));
      }
    } else {
      results.ok++;
    }
  }

  return results;
}

// CLI
if (require.main === module) {
  const dryRun = process.argv.includes('--dry-run');
  const targetFile = process.argv[2];

  const results = autoFixGoldenSet({ dryRun, targetFile });

  console.log('\n🔧 Fix Parser Results\n');
  console.log(`✅ ${results.ok} files OK`);
  console.log(`🔧 ${results.fixed} files fixed`);
  console.log(`⚠️  ${results.warnings} files need manual review`);

  if (dryRun) {
    console.log('\n(Dry run - no changes saved)');
  } else {
    console.log('\nChanges saved. Run /verify to confirm fixes.');
  }
}

module.exports = { autoFixGoldenSet };
```

---

**Last Updated:** 2026-01-13
**Version:** 1.0.0
