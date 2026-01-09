# Block Type System - Test Summary

## ✅ Successfully Deployed

Migration: `20260104140000_block_type_system.sql`

### What Was Created

#### 1. **block_type_catalog** Table
Master catalog of 17 standardized block types:

**PREPARATION (3 blocks)**
- WU (Warm-Up)
- ACT (Activation)  
- MOB (Mobility)

**STRENGTH (3 blocks)**
- STR (Strength)
- ACC (Accessory)
- HYP (Hypertrophy)

**POWER (2 blocks)**
- PWR (Power)
- WL (Weightlifting)

**SKILL (2 blocks)**
- SKILL (Skill)
- GYM (Gymnastics)

**CONDITIONING (4 blocks)**
- METCON (Metcon)
- INTV (Intervals)
- SS (Steady State)
- HYROX (Hyrox)

**RECOVERY (3 blocks)**
- CD (Cool-Down)
- STRETCH (Stretching)
- BREATH (Breathwork)

#### 2. **block_code_aliases** Table
60+ aliases supporting:
- English variations (warmup, warm-up, strength, str)
- Abbreviations (wu, str, acc, hyp, pwr, wl)
- Hebrew (חימום, כוח, עזר, קונדישן, etc.)

#### 3. **workout_blocks** Enhancement
Added `ui_hint` column for frontend rendering instructions

#### 4. **normalize_block_code()** Function
AI tool for block code normalization with alias matching

#### 5. **Helper Views**
- `v_block_types_reference` - Complete catalog with aliases
- `v_block_types_by_category` - Grouped for UI menus

---

## 🎨 UI Hints Available

14 distinct rendering hints:

| UI Hint | Best For |
|---------|----------|
| `item_list_with_done` | Warmups, cool-downs |
| `item_list_with_side_hold` | Mobility work |
| `exercise_table_with_sets` | Strength training |
| `exercise_table_compact` | Accessory work |
| `exercise_table_short_sets` | Power/explosive |
| `exercise_table_with_attempts` | Olympic lifts |
| `skill_card_with_quality` | Skill practice |
| `skill_card_with_progression` | Gymnastics |
| `score_card_central` | Metcons |
| `splits_table` | Intervals |
| `summary_card_pace` | Steady state cardio |
| `score_card_with_splits` | Hyrox/multi-stage |
| `stretch_list` | Stretching |
| `breath_protocol` | Breathwork |

---

## 🤖 AI Integration

### Function: normalize_block_code(input)

**Purpose:** Convert any block name/alias to standardized block_code

**Examples:**
```sql
-- English
SELECT * FROM zamm.normalize_block_code('strength');
→ Returns: STR (via alias match)

-- Hebrew
SELECT * FROM zamm.normalize_block_code('כוח');
→ Returns: STR (Hebrew alias)

-- Common abbreviation
SELECT * FROM zamm.normalize_block_code('wod');
→ Returns: METCON (via alias)

-- Direct code
SELECT * FROM zamm.normalize_block_code('METCON');
→ Returns: METCON (exact match)
```

**Returns:**
- `block_code` - Standardized code (STR, METCON, etc.)
- `block_type` - Legacy type field
- `category` - High-level grouping
- `result_model` - How to track results
- `ui_hint` - How to render
- `display_name` - User-friendly name
- `matched_via` - How match was found (exact/alias/partial)

---

## 📊 Query Examples

### Get All Blocks by Category
```sql
SELECT * FROM zamm.v_block_types_by_category;
```

### Get Strength Blocks
```sql
SELECT * FROM zamm.block_type_catalog
WHERE category = 'strength';
```

### Find Conditioning Workouts
```sql
SELECT 
  w.workout_date,
  wb.block_code,
  wb.name,
  wbr.total_time_sec
FROM zamm.workout_blocks wb
JOIN zamm.workout_sessions ws ON wb.session_id = ws.session_id
JOIN zamm.workouts w ON ws.workout_id = w.workout_id
LEFT JOIN zamm.workout_block_results wbr ON wb.block_id = wbr.block_id
WHERE wb.block_code IN ('METCON', 'INTV', 'SS', 'HYROX')
ORDER BY w.workout_date DESC;
```

---

## 🎯 Usage in Parser

### Before (Old System)
```json
{
  "block_code": "A",
  "block_type": "strength"
}
```

### After (New System)
```json
{
  "block_code": "STR",
  "block_type": "strength",
  "category": "strength",
  "result_model": "tracked_sets",
  "ui_hint": "exercise_table_with_sets"
}
```

### Workflow
1. AI Agent identifies block from text ("Today we did strength work...")
2. Calls `normalize_block_code('strength')`
3. Gets back: `STR` + full metadata
4. Stores in `workout_blocks` with all fields populated
5. Frontend renders using `ui_hint`

---

## 📝 Common Workout Patterns

### Pattern 1: Strength Focus
```
WU (5min)   → item_list_with_done
STR (25min) → exercise_table_with_sets
ACC (15min) → exercise_table_compact
STRETCH     → stretch_list
```

### Pattern 2: Metcon Focus
```
WU (10min)    → item_list_with_done
SKILL (15min) → skill_card_with_quality
METCON (20min) → score_card_central
CD (5min)     → item_list_with_done
```

### Pattern 3: Olympic Lifting
```
MOB (10min) → item_list_with_side_hold
WL (30min)  → exercise_table_with_attempts
METCON (15min) → score_card_central
STRETCH    → stretch_list
```

---

## ✅ Validation

All block codes and UI hints are validated via constraints:

```sql
-- Valid block codes (from catalog)
WU, ACT, MOB, STR, ACC, HYP, PWR, WL, SKILL, GYM, 
METCON, INTV, SS, HYROX, CD, STRETCH, BREATH

-- Valid UI hints
'item_list_with_done', 'item_list_with_side_hold',
'exercise_table_with_sets', 'exercise_table_compact',
'exercise_table_short_sets', 'exercise_table_with_attempts',
'skill_card_with_quality', 'skill_card_with_progression',
'score_card_central', 'splits_table', 'summary_card_pace',
'score_card_with_splits', 'stretch_list', 'breath_protocol'
```

---

## 🚀 Next Steps

1. **Update AI Agent** - Add normalize_block_code() as Tool #7
2. **Update AI Prompts** - Include block_code + ui_hint in output schema
3. **Frontend Implementation** - Build UI components based on ui_hints
4. **Test with Real Data** - Parse actual workouts using new system

---

**Status:** ✅ Deployed to Supabase  
**Migration File:** 20260104140000_block_type_system.sql  
**Documentation:** BLOCK_TYPES_REFERENCE.md  
**Database Score:** 97/100 (unchanged - infrastructure enhancement)
