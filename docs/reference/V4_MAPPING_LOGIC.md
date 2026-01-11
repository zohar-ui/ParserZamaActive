# commit_full_workout_v4 - Mapping Logic & Quality Gate

**Version:** 4.0.0
**Date:** 2026-01-11
**Compatible With:** Canonical JSON Schema v3.2.0

---

## 🎯 Purpose

This document explains how **commit_full_workout_v4** transforms JSON v3.2 structured data into flat database columns while preserving data integrity through a quality gate system.

---

## 📊 Mapping Summary

### JSON v3.2 → Database Column Mapping

| JSON v3.2 Path | Database Table.Column | Extraction Logic | Example |
|----------------|----------------------|------------------|---------|
| `performed.sets[].load` | `res_item_sets.load_kg` | Extract `.value`, convert unit to kg | `{value: 100, unit: "kg"}` → `100.0` |
| `performed.sets[].duration` | `res_item_sets.duration_sec` | Extract `.value`, convert unit to sec | `{value: 2, unit: "min"}` → `120.0` |
| `performed.sets[].distance` | `res_item_sets.distance_m` | Extract `.value`, convert unit to m | `{value: 500, unit: "m"}` → `500.0` |
| `performed.actual_duration` | `res_blocks.total_time_sec` | Extract `.value`, convert unit to sec | `{value: 15, unit: "min"}` → `900.0` |
| `exercise_key` | `workout_items.exercise_key` | Direct mapping (text) | `"deadlift"` → `"deadlift"` |
| `equipment_key` | `workout_items.equipment_key` | Direct mapping (text) | `"barbell"` → `"barbell"` |
| `prescription_data` | `workout_items.prescription_data` | Full JSONB stored as backup | `{...}` → `JSONB` |
| `performed_data` | `workout_items.performed_data` | Full JSONB stored as backup | `{...}` → `JSONB` |

---

## 🔧 Smart Extraction Logic

### Helper Function: `extract_measurement_value()`

**Purpose:** Extract numeric values from v3.2 `{value, unit}` objects with automatic unit conversion.

**Signature:**
```sql
zamm.extract_measurement_value(
    p_jsonb JSONB,           -- Input: {value: 100, unit: "kg"}
    p_target_unit TEXT       -- Target unit: "kg", "sec", "m"
) RETURNS NUMERIC
```

**Conversion Rules:**

#### Weight Conversions (Target: kg)
```
kg   → kg    (× 1.0)
lbs  → kg    (× 0.453592)
g    → kg    (× 0.001)
```

**Example:**
```sql
-- Input JSON: {"value": 220, "unit": "lbs"}
SELECT zamm.extract_measurement_value('{"value": 220, "unit": "lbs"}'::jsonb, 'kg');
-- Output: 99.79 (220 × 0.453592)
```

#### Duration Conversions (Target: sec)
```
sec    → sec    (× 1.0)
min    → sec    (× 60.0)
hours  → sec    (× 3600.0)
```

**Example:**
```sql
-- Input JSON: {"value": 2.5, "unit": "min"}
SELECT zamm.extract_measurement_value('{"value": 2.5, "unit": "min"}'::jsonb, 'sec');
-- Output: 150.0 (2.5 × 60)
```

#### Distance Conversions (Target: m)
```
m      → m     (× 1.0)
km     → m     (× 1000.0)
yards  → m     (× 0.9144)
miles  → m     (× 1609.34)
```

**Example:**
```sql
-- Input JSON: {"value": 400, "unit": "yards"}
SELECT zamm.extract_measurement_value('{"value": 400, "unit": "yards"}'::jsonb, 'm');
-- Output: 365.76 (400 × 0.9144)
```

---

## 🚦 Quality Gate System

### Overview

The quality gate prevents incomplete or invalid data from being marked as "completed". Workouts with missing critical data are flagged for human review.

### Quality Check Function: `check_workout_quality()`

**Purpose:** Validate workout JSON for missing critical data before committing to database.

**Checks Performed:**

1. **Missing `exercise_name`** → CRITICAL ERROR
2. **Missing `exercise_key`** → WARNING (needs catalog lookup)
3. **Missing `target_sets` or `target_reps`** → WARNING (incomplete prescription)

**Return Values:**
```sql
-- Returns TABLE:
needs_review BOOLEAN        -- true if any check fails
review_reason TEXT          -- Specific reasons (semicolon-separated)
missing_count INTEGER       -- Number of issues found
```

**Example Output:**
```json
{
  "needs_review": true,
  "review_reason": "Session 1 Block 2 Item 1: Missing exercise_key for \"Deadlift\"; Session 1 Block 3 Item 2: Missing target_sets/target_reps for \"Row\"",
  "missing_count": 2
}
```

---

## 🏗️ Workflow Changes

