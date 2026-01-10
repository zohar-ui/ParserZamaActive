# 📜 The Constitution: Canonical JSON Schema

**Version:** 3.0.0  
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

### Principle #2: Atomic Types & Scalable Structures (UPDATED in v3.0)
**Numbers are numbers. Strings are strings. Units are explicit.**

```json
// ✅ CORRECT - Structured values with units (v3.0)
{
  "target_reps": 5,                    // number
  "target_weight": {                   // object with value + unit
    "value": 100.5,
    "unit": "kg"
  },
  "target_duration_sec": 45            // number (seconds)
}

// ❌ WRONG - Hardcoded units in field names (v2.0 legacy)
{
  "target_reps": "5",
  "target_weight_kg": "100kg",         // Unit in field name = not scalable
  "target_duration_sec": "45 seconds"
}
```

**Rule:** 
- If the original text says "5", parse it to the number `5`, not the string `"5"`.
- Weight/load fields MUST use `{value, unit}` structure (v3.0+).
- Supported units: `"kg"`, `"lbs"`, `"g"` (grams for resistance bands).

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
  target_duration_sec?: number;   // Total time for the block (in seconds)
  target_rest_sec?: number;       // Rest between sets (in seconds)
  target_rest_min?: number;       // Rest between sets (in minutes)
  target_tempo?: string;          // "3-0-2-0" format (eccentric-pause-concentric-pause)
  notes?: string;                 // Any additional prescription notes
  
  // AMRAP specific
  target_amrap_duration_sec?: number;
  
  // For Time specific
  target_fortime_rounds?: number;
  target_fortime_cap_sec?: number;
}
```

**Field Rules:**
- All fields are optional (some blocks have minimal prescription).
- Duration fields: ALWAYS in seconds (convert minutes to seconds: 5min = 300sec).
- Rest: Can be in seconds OR minutes (use the unit from original text).
- Tempo: String format "eccentric-bottom pause-concentric-top pause" (e.g., "3-0-1-0").

---

### Block Performed Object

```typescript
interface BlockPerformed {
  completed: boolean;             // Did they finish the block?
  did_complete?: boolean;         // Alias for 'completed' (legacy)
  notes?: string;                 // Free text notes about performance
  
  actual_sets?: number;           // How many sets done
  actual_rounds?: number;         // For circuits
  actual_duration_sec?: number;   // Total time taken (in seconds)
  actual_weight_kg?: number;      // If the whole block used same weight
  actual_reps?: number;           // If the whole block used same reps
  actual_sets_per_side?: number;  // For unilateral movements
  
  // For AMRAP
  actual_rounds_completed?: number;
  actual_partial_reps?: number;   // Reps into incomplete round
  
  // For Time
  actual_time_sec?: number;       // Time to complete
}
```

**Field Rules:**
- `completed`: REQUIRED if performed object exists.
- Duration: ALWAYS in seconds.
- Block-level fields: Only use if ALL items in block share the same value.

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
  
  // Duration
  target_duration_sec?: number;
  target_duration_min?: number;     // Minutes (if text uses minutes explicitly)
  
  // Intensity
  target_rpe?: number;              // 1-10 scale
  target_rpe_min?: number;
  target_rpe_max?: number;
  target_rir?: number;              // Reps in reserve (0-5)
  
  // Tempo
  target_tempo?: string;            // "3-0-2-0" format
  
  // Equipment
  equipment?: string;               // "barbell", "dumbbell", "kettlebell", etc.
  position?: string;                // "half_kneeling", "single_leg", etc.
  
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
  target_meters?: number;
  
  // Reps with breakdown
  target_reps_forward?: number;     // "8 forward, 8 backward"
  target_reps_backward?: number;
  
  // Notes
  notes?: string;
}
```

**Field Rules:**
- Ranges: Use `_min` and `_max` suffixes, never string ranges.
- Weight: Prefer kg. Convert lbs to kg if needed (1 lb = 0.453592 kg).
- Percentage: Decimal format (70% = 0.70, not 70).
- RPE: 1-10 scale (can be decimal like 7.5).
- RIR: Typically 0-5 (0 = failure, 5 = very easy).
- Tempo: Always "eccentric-pause-concentric-pause" (e.g., "3-0-2-0", "4-1-X-1").

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
  actual_duration_sec?: number;
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
- Duration: ALWAYS in seconds.
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
  duration_sec?: number;
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

## 🔴 Critical Validation Rules

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
    "target_amrap_duration_sec": 720,
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
        "target_duration_sec": 300
      }
    },
    {
      "exercise_name": "Row",
      "prescription": {
        "target_duration_sec": 300,
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

## 📚 Related Documents

- [BLOCK_TYPES_REFERENCE.md](./BLOCK_TYPES_REFERENCE.md) - Complete list of 17 block codes
- [AI_PROMPTS.md](../guides/AI_PROMPTS.md) - Parser agent instructions
- [PARSER_WORKFLOW.md](../guides/PARSER_WORKFLOW.md) - Full 4-stage pipeline
- [VALIDATION_SYSTEM_SUMMARY.md](../VALIDATION_SYSTEM_SUMMARY.md) - Validation functions

---

## 🔒 Schema Version History

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
