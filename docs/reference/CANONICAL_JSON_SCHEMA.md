---
version: "3.2.0"
last_updated: "2026-01-10"
status: "LOCKED"
compatible_db_migration: "20260104120200"
parser_ruleset_version: "v3.2"
breaking_changes_from: "3.1.0"
---

# 📜 The Constitution: Canonical JSON Schema

**Version:** 3.2.0
**Status:** 🔒 LOCKED - This is the ONLY allowed schema
**Last Updated:** January 10, 2026

**Purpose:** Define the exact, immutable structure that the parser MUST produce. Any deviation is a parser bug.

---

## 🎯 Core Principles

### Principle #0: Identity Before Data (NEW in v3.0)
**Field ordering matters for readability. Exercise identity comes BEFORE workout data.**

```json
// ✅ CORRECT - Identity → Instructions → Results
{
  "item_sequence": 1,
  "exercise_name": "Bench Press",
  "equipment_key": "barbell",
  "prescription": { "target_sets": 5 },
  "performed": { "actual_sets": 5 }
}

// ❌ WRONG - Results before instructions
{
  "item_sequence": 1,
  "exercise_name": "Bench Press",
  "equipment_key": "barbell",
  "performed": { "actual_sets": 5 },
  "prescription": { "target_sets": 5 }
}
```

**Rule:** In ALL objects with prescription/performed, order MUST be:
1. Identity fields first (`item_sequence`, `exercise_name`, `equipment_key`)
2. **`prescription`** (instructions come first)
3. **`performed`** (results come after instructions)
4. Special structures (`circuit_config`, etc.)

**Why this order:** You read instructions before you execute. Prescription defines what to do, performed records what happened.

---

### Principle #1: The Great Divide
**Every object MUST separate `prescription` (plan) from `performed` (actual execution).**

```json
// ✅ CORRECT
{
  "prescription": { "target_reps": 5 },
  "performed": { "actual_reps": 4 }
}

// ❌ WRONG - Mixed data
{
  "reps": 5,
  "notes": "got only 4"
}
```

**Rule:** If you're not sure if something is prescription or performance, default to `prescription` and set `performed: null`.

---

### Principle #2: Atomic Types & Scalable Structures (UPDATED in v3.2)
**Numbers are numbers. Strings are strings. Units are explicit.**

```json
// ✅ CORRECT - Structured values with units (v3.2)
{
  "target_reps": 5,                    // number (unitless)
  "target_weight": {                   // object with value + unit
    "value": 100.5,
    "unit": "kg"
  },
  "target_duration": {                 // object with value + unit (v3.2)
    "value": 45,
    "unit": "sec"
  },
  "target_distance": {                 // object with value + unit (v3.2)
    "value": 500,
    "unit": "m"
  }
}

// ❌ WRONG - Hardcoded units in field names (v3.0 legacy)
{
  "target_reps": "5",
  "target_weight_kg": "100kg",         // Unit in field name = not scalable
  "target_duration_sec": 45,           // Plain number (v3.0 - deprecated)
  "target_meters": 500                 // Plain number (v3.0 - deprecated)
}
```

**Rule:**
- If the original text says "5", parse it to the number `5`, not the string `"5"`.
- ALL measurement fields MUST use `{value, unit}` structure (v3.2+):
  - **Weight/load:** `"kg"`, `"lbs"`, `"g"` (grams for resistance bands)
  - **Duration:** `"sec"`, `"min"`, `"hours"`
  - **Distance:** `"m"`, `"km"`, `"yards"`, `"miles"`

---

### Principle #3: Ranges as Min/Max
**Ranges are NEVER stored as strings like "8-12". Use separate min/max fields.**

```json
// ✅ CORRECT - Explicit range
{
  "target_reps_min": 8,
  "target_reps_max": 12
}

// ❌ WRONG - String range
{
  "target_reps": "8-12"
}
```

**Rule:** Ranges apply to: reps, weight, duration, RPE, stroke rate, damper, tempo.

---

### Principle #4: Strict Normalization
**Use canonical keys. Never free text.**

```json
// ✅ CORRECT - Normalized key
{
  "exercise_name": "Back Squat",     // From exercise catalog
  "block_code": "STR"                // One of 17 standard codes
}

// ❌ WRONG - Free text
{
  "exercise_name": "squat that I did today",
  "block_code": "strength stuff"
}
```

**Rule:** Exercise names must match the exercise catalog. Block codes must be one of the 17 standards (see [BLOCK_TYPES_REFERENCE.md](./BLOCK_TYPES_REFERENCE.md)).

---

### Principle #5: Null Safety
**Unknown = `null`. Never guess. Never invent.**

```json
// ✅ CORRECT - Explicit null
{
  "prescription": { "target_reps": 5 },
  "performed": null  // We don't know if they actually did it
}

// ❌ WRONG - Guessing
{
  "prescription": { "target_reps": 5 },
  "performed": { "actual_reps": 5 }  // Assuming they did exactly as planned
}
```

**Rule:** If the text doesn't explicitly say what happened, set `performed: null`. Do not copy prescription into performed.

---

### Principle #6: Result Model - Hierarchical Performance Recording (NEW in v3.0)
**Performance data can be recorded at THREE levels. Choose the most appropriate level based on available detail.**

#### 🎯 The Three Levels:

**Level 1: Block-Level Performance** (Aggregated)
Use when ALL exercises in the block share the same outcome:
```json
{
  "block_code": "STR",
  "block_label": "A",
  "prescription": {
    "description": "Back Squat: 5x5 @ 100kg"
  },
  "performed": {
    "completed": true,
    "actual_sets": 5,
    "actual_reps": 5,
    "actual_weight": { "value": 100, "unit": "kg" }
  },
  "items": [...]  // Items have performed: null
}
```

**Level 2: Item-Level Performance** (Simple Summary)
Use when the text gives overall results per exercise, but not set-by-set:
```json
{
  "item_sequence": 1,
  "exercise_name": "Back Squat",
  "equipment_key": "barbell",
  "prescription": {
    "target_sets": 5,
    "target_reps": 5,
    "target_weight": { "value": 100, "unit": "kg" }
  },
  "performed": {
    "actual_sets": 5,
    "actual_reps": 5,
    "actual_weight": { "value": 100, "unit": "kg" },
    "notes": "Felt strong today"
  }
}
```

**Level 3: Set-by-Set Performance** (Detailed Breakdown)
Use when the text provides individual set results:
```json
{
  "item_sequence": 1,
  "exercise_name": "Back Squat",
  "equipment_key": "barbell",
  "prescription": {
    "target_sets": 5,
    "target_reps": 5,
    "target_weight": { "value": 100, "unit": "kg" }
  },
  "performed": {
    "sets": [
      { "set_index": 1, "reps": 5, "load": { "value": 100, "unit": "kg" }, "rpe": 7 },
      { "set_index": 2, "reps": 5, "load": { "value": 100, "unit": "kg" }, "rpe": 8 },
      { "set_index": 3, "reps": 5, "load": { "value": 100, "unit": "kg" }, "rpe": 8 },
      { "set_index": 4, "reps": 4, "load": { "value": 100, "unit": "kg" }, "rpe": 9, "notes": "Failed last rep" },
      { "set_index": 5, "reps": 4, "load": { "value": 95, "unit": "kg" }, "rpe": 9, "notes": "Reduced weight" }
    ]
  }
}
```

#### 📊 Decision Tree - Which Level to Use?

```
Does the text provide set-by-set details?
│
├─ YES → Use Level 3 (performed.sets[])
│         Example: "Set 1: 5 @ 100kg RPE 7, Set 2: 5 @ 100kg RPE 8..."
│
└─ NO → Is there an overall result for the exercise?
    │
    ├─ YES → Use Level 2 (item.performed with simple fields)
    │         Example: "Completed 5x5 @ 100kg, felt good"
    │
    └─ NO → Is there a block-level summary?
        │
        ├─ YES → Use Level 1 (block.performed)
        │         Example: "Block A: All completed as prescribed"
        │
        └─ NO → Set performed: null
                  Example: Only prescription exists, no execution data
```

#### ⚠️ Critical Rules:

1. **Never Duplicate Data Across Levels**
   ```json
   // ❌ WRONG - Duplicating at block AND item level
   {
     "block_performed": { "actual_sets": 5 },
     "items": [{
       "performed": { "actual_sets": 5 }  // Redundant!
     }]
   }
   
   // ✅ CORRECT - Choose ONE level
   {
     "block_performed": { "actual_sets": 5 },
     "items": [{
       "performed": null  // Block-level only
     }]
   }
   ```

2. **Level 3 Takes Priority**
   If set-by-set data exists, ALWAYS use `performed.sets[]`:
   ```json
   // ❌ WRONG - Mixing simple fields with sets array
   {
     "performed": {
       "actual_sets": 3,
       "actual_reps": 5,  // Don't do this!
       "sets": [...]      // If you have sets[], don't use simple fields
     }
   }
   
   // ✅ CORRECT - Sets array only
   {
     "performed": {
       "sets": [
         { "set_index": 1, "reps": 5, ... },
         { "set_index": 2, "reps": 5, ... },
         { "set_index": 3, "reps": 4, ... }
       ]
     }
   }
   ```

