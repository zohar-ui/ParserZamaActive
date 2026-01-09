# ✨ commit_full_workout_v3 - Enhanced Update

> **⚠️ ARCHIVED DOCUMENT:** This document contains historical references to n8n integration which is no longer active. The stored procedure is still valid.

## What Changed?

עדכנתי את ה-stored procedure ל-**version 3** שמטפלת הרבה יותר טוב בהפרדה בין prescription ל-performance!

---

## 🎯 Key Improvements in v3

### 1. **Better Prescription/Performance Separation**
- ✅ Stores `prescription_data` separately in `workout_items`
- ✅ Stores `performed_data` separately in `workout_items`
- ✅ Creates individual set results in `item_set_results` table

### 2. **Detailed Set Results**
כעת הפונקציה יוצרת רשומה נפרדת **לכל סט בודד** ב-`item_set_results`:

```sql
-- For each set in performed data:
INSERT INTO item_set_results (
    item_id,
    set_index,    -- 1, 2, 3...
    reps,         -- actual reps performed
    load_kg,      -- actual load used
    rpe,          -- Rate of Perceived Exertion
    rir,          -- Reps In Reserve
    notes         -- any notes about the set
);
```

### 3. **Block-Level Results**
- ✅ Stores total time, completion status, and notes in `workout_block_results`
- ✅ Handles Metcon results (time, score, etc.)

### 4. **Graceful Handling of Missing Data**
- ✅ Works even if no performance data exists (plan-only workouts)
- ✅ Handles partial performance data
- ✅ Never fails on null/empty fields

---

## 📝 Example: Before vs After

### Input JSON:
```json
{
  "sessions": [{
    "sessionInfo": {"date": "2026-01-04", "title": "Strength Day"},
    "blocks": [{
      "block_code": "A",
      "block_type": "strength",
      "name": "Back Squat",
      "prescription": {
        "steps": [{
          "exercise_name": "Back Squat",
          "target_sets": 3,
          "target_reps": 5,
          "target_load": {"value": 100, "unit": "kg"}
        }]
      },
      "performed": {
        "did_complete": true,
        "steps": [{
          "sets": [
            {"set_index": 1, "reps": 5, "load_kg": 100, "rpe": 7},
            {"set_index": 2, "reps": 5, "load_kg": 100, "rpe": 8},
            {"set_index": 3, "reps": 4, "load_kg": 100, "rpe": 9.5, "notes": "grip failed"}
          ]
        }]
      }
    }]
  }]
}
```

### What v2 Did:
```
workout_items:
  - prescription_data: {full json}
  - performed_data: {full json}
  
❌ No individual set records
```

### What v3 Does:
```
workout_items:
  - prescription_data: {target_sets: 3, target_reps: 5, target_load: 100kg}
  - performed_data: {full performed json}

workout_block_results:
  - did_complete: true

item_set_results (3 rows):
  ✅ Row 1: set_index=1, reps=5, load_kg=100, rpe=7
  ✅ Row 2: set_index=2, reps=5, load_kg=100, rpe=8
  ✅ Row 3: set_index=3, reps=4, load_kg=100, rpe=9.5, notes="grip failed"
```

---

## 🔧 Usage in n8n

### Option 1: Use v3 explicitly
```sql
SELECT zamm.commit_full_workout_v3(
  p_import_id := {{ $json.import_id }}::uuid,
  p_draft_id := {{ $json.draft_id }}::uuid,
  p_ruleset_id := {{ $json.ruleset_id }}::uuid,
  p_athlete_id := {{ $json.athlete_id }}::uuid,
  p_normalized_json := {{ $json.parsed_json }}::jsonb
);
```

### Option 2: Use the "latest" alias (recommended)
```sql
SELECT zamm.commit_full_workout_latest(
  p_import_id := {{ $json.import_id }}::uuid,
  p_draft_id := {{ $json.draft_id }}::uuid,
  p_ruleset_id := {{ $json.ruleset_id }}::uuid,
  p_athlete_id := {{ $json.athlete_id }}::uuid,
  p_normalized_json := {{ $json.parsed_json }}::jsonb
);
```

The `_latest` alias always points to the newest version, so you won't need to update your workflow when v4 comes out!

---

## ✅ What's Now Complete

