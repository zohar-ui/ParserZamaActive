# 🔥 Stress Test Execution Guide

**For:** AI Parsing Agent  
**Input File:** [`/data/stress_test_10.txt`](../data/stress_test_10.txt)  
**Schema Reference:** [`CANONICAL_JSON_SCHEMA.md`](./CANONICAL_JSON_SCHEMA.md)  
**Purpose:** Validate parser resilience against 10 challenging edge cases

---

## Quick Reference: The Nasty 10

### 🎯 Test Case 1: Hebrew-English Salad

**Input:**
```
Back Squat 3x5 @ 100kg
הרגשתי כבד מאוד היום
Last set failed - got only 4 reps
כאב קל בברך השמאלית
```

**Expected Output:**
```json
{
  "exercise_name": "Back Squat",
  "prescription": {
    "target_sets": 3,
    "target_reps": 5,
    "target_weight": { "value": 100, "unit": "kg" }
  },
  "performed": {
    "actual_sets": 3,
    "notes": "הרגשתי כבד מאוד היום. Last set failed - got only 4 reps. כאב קל בברך השמאלית"
  }
}
```

**Validation Checks:**
- ✅ Hebrew ONLY in `performed.notes`
- ✅ English in `prescription` (if any description)
- ✅ Failed rep data captured

---

### 🎯 Test Case 2: Complex Range

**Input:**
```
Row - 5 intervals
Target: 500m @ 22-24 spm
Drag factor: 110-120
```

**Expected Output:**
```json
{
  "exercise_name": "Row",
  "prescription": {
    "target_sets": 5,
    "target_distance_m": 500,
    "target_spm_min": 22,
    "target_spm_max": 24,
    "target_drag_factor_min": 110,
    "target_drag_factor_max": 120
  }
}
```

**Validation Checks:**
- ✅ Ranges as min/max (NOT strings like "22-24")
- ✅ All values are `number` type
- ✅ No string "110-120"

---

### 🎯 Test Case 3: Implicit Date

**Input:**
```
Day 3, Week 5 - Lower Body
```

**Expected Output:**
```json
{
  "workout_date": null,
  "title": "Day 3, Week 5 - Lower Body",
  "status": "planned"
}
```

**OR** (if date inference is implemented):
```json
{
  "workout_date": "2026-01-XX",
  "title": "Day 3, Week 5 - Lower Body",
  "notes": "Date calculated from Week 5, Day 3"
}
```

**Validation Checks:**
- ✅ `workout_date` is either null OR valid YYYY-MM-DD
- ✅ Never "Day 3" or "Week 5" as date
- ✅ Title preserved

---

### 🎯 Test Case 4: Superset Nightmare

**Input:**
```
A1) Bench Press 3x10 @ 60kg
A2) Pull Ups 3xMax
A3) Rest 90 seconds
```

**Expected Output:**
```json
{
  "block_label": "A",
  "items": [
    {
      "item_sequence": 1,
      "exercise_name": "Bench Press",
      "equipment_key": "barbell",
      "prescription": {
        "target_sets": 3,
        "target_reps": 10,
        "target_weight": { "value": 60, "unit": "kg" }
      }
    },
    {
      "item_sequence": 2,
      "exercise_name": "Pull Up",
      "equipment_key": "bodyweight",
      "prescription": {
        "target_sets": 3,
        "target_reps_min": 1,
        "target_reps_max": 999,
        "notes": "Max reps"
      }
    }
  ],
  "prescription": {
    "target_rest_sec": 90
  }
}
```

**Validation Checks:**
- ✅ 2 distinct items (A1, A2)
- ✅ A3 becomes block-level rest prescription
- ✅ Sequence preserved (1, 2)
- ✅ "Max" handled as range or note

---

### 🎯 Test Case 5: Ghost Athlete

**Input:**
```
Block A (METCON):
AMRAP 12:00
- 10 Burpees
- 15 KB Swings @ 24kg
```

**Expected Output:**
```json
{
  "workout_date": "2026-01-10",
  "athlete_id": null,
  "title": "AMRAP Workout",
  "sessions": [...]
}
```

**Validation Checks:**
- ✅ `athlete_id` is EXACTLY `null`
- ❌ NO generated UUID like "00000000-0000-0000-0000-000000000000"
- ❌ NO string "unknown" or "anonymous"

---

### 🎯 Test Case 6: RPE Decimal

**Input:**
```
Deadlift
Single @ RPE 7.5-8.0
```

**Expected Output:**
```json
{
  "exercise_name": "Deadlift",
  "prescription": {
    "target_reps": 1,
    "target_rpe_min": 7.5,
    "target_rpe_max": 8.0
  }
}
```

**Validation Checks:**
- ✅ RPE values are `float` (7.5, not "7.5")
- ✅ Range handled correctly
- ✅ "Single" = 1 rep

---

### 🎯 Test Case 7: Typos & Aliases

**Input:**
```
Bak Squot 5x5 @ 100kg
Benchh Pres 5x5 @ 80kg
Dedlift 3x5 @ 120kg
```

**Expected Output:**
```json
{
  "items": [
    { "exercise_name": "Back Squat" },
    { "exercise_name": "Bench Press" },
    { "exercise_name": "Deadlift" }
  ]
}
```

**Validation Checks:**
- ✅ Auto-correction via `lib_exercise_aliases`
- ✅ Canonical names used
- ❌ NO "Bak Squot" in output

---

### 🎯 Test Case 8: Performance Only

**Input:**
```
Just did a 5k run in 20:15
Felt pretty good
```