3. **Partial Data = Use Lower Level + Notes**
   ```json
   // Text: "Got 5 reps but forgot to track weight"
   {
     "performed": {
       "actual_reps": 5,
       "notes": "Weight not recorded"
     }
   }
   ```

#### 🔍 Real-World Examples:

**Example A: Aggregate Block Result**
```
Text: "Strength Block: 3 rounds of 8-10 reps on all exercises, moderate weight"

{
  "block_performed": {
    "completed": true,
    "actual_rounds": 3,
    "notes": "moderate weight used on all exercises"
  },
  "items": [
    { "exercise_name": "...", "performed": null },
    { "exercise_name": "...", "performed": null }
  ]
}
```

**Example B: Per-Exercise Summary**
```
Text: 
"1. Bench Press: Completed 5x5 @ 80kg"
"2. Row: Completed 5x5 @ 70kg"

{
  "items": [
    {
      "exercise_name": "Bench Press",
      "performed": {
        "actual_sets": 5,
        "actual_reps": 5,
        "actual_weight": { "value": 80, "unit": "kg" }
      }
    },
    {
      "exercise_name": "Row",
      "performed": {
        "actual_sets": 5,
        "actual_reps": 5,
        "actual_weight": { "value": 70, "unit": "kg" }
      }
    }
  ]
}
```

**Example C: Full Set-by-Set Detail**
```
Text:
"Deadlift:
Set 1: 5 @ 140kg RPE 6
Set 2: 5 @ 140kg RPE 7
Set 3: 3 @ 140kg RPE 9 - grip failed"

{
  "exercise_name": "Deadlift",
  "performed": {
    "sets": [
      { "set_index": 1, "reps": 5, "load": { "value": 140, "unit": "kg" }, "rpe": 6 },
      { "set_index": 2, "reps": 5, "load": { "value": 140, "unit": "kg" }, "rpe": 7 },
      { "set_index": 3, "reps": 3, "load": { "value": 140, "unit": "kg" }, "rpe": 9, "notes": "grip failed" }
    ]
  }
}
```

**Rule:** Match the level of detail in your JSON to the level of detail in the source text. Never invent granularity that doesn't exist.

---

## 📐 Schema Definition

### Top Level: Workout Object

```typescript
interface Workout {
  workout_date: string;           // YYYY-MM-DD format (ISO 8601)
  athlete_id: string | null;      // UUID or null if unknown
  title: string;                  // Workout title (e.g., "W1 T1", "Mon AM")
  warmup_objective?: string;      // Optional (e.g., "Foundation & Control")
  status: "completed" | "partial" | "planned" | "skipped";
  sessions: Session[];            // Array of 1+ sessions (AM/PM splits)
}
```