### Before (v3):
```
JSON v3.2 → commit_full_workout_v3() → Database
                 ↓
         ❌ Data loss (NULLs)
         ❌ No validation
         ❌ Always status='completed'
```

### After (v4):
```
JSON v3.2 → Quality Check → commit_full_workout_v4() → Database
                ↓                      ↓
        Validate data          Smart extraction
                ↓                      ↓
      Set review flags         Flat columns + JSONB backup
                ↓
    status='pending_review' OR 'completed'
```

---

## 📋 Schema Changes

### New Columns in `workout_main`

| Column | Type | Default | Purpose |
|--------|------|---------|---------|
| `requires_review` | BOOLEAN | `false` | Flag for workouts needing human review |
| `review_reason` | TEXT | `NULL` | Specific reason(s) why review is required |

**Usage:**
```sql
-- Find all workouts needing review
SELECT workout_id, workout_date, review_reason
FROM zamm.workout_main
WHERE requires_review = true;
```

### New Column in `workout_items`

| Column | Type | Default | Purpose |
|--------|------|---------|---------|
| `is_verified` | BOOLEAN | `false` | Flag indicating item has complete data (exercise_key, prescription) |

**Usage:**
```sql
-- Find unverified items
SELECT exercise_name, exercise_key, is_verified
FROM zamm.workout_items
WHERE is_verified = false;
```

### New Columns in `res_item_sets`

| Column | Type | Purpose |
|--------|------|---------|
| `duration_sec` | NUMERIC | Extracted duration in seconds (from v3.2 `{value, unit}`) |
| `distance_m` | NUMERIC | Extracted distance in meters (from v3.2 `{value, unit}`) |

**Note:** `load_kg` already existed, now properly extracts from v3.2 `load: {value, unit}`.

---

## 🔄 Detailed Mapping Examples

### Example 1: Weight Extraction (Set Result)

**JSON v3.2 Input:**
```json
{
  "performed_data": {
    "sets": [
      {
        "set_index": 1,
        "reps": 5,
        "load": {
          "value": 140,
          "unit": "kg"
        },
        "rpe": 7
      }
    ]
  }
}
```

**Database Output (`res_item_sets`):**
```sql
set_index: 1
reps: 5
load_kg: 140.0        -- ✅ Extracted from load.value
rpe: 7
duration_sec: NULL
distance_m: NULL
```

**Extraction Code (from v4):**
```sql
v_load_kg := zamm.extract_measurement_value(
    v_set_rec.load,  -- {"value": 140, "unit": "kg"}
    'kg'
);
```

---

### Example 2: Duration Extraction (Block Result)

**JSON v3.2 Input:**
```json
{
  "performed": {
    "completed": true,
    "actual_duration": {
      "value": 12,
      "unit": "min"
    }
  }
}
```

**Database Output (`res_blocks`):**
```sql
did_complete: true
total_time_sec: 720.0     -- ✅ Extracted and converted (12 min × 60 = 720 sec)
```

**Extraction Code (from v4):**
```sql
zamm.extract_measurement_value(
    v_blk_rec.performed->'actual_duration',
    'sec'  -- Convert to seconds
)
```

---

### Example 3: Mixed Units (Distance in Yards)

**JSON v3.2 Input:**
```json
{
  "performed_data": {
    "sets": [
      {
        "set_index": 1,
        "distance": {
          "value": 400,
          "unit": "yards"
        }
      }
    ]
  }
}
```

**Database Output (`res_item_sets`):**
```sql
set_index: 1
distance_m: 365.76      -- ✅ Converted (400 yards × 0.9144 = 365.76 m)
```

**Extraction Code (from v4):**
```sql
v_distance_m := zamm.extract_measurement_value(
    v_set_rec.distance,
    'm'  -- Convert to meters
);
```

---

### Example 4: Quality Gate Triggering

**JSON v3.2 Input (Incomplete):**
```json
{
  "sessions": [{
    "blocks": [{
      "items": [
        {
          "exercise_name": "Deadlift",
          "exercise_key": null,      // ❌ Missing!
          "prescription_data": {
            "target_sets": 3
            // ❌ Missing target_reps!
          }
        }
      ]
    }]
  }]
}
```

**Quality Check Result:**
```json
{
  "needs_review": true,
  "review_reason": "Session 1 Block 1 Item 1: Missing exercise_key for \"Deadlift\"; Session 1 Block 1 Item 1: Missing target_sets/target_reps for \"Deadlift\"",
  "missing_count": 2
}
```

**Database Output (`workout_main`):**
```sql
workout_id: <uuid>
status: 'pending_review'     -- ✅ NOT 'completed'
requires_review: true
review_reason: "Session 1 Block 1 Item 1: Missing exercise_key for \"Deadlift\"..."
```