**Expected Output:**
```json
{
  "exercise_name": "Run",
  "prescription": null,
  "performed": {
    "actual_distance_m": 5000,
    "actual_duration_sec": 1215,
    "notes": "Felt pretty good"
  }
}
```

**Validation Checks:**
- ✅ `prescription` is `null` (not empty object)
- ✅ `performed` has data
- ✅ No copying prescription → performed

---

### 🎯 Test Case 9: Metric Confusion

**Input:**
```
Deadlift 5x5 @ 300 lbs
```

**Expected Output (Option A - Preserve Units):**
```json
{
  "exercise_name": "Deadlift",
  "prescription": {
    "target_sets": 5,
    "target_reps": 5,
    "target_weight": {
      "value": 300,
      "unit": "lbs"
    }
  }
}
```

**Expected Output (Option B - Convert to kg):**
```json
{
  "exercise_name": "Deadlift",
  "prescription": {
    "target_sets": 5,
    "target_reps": 5,
    "target_weight": {
      "value": 136.1,
      "unit": "kg"
    },
    "notes": "Original: 300 lbs"
  }
}
```

**Validation Checks:**
- ✅ Unit explicitly stated ("lbs" or "kg")
- ✅ Numeric value (not "300 lbs" string)
- ⚠️ Either preserved OR converted with note

---

### 🎯 Test Case 10: Empty Shell

**Input:**
```
Rest Day
Active recovery walk - 30 minutes
Mobility work - 15 minutes
```

**Expected Output:**
```json
{
  "workout_date": "2026-01-10",
  "athlete_id": null,
  "title": "Rest Day",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "blocks": [
        {
          "block_code": "RECOVERY",
          "block_label": null,
          "prescription": {
            "description": "Active recovery walk - 30 minutes, Mobility work - 15 minutes"
          },
          "performed": null,
          "items": []
        }
      ]
    }
  ]
}
```

**Validation Checks:**
- ✅ Valid JSON (not null/empty)
- ✅ Empty `items` array (not crash)
- ✅ `RECOVERY` block type
- ✅ Descriptive text captured

---

## Execution Workflow

### Step 1: Parse Each Scenario

For each of the 10 test cases:

```bash
# Extract scenario from stress_test_10.txt
grep -A 10 "Test Case N:" data/stress_test_10.txt

# Parse using AI agent
<AI_PARSING_COMMAND>

# Save output to:
data/stress_test_results/test_case_N.json
```

### Step 2: Validate Each Output

Run validation script:

```python
python3 scripts/validate_golden_sets.py --file data/stress_test_results/test_case_N.json
```

### Step 3: DB Commit Test

Test if database will accept the structure:

```sql
SELECT zamm.validate_parsed_workout(
  pg_read_file('/path/to/test_case_N.json')::jsonb
);
```

### Step 4: Document Results

Update this table:

| Test Case | Parsed | Valid JSON | Type Safe | DB Ready | Notes |
|-----------|--------|------------|-----------|----------|-------|
| 1. Hebrew-English | ⏳ | ⏳ | ⏳ | ⏳ | |
| 2. Complex Range | ⏳ | ⏳ | ⏳ | ⏳ | |
| 3. Implicit Date | ⏳ | ⏳ | ⏳ | ⏳ | |
| 4. Superset | ⏳ | ⏳ | ⏳ | ⏳ | |
| 5. Ghost Athlete | ⏳ | ⏳ | ⏳ | ⏳ | |
| 6. RPE Decimal | ⏳ | ⏳ | ⏳ | ⏳ | |
| 7. Typos | ⏳ | ⏳ | ⏳ | ⏳ | |
| 8. Performance Only | ⏳ | ⏳ | ⏳ | ⏳ | |
| 9. Metric Confusion | ⏳ | ⏳ | ⏳ | ⏳ | |
| 10. Empty Shell | ⏳ | ⏳ | ⏳ | ⏳ | |

---

## Success Criteria

### Per Test Case

- ✅ Generates valid JSON
- ✅ Passes all type safety checks
- ✅ Follows CANONICAL_JSON_SCHEMA.md
- ✅ DB validation passes
- ✅ No data loss from original text

### Overall

- **Target:** 9/10 cases pass (90%)
- **Production Ready:** 10/10 cases pass (100%)

---

## Common Pitfalls to Avoid

### ❌ DON'T:
1. Hallucinate athlete_id when not provided
2. Convert ranges to strings ("8-12")
3. Mix prescription and performance
4. Copy prescription into performed when not stated
5. Use non-standard block codes
6. Skip equipment_key field (v3.0)

### ✅ DO:
1. Set athlete_id to `null` if unknown
2. Use min/max for ranges
3. Separate prescription from performed cleanly
4. Set performed to `null` if no execution data
5. Use only the 17 standard block codes
6. Include equipment_key for all exercises

---

## Quick Validation Commands

### Check Type Safety
```bash
jq '[.. | .target_reps?, .actual_reps? | select(type == "string")] | length' result.json
# Should return: 0
```

### Check Ranges
```bash
jq '[.. | select(has("target_reps") and (.target_reps | type) == "string")] | length' result.json
# Should return: 0
```

### Check Block Codes
```bash
jq '[.. | .block_code? | select(. != null)] | unique' result.json
# Should return only: WU, STR, METCON, etc. (17 codes)
```

### Check Equipment Keys
```bash
jq '[.. | .items[]? | select(.exercise_name != null and .equipment_key == null)] | length' result.json
# Should return: 0 (or low number for legacy)
```

---

**Ready to execute?** Start with Test Case 5 (easiest) and work up to Test Case 4 (hardest).