**Field Rules:**
- `workout_date`: MUST be ISO 8601 date. No time component.
- `athlete_id`: MUST be UUID or null (parser won't know this, set to null).
- `title`: Short workout identifier, NOT a full description.
- `status`: 
  - `"completed"` = Athlete did the workout
  - `"partial"` = Started but didn't finish
  - `"planned"` = Only prescription, no performance
  - `"skipped"` = Didn't do it at all

---

### Session Object

```typescript
interface Session {
  session_code: string | null;    // "AM", "PM", or null
  session_time?: string | null;   // "08:00" format or null
  blocks: Block[];                // Array of workout blocks
}
```

**Field Rules:**
- `session_code`: Only `"AM"`, `"PM"`, or `null`. No other values.
- `session_time`: 24-hour format (HH:MM) or null.
- `blocks`: Every session MUST have at least 1 block.

---

### Block Object (The Core Structure)

```typescript
interface Block {
  block_code: BlockCode;          // One of 17 standard codes (WU, STR, METCON, etc.)
  block_label: string;            // "A", "B", "C", etc.
  block_title?: string;           // Human-readable title (e.g., "Back Squat 5x5")
  
  prescription: BlockPrescription;  // What was PLANNED
  performed: BlockPerformed | null; // What ACTUALLY happened
  
  items: BlockItem[];             // Individual exercises in this block
}
```

**Field Rules:**
- `block_code`: MUST be one of:
  - **PREPARATION:** `WU`, `ACT`, `MOB`
  - **STRENGTH:** `STR`, `ACC`, `HYP`
  - **POWER:** `PWR`, `WL`
  - **SKILL:** `SKILL`, `GYM`
  - **CONDITIONING:** `METCON`, `INTV`, `SS`, `HYROX`
  - **RECOVERY:** `CD`, `STRETCH`, `BREATH`
- `block_label`: Single letter (A-Z) or null.
- `prescription`: ALWAYS present (even if empty object).
- `performed`: ONLY present if text explicitly states what happened.

---

### Block Prescription Object

```typescript
interface BlockPrescription {
  description?: string;           // Free text description
  target_sets?: number;           // How many sets total
  target_rounds?: number;         // For circuits/metcons
  target_duration?: {             // Total time for the block (v3.2)
    value: number;
    unit: "sec" | "min" | "hours";
  };
  target_rest?: {                 // Rest between sets (v3.2)
    value: number;
    unit: "sec" | "min";
  };
  target_tempo?: string;          // "3-0-2-0" format (eccentric-pause-concentric-pause)
  notes?: string;                 // Any additional prescription notes

  // AMRAP specific
  target_amrap_duration?: {       // AMRAP time limit (v3.2)
    value: number;
    unit: "sec" | "min" | "hours";
  };

  // For Time specific
  target_fortime_rounds?: number;
  target_fortime_cap?: {          // Time cap (v3.2)
    value: number;
    unit: "sec" | "min" | "hours";
  };
  
  // NEW v3.1: Buy-in/Buy-out structure
  buy_in?: BlockItem[];           // Exercises before main work (e.g., "400m Run before AMRAP")
  buy_out?: BlockItem[];          // Exercises after main work (e.g., "400m Run after AMRAP")
  
  // NEW v3.1: Team format
  team_format?: {
    type: "individual" | "partners" | "team_of_3" | "team_of_4" | "relay";
    scoring: "team_total" | "individual_contribution" | "each_athlete";
    notes?: string;               // Additional team format details
  };
}
```

**Field Rules:**
- All fields are optional (some blocks have minimal prescription).
- Duration fields: Use `{value, unit}` structure (v3.2). Preserve original units from text.
- Rest: Use `{value, unit}` structure (v3.2). Can be "sec" or "min".
- Tempo: String format "eccentric-bottom pause-concentric-top pause" (e.g., "3-0-1-0").
- **Buy-in/Buy-out:** Use when workout has exercises before/after main work. Can have buy_in only, buy_out only, or both.
- **Team Format:** Use when workout involves partners/teams. `scoring` determines how to record individual athlete results:
  - `"team_total"` = Record team's combined result (use only for team-wide tracking)
  - `"individual_contribution"` = Record each athlete's contribution separately
  - `"each_athlete"` = Each athlete performs full workout, results tracked individually

---

### Block Performed Object

```typescript
interface BlockPerformed {
  completed: boolean;             // Did they finish the block?
  did_complete?: boolean;         // Alias for 'completed' (legacy)
  notes?: string;                 // Free text notes about performance

  actual_sets?: number;           // How many sets done
  actual_rounds?: number;         // For circuits
  actual_duration?: {             // Total time taken (v3.2)
    value: number;
    unit: "sec" | "min" | "hours";
  };
  actual_weight?: {               // If the whole block used same weight (v3.0)
    value: number;
    unit: "kg" | "lbs" | "g";
  };
  actual_reps?: number;           // If the whole block used same reps
  actual_sets_per_side?: number;  // For unilateral movements

  // For AMRAP
  actual_rounds_completed?: number;
  actual_partial_reps?: number;   // Reps into incomplete round

  // For Time
  actual_time?: {                 // Time to complete (v3.2)
    value: number;
    unit: "sec" | "min" | "hours";
  };
}
```

**Field Rules:**
- `completed`: REQUIRED if performed object exists.
- Duration: Use `{value, unit}` structure (v3.2).
- Block-level fields: Only use if ALL items in block share the same value.
- **Team workouts:** If `team_format.scoring` is `"individual_contribution"`, record ONLY the athlete's personal performance, NOT the team total.

---

### Block Item Object (Individual Exercise)

```typescript
interface BlockItem {
  item_sequence: number;          // 1, 2, 3... (order in block)
  exercise_name: string;          // Normalized exercise name
  equipment_key?: string;         // Canonical equipment key (NEW in v3.0)
  
  prescription: ItemPrescription;   // What was PLANNED for this exercise
  performed: ItemPerformed | null;  // What ACTUALLY happened
  
  // Special structures
  exercise_options?: ExerciseOption[];  // Alternative exercises (e.g., "Bike OR Row")
  circuit_config?: CircuitConfig;       // For circuits/supersets
  exercises?: BlockItem[];              // Nested exercises (for circuits)
}
```

**Field Rules:**
- `item_sequence`: Starts at 1, increments sequentially.
- `exercise_name`: MUST match exercise catalog (use normalization function).
- `equipment_key`: MUST be from `lib_equipment_catalog` (e.g., "barbell", "dumbbell", "kettlebell", "bodyweight"). Added in v3.0.
- EITHER `exercise_name` OR `exercise_options` OR `exercises` (for circuits).
- `circuit_config`: Only present if this is a circuit/superset.

**Field Ordering (MANDATORY in v3.0):**
1. `item_sequence`
2. `exercise_name` (or `exercise_options`/`exercises`)
3. `equipment_key` (if applicable)
4. `prescription`
5. `performed`
6. Other fields (`circuit_config`, etc.)

---

### Item Prescription Object

```typescript
interface ItemPrescription {
  // Sets & Reps
  target_sets?: number;
  target_reps?: number;
  target_reps_min?: number;         // For ranges (e.g., "8-12 reps")
  target_reps_max?: number;
  target_sets_per_side?: number;    // For unilateral
  
  // Load (v3.0 structure - value + unit)
  target_weight?: {
    value: number;
    unit: "kg" | "lbs" | "g";       // Explicit unit
  };
  target_weight_min?: {              // For ranges
    value: number;
    unit: "kg" | "lbs" | "g";
  };
  target_weight_max?: {
    value: number;
    unit: "kg" | "lbs" | "g";
  };
  target_percentage_1rm?: number;   // "@ 70%" = 0.70

  // Duration (v3.2 - unified structure)
  target_duration?: {
    value: number;
    unit: "sec" | "min" | "hours";
  };
  
  // Intensity
  target_rpe?: number;              // 1-10 scale
  target_rpe_min?: number;
  target_rpe_max?: number;
  target_rir?: number;              // Reps in reserve (0-5)
  
  // Tempo
  target_tempo?: string;            // "3-0-2-0" format
  
  // Equipment & Execution Pattern
  equipment?: string;               // "barbell", "dumbbell", "kettlebell", etc.
  position?: string;                // "half_kneeling", "single_leg", etc.
  execution_pattern?: ExecutionPattern; // How limbs work (NEW in v3.0)
  
  // Rowing specific
  target_stroke_rate?: number;
  target_stroke_rate_min?: number;
  target_stroke_rate_max?: number;
  target_damper?: number;
  target_damper_min?: number;
  target_damper_max?: number;
  target_pace_per_500m?: string;    // "2:00" format
  target_watts?: number;
  target_calories?: number;
  target_distance?: {               // Distance target (v3.2)
    value: number;
    unit: "m" | "km" | "yards" | "miles";
  };
  
  // Reps with breakdown
  target_reps_forward?: number;     // "8 forward, 8 backward"
  target_reps_backward?: number;
  
  // Notes
  notes?: string;
}
```

```

```typescript
type ExecutionPattern = 
  | "bilateral"          // Both limbs together (default)
  | "alternating"        // One limb then the other, same set
  | "single_side";       // One limb only, separate sets per side
```

**Field Rules:**
- Ranges: Use `_min` and `_max` suffixes, never string ranges.
- Weight: Prefer kg. Convert lbs to kg if needed (1 lb = 0.453592 kg).
- Percentage: Decimal format (70% = 0.70, not 70).
- RPE: 1-10 scale (can be decimal like 7.5).
- RIR: Typically 0-5 (0 = failure, 5 = very easy).
- Tempo: Always "eccentric-pause-concentric-pause" (e.g., "3-0-2-0", "4-1-X-1").
- Equipment: See "Equipment Model" section below for full catalog and normalization rules.
- Execution Pattern: See "Unilateral Patterns" section below for detailed usage.

---

### Item Performed Object

```typescript
interface ItemPerformed {
  // Simple execution
  actual_sets?: number;
  actual_reps?: number;
  actual_weight?: {                  // v3.0 structure - ALWAYS {value, unit}
    value: number;
    unit: "kg" | "lbs" | "g";
  };
  actual_duration?: {                // v3.2 structure
    value: number;
    unit: "sec" | "min" | "hours";
  };
  actual_distance?: {                // v3.2 structure
    value: number;
    unit: "m" | "km" | "yards" | "miles";
  };
  actual_sets_per_side?: number;
  
  // Intensity
  actual_rpe?: number;
  actual_rir?: number;
  
  // Set-by-set breakdown
  sets?: SetResult[];               // Array of individual set results
  
  // Notes
  notes?: string;
}
```

**Field Rules:**
- `actual_weight`: MUST use `{value, unit}` structure. Never `actual_weight_kg` or `actual_weight_lbs`.
- `actual_duration`: MUST use `{value, unit}` structure (v3.2). Never plain number.
- `actual_distance`: MUST use `{value, unit}` structure (v3.2). Never plain number.
- `sets`: Use for detailed set-by-set breakdown. Otherwise use aggregate fields.

---

### Set Result Object (Individual Set Performance)

```typescript
interface SetResult {
  set_index: number;                // 1, 2, 3...
  reps?: number;
  load?: {                          // v3.0 structure
    value: number;
    unit: "kg" | "lbs" | "g";
  };
  duration?: {                      // v3.2 structure
    value: number;
    unit: "sec" | "min" | "hours";
  };
  distance?: {                      // v3.2 structure
    value: number;
    unit: "m" | "km" | "yards" | "miles";
  };
  rpe?: number;
  rir?: number;
  set_technique?: SetTechnique;     // Advanced techniques (NEW in v3.0)
  notes?: string;                   // Set-specific notes (e.g., "Failed last rep")
}

type SetTechnique = 
  | "standard"           // Regular set (default)
  | "drop_set"           // Drop set (reduce weight mid-set)
  | "rest_pause"         // Rest-pause (micro-rests within set)
  | "cluster"            // Cluster set (rest between reps)
  | "myo_reps"           // Myo-reps technique
  | "amrap"              // As many reps as possible
  | "tempo"              // Controlled tempo
  | "isometric_hold";    // Static hold
```

**Field Rules:**
- `set_index`: Starts at 1, increments sequentially.
- `set_technique`: Default is `"standard"`. Use specific technique only when explicitly stated in text.
- For advanced techniques (drop sets, rest-pause, etc.), see "Advanced Set Techniques" section below.
- Use this structure when each set has different performance (most common).

---

### Circuit Config Object

```typescript
interface CircuitConfig {
  rounds: number;                   // Number of rounds
  type: "for_quality" | "for_time" | "amrap" | "emom";
  rest_between_rounds_sec?: number;
  rest_between_exercises_sec?: number;
}
```

---

## 🎯 Advanced Set Techniques (NEW in v3.0)

### Overview
Advanced training techniques require special handling. Use `set_technique` field in `SetResult` to identify the technique used.

---

### Technique 1: Drop Set
**Definition:** Reduce weight mid-set to continue with more reps.

**Text Example:**
```
Bench Press:
Set 3: 8 @ 100kg → drop to 80kg for 6 more → drop to 60kg for 4 more
```

**JSON Structure:**
```json
{
  "exercise_name": "Bench Press",
  "performed": {
    "sets": [
      {
        "set_index": 3,
        "set_technique": "drop_set",
        "notes": "Drop set: 8 @ 100kg → 6 @ 80kg → 4 @ 60kg",
        "reps": 18,
        "load": { "value": 100, "unit": "kg" }
      }
    ]
  }
}
```

**Alternative (Detailed Breakdown):**
If you want to preserve each drop as separate mini-sets:
```json
{
  "performed": {
    "sets": [
      {
        "set_index": 3,
        "set_technique": "drop_set",
        "reps": 8,
        "load": { "value": 100, "unit": "kg" },
        "notes": "First drop"
      },
      {
        "set_index": 3.1,
        "set_technique": "drop_set",
        "reps": 6,
        "load": { "value": 80, "unit": "kg" },
        "notes": "Second drop"
      },
      {
        "set_index": 3.2,
        "set_technique": "drop_set",
        "reps": 4,
        "load": { "value": 60, "unit": "kg" },
        "notes": "Final drop"
      }
    ]
  }
}
```

---

### Technique 2: Rest-Pause
**Definition:** Take short breaks (10-20 seconds) within a single set.

**Text Example:**
```
Squat: 
Set 4: 5 reps @ 120kg, rest 15 sec, 3 more reps, rest 15 sec, 2 more reps
```

**JSON Structure:**
```json
{
  "set_index": 4,
  "set_technique": "rest_pause",
  "reps": 10,
  "load": { "value": 120, "unit": "kg" },
  "notes": "5 + 3 + 2 reps with 15s rest-pause"
}
```

---

### Technique 3: Cluster Set
**Definition:** Rest between individual reps or small clusters (e.g., 1 rep, rest 10s, repeat).

**Text Example:**
```
Deadlift:
Set 1: 5 singles @ 180kg with 20s rest between reps
```

**JSON Structure:**
```json
{
  "set_index": 1,
  "set_technique": "cluster",
  "reps": 5,
  "load": { "value": 180, "unit": "kg" },
  "notes": "5 singles with 20s rest"
}
```

---

### Technique 4: Myo-Reps
**Definition:** Activation set followed by mini-sets with short rest.

**Text Example:**
```
Leg Press:
Set 1: 15 @ 100kg (activation), then 5 mini-sets of 3-5 reps with 5s rest
```

**JSON Structure:**
```json
{
  "set_index": 1,
  "set_technique": "myo_reps",
  "reps": 35,
  "load": { "value": 100, "unit": "kg" },
  "notes": "15 reps activation + 5 mini-sets (5,5,4,3,3)"
}
```

---

### Technique 5: Superset
**Definition:** Two exercises performed back-to-back with no rest.

**Text Example:**
```
Superset:
A1. Bench Press: 3x8 @ 80kg
A2. Barbell Row: 3x8 @ 70kg
```

**JSON Structure:**
```json
{
  "block_label": "A",
  "circuit_config": {
    "rounds": 3,
    "type": "for_quality",
    "rest_between_exercises_sec": 0,
    "rest_between_rounds_sec": 90
  },
  "items": [
    {
      "item_sequence": 1,
      "exercise_name": "Bench Press",
      "equipment_key": "barbell",
      "prescription": {
        "target_sets": 3,
        "target_reps": 8,
        "target_weight": { "value": 80, "unit": "kg" }
      },
      "performed": null
    },
    {
      "item_sequence": 2,
      "exercise_name": "Barbell Row",
      "equipment_key": "barbell",
      "prescription": {
        "target_sets": 3,
        "target_reps": 8,
        "target_weight": { "value": 70, "unit": "kg" }
      },
      "performed": null
    }
  ]
}
```

---

### Technique 6: Giant Set
**Definition:** 4+ exercises performed consecutively with minimal rest.

**Text Example:**
```
Giant Set (4 rounds):
1. Push-ups: 15 reps
2. Pull-ups: 10 reps
3. Dips: 12 reps
4. Inverted Rows: 15 reps
Rest 2 min between rounds
```

**JSON Structure:**
```json
{
  "block_code": "STR",
  "block_label": "B",
  "circuit_config": {
    "rounds": 4,
    "type": "for_quality",
    "rest_between_exercises_sec": 0,
    "rest_between_rounds_sec": 120
  },
  "items": [
    {
      "item_sequence": 1,
      "exercise_name": "Push-up",
      "prescription": { "target_reps": 15 }
    },
    {
      "item_sequence": 2,
      "exercise_name": "Pull-up",
      "prescription": { "target_reps": 10 }
    },
    {
      "item_sequence": 3,
      "exercise_name": "Dip",
      "prescription": { "target_reps": 12 }
    },
    {
      "item_sequence": 4,
      "exercise_name": "Inverted Row",
      "prescription": { "target_reps": 15 }
    }
  ]
}
```

---

### Technique 7: AMRAP Set
**Definition:** As Many Reps As Possible (to failure or near-failure).

**Text Example:**
```
Pull-ups:
Set 3: AMRAP @ bodyweight → got 12 reps
```

**JSON Structure:**
```json
{
  "set_index": 3,
  "set_technique": "amrap",
  "reps": 12,
  "notes": "AMRAP @ bodyweight"
}
```

---

### Decision Tree - Which Structure to Use?

```
Is it multiple exercises done together?
│
├─ YES → Use circuit_config
│   │
│   ├─ 2 exercises → Superset
│   ├─ 3 exercises → Tri-set
│   └─ 4+ exercises → Giant Set
│
└─ NO → Is it a single exercise with special technique?
    │
    └─ YES → Use set_technique field
        │
        ├─ Weight changes within set → drop_set
        ├─ Micro-rests within set → rest_pause
        ├─ Rest between reps → cluster
        ├─ Activation + mini-sets → myo_reps
        ├─ Max reps → amrap
        └─ Standard execution → standard (default)
```

---

### Critical Rules for Advanced Techniques:

1. **Always Document in Notes**
   Even with `set_technique` field, add detailed notes explaining the execution.

2. **Preserve Original Text Structure**
   If text says "8 @ 100 → 6 @ 80", keep that format in notes.

3. **Use Decimal set_index for Sub-Sets**
   Drop set breakdowns: 3, 3.1, 3.2 (all part of "Set 3")

4. **Circuit vs Set Technique**
   - Multiple exercises = `circuit_config`
   - Single exercise advanced technique = `set_technique`

5. **Total Reps Calculation**
   For drop/rest-pause/myo-reps: Sum all reps into single number.
   Example: "5 + 3 + 2" = `reps: 10`

---

### Exercise Option Object (Alternatives)

```typescript
interface ExerciseOption {
  exercise_name: string;
  prescription: ItemPrescription;
}
```

**Usage:** When text says "Bike OR Row (5min)" - both are options, athlete picks one.

---

## �️ Equipment Model (NEW in v3.0)

### Overview
Equipment identification is CRITICAL for exercise differentiation. The same movement with different equipment = different exercise.

### Two Equipment Fields

**1. `equipment_key` (Block Item Level)** - Primary identifier
- Location: `BlockItem.equipment_key`
- Purpose: Part of exercise identity
- Source: `lib_equipment_catalog` table
- Mandatory: Should be present for all equipment-based exercises

**2. `equipment` (Prescription Level)** - Additional context
- Location: `ItemPrescription.equipment`
- Purpose: Prescription-specific equipment details
- Use Case: When prescription requires specific equipment variant
- Example: "use competition barbell" vs "use training barbell"

### Standard Equipment Catalog

**Free Weights:**
- `barbell` - Olympic barbell, powerlifting bar, EZ bar
- `dumbbell` - Dumbbells (pair or single)
- `kettlebell` - Kettlebells
- `plate` - Weight plates (bumper, iron)
- `medicine_ball` - Medicine ball, slam ball

**Machines:**
- `cable_machine` - Cable crossover, functional trainer
- `smith_machine` - Smith machine
- `leg_press` - Leg press machine
- `lat_pulldown` - Lat pulldown machine
- `leg_curl` - Leg curl machine
- `leg_extension` - Leg extension machine

**Cardio:**
- `rower` - Concept2 rower, erg
- `bike` - Assault bike, echo bike, stationary bike
- `ski_erg` - Ski erg
- `treadmill` - Treadmill

**Bodyweight & Suspension:**
- `bodyweight` - No equipment (push-ups, pull-ups)
- `rings` - Gymnastic rings
- `trx` - TRX, suspension trainer
- `parallettes` - Parallettes, paralettes

**Other:**
- `bench` - Flat bench, incline bench
- `box` - Plyo box, step box
- `resistance_band` - Resistance bands, mini bands
- `sled` - Prowler, sled
- `sandbag` - Sandbag
- `battle_rope` - Battle ropes
- `pull_up_bar` - Pull-up bar, chin-up bar

### Equipment Normalization Rules

**Aliases (Common Abbreviations):**
```
"BB" → "barbell"
"DB" → "dumbbell"
"KB" → "kettlebell"
"BW" → "bodyweight"
"MB" → "medicine_ball"
"RB" → "resistance_band"
```

**Context-Based Resolution:**
```
Text: "Bench Press"
→ equipment_key: "barbell" (default for bench press)

Text: "DB Bench Press"
→ equipment_key: "dumbbell" (explicit)

Text: "Machine Bench Press"
→ equipment_key: "machine" (explicit)
```

### Multi-Equipment Exercises

**Primary Equipment in equipment_key, Secondary in prescription.equipment:**

```json
// Example: Dumbbell bench press on bench
{
  "exercise_name": "Dumbbell Bench Press",
  "equipment_key": "dumbbell",
  "prescription": {
    "equipment": "flat_bench",
    "notes": "Use adjustable bench"
  }
}
```

**Alternative Equipment:**
Use `exercise_options` when text offers choices:

```json
{
  "exercise_options": [
    {
      "exercise_name": "Barbell Row",
      "prescription": { "target_reps": 8 }
    },
    {
      "exercise_name": "Dumbbell Row",
      "prescription": { "target_reps": 8 }
    }
  ]
}
```

### Equipment-Specific Fields

**Rowing Equipment:**
- `target_stroke_rate`, `target_damper`, `target_pace_per_500m`
- Only valid when `equipment_key: "rower"`

**Loaded Movements:**
- `target_weight`, `target_percentage_1rm`
- Valid for: barbell, dumbbell, kettlebell, machine, cable

**Bodyweight:**
- No `target_weight` field
- May have `target_weight` for added weight (e.g., weighted pull-ups)

### Decision Tree - Equipment Assignment

```
Is equipment explicitly stated in text?
│
├─ YES → Use exact equipment
│   Example: "DB Curl" → equipment_key: "dumbbell"
│
└─ NO → Infer from exercise name
    │
    ├─ Exercise has standard equipment?
    │   Example: "Back Squat" → "barbell" (default)
    │
    └─ Ambiguous?
        → Check catalog for most common variant
        → Set needs_review: true
```

---

## 💪 Unilateral Patterns (NEW in v3.0)

### Overview
Unilateral (single-limb) exercises have THREE distinct execution patterns. Each affects volume calculation differently.

### The Three Patterns

#### Pattern 1: Bilateral (Default)
**Both limbs work together, simultaneously.**

**Text Examples:**
- "Barbell Curl: 3x10"
- "DB Bench Press: 4x8" (both arms at once)
- "Leg Press: 3x12"

**Characteristics:**
- Both limbs move at the same time
- Typically uses 2 dumbbells, 1 barbell, or machine
- Sets = stated sets
- Reps = stated reps

**JSON Structure:**
```json
{
  "exercise_name": "Dumbbell Bench Press",
  "equipment_key": "dumbbell",
  "prescription": {
    "target_sets": 3,
    "target_reps": 10,
    "execution_pattern": "bilateral"
  }
}
```

**Volume Calculation:**
- Sets: 3
- Reps per set: 10
- Total reps: 30 (3 × 10)

---

#### Pattern 2: Alternating
**One limb, then the other, within the SAME set.**

**Text Examples:**
- "DB Curl alternating: 3x10"
- "Single-arm KB Press alternating: 4x8"
- "Alternating lunges: 3x16"

**Characteristics:**
- Right limb does rep, then left limb does rep
- Usually 2 dumbbells/kettlebells, or bodyweight
- Stated reps = TOTAL (both limbs combined)
- No rest between sides within a set

**JSON Structure:**
```json
{
  "exercise_name": "Dumbbell Curl",
  "equipment_key": "dumbbell",
  "prescription": {
    "target_sets": 3,
    "target_reps": 10,
    "execution_pattern": "alternating",
    "notes": "10 reps = 5 per arm, alternating"
  }
}
```

**Volume Calculation:**
- Sets: 3
- Total reps per set: 10 (5 right + 5 left)
- Total reps: 30 (3 × 10)
- Per limb: 15 reps each side

**Critical Rule:** If text says "3x10 alternating", the 10 includes BOTH sides.

---

#### Pattern 3: Single-Side
**One limb only, separate sets for each side.**

**Text Examples:**
- "Single-arm DB Row: 3x8/side"
- "Bulgarian Split Squat: 4x10/leg"
- "Single-leg RDL: 3x6/side"

**Characteristics:**
- Complete ALL sets for one side, then switch
- Usually 1 dumbbell/kettlebell, or bodyweight
- The "/side" or "/leg" notation is KEY
- Stated sets apply to EACH side

**JSON Structure:**
```json
{
  "exercise_name": "Single-arm Dumbbell Row",
  "equipment_key": "dumbbell",
  "prescription": {
    "target_sets": 3,
    "target_reps": 8,
    "target_sets_per_side": 3,
    "execution_pattern": "single_side",
    "notes": "3 sets per arm = 6 total sets"
  }
}
```

**Volume Calculation:**
- Sets per side: 3
- Total sets: 6 (3 right + 3 left)
- Reps per set: 8
- Total reps: 48 (6 × 8)
- Per limb: 24 reps each side

**Critical Rule:** If text says "3x8/side", you do 3 sets on right, then 3 sets on left = 6 total sets.

---

### Pattern Comparison Table

| Pattern | Text Example | Sets Total | Reps Total | Per Limb |
|---------|-------------|------------|------------|-----------|
| **Bilateral** | "DB Curl: 3x10" | 3 | 30 | N/A |
| **Alternating** | "DB Curl alt: 3x10" | 3 | 30 | 15 each |
| **Single-Side** | "DB Curl: 3x10/side" | 6 | 60 | 30 each |

---

### Decision Tree - Which Pattern?

```
Does text mention "/side", "/leg", "/arm", "per side", "each side"?
│
├─ YES → Pattern 3: single_side
│   - Use target_sets_per_side
│   - Total sets = target_sets × 2
│
└─ NO → Does text say "alternating", "alt", "hand-to-hand"?
    │
    ├─ YES → Pattern 2: alternating
    │   - Stated reps include both sides
    │   - Total sets = stated sets
    │
    └─ NO → Pattern 1: bilateral (default)
        - Both limbs work together
        - Standard set/rep counting
```

---

### Real-World Examples

**Example A: Bilateral (Standard)**
```
Text: "Dumbbell Bench Press: 4x8 @ 30kg"

JSON:
{
  "exercise_name": "Dumbbell Bench Press",
  "equipment_key": "dumbbell",
  "prescription": {
    "target_sets": 4,
    "target_reps": 8,
    "target_weight": { "value": 30, "unit": "kg" },
    "execution_pattern": "bilateral"
  }
}

Volume:
- 4 sets × 8 reps = 32 total reps
- Both arms work simultaneously
```

**Example B: Alternating**
```
Text: "KB Press alternating: 3x12 @ 16kg"

JSON:
{
  "exercise_name": "Kettlebell Press",
  "equipment_key": "kettlebell",
  "prescription": {
    "target_sets": 3,
    "target_reps": 12,
    "target_weight": { "value": 16, "unit": "kg" },
    "execution_pattern": "alternating",
    "notes": "12 reps = 6 per arm, alternating within set"
  }
}

Volume:
- 3 sets × 12 reps = 36 total reps
- 18 reps per arm (6 per set × 3 sets)
```

**Example C: Single-Side**
```
Text: "Single-arm DB Row: 3x8/side @ 25kg"

JSON:
{
  "exercise_name": "Single-arm Dumbbell Row",
  "equipment_key": "dumbbell",
  "prescription": {
    "target_sets": 3,
    "target_reps": 8,
    "target_sets_per_side": 3,
    "target_weight": { "value": 25, "unit": "kg" },
    "execution_pattern": "single_side",
    "notes": "3 sets per arm = 6 total sets"
  }
}

Volume:
- 6 total sets (3 per side)
- 6 sets × 8 reps = 48 total reps
- 24 reps per arm
```

---

### Critical Rules for Unilateral Patterns

1. **Notation is Key**
   - "/side" = single_side pattern
   - "alternating" or "alt" = alternating pattern
   - No notation = bilateral (default)

2. **Volume Calculations Differ**
   - Bilateral: sets × reps = total
   - Alternating: sets × reps = total (already includes both sides)
   - Single-side: (sets × 2) × reps = total

3. **Equipment Inference**
   - 2 dumbbells usually = bilateral or alternating
   - 1 dumbbell usually = single_side
   - Context matters: "DB Curl alternating" uses 2 dumbbells

4. **Always Document**
   Use `notes` field to clarify execution:
   ```json
   "notes": "3 sets per side = 6 total sets, 48 total reps (24 per leg)"
   ```

5. **Performance Tracking**
   For set-by-set results:
   ```json
   "performed": {
     "sets": [
       { "set_index": 1, "reps": 8, "notes": "Right arm" },
       { "set_index": 2, "reps": 8, "notes": "Left arm" },
       { "set_index": 3, "reps": 8, "notes": "Right arm" },
       { "set_index": 4, "reps": 8, "notes": "Left arm" }
     ]
   }
   ```

---

## 💪 Intensity Metrics: RPE vs RIR (NEW in v3.0)

### Overview
Two competing systems for measuring effort. **Use ONE, not both.**

### The Two Systems

#### System 1: RPE (Rate of Perceived Exertion)
**Scale:** 1-10 (Borg CR10 Scale adapted for resistance training)

**What it measures:** How hard the set FELT overall.

**The Scale:**
```
1-2:  Very easy, could do 50+ more reps
3-4:  Easy, could do 20+ more reps
5-6:  Moderate effort, could do 10+ more reps
7:    Hard, could do 5-7 more reps
8:    Very hard, could do 3-4 more reps
9:    Extremely hard, could do 1-2 more reps
10:   Maximum effort, absolute failure
```

**When to use:**
- Bodybuilding/hypertrophy training
- General fitness programs
- When coach prescribes RPE ranges ("@ RPE 7-8")

**JSON Structure:**
```json
{
  "prescription": {
    "target_rpe": 8,
    "target_rpe_min": 7,
    "target_rpe_max": 8
  },
  "performed": {
    "sets": [
      { "set_index": 1, "reps": 5, "rpe": 7 },
      { "set_index": 2, "reps": 5, "rpe": 8 },
      { "set_index": 3, "reps": 4, "rpe": 9 }
    ]
  }
}
```

---

#### System 2: RIR (Reps in Reserve)
**Scale:** 0-10+ (number of reps left in the tank)

**What it measures:** How many MORE reps you could have done.

**The Scale:**
```
0:    Absolute failure (couldn't do 1 more rep)
1:    Could do 1 more rep
2:    Could do 2 more reps
3:    Could do 3 more reps
4:    Could do 4 more reps
5+:   Easy, 5 or more reps left
```

**When to use:**
- Powerlifting/strength training
- Autoregulation protocols (e.g., "3 @ 8" = 3 reps with 2 RIR)
- When precision matters for programming

**JSON Structure:**
```json
{
  "prescription": {
    "target_rir": 2,
    "notes": "3 reps @ 2 RIR = stop when you could do 2 more"
  },
  "performed": {
    "sets": [
      { "set_index": 1, "reps": 3, "rir": 2 },
      { "set_index": 2, "reps": 3, "rir": 1 },
      { "set_index": 3, "reps": 3, "rir": 0 }
    ]
  }
}
```

---

### RPE ↔ RIR Conversion Table

| RPE | RIR | Description |
|-----|-----|-------------|
| 10  | 0   | Absolute failure |
| 9.5 | 0-1 | Could maybe do 1 more |
| 9   | 1   | Could definitely do 1 more |
| 8.5 | 1-2 | Between 1-2 reps left |
| 8   | 2   | Could do 2 more |
| 7.5 | 2-3 | Between 2-3 reps left |
| 7   | 3   | Could do 3 more |
| 6   | 4   | Could do 4 more |
| 5   | 5+  | Easy, 5+ reps left |

---

### Critical Rules

1. **Never Use Both**
   ```json
   // ❌ WRONG - Redundant and confusing
   {
     "rpe": 8,
     "rir": 2
   }
   
   // ✅ CORRECT - Pick one system
   { "rpe": 8 }
   // OR
   { "rir": 2 }
   ```

2. **Match Source Text**
   ```
   Text: "@ RPE 7-8" → Use target_rpe_min/max
   Text: "3 @ 8" (powerlifting notation) → Use target_rir: 2
   ```

3. **Validation Ranges**
   - RPE: 1-10 (allow decimals like 7.5)
   - RIR: 0-10 (integers only)

4. **Default to RPE When Ambiguous**
   If text says "hard" or "moderate" without specifying system, use RPE scale.

5. **Omit If Not Stated**
   ```json
   // If text doesn't mention intensity:
   {
     "prescription": { "target_reps": 5 },
     "performed": { "reps": 5 }
     // No rpe or rir fields
   }
   ```

---

### Real-World Examples

**Example A: RPE Prescription**
```
Text: "Back Squat: 3x5 @ RPE 7-8"

JSON:
{
  "prescription": {
    "target_sets": 3,
    "target_reps": 5,
    "target_rpe_min": 7,
    "target_rpe_max": 8
  }
}
```

**Example B: RIR Prescription**
```
Text: "Bench Press: 5x3 @ 2 RIR"

JSON:
{
  "prescription": {
    "target_sets": 5,
    "target_reps": 3,
    "target_rir": 2,
    "notes": "Stop when you could do 2 more reps"
  }
}
```

**Example C: Autoregulation (RIR-Based)**
```
Text: "Deadlift: Work up to heavy single @ 1 RIR, then 3x3 @ same weight"

JSON:
{
  "items": [
    {
      "item_sequence": 1,
      "exercise_name": "Deadlift",
      "prescription": {
        "target_reps": 1,
        "target_rir": 1,
        "notes": "Work up to heavy single with 1 rep in reserve"
      }
    },
    {
      "item_sequence": 2,
      "exercise_name": "Deadlift",
      "prescription": {
        "target_sets": 3,
        "target_reps": 3,
        "notes": "Use same weight as heavy single"
      }
    }
  ]
}
```

---

## 🔄 Position Variants Catalog (NEW in v3.0)

### Overview
Position variants significantly change exercise biomechanics. Use `position` field in `ItemPrescription`.

### Standard Positions by Category

#### Stance Positions
**Lower Body:**
- `conventional` - Standard hip-width stance
- `sumo` - Wide stance, toes out (deadlifts, squats)
- `wide_stance` - Wider than shoulder-width
- `narrow_stance` - Feet together or very close
- `split_stance` - One foot forward, one back (not lunging)
- `staggered_stance` - Slight offset, both feet mostly parallel
- `single_leg` - Standing on one leg only

**Upper Body:**
- `half_kneeling` - One knee down, one foot planted
- `tall_kneeling` - Both knees down, upright torso
- `quadruped` - Hands and knees (all fours)

#### Grip Positions
**Width:**
- `wide_grip` - Hands wider than shoulder-width
- `narrow_grip` - Hands closer than shoulder-width
- `close_grip` - Hands very close together
- `standard_grip` - Shoulder-width or natural position

**Orientation:**
- `pronated` - Palms facing away (overhand)
- `supinated` - Palms facing toward you (underhand)
- `neutral` - Palms facing each other
- `mixed_grip` - One pronated, one supinated

#### Bar Position (Squats)
- `high_bar` - Bar on traps (Olympic squat)
- `low_bar` - Bar on rear delts (powerlifting squat)
- `front_rack` - Bar on front shoulders (front squat)
- `zercher` - Bar in elbow crooks

#### Body Angles
- `incline` - Upper body elevated (bench angles)
- `decline` - Upper body lower than hips
- `flat` - Body parallel to ground
- `vertical` - Body upright (90° to ground)

### Usage in JSON

**Example 1: Grip Variant**
```json
{
  "exercise_name": "Pull-up",
  "equipment_key": "pull_up_bar",
  "prescription": {
    "target_reps": 10,
    "position": "wide_grip"
  }
}
```

**Example 2: Stance Variant**
```json
{
  "exercise_name": "Deadlift",
  "equipment_key": "barbell",
  "prescription": {
    "target_sets": 5,
    "target_reps": 3,
    "position": "sumo",
    "target_weight": { "value": 140, "unit": "kg" }
  }
}
```

**Example 3: Combined Positions**
```json
{
  "exercise_name": "Dumbbell Press",
  "equipment_key": "dumbbell",
  "prescription": {
    "target_sets": 3,
    "target_reps": 8,
    "position": "half_kneeling",
    "notes": "Neutral grip, half-kneeling position"
  }
}
```

### Normalization Rules

**Aliases:**
```
"OH" → "overhand" → "pronated"
"UH" → "underhand" → "supinated"
"close" → "close_grip"
"wide" → "wide_grip"
"HB" → "high_bar"
"LB" → "low_bar"
```

**Context Inference:**
```
Text: "Wide-grip Pull-ups"
→ position: "wide_grip"

Text: "Sumo Deadlift"
→ position: "sumo"

Text: "Close-grip Bench Press"
→ exercise_name: "Bench Press"
→ position: "close_grip"
```

---

## ⏱️ Tempo Components Guide (NEW in v3.0)

### Overview
Tempo controls the speed of each rep phase. Format: **"Eccentric-Pause1-Concentric-Pause2"**

### The Four Components

#### Component 1: Eccentric (Lowering)
**First number** - Time in seconds to lower the weight

```
"3"-0-2-0  ← 3 seconds to lower
```

**What it is:**
- The "negative" phase
- Muscle lengthening under load
- Usually the stronger phase

**Examples:**
- Squat: Going down
- Bench Press: Lowering bar to chest
- Pull-up: Lowering down from top
- Deadlift: Lowering bar to ground

#### Component 2: Bottom Pause
**Second number** - Time in seconds to pause at the bottom

```
3-"1"-2-0  ← 1 second pause at bottom
```

**What it is:**
- Pause at the stretched position
- Removes stretch reflex
- Increases difficulty significantly

#### Component 3: Concentric (Lifting)
**Third number** - Time in seconds to lift the weight

```
3-0-"2"-0  ← 2 seconds to lift
```

**Special notation:**
- `X` or `0` = Explosive (as fast as possible)
- `1` = Controlled speed
- `2-4` = Slow, deliberate

#### Component 4: Top Pause
**Fourth number** - Time in seconds to pause at the top

```
3-0-2-"1"  ← 1 second pause at top
```

### Common Tempo Prescriptions

| Tempo | Description | Use Case | TUT/Rep |
|-------|-------------|----------|---------|
| 3-0-1-0 | Controlled | General strength | 4 sec |
| 4-0-X-0 | Eccentric focus | Hypertrophy | 4+ sec |
| 3-1-3-1 | Max tension | Bodybuilding | 8 sec |
| 2-0-2-0 | Standard | Default | 4 sec |
| 5-2-X-0 | Extreme eccentric | Advanced | 7+ sec |

### Parsing Rules

**1. Always 4 numbers:**
```
✅ "3-0-2-0"
✅ "4-1-X-1"
❌ "3-2-1" (missing 4th)
❌ "slow" (not numeric)
```

**2. X means explosive:**
```
"3-0-X-0" = 3 sec down, explode up
```

**3. Convert descriptive text:**
```
"Slow eccentric" → "3-0-1-0"
"Pause at bottom" → "3-2-1-0"
```

**4. Default when not specified: omit field**

---

## 🏃 METCON Formats Guide (NEW in v3.0)

### The 4 Primary Formats

#### Format 1: AMRAP (As Many Rounds As Possible)
**Structure:** Fixed time, maximize rounds

**Key Fields:**
- `target_amrap_duration`: Time limit (v3.2)
- `actual_rounds_completed`: Full rounds done
- `actual_partial_reps`: Reps into incomplete round

**Example:**
```json
{
  "prescription": {
    "target_amrap_duration": {
      "value": 12,
      "unit": "min"
    }
  },
  "performed": {
    "actual_rounds_completed": 5,
    "actual_partial_reps": 15
  }
}
```

#### Format 2: For Time (Race the Clock)
**Structure:** Fixed work, minimize time

**Key Fields:**
- `target_fortime_rounds`: Rounds to complete
- `target_fortime_cap`: Time cap (v3.2)
- `actual_time`: Time taken (v3.2)

**Example:**
```json
{
  "prescription": {
    "target_fortime_rounds": 5,
    "target_fortime_cap": {
      "value": 15,
      "unit": "min"
    }
  },
  "performed": {
    "actual_time": {
      "value": 694,
      "unit": "sec"
    }
  }
}
```

#### Format 3: EMOM (Every Minute On the Minute)
**Structure:** Start new work each minute

**Key Fields:**
- `circuit_config.type`: "emom"
- `target_duration`: 60 seconds per station (v3.2)

**Example:**
```json
{
  "circuit_config": {
    "rounds": 4,
    "type": "emom"
  }
}
```

#### Format 4: Intervals (Work/Rest)
**Structure:** Alternating work and rest

**Key Fields:**
- `target_duration`: Work time (v3.2)
- `target_rest`: Rest time (v3.2)
- `target_rounds`: Number of intervals

**Common Ratios:**
- Tabata: 20s / 10s
- Classic: 30s / 30s
- Long: 60s / 60s

---

## 📝 Notes Field Guidelines (NEW in v3.0)

### When to Use Notes

#### ✅ DO Include:

1. **Execution details:** "Pause 2 seconds at bottom"
2. **Equipment specifics:** "Use competition bar"
3. **Performance context:** "Failed last rep", "Grip gave out"
4. **Clarifications:** "3 sets per arm = 6 total"
5. **Deviations:** "Reduced weight due to fatigue"

#### ❌ DON'T Include:

1. **Data with fields:** Use reps/rpe/load fields, not notes
2. **Redundant info:** Don't repeat exercise name
3. **Unstructured data:** Use target_tempo, not "tempo 3-0-2-0" in notes

### Language Rules

**Preserve original language:**
```json
"notes": "הרגשתי חזק היום"  // Hebrew
"notes": "Felt strong today"  // English
```

### Length Guidelines

- **Recommended:** 5-100 characters
- **Maximum:** 500 characters
- **Best:** Concise and actionable

### Level-Specific Usage

**Block-Level:** General instructions for entire block
```json
"notes": "Superset A1 and A2, rest 90s"
```

**Item-Level:** Exercise-specific instructions
```json
"notes": "Use neutral grip, pause at bottom"
```

**Set-Level:** Individual set context
```json
"notes": "Failed last rep"
```

---

## �🔴 Critical Validation Rules

### Rule 1: No Hallucinated Data
❌ **NEVER:**
- Copy prescription into performed (unless text explicitly confirms it)
- Invent set details (e.g., assuming all sets were successful)
- Guess equipment or exercise names
- Convert units without source text support

✅ **ALWAYS:**
- Set `performed: null` if no performance data in text
- Use `notes` field for ambiguous information
- Preserve original language in notes (Hebrew/English)

---

### Rule 2: Number Validation

```typescript
// Valid ranges
{
  target_reps: 1-500,           // Warn if > 100
  target_weight_kg: 0-500,      // Warn if > 300
  target_duration_sec: 0-7200,  // Warn if > 2 hours
  target_rpe: 1-10,             // Error if outside range
  target_rir: 0-10,             // Error if outside range
  target_percentage_1rm: 0-2.0  // Error if > 200%
}
```

**Validation Logic:**
- Numbers < 0: ERROR (invalid)
- RPE outside 1-10: ERROR
- Weight > 500kg: WARNING (possible)
- Reps > 100: WARNING (possible in metcons)

---

### Rule 3: Block Code Validation

**Valid codes:**
```typescript
type BlockCode = 
  | "WU" | "ACT" | "MOB"              // Preparation
  | "STR" | "ACC" | "HYP"             // Strength
  | "PWR" | "WL"                      // Power
  | "SKILL" | "GYM"                   // Skill
  | "METCON" | "INTV" | "SS" | "HYROX" // Conditioning
  | "CD" | "STRETCH" | "BREATH";      // Recovery
```

**If block type is ambiguous:** Use the normalization function or default to `"STR"` for heavy lifting, `"METCON"` for circuits.

---

### Rule 4: Exercise Name Normalization

**Process:**
1. Extract raw exercise name from text
2. Call `zamm.check_exercise_exists(raw_name)`
3. Use returned `exercise_key` in JSON
4. If not found, use best guess BUT set `needs_review: true`

**Examples:**
```
"bench" → "Bench Press"
"sq" → "Back Squat"
"DL" → "Deadlift"
"row" (ambiguous!) → Use context (barbell row? dumbbell row?)
```

---

### Rule 5: Tempo Format

**Valid tempo:** `"eccentric-pause-concentric-pause"`

```json
// ✅ CORRECT
"target_tempo": "3-0-2-0"    // 3s down, no pause, 2s up, no pause
"target_tempo": "4-1-X-1"    // 4s down, 1s pause, explosive up, 1s pause

// ❌ WRONG
"target_tempo": "slow"
"target_tempo": "3 seconds down"
```

**X = Explosive (as fast as possible)**

---

### Rule 6: Date Format

**MUST be ISO 8601:** `YYYY-MM-DD`

```json
// ✅ CORRECT
"workout_date": "2025-11-02"

// ❌ WRONG
"workout_date": "11/02/2025"
"workout_date": "Nov 2, 2025"
"workout_date": "02-11-2025"
```

---

## 🧪 Test Cases (Parser Must Pass These)

### Test Case 1: Plan Only

**Input Text:**
```
Back Squat: 5x5 @ 70%
```

**Expected Output (v3.0):**
```json
{
  "item_sequence": 1,
  "exercise_name": "Back Squat",
  "equipment_key": "barbell",
  "prescription": {
    "target_sets": 5,
    "target_reps": 5,
    "target_percentage_1rm": 0.70
  },
  "performed": null
}
```

---

### Test Case 2: Plan + Actual

**Input Text:**
```
Back Squat: 5x5 @ 100kg
Set 1: 5 @ 100kg RPE 7
Set 2: 5 @ 100kg RPE 8
Set 3: 4 @ 100kg RPE 9 (failed last rep)
```

**Expected Output (v3.0):**
```json
{
  "item_sequence": 1,
  "exercise_name": "Back Squat",
  "equipment_key": "barbell",
  "prescription": {
    "target_sets": 5,
    "target_reps": 5,
    "target_weight": {
      "value": 100,
      "unit": "kg"
    }
  },
  "performed": {
    "sets": [
      { "set_index": 1, "reps": 5, "load": { "value": 100, "unit": "kg" }, "rpe": 7 },
      { "set_index": 2, "reps": 5, "load": { "value": 100, "unit": "kg" }, "rpe": 8 },
      { "set_index": 3, "reps": 4, "load": { "value": 100, "unit": "kg" }, "rpe": 9, "notes": "failed last rep" }
    ]
  }
}
```

---

### Test Case 3: Rep Range

**Input Text:**
```
DB Bench Press: 3x8-12 @ moderate weight
```

**Expected Output (v3.0):**
```json
{
  "item_sequence": 1,
  "exercise_name": "Dumbbell Bench Press",
  "equipment_key": "dumbbell",
  "prescription": {
    "target_sets": 3,
    "target_reps_min": 8,
    "target_reps_max": 12
  },
  "performed": null
}
```

---

### Test Case 4: AMRAP

**Input Text:**
```
AMRAP 12 minutes:
- 10 Pull-ups
- 20 Push-ups
- 30 Air Squats

Result: 5 rounds + 15 reps
```

**Expected Output:**
```json
{
  "block_code": "METCON",
  "block_label": "A",
  "prescription": {
    "target_amrap_duration": {
      "value": 12,
      "unit": "min"
    },
    "target_rounds": null
  },
  "performed": {
    "completed": true,
    "actual_rounds_completed": 5,
    "actual_partial_reps": 15
  },
  "items": [
    {
      "item_sequence": 1,
      "exercise_name": "Pull-up",
      "prescription": { "target_reps": 10 },
      "performed": null
    },
    {
      "item_sequence": 2,
      "exercise_name": "Push-up",
      "prescription": { "target_reps": 20 },
      "performed": null
    },
    {
      "item_sequence": 3,
      "exercise_name": "Air Squat",
      "prescription": { "target_reps": 30 },
      "performed": null
    }
  ]
}
```

---

### Test Case 5: Circuit with Alternatives

**Input Text:**
```
3 rounds:
- 5 min Bike OR Row (s/r 22-24, damper 5-6)
```

**Expected Output:**
```json
{
  "item_sequence": 1,
  "circuit_config": {
    "rounds": 3,
    "type": "for_quality"
  },
  "exercise_options": [
    {
      "exercise_name": "Bike",
      "prescription": {
        "target_duration": {
          "value": 5,
          "unit": "min"
        }
      }
    },
    {
      "exercise_name": "Row",
      "prescription": {
        "target_duration": {
          "value": 5,
          "unit": "min"
        },
        "target_stroke_rate_min": 22,
        "target_stroke_rate_max": 24,
        "target_damper_min": 5,
        "target_damper_max": 6
      }
    }
  ],
  "performed": null
}
```

---

### Test Case 6: Buy-in + AMRAP + Buy-out

**Input Text:**
```
Buy-in: 400m Run

AMRAP 10 minutes:
- 5 Pull-ups
- 10 Push-ups
- 15 Air Squats

Buy-out: 400m Run

Result: Completed buy-in in 1:45, got 6 rounds + 10 reps, buy-out in 1:52
```

**Expected Output:**
```json
{
  "block_code": "METCON",
  "block_label": "A",
  "prescription": {
    "target_amrap_duration": {
      "value": 10,
      "unit": "min"
    },
    "buy_in": [
      {
        "item_sequence": 1,
        "exercise_name": "Run",
        "equipment_key": "bodyweight",
        "prescription": {
          "target_distance": {
            "value": 400,
            "unit": "m"
          }
        },
        "performed": null
      }
    ],
    "buy_out": [
      {
        "item_sequence": 1,
        "exercise_name": "Run",
        "equipment_key": "bodyweight",
        "prescription": {
          "target_distance": {
            "value": 400,
            "unit": "m"
          }
        },
        "performed": null
      }
    ]
  },
  "performed": {
    "completed": true,
    "actual_rounds_completed": 6,
    "actual_partial_reps": 10,
    "notes": "Buy-in: 1:45, Buy-out: 1:52"
  },
  "items": [
    {
      "item_sequence": 1,
      "exercise_name": "Pull-up",
      "equipment_key": "pullup_bar",
      "prescription": { "target_reps": 5 },
      "performed": null
    },
    {
      "item_sequence": 2,
      "exercise_name": "Push-up",
      "equipment_key": "bodyweight",
      "prescription": { "target_reps": 10 },
      "performed": null
    },
    {
      "item_sequence": 3,
      "exercise_name": "Air Squat",
      "equipment_key": "bodyweight",
      "prescription": { "target_reps": 15 },
      "performed": null
    }
  ]
}
```

---

### Test Case 7: Team Workout (Partners)

**Input Text:**
```
Partners - 30min AMRAP:
- 20 Thrusters (43kg)
- 20 Pull-ups
- 400m Run (together)

Team result: 10 rounds
My contribution: 5 rounds (did half)
```

**Expected Output:**
```json
{
  "block_code": "METCON",
  "block_label": "A",
  "prescription": {
    "target_amrap_duration": {
      "value": 30,
      "unit": "min"
    },
    "team_format": {
      "type": "partners",
      "scoring": "individual_contribution",
      "notes": "Partners split work, run together"
    }
  },
  "performed": {
    "completed": true,
    "actual_rounds_completed": 5,
    "notes": "Team total: 10 rounds, my contribution: 5 rounds"
  },
  "items": [
    {
      "item_sequence": 1,
      "exercise_name": "Thruster",
      "equipment_key": "barbell",
      "prescription": {
        "target_reps": 20,
        "target_weight": { "value": 43, "unit": "kg" }
      },
      "performed": null
    },
    {
      "item_sequence": 2,
      "exercise_name": "Pull-up",
      "equipment_key": "pullup_bar",
      "prescription": { "target_reps": 20 },
      "performed": null
    },
    {
      "item_sequence": 3,
      "exercise_name": "Run",
      "equipment_key": "bodyweight",
      "prescription": {
        "target_distance": {
          "value": 400,
          "unit": "m"
        },
        "notes": "Together"
      },
      "performed": null
    }
  ]
}
```

**CRITICAL:** Record `actual_rounds_completed: 5` (individual contribution), NOT 10 (team total)!

---

### Test Case 8: Buy-in Only

**Input Text:**
```
Buy-in: 800m Run

Then:
5 Rounds for Time:
- 10 Thrusters
- 10 Pull-ups

Time: 12:34
```

**Expected Output:**
```json
{
  "block_code": "METCON",
  "block_label": "A",
  "prescription": {
    "target_fortime_rounds": 5,
    "buy_in": [
      {
        "item_sequence": 1,
        "exercise_name": "Run",
        "equipment_key": "bodyweight",
        "prescription": {
          "target_distance": {
            "value": 800,
            "unit": "m"
          }
        },
        "performed": null
      }
    ]
  },
  "performed": {
    "completed": true,
    "actual_time": {
      "value": 754,
      "unit": "sec"
    }
  },
  "items": [
    {
      "item_sequence": 1,
      "exercise_name": "Thruster",
      "equipment_key": "barbell",
      "prescription": { "target_reps": 10 },
      "performed": null
    },
    {
      "item_sequence": 2,
      "exercise_name": "Pull-up",
      "equipment_key": "pullup_bar",
      "prescription": { "target_reps": 10 },
      "performed": null
    }
  ]
}
```

---

## 🚨 Parser Errors to Avoid

### Error 1: Mixing Prescription and Performance

```json
// ❌ WRONG
{
  "target_reps": 5,
  "actual_reps": 4,
  "notes": "Failed last rep"
}

// ✅ CORRECT
{
  "prescription": { "target_reps": 5 },
  "performed": { "actual_reps": 4, "notes": "Failed last rep" }
}
```

---

### Error 2: String Numbers

```json
// ❌ WRONG
{ "target_reps": "5" }

// ✅ CORRECT
{ "target_reps": 5 }
```

---

### Error 3: Range as String

```json
// ❌ WRONG
{ "target_reps": "8-12" }

// ✅ CORRECT
{ "target_reps_min": 8, "target_reps_max": 12 }
```

---

### Error 4: Hallucinated Performance

```json
// ❌ WRONG - Text only says "5x5 planned"
{
  "prescription": { "target_sets": 5, "target_reps": 5 },
  "performed": { "actual_sets": 5, "actual_reps": 5 }  // Hallucinated!
}

// ✅ CORRECT
{
  "prescription": { "target_sets": 5, "target_reps": 5 },
  "performed": null  // Unknown if they did it
}
```

---

### Error 5: Non-standard Block Code

```json
// ❌ WRONG
{ "block_code": "strength_work" }

// ✅ CORRECT
{ "block_code": "STR" }
```

---

### Error 6: Recording Team Total Instead of Individual Contribution

```json
// ❌ WRONG - Recording team's combined result
{
  "prescription": {
    "team_format": {
      "type": "partners",
      "scoring": "individual_contribution"
    }
  },
  "performed": {
    "actual_rounds_completed": 12  // This is the TEAM total, not athlete's personal!
  }
}

// ✅ CORRECT - Recording athlete's personal contribution
{
  "prescription": {
    "team_format": {
      "type": "partners",
      "scoring": "individual_contribution"
    }
  },
  "performed": {
    "actual_rounds_completed": 6,  // Athlete did 6 rounds personally
    "notes": "Team total: 12 rounds"
  }
}
```

**CRITICAL:** When `scoring: "individual_contribution"`, NEVER record team totals in performed fields. Only record what THIS athlete did!

---

## 📚 Related Documents

- [BLOCK_TYPES_REFERENCE.md](./BLOCK_TYPES_REFERENCE.md) - Complete list of 17 block codes
- [AI_PROMPTS.md](../guides/AI_PROMPTS.md) - Parser agent instructions
- [PARSER_WORKFLOW.md](../guides/PARSER_WORKFLOW.md) - Full 4-stage pipeline
- [VALIDATION_SYSTEM_SUMMARY.md](../VALIDATION_SYSTEM_SUMMARY.md) - Validation functions

---

## 🔒 Schema Version History

- **v3.2.0** (Jan 10, 2026): Unified measurement structure - Duration and Distance
  - **Breaking Changes:**
    - Duration fields MUST use `{value, unit}` structure:
      - `target_duration_sec` → `target_duration: {value, unit: "sec"}`
      - `target_duration_min` → `target_duration: {value, unit: "min"}`
      - `target_amrap_duration_sec` → `target_amrap_duration: {value, unit}`
      - `target_fortime_cap_sec` → `target_fortime_cap: {value, unit}`
      - `actual_duration_sec` → `actual_duration: {value, unit}`
      - `actual_time_sec` → `actual_time: {value, unit}`
    - Distance fields MUST use `{value, unit}` structure:
      - `target_meters` → `target_distance: {value, unit: "m"}`
      - `actual_meters` → `actual_distance: {value, unit: "m"}`
    - Supported units: Duration: `"sec"`, `"min"`, `"hours"` | Distance: `"m"`, `"km"`, `"yards"`, `"miles"`
  - **Rationale:** Achieve consistency across ALL measurement types (weight, duration, distance)
  - **Migration:** All golden set files updated (19 files)
- **v3.1.0** (Jan 10, 2026): Buy-in/Buy-out + Team format support
  - **New Features:**
    - `buy_in?: BlockItem[]` - Exercises before main work
    - `buy_out?: BlockItem[]` - Exercises after main work
    - `team_format` - Support for partner/team workouts with proper individual attribution
  - **Critical Rules:**
    - Can have buy_in only, buy_out only, or both
    - Team workouts: MUST record individual contribution, NOT team total (when scoring is "individual_contribution")
  - **Migration:** No breaking changes, backward compatible
- **v3.0.0** (Jan 10, 2026): Field ordering standardization + scalable weight structure
  - **Breaking Changes:**
    - Field order MUST be: item_sequence → exercise_name → equipment_key → prescription → performed
    - Weight fields MUST use `{value, unit}` structure (no more `*_kg` or `*_lbs` field names)
    - Added mandatory `equipment_key` field to BlockItem
  - **Migration:** All golden set files updated (19 files)
- **v2.0.0** (Jan 10, 2026): The Constitution - Canonical schema locked
- **v1.0.0** (Jan 7, 2026): Initial schema from golden set examples

---

**⚖️ THE LAW:** This schema is IMMUTABLE. Any deviation is a bug, not a feature request.