**Database Output (`workout_items`):**
```sql
item_id: <uuid>
exercise_name: 'Deadlift'
exercise_key: NULL
is_verified: false           -- ✅ Flagged as unverified
prescription_data: {...}     -- ✅ Full JSONB still saved as backup
```

---

## 🎯 Data Safety Strategy

### Dual Storage Model

**v4 uses a "best of both worlds" approach:**

1. **Flat Columns** → Fast queries, analytics, reporting
2. **JSONB Backup** → Full data preservation, no information loss

**Example:**

```sql
-- workout_items table stores BOTH:
prescription_data: {              -- JSONB backup (full v3.2 structure)
  "target_sets": 3,
  "target_reps": 5,
  "target_weight": {
    "value": 100,
    "unit": "kg"
  }
}

-- AND extracted flat values (from other tables like res_item_sets):
load_kg: 100.0                    -- Extracted for queries
```

**Benefits:**
- ✅ Can query extracted values: `SELECT * FROM res_item_sets WHERE load_kg > 100`
- ✅ Can reconstruct original: `SELECT prescription_data FROM workout_items`
- ✅ No data loss if extraction fails (falls back to JSONB)

---

## 🔍 Query Examples

### Query 1: Find Workouts Needing Review
```sql
SELECT
    wm.workout_id,
    wm.workout_date,
    la.full_name AS athlete,
    wm.review_reason,
    wm.created_at
FROM zamm.workout_main wm
JOIN zamm.lib_athletes la ON wm.athlete_id = la.athlete_id
WHERE wm.requires_review = true
ORDER BY wm.created_at DESC;
```

### Query 2: Find Unverified Exercises
```sql
SELECT
    wi.exercise_name,
    wi.exercise_key,
    COUNT(*) AS usage_count
FROM zamm.workout_items wi
WHERE wi.is_verified = false
GROUP BY wi.exercise_name, wi.exercise_key
ORDER BY usage_count DESC;
```

### Query 3: Analyze Load Distribution (Now Possible!)
```sql
-- This query now works thanks to extracted load_kg!
SELECT
    wi.exercise_name,
    AVG(ris.load_kg) AS avg_load_kg,
    MAX(ris.load_kg) AS max_load_kg,
    COUNT(*) AS total_sets
FROM zamm.res_item_sets ris
JOIN zamm.workout_items wi ON ris.item_id = wi.item_id
WHERE ris.load_kg IS NOT NULL
GROUP BY wi.exercise_name
ORDER BY avg_load_kg DESC
LIMIT 10;
```

### Query 4: Find Missing Data Patterns
```sql
-- Identify which fields are most commonly missing
SELECT
    CASE
        WHEN exercise_key IS NULL THEN 'Missing exercise_key'
        WHEN prescription_data IS NULL OR prescription_data = '{}'::jsonb THEN 'Missing prescription'
        WHEN is_verified = false THEN 'Unverified'
        ELSE 'OK'
    END AS issue_type,
    COUNT(*) AS issue_count
FROM zamm.workout_items
GROUP BY issue_type
ORDER BY issue_count DESC;
```

---

## ⚙️ Migration Impact

### Backward Compatibility

✅ **v3 still available** - Old code can still call `commit_full_workout_v3`
✅ **v4 is opt-in** - Use `commit_full_workout_v4` when ready
✅ **Alias updated** - `commit_full_workout_latest` now points to v4

### Testing Checklist

- [ ] Test v4 with complete workout (all fields present)
- [ ] Test v4 with incomplete workout (missing exercise_key)
- [ ] Test v4 with mixed units (lbs, kg, min, sec, yards)
- [ ] Verify quality gate flags workouts correctly
- [ ] Verify extracted values match expected conversions
- [ ] Verify JSONB backup preserves original data
- [ ] Query workouts needing review
- [ ] Query unverified items

---

## 🚨 Breaking Changes from v3

### None! (Backward Compatible)

v4 is fully backward compatible with v3:
- ✅ Same function signature
- ✅ Same input JSON format (v3.2)
- ✅ Same transaction safety (atomic commits)
- ✅ v3 still available for legacy systems

**New Features:**
- ✅ Smart extraction of `{value, unit}` objects
- ✅ Quality gate for incomplete data
- ✅ Review tracking columns
- ✅ Verification flags

---

## 📚 Related Documents

- [CANONICAL_JSON_SCHEMA.md](./CANONICAL_JSON_SCHEMA.md) - JSON v3.2 specification
- [VALIDATION_SYSTEM_SUMMARY.md](../VALIDATION_SYSTEM_SUMMARY.md) - Validation rules
- [ARCHITECTURE.md](../architecture/ARCHITECTURE.md) - System architecture

---

**Last Updated:** 2026-01-11
**Maintained By:** AI Development Team + @db-architect
