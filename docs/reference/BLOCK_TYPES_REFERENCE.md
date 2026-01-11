---
version: 2.2.0
last_updated: 2026-01-11
status: stable - table names verified against live database
related_migrations: [20260104140000_block_type_system]
breaking_changes: v2.2.0 - Updated all table names to match actual database schema
verification_required: Always verify table names with inspect_db.sh before use
verification_date: 2026-01-11
verification_source: Remote Supabase database (dtzcamerxuonoeujrgsu)
---

## ⚠️ CRITICAL: Verify Schema Before Use

**This documentation may contain outdated table names.**

Before using any SQL examples, ALWAYS verify table names:
```bash
./scripts/utils/inspect_db.sh <table_name>
```

Common issues:
- Documentation may reference old table names
- Column names may have changed
- Migrations may not have been applied

**See `.claude/CLAUDE.md` for strict verification protocols.**

# 📚 Block Types & Result Models Reference

Comprehensive reference for workout block classification, result tracking, and UI rendering in ParserZamaActive.

---

## 📑 Table of Contents

- [Overview](#overview)
- [Block Type Catalog](#block-type-catalog)
  - [🔥 PREPARATION](#preparation-warm-up--mobility)
  - [💪 STRENGTH](#strength-force-production)
  - [⚡ POWER](#power-explosive)
  - [🎯 SKILL](#skill-technical)
  - [🏃 CONDITIONING](#conditioning-metabolic)
  - [🧘 RECOVERY](#recovery-cool-down)
- [Decision Guide](#decision-guide)
- [Technical Reference](#technical-reference)
  - [Result Models](#result-models-explained)
  - [UI Hints](#ui-hints-explained)
  - [Database Schema](#database-schema)
- [Integration Guide](#integration-guide)
  - [normalize_block_code() Function](#normalize_block_code-function)
  - [Parser Usage](#parser-usage)
  - [SQL Query Examples](#sql-query-examples)
- [Frontend Implementation](#frontend-implementation)
- [Example Workouts](#example-workouts)
- [Troubleshooting](#troubleshooting)
- [Related Documents](#related-documents)

---

## Overview

Each workout block has **four key attributes** that define its structure, tracking, and UI presentation:

| Attribute | Purpose | Example Values |
|-----------|---------|----------------|
| **block_code** | Standardized identifier (PRIMARY) | `"STR"`, `"METCON"`, `"WU"` |
| **block_type** | Legacy type field for grouping | `"strength"`, `"conditioning"`, `"prep"` |
| **result_model** | How results are tracked/stored | `"tracked_sets"`, `"scored_effort_metcon"`, `"completion"` |
| **ui_hint** | How to render in the interface | `"exercise_table_with_sets"`, `"score_card_central"` |

### Workout Block Hierarchy

```
Workout Session
│
├── PREPARATION Phase (5-15min)
│   ├── WU (Warm-Up) → completion checklist
│   ├── ACT (Activation) → completion checklist
│   └── MOB (Mobility) → bilateral holds tracking
│
├── MAIN Phase (20-45min)
│   ├── STRENGTH (STR/ACC/HYP) → full set tracking (reps, load, RPE, RIR)
│   ├── POWER (PWR/WL) → set tracking with attempts/quality
│   ├── SKILL (SKILL/GYM) → quality scores and progression notes
│   └── CONDITIONING (METCON/INTV/SS/HYROX) → time/rounds/distance tracking
│
└── RECOVERY Phase (5-10min)
    ├── CD (Cool-Down) → completion checklist
    ├── STRETCH (Stretching) → hold durations
    └── BREATH (Breathwork) → protocol timing
```

---

## Block Type Catalog

### 🔥 PREPARATION (Warm-up & Mobility)

Prepares the body for main work through movement prep, activation, and mobility.

| Block Code | Display Name | Result Model | UI Hint | Description |
|------------|--------------|--------------|---------|-------------|
| **WU** | Warm-Up | `completion` | `item_list_with_done` | General warm-up and movement prep |
| **ACT** | Activation | `completion` | `item_list_with_done` | Targeted muscle activation drills |
| **MOB** | Mobility | `completion` | `item_list_with_side_hold` | Joint mobility and stretching |

**Common Aliases:** warmup, warm-up, activation, mobility, prep, חימום (Hebrew), הפעלה (Hebrew), ניידות (Hebrew)

**Result Storage:** Simple completion tracking - exercises marked as done with minimal detail

**Typical Duration:** 5-15 minutes

---

### 💪 STRENGTH (Force Production)

Develops maximal force through progressive loading of compound and accessory movements.

| Block Code | Display Name | Result Model | UI Hint | Description |
|------------|--------------|--------------|---------|-------------|
| **STR** | Strength | `tracked_sets` | `exercise_table_with_sets` | Heavy compound lifts (3-6 reps) |
| **ACC** | Accessory | `tracked_sets` | `exercise_table_compact` | Supplemental work (8-15 reps) |
| **HYP** | Hypertrophy | `tracked_sets` | `exercise_table_with_sets` | Muscle building (6-12 reps) |

**Common Aliases:** strength, str, accessory, acc, hypertrophy, hyp, volume, כוח (Hebrew), עזר (Hebrew)

**Result Storage:** Full set tracking in `zamm.item_set_results` - each set records reps, load_kg, RPE, RIR, notes

**Typical Duration:** 20-40 minutes

---

### ⚡ POWER (Explosive)

Develops rate of force development through explosive and Olympic lifting movements.

| Block Code | Display Name | Result Model | UI Hint | Description |
|------------|--------------|--------------|---------|-------------|
| **PWR** | Power | `tracked_sets` | `exercise_table_short_sets` | Explosive movements (1-5 reps) |
| **WL** | Weightlifting | `tracked_sets` | `exercise_table_with_attempts` | Olympic lifts (snatch, clean & jerk) |

**Common Aliases:** power, pwr, explosive, weightlifting, wl, olympic, oly, עוצמה (Hebrew)

**Result Storage:** Set tracking with emphasis on quality and attempt success rate

**Typical Duration:** 15-30 minutes

---

### 🎯 SKILL (Technical)

Develops technical proficiency and movement quality through focused practice.

| Block Code | Display Name | Result Model | UI Hint | Description |
|------------|--------------|--------------|---------|-------------|
| **SKILL** | Skill | `practice_quality` | `skill_card_with_quality` | Technical skill development |
| **GYM** | Gymnastics | `practice_quality` | `skill_card_with_progression` | Bodyweight skill practice |

**Common Aliases:** skill, technique, practice, gymnastics, gym, bodyweight, מיומנות (Hebrew)

**Result Storage:** Quality scores (1-10), progression milestones, and detailed practice notes

**Typical Duration:** 10-20 minutes

---

### 🏃 CONDITIONING (Metabolic)

Develops aerobic and anaerobic capacity through varied metabolic work.

| Block Code | Display Name | Result Model | UI Hint | Description |
|------------|--------------|--------------|---------|-------------|
| **METCON** | Metcon | `scored_effort_metcon` | `score_card_central` | Mixed-modal conditioning (AMRAP/For Time) |
| **INTV** | Intervals | `scored_effort_intervals` | `splits_table` | High-intensity interval training |
| **SS** | Steady State | `scored_effort_steady_state` | `summary_card_pace` | Sustained aerobic effort |
| **HYROX** | Hyrox | `scored_effort_hyrox` | `score_card_with_splits` | Hyrox race simulation |

**Common Aliases:** metcon, conditioning, wod, cardio, intervals, hiit, endurance, קונדישן (Hebrew)

**Result Storage:** Time, rounds/reps completed, distance, with optional split tracking in `zamm.workout_block_results`

**Typical Duration:** 10-30 minutes

---

### 🧘 RECOVERY (Cool-down)

Facilitates recovery through low-intensity movement, stretching, and breathwork.

| Block Code | Display Name | Result Model | UI Hint | Description |
|------------|--------------|--------------|---------|-------------|
| **CD** | Cool-Down | `completion` | `item_list_with_done` | Post-workout recovery movement |
| **STRETCH** | Stretching | `completion` | `stretch_list` | Static stretching protocols |
| **BREATH** | Breathwork | `completion` | `breath_protocol` | Breathing exercises and protocols |

**Common Aliases:** cooldown, cool-down, stretching, breathing, recovery, קירור (Hebrew), מתיחות (Hebrew)

**Result Storage:** Simple completion tracking with optional duration/round counts

**Typical Duration:** 5-10 minutes

---

## Decision Guide

### When to Use Which Block Type?

```
START: What is the training goal?
│
├── Build strength/muscle? → STR (heavy), ACC (volume), HYP (hypertrophy)
│
├── Develop power/explosiveness? → PWR (jumps, throws), WL (olympic lifts)
│
├── Improve technical skill? → SKILL (technique), GYM (bodyweight)
│
├── Increase conditioning?
│   ├── Mixed movements? → METCON (AMRAP, For Time)
│   ├── Repeatable efforts? → INTV (rounds with rest)
│   ├── Long duration? → SS (run, row, bike)
│   └── Race specific? → HYROX (8 station format)
│
├── Prepare for training? → WU (general), ACT (activation), MOB (mobility)
│
└── Recover from training? → CD (movement), STRETCH (static), BREATH (breathing)
```

### Training Goal to Block Type Mapping

| Training Goal | Primary Block Types | Common Pattern |
|--------------|-------------------|----------------|
| **Maximal Strength** | STR, ACC | WU → STR → ACC → STRETCH |
| **Muscle Building** | HYP, ACC | WU → HYP → HYP → ACC → CD |
| **Power Development** | PWR, WL, STR | WU → PWR → STR → STRETCH |
| **Work Capacity** | METCON, INTV | WU → SKILL → METCON → CD |
| **Aerobic Base** | SS, INTV | WU → SS → STRETCH |
| **Technical Skill** | SKILL, GYM | MOB → SKILL → GYM → CD |
| **Competition Prep** | WL, METCON | WU → WL → METCON → STRETCH |
| **Hybrid Training** | STR, METCON | WU → STR → ACC → METCON → CD |

---

## Technical Reference

### Result Models Explained

Each result model determines how performance data is captured and stored.

| Result Model | Storage Location | Data Captured | Best For |
|-------------|------------------|---------------|----------|
| `completion` | `workout_blocks.performed` | Boolean completion, optional notes | WU, ACT, MOB, CD, STRETCH, BREATH |
| `tracked_sets` | `zamm.workout_item_set_results` ✅ | Set-by-set: reps, load, RPE, RIR, notes | STR, ACC, HYP, PWR, WL |
| `practice_quality` | `workout_blocks.performed` | Quality score (1-10), progression notes | SKILL, GYM |
| `scored_effort_metcon` | `zamm.res_blocks` ✅ | Time, rounds, reps, score_text | METCON |
| `scored_effort_intervals` | `zamm.res_blocks` ✅ | Split times, round-by-round data | INTV |
| `scored_effort_steady_state` | `zamm.res_blocks` ✅ | Distance, time, pace, avg HR | SS |
| `scored_effort_hyrox` | `zamm.res_blocks` ✅ | Segment splits, overall time | HYROX |

### UI Hints Explained

UI hints guide frontend rendering without coupling to specific component implementations.

| UI Hint | Visual Layout | Used For Block Types |
|---------|---------------|---------------------|
| `item_list_with_done` | Simple checklist with checkboxes | WU, ACT, CD |
| `item_list_with_side_hold` | Left/Right bilateral tracking | MOB |
| `exercise_table_with_sets` | Full table: Set, Reps, Load, RPE, RIR | STR, HYP |
| `exercise_table_compact` | Simplified table: Set, Reps, Load only | ACC |
| `exercise_table_short_sets` | Focus on 1-3 rep sets | PWR |
| `exercise_table_with_attempts` | Attempt log with success/miss markers | WL |
| `skill_card_with_quality` | Quality score + freeform notes | SKILL |
| `skill_card_with_progression` | Progression tracker with milestones | GYM |
| `score_card_central` | Large central score display | METCON |
| `splits_table` | Round-by-round split data | INTV |
| `summary_card_pace` | Distance, time, pace summary | SS |
| `score_card_with_splits` | Overall score + segment splits | HYROX |
| `stretch_list` | Stretch names with hold durations | STRETCH |
| `breath_protocol` | Protocol name with round/timing | BREATH |

### Database Schema

#### Block Type Catalog

**✅ VERIFIED TABLE NAME:** `zamm.lib_block_types` (NOT `block_type_catalog`)

```sql
CREATE TABLE zamm.lib_block_types (
    block_code TEXT PRIMARY KEY,           -- "STR", "METCON", "WU", etc.
    block_type TEXT NOT NULL,              -- "strength", "conditioning", "prep"
    category TEXT NOT NULL,                -- High-level grouping
    result_model TEXT NOT NULL,            -- How results are tracked
    ui_hint TEXT NOT NULL,                 -- How to render in UI
    display_name TEXT NOT NULL,            -- User-friendly name
    description TEXT,
    sort_order INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Block Code Aliases

**✅ VERIFIED TABLE NAME:** `zamm.lib_block_aliases` (NOT `block_code_aliases`)

```sql
CREATE TABLE zamm.lib_block_aliases (
    alias_id UUID PRIMARY KEY,
    block_code TEXT REFERENCES zamm.lib_block_types(block_code),
    alias_text TEXT NOT NULL UNIQUE,
    language TEXT,                         -- "en", "he", etc.
    is_active BOOLEAN DEFAULT true
);
```

#### Workout Blocks

```sql
CREATE TABLE zamm.workout_blocks (
    block_id UUID PRIMARY KEY,
    session_id UUID NOT NULL,
    letter TEXT,                           -- "A", "B", "C" for block ordering
    block_code TEXT NOT NULL,              -- References block_type_catalog
    block_type TEXT NOT NULL,              -- Legacy field
    name TEXT NOT NULL,
    structure_model TEXT NOT NULL,
    presentation_structure TEXT NOT NULL,
    result_entry_model TEXT NOT NULL,
    prescription JSONB NOT NULL,           -- Planned workout
    performed JSONB DEFAULT '{}',          -- Actual performance
    ui_hint TEXT,                          -- Rendering hint (added 20260104140000)
    raw_block_text TEXT DEFAULT '',
    confidence_score NUMERIC(4,3),
    block_notes JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ
);
```

#### Block Results

**✅ VERIFIED TABLE NAME:** `zamm.res_blocks` (NOT `workout_block_results`)

```sql
-- For conditioning blocks (METCON, INTV, SS, HYROX)
CREATE TABLE zamm.res_blocks (
    block_result_id UUID PRIMARY KEY,
    block_id UUID NOT NULL,
    did_complete BOOLEAN,
    total_time_sec INTEGER,
    score_time_sec INTEGER,
    score_text TEXT,                      -- "15 rounds + 8 reps", "7:34", etc.
    distance_m INTEGER,
    avg_hr_bpm INTEGER,
    calories INTEGER,
    athlete_notes TEXT,
    created_at TIMESTAMPTZ
);
```

**✅ VERIFIED TABLE NAME:** `zamm.workout_item_set_results` (NOT `item_set_results`)

```sql
-- For strength/power blocks (STR, ACC, HYP, PWR, WL)
CREATE TABLE zamm.workout_item_set_results (
    set_result_id UUID PRIMARY KEY,
    block_id UUID NOT NULL,
    item_id UUID NOT NULL,
    set_index INTEGER NOT NULL,
    reps INTEGER,
    load_kg NUMERIC(10,2),
    rpe NUMERIC(4,2),                     -- Rate of Perceived Exertion (1-10)
    rir NUMERIC(4,2),                     -- Reps in Reserve (0-10+)
    notes TEXT,
    created_at TIMESTAMPTZ
);
```

---

## Integration Guide

### normalize_block_code() Function

The `normalize_block_code()` function maps any block type string (including aliases) to its canonical block code with full metadata.

#### Function Signature

```sql
CREATE FUNCTION zamm.normalize_block_code(p_input TEXT)
RETURNS TABLE (
    block_code TEXT,
    block_type TEXT,
    category TEXT,
    result_model TEXT,
    ui_hint TEXT,
    display_name TEXT,
    matched_via TEXT                      -- "exact", "alias", "fuzzy"
);
```

#### Usage Examples

```sql
-- Exact match
SELECT * FROM zamm.normalize_block_code('STR');
-- Returns: block_code='STR', display_name='Strength', matched_via='exact'

-- Alias match (English)
SELECT * FROM zamm.normalize_block_code('strength');
-- Returns: block_code='STR', matched_via='alias'

-- Alias match (legacy)
SELECT * FROM zamm.normalize_block_code('WOD');
-- Returns: block_code='METCON', matched_via='alias'

-- Alias match (Hebrew)
SELECT * FROM zamm.normalize_block_code('כוח');
-- Returns: block_code='STR', matched_via='alias'

-- Invalid input
SELECT * FROM zamm.normalize_block_code('invalid');
-- Returns: 0 rows (handle gracefully in calling code)
```

### Parser Usage

When parsing workout text, the AI must populate all four key attributes using `normalize_block_code()`:

```json
{
  "session_code": "AM",
  "blocks": [
    {
      "letter": "A",
      "block_code": "STR",
      "block_type": "strength",
      "ui_hint": "exercise_table_with_sets",
      "result_model": "tracked_sets",
      "name": "Back Squat",
      "prescription": {
        "steps": [
          {
            "exercise_key": "back_squat",
            "target_sets": 5,
            "target_reps": 5,
            "target_load": { "value": 140, "unit": "kg" },
            "target_rpe": 8
          }
        ]
      }
    }
  ]
}
```

### SQL Query Examples

```sql
-- Get all strength blocks from a workout
SELECT * FROM zamm.workout_blocks
WHERE block_code IN ('STR', 'ACC', 'HYP');

-- Get conditioning blocks with their results
-- ✅ VERIFIED: Uses zamm.res_blocks (NOT workout_block_results)
SELECT
  wb.block_code,
  wb.name,
  rb.score_text,
  rb.total_time_sec,
  rb.did_complete
FROM zamm.workout_blocks wb
JOIN zamm.res_blocks rb ON wb.block_id = rb.block_id
WHERE wb.block_code IN ('METCON', 'INTV', 'SS', 'HYROX');

-- Get all blocks grouped by category
-- ✅ VERIFIED: Uses zamm.lib_block_types (NOT block_type_catalog)
SELECT
  lbt.category,
  lbt.block_code,
  lbt.display_name,
  COUNT(wb.block_id) as usage_count
FROM zamm.lib_block_types lbt
LEFT JOIN zamm.workout_blocks wb ON lbt.block_code = wb.block_code
GROUP BY lbt.category, lbt.block_code, lbt.display_name
ORDER BY lbt.category, lbt.sort_order;

-- Find workouts with specific block sequence (e.g., STR + METCON)
-- ✅ VERIFIED: Uses zamm.workout_main (NOT workouts)
SELECT
  wm.workout_id,
  wm.workout_date,
  STRING_AGG(wb.block_code, ' → ' ORDER BY wb.letter) as block_sequence
FROM zamm.workout_main wm
JOIN zamm.workout_sessions ws ON wm.workout_id = ws.workout_id
JOIN zamm.workout_blocks wb ON ws.session_id = wb.session_id
GROUP BY wm.workout_id, wm.workout_date
HAVING STRING_AGG(wb.block_code, ' → ' ORDER BY wb.letter) LIKE '%STR%METCON%';
```

---

## Frontend Implementation

### Block Rendering Logic

```typescript
function renderBlock(block: WorkoutBlock) {
  switch (block.ui_hint) {
    case 'exercise_table_with_sets':
      return <ExerciseTable showRPE={true} showRIR={true} />;

    case 'exercise_table_compact':
      return <ExerciseTable compact={true} />;

    case 'exercise_table_short_sets':
      return <ExerciseTable maxReps={5} />;

    case 'exercise_table_with_attempts':
      return <ExerciseTable showAttempts={true} />;

    case 'score_card_central':
      return <ScoreCard size="large" centered={true} />;

    case 'splits_table':
      return <SplitsTable />;

    case 'summary_card_pace':
      return <SummaryCard showPace={true} />;

    case 'item_list_with_done':
      return <ChecklistView />;

    case 'item_list_with_side_hold':
      return <BilateralTracker />;

    case 'skill_card_with_quality':
      return <SkillCard showQualityScore={true} />;

    case 'skill_card_with_progression':
      return <SkillCard showProgression={true} />;

    default:
      return <DefaultBlockView block={block} />;
  }
}
```

### Category-Based Navigation

```typescript
// Fetch block types grouped by category
const categories = await fetchBlockTypesByCategory();

// Returns:
// [
//   { category: 'preparation', blocks: [{code: 'WU', name: 'Warm-Up'}, ...] },
//   { category: 'strength', blocks: [{code: 'STR', name: 'Strength'}, ...] },
//   ...
// ]

// Render navigation menu
<BlockTypeMenu>
  {categories.map(cat => (
    <CategorySection key={cat.category} title={cat.category}>
      {cat.blocks.map(block => (
        <BlockTypeButton
          key={block.code}
          code={block.code}
          icon={block.icon}
          onClick={() => addBlock(block.code)}
        />
      ))}
    </CategorySection>
  ))}
</BlockTypeMenu>
```

---

## Example Workouts

### Typical Workout Structures

```
STRENGTH FOCUS (60min)
├── WU (5min) - Movement prep
├── STR (30min) - Heavy compound lift
├── ACC (20min) - Accessory work
└── STRETCH (5min) - Static stretching

METCON FOCUS (45min)
├── WU (8min) - Dynamic warm-up
├── SKILL (12min) - Technical practice
├── METCON (20min) - Mixed-modal work
└── CD (5min) - Cool-down

HYBRID (75min)
├── WU (10min) - General + specific prep
├── STR (25min) - Main strength work
├── ACC (15min) - Accessory movements
├── METCON (15min) - Conditioning
└── STRETCH (10min) - Full-body stretching

SKILL DEVELOPMENT (50min)
├── MOB (10min) - Joint preparation
├── SKILL (15min) - Focused practice
├── GYM (20min) - Strength skill work
└── CD (5min) - Recovery

COMPETITION PREP (65min)
├── WU (10min) - Progressive warm-up
├── WL (30min) - Olympic lift focus
├── METCON (20min) - Competition simulation
└── STRETCH (5min) - Targeted recovery
```

### Common Block Combinations

| Pattern Name | Block Sequence | Total Time | Training Goal |
|-------------|----------------|------------|---------------|
| Pure Strength | WU → STR → ACC → STRETCH | 50-60min | Maximal strength |
| Power Focus | WU → PWR → STR → CD | 45-55min | Explosiveness |
| Volume Day | WU → HYP → HYP → ACC → STRETCH | 60-75min | Muscle building |
| Conditioning | WU → METCON → CD | 35-45min | Work capacity |
| Skills Practice | MOB → SKILL → GYM → STRETCH | 45-60min | Technique |
| Competition Sim | WU → WL → METCON → CD | 60min | Sport-specific |
| Active Recovery | WU → SS → STRETCH → BREATH | 30-40min | Recovery |
| Hyrox Prep | WU → STR → HYROX → STRETCH | 70-80min | Race simulation |

---

## Troubleshooting

### Common Errors and Solutions

#### Error: "Invalid block_code"

**Cause:** Parser returned a block code not in the catalog

**Solution:**
```sql
-- ✅ VERIFIED: Use zamm.lib_block_types (NOT block_type_catalog)
SELECT * FROM zamm.lib_block_types WHERE block_code = 'UNKNOWN';

-- Use normalize_block_code() to map aliases
SELECT * FROM zamm.normalize_block_code('user_input_text');

-- If no match, default to closest category or ask user for clarification
```

#### Error: "Missing ui_hint"

**Cause:** Block created before migration 20260104140000

**Solution:**
```sql
-- ✅ VERIFIED: Backfill ui_hint based on block_code
UPDATE zamm.workout_blocks wb
SET ui_hint = lbt.ui_hint
FROM zamm.lib_block_types lbt
WHERE wb.block_code = lbt.block_code
  AND wb.ui_hint IS NULL;
```

#### Error: "Result model mismatch"

**Cause:** Block type expects results in specific table but data is elsewhere

**Solution:**
- Verify `result_model` in `lib_block_types` matches actual result storage
- For STR/ACC/HYP/PWR/WL: store results in `zamm.workout_item_set_results` ✅
- For METCON/INTV/SS/HYROX: store results in `zamm.res_blocks` ✅
- For WU/ACT/MOB/CD/STRETCH/BREATH: store completion in `workout_blocks.performed` ✅

### Alias Resolution Examples

```sql
-- Test alias resolution
SELECT * FROM zamm.normalize_block_code('conditioning');  -- → METCON
SELECT * FROM zamm.normalize_block_code('hiit');          -- → INTV
SELECT * FROM zamm.normalize_block_code('cardio');        -- → SS
SELECT * FROM zamm.normalize_block_code('wod');           -- → METCON
SELECT * FROM zamm.normalize_block_code('volume');        -- → HYP
SELECT * FROM zamm.normalize_block_code('explosive');     -- → PWR
SELECT * FROM zamm.normalize_block_code('olympic');       -- → WL
```

### Invalid Block Type Handling

```javascript
// Graceful degradation when block type unknown
async function parseBlockType(userInput) {
  const result = await db.query(
    'SELECT * FROM zamm.normalize_block_code($1)',
    [userInput]
  );

  if (result.rows.length === 0) {
    // No exact match - try fuzzy matching or ask user
    logger.warn(`Unknown block type: ${userInput}`);

    // Option 1: Default to generic type
    return { block_code: 'STR', matched_via: 'default' };

    // Option 2: Ask user to clarify
    return { error: 'UNKNOWN_BLOCK_TYPE', suggestions: await getSuggestions(userInput) };
  }

  return result.rows[0];
}
```

---

## Related Documents

- **[CANONICAL_JSON_SCHEMA.md](./CANONICAL_JSON_SCHEMA.md)** - Parser output specification
- **[ARCHITECTURE.md](../architecture/ARCHITECTURE.md)** - System architecture and data flow
- **[AI_PROMPTS.md](../guides/AI_PROMPTS.md)** - Parser prompt templates
- **[VALIDATION_SYSTEM_SUMMARY.md](../VALIDATION_SYSTEM_SUMMARY.md)** - Validation rules
- **[CLAUDE.md](../../.claude/CLAUDE.md)** - AI agent development guidelines

---

**Version:** 2.2.0
**Last Updated:** January 11, 2026 (Table names verified against live database)
**Migration:** `20260104140000_block_type_system.sql`
**Database Compatibility:** PostgreSQL 14+
**Status:** Stable (17 block types, 7 result models, 14 UI hints)
**✅ Verified:** All table names confirmed via `./scripts/utils/inspect_db.sh` on 2026-01-11
**📋 Full List:** See `docs/reference/VERIFIED_TABLE_NAMES.md` for complete table list