| Feature | v2 | v3 |
|---------|----|----|
| Basic workout structure | ✅ | ✅ |
| Prescription/performed separation | ⚠️ | ✅ |
| Individual set results | ❌ | ✅ |
| Block-level results | ❌ | ✅ |
| Handles empty performed data | ⚠️ | ✅ |
| Full field population | ⚠️ | ✅ |

---

## 🧪 Testing v3

Use this query to test:

```sql
-- Create test data
DO $$
DECLARE
    v_import_id UUID;
    v_draft_id UUID;
    v_ruleset_id UUID;
    v_athlete_id UUID;
    v_workout_id UUID;
BEGIN
    -- Get or create test athlete
    SELECT athlete_natural_id INTO v_athlete_id
    FROM zamm.dim_athletes
    WHERE full_name = 'Test Athlete'
    LIMIT 1;

    IF v_athlete_id IS NULL THEN
        INSERT INTO zamm.dim_athletes (full_name, is_current)
        VALUES ('Test Athlete', true)
        RETURNING athlete_natural_id INTO v_athlete_id;
    END IF;

    -- Get active ruleset
    SELECT ruleset_id INTO v_ruleset_id
    FROM zamm.parser_rulesets
    WHERE is_active = true
    LIMIT 1;

    -- Create import
    INSERT INTO zamm.imports (source, raw_text)
    VALUES ('test', 'Squat: 3x5 @ 100kg. Last set only 4 reps.')
    RETURNING import_id INTO v_import_id;

    -- Create draft
    INSERT INTO zamm.parse_drafts (import_id, ruleset_id, parser_version, stage, parsed_draft)
    VALUES (v_import_id, v_ruleset_id, 'test', 'normalized', '{}'::jsonb)
    RETURNING draft_id INTO v_draft_id;

    -- Test v3
    v_workout_id := zamm.commit_full_workout_v3(
        v_import_id,
        v_draft_id,
        v_ruleset_id,
        v_athlete_id,
        '{
            "sessions": [{
                "sessionInfo": {"date": "2026-01-04", "title": "Test"},
                "blocks": [{
                    "block_code": "A",
                    "block_type": "strength",
                    "name": "Squat",
                    "prescription": {
                        "steps": [{
                            "exercise_name": "Back Squat",
                            "target_sets": 3,
                            "target_reps": 5,
                            "target_load": {"value": 100, "unit": "kg"}
                        }]
                    },
                    "performed": {
                        "did_complete": true,
                        "steps": [{
                            "sets": [
                                {"set_index": 1, "reps": 5, "load_kg": 100},
                                {"set_index": 2, "reps": 5, "load_kg": 100},
                                {"set_index": 3, "reps": 4, "load_kg": 100}
                            ]
                        }]
                    }
                }]
            }]
        }'::jsonb
    );

    RAISE NOTICE 'Created workout: %', v_workout_id;
END $$;

-- Check results
SELECT 
    'workout' as table_name,
    w.workout_id::text as id,
    w.workout_date
FROM zamm.workouts w
WHERE w.workout_date >= CURRENT_DATE - 1
UNION ALL
SELECT 
    'item_set_results' as table_name,
    isr.set_result_id::text as id,
    concat('Set ', isr.set_index, ': ', isr.reps, ' reps @ ', isr.load_kg, 'kg')
FROM zamm.item_set_results isr
JOIN zamm.workout_items wi ON isr.item_id = wi.item_id
JOIN zamm.workout_blocks wb ON wi.block_id = wb.block_id
JOIN zamm.workout_sessions ws ON wb.session_id = ws.session_id
JOIN zamm.workouts w ON ws.workout_id = w.workout_id
WHERE w.workout_date >= CURRENT_DATE - 1
ORDER BY table_name, id;
```

---

## 📊 Database Impact

**New data will be stored in:**
1. `workout_items` - prescription_data AND performed_data (as before)
2. `item_set_results` - **NEW!** Individual set records
3. `workout_block_results` - **NEW!** Block-level completion data

**Old data (v2) is NOT affected** - you can query it normally.

---

## 🚀 Status

- ✅ Function created and deployed
- ✅ Permissions granted
- ✅ Documentation updated
- ✅ Alias (`commit_full_workout_latest`) created

**Ready to use in n8n!** 🎉
