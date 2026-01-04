# Block Types & Result Models Reference

## Overview

Each workout block has **four key attributes** that define its structure, tracking, and UI presentation:

| Field | Description | Example |
|-------|-------------|---------|
| **block_code** | Standardized block identifier | "STR", "METCON", "WU", "ACC" |
| **block_type** | Legacy type field | "strength", "conditioning", "prep" |
| **result_model** | How results are tracked/stored | "tracked_sets", "scored_effort_metcon", "completion" |
| **ui_hint** | How to render in the interface | "exercise_table_with_sets", "score_card_central" |

---

## 🎯 Complete Block Type Catalog

### PREPARATION (Warm-up & Mobility)

| Block Code | Display Name | Result Model | UI Hint | Description |
|------------|--------------|--------------|---------|-------------|
| **WU** | Warm-Up | \`completion\` | \`item_list_with_done\` | General warm-up and mobility prep 🔥 |
| **ACT** | Activation | \`completion\` | \`item_list_with_done\` | Muscle activation drills ⚡ |
| **MOB** | Mobility | \`completion\` | \`item_list_with_side_hold\` | Mobility work and stretching 🧘 |

**Common Aliases:** warmup, warm-up, activation, mobility, חימום, הפעלה, ניידות

**Result Storage:** Simple completion tracking

---

### STRENGTH (Force Production)

| Block Code | Display Name | Result Model | UI Hint | Description |
|------------|--------------|--------------|---------|-------------|
| **STR** | Strength | \`tracked_sets\` | \`exercise_table_with_sets\` | Heavy compound lifts 💪 |
| **ACC** | Accessory | \`tracked_sets\` | \`exercise_table_compact\` | Supplemental work 🔧 |
| **HYP** | Hypertrophy | \`tracked_sets\` | \`exercise_table_with_sets\` | Muscle building 💎 |

**Common Aliases:** strength, str, accessory, acc, hypertrophy, hyp, כוח, עזר

**Result Storage:** Full set tracking (reps, load, RPE, RIR) in \`item_set_results\`

---

### POWER (Explosive)

| Block Code | Display Name | Result Model | UI Hint | Description |
|------------|--------------|--------------|---------|-------------|
| **PWR** | Power | \`tracked_sets\` | \`exercise_table_short_sets\` | Explosive movements ⚡ |
| **WL** | Weightlifting | \`tracked_sets\` | \`exercise_table_with_attempts\` | Olympic lifts 🏋️ |

**Common Aliases:** power, pwr, weightlifting, wl, olympic, oly, עוצמה

**Result Storage:** Set tracking with quality/attempts

---

### SKILL (Technical)

| Block Code | Display Name | Result Model | UI Hint | Description |
|------------|--------------|--------------|---------|-------------|
| **SKILL** | Skill | \`practice_quality\` | \`skill_card_with_quality\` | Technical development 🎯 |
| **GYM** | Gymnastics | \`practice_quality\` | \`skill_card_with_progression\` | Bodyweight skills 🤸 |

**Common Aliases:** skill, technique, gymnastics, gym, bodyweight, מיומנות

**Result Storage:** Quality scores, progression notes

---

### CONDITIONING (Metabolic)

| Block Code | Display Name | Result Model | UI Hint | Description |
|------------|--------------|--------------|---------|-------------|
| **METCON** | Metcon | \`scored_effort_metcon\` | \`score_card_central\` | Mixed-modal (AMRAP/For Time) 🔥 |
| **INTV** | Intervals | \`scored_effort_intervals\` | \`splits_table\` | HIIT training ⏱️ |
| **SS** | Steady State | \`scored_effort_steady_state\` | \`summary_card_pace\` | Aerobic work 🏃 |
| **HYROX** | Hyrox | \`scored_effort_hyrox\` | \`score_card_with_splits\` | Hyrox workouts 🏆 |

**Common Aliases:** metcon, conditioning, wod, intervals, hiit, cardio, קונדישן

**Result Storage:** Time/rounds/distance with splits

---

### RECOVERY (Cool-down)

| Block Code | Display Name | Result Model | UI Hint | Description |
|------------|--------------|--------------|---------|-------------|
| **CD** | Cool-Down | \`completion\` | \`item_list_with_done\` | Post-workout recovery ❄️ |
| **STRETCH** | Stretching | \`completion\` | \`stretch_list\` | Static stretching 🧘 |
| **BREATH** | Breathwork | \`completion\` | \`breath_protocol\` | Breathing exercises 🌬️ |

**Common Aliases:** cooldown, stretching, breathing, קירור, מתיחות

**Result Storage:** Simple completion

---

## 🎨 UI Hints Explained

| UI Hint | Visual Layout | Best For |
|---------|---------------|----------|
| \`item_list_with_done\` | Checklist with ☑️ | Warmups, cool-downs |
| \`item_list_with_side_hold\` | Left/Right bilateral tracking | Mobility holds |
| \`exercise_table_with_sets\` | Full table (Set, Reps, Load, RPE, RIR) | Strength training |
| \`exercise_table_compact\` | Simplified table | Accessory work |
| \`exercise_table_short_sets\` | 1-3 rep focus | Power/explosive |
| \`exercise_table_with_attempts\` | Attempt log with success/miss | Olympic lifts |
| \`skill_card_with_quality\` | Quality score + notes | Skill practice |
| \`skill_card_with_progression\` | Progression tracker | Gymnastics |
| \`score_card_central\` | Large central score display | Metcons |
| \`splits_table\` | Round-by-round data | Intervals |
| \`summary_card_pace\` | Distance, time, pace | Steady state cardio |
| \`score_card_with_splits\` | Overall + segment splits | Hyrox/multi-stage |
| \`stretch_list\` | Stretches with durations | Stretching protocols |
| \`breath_protocol\` | Protocol with timing | Breathwork |

---

## 🗄️ Database Schema

### Block Type Catalog
\`\`\`sql
CREATE TABLE zamm.block_type_catalog (
    block_code TEXT PRIMARY KEY,       -- "STR", "METCON", "WU"
    block_type TEXT NOT NULL,          -- "strength", "conditioning", "prep"
    category TEXT NOT NULL,            -- High-level grouping
    result_model TEXT NOT NULL,        -- How results are tracked
    ui_hint TEXT NOT NULL,             -- How to render in UI
    display_name TEXT NOT NULL,        -- "Strength", "Metcon"
    description TEXT,
    icon TEXT,                         -- Emoji icon
    sort_order INTEGER,
    is_active BOOLEAN DEFAULT true
);
\`\`\`

### Workout Blocks (Updated)
\`\`\`sql
ALTER TABLE zamm.workout_blocks
ADD COLUMN ui_hint TEXT;

-- Now includes standardized block_code + ui_hint
-- block_code: "STR", "METCON", "WU", etc.
-- ui_hint: Rendering instruction for frontend
\`\`\`

---

## 🤖 AI Agent Integration

### New Tool: \`normalize_block_code()\`

\`\`\`sql
SELECT * FROM zamm.normalize_block_code('strength');
-- Returns:
-- block_code: STR
-- block_type: strength
-- category: strength
-- result_model: tracked_sets
-- ui_hint: exercise_table_with_sets
-- display_name: Strength
-- matched_via: alias

SELECT * FROM zamm.normalize_block_code('WOD');
-- Returns: METCON (matched via alias)

SELECT * FROM zamm.normalize_block_code('כוח');
-- Returns: STR (Hebrew alias matched)
\`\`\`

### Usage in Parser
\`\`\`json
{
  "block_code": "STR",
  "block_type": "strength",
  "ui_hint": "exercise_table_with_sets",
  "result_model": "tracked_sets",
  "prescription": {
    "steps": [...]
  }
}
\`\`\`

---

## 📊 Quick Reference Table

| Block Code | Category | Primary Use | Result Tracking | UI Display |
|------------|----------|-------------|-----------------|------------|
| WU | prep | Warm-up prep | Completion only | Checklist |
| ACT | prep | Activation | Completion only | Checklist |
| MOB | prep | Mobility work | Completion + holds | Bilateral tracker |
| STR | strength | Heavy lifts | Full set details | Full table |
| ACC | strength | Accessory work | Set details | Compact table |
| HYP | strength | Muscle building | Full set details | Full table |
| PWR | power | Explosive work | Sets + quality | Short sets table |
| WL | power | Olympic lifts | Attempts + success | Attempts log |
| SKILL | skill | Technical practice | Quality scores | Skill card |
| GYM | skill | Bodyweight skills | Progression | Progression card |
| METCON | conditioning | AMRAP/For Time | Time/rounds | Central score |
| INTV | conditioning | Intervals | Split times | Splits table |
| SS | conditioning | Steady state | Pace/distance | Summary card |
| HYROX | conditioning | Hyrox workout | Segment splits | Split scores |
| CD | recovery | Cool-down | Completion only | Checklist |
| STRETCH | recovery | Stretching | Completion + holds | Stretch list |
| BREATH | recovery | Breathwork | Completion + rounds | Protocol card |

---

## 📝 Example Usage

### Typical Workout Structure

\`\`\`
WU (5min)  - Warm-up checklist
MOB (10min) - Hip mobility + shoulder prep
STR (25min) - Back Squat 5x5 @ 80%
ACC (15min) - 3x12 RDLs + 3x12 Face Pulls
METCON (15min) - AMRAP 12: 10 T2B, 15 Wall Balls
STRETCH (5min) - Lower body static stretch
\`\`\`

### Common Patterns

| Pattern | Block Sequence | Total Time |
|---------|----------------|------------|
| Strength Focus | WU → STR → ACC → STRETCH | 50-60min |
| Metcon Focus | WU → SKILL → METCON → CD | 40-50min |
| Hybrid | WU → STR → METCON → STRETCH | 60-75min |
| Skill Development | MOB → SKILL → GYM → CD | 45-60min |
| Competition Prep | WU → WL → METCON → STRETCH | 60min |

---

## 🔍 Querying by Block Code

\`\`\`sql
-- Get all strength blocks
SELECT * FROM zamm.workout_blocks
WHERE block_code IN ('STR', 'ACC', 'HYP');

-- Get conditioning blocks with scores
SELECT 
  wb.block_code,
  wb.name,
  wbr.rounds_completed,
  wbr.total_time_sec
FROM zamm.workout_blocks wb
JOIN zamm.workout_block_results wbr ON wb.block_id = wbr.block_id
WHERE wb.block_code IN ('METCON', 'INTV', 'SS', 'HYROX');

-- Get blocks by category
SELECT * FROM zamm.block_type_catalog
WHERE category = 'strength';
\`\`\`

---

## 🎯 UI Implementation Guide

### Frontend Block Rendering

\`\`\`typescript
function renderBlock(block: WorkoutBlock) {
  switch (block.ui_hint) {
    case 'exercise_table_with_sets':
      return <ExerciseTable showRPE showRIR />;
    case 'exercise_table_compact':
      return <ExerciseTable compact />;
    case 'score_card_central':
      return <ScoreCard large centered />;
    case 'splits_table':
      return <SplitsTable />;
    case 'item_list_with_done':
      return <ChecklistView />;
    // ... etc
  }
}
\`\`\`

### Category-Based Navigation

\`\`\`sql
-- Get blocks grouped by category for UI menu
SELECT * FROM zamm.v_block_types_by_category;

-- Returns:
-- category: preparation
--   blocks: [{code: WU, name: Warm-Up}, {code: ACT, ...}, ...]
-- category: strength
--   blocks: [{code: STR, name: Strength}, ...]
\`\`\`

---

**Last Updated:** January 4, 2026  
**Migration:** 20260104140000_block_type_system.sql  
**Database Score:** 97/100  

**Related Docs:** 
- [DB_ARCHITECTURE_REVIEW.md](./DB_ARCHITECTURE_REVIEW.md)
- [PRIORITY1_COMPLETE.md](./PRIORITY1_COMPLETE.md)
- [AI_PROMPTS.md](./AI_PROMPTS.md)
