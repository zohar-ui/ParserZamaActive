# MCP Integration in Parsing Workflow

**Purpose:** How to use MCP (Model Context Protocol) tools during the 4-stage workout parsing process.

**Last Updated:** 2026-01-11

---

## Overview

The ZAMM parser follows a 4-stage workflow. MCP replaces manual bash/psql commands with natural language queries at each stage.

### The 4 Stages

```
┌─────────────────────────────────────────────────────────────────┐
│  Stage 1: Context & Ingestion                                   │
│  - Import raw text                                              │
│  - Identify athlete                                             │
│  - Get active ruleset                                           │
│  MCP Tools: execute_sql, list_tables                            │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  Stage 2: Parsing Agent                                         │
│  - Separate prescription from performance                       │
│  - Lookup exercises in catalog                                  │
│  - Lookup equipment in catalog                                  │
│  - Normalize block types                                        │
│  MCP Tools: execute_sql (catalog queries)                       │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  Stage 3: Validation & Normalization                            │
│  - Validate JSON structure                                      │
│  - Check exercise names exist                                   │
│  - Check equipment exists                                       │
│  - Validate value ranges (weights, reps, etc)                   │
│  MCP Tools: execute_sql (validation functions)                  │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  Stage 4: Atomic Commit                                         │
│  - Call commit_full_workout_v3() stored procedure               │
│  - Verify commit success                                        │
│  MCP Tools: execute_sql (procedure call)                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Stage 1: Context & Ingestion

### Goal
Import raw workout text, identify athlete, get parser configuration.

### Without MCP (Old Way)
```bash
# Check athlete exists
./scripts/utils/inspect_db.sh lib_athletes

# Get active ruleset
psql "$SUPABASE_DB_URL" -c "SELECT * FROM zamm.lib_parser_rulesets WHERE is_active = true;"

# Insert raw text
psql "$SUPABASE_DB_URL" -c "INSERT INTO zamm.stg_imports ..."
```

### With MCP (New Way)
```
AI Agent receives workout text from user.

STEP 1: "Find athlete named 'Tomer' in the database"
→ MCP executes: SELECT * FROM zamm.lib_athletes WHERE full_name ILIKE '%Tomer%'

STEP 2: "Get the active parser ruleset"
→ MCP executes: SELECT * FROM zamm.cfg_parser_rules WHERE is_active = true

STEP 3: "Import this raw text into stg_imports"
→ MCP executes: INSERT INTO zamm.stg_imports (source, athlete_id, raw_text)
                VALUES ('sms', '<athlete_id>', '<workout_text>')
```

### MCP Query Examples

**Check if athlete exists:**
```sql
SELECT athlete_id, full_name, email
FROM zamm.lib_athletes
WHERE full_name ILIKE '%<name>%'
  OR email = '<email>'
LIMIT 5;
```

**Get active ruleset:**
```sql
SELECT ruleset_id, version, name, is_active
FROM zamm.cfg_parser_rules
WHERE is_active = true
LIMIT 1;
```

**Import raw text (with idempotency):**
```sql
SELECT zamm.import_raw_text_idempotent(
    p_source := 'sms',
    p_source_ref := NULL,
    p_athlete_id := '<athlete_uuid>',
    p_raw_text := '<workout_text>',
    p_tags := ARRAY['manual_entry']
);
```

---

## Stage 2: Parsing Agent

### Goal
Parse workout text into structured JSON, separating prescription from performance.

### Catalog Lookups During Parsing

**1. Exercise Name Normalization**

**Raw Text:**
```
"Deadlift: 3x5 @ 140kg"
```

**MCP Query:**
```sql
-- Check if "Deadlift" exists in catalog
SELECT exercise_key, display_name, category
FROM zamm.lib_exercise_catalog
WHERE display_name ILIKE '%deadlift%'
   OR exercise_key = 'deadlift'
LIMIT 1;
```

**Result:**
```json
{
  "exercise_key": "conventional_deadlift",
  "display_name": "Conventional Deadlift",
  "category": "strength"
}
```

**Parsed JSON (use exercise_key):**
```json
{
  "exercise_name": "Conventional Deadlift",
  "exercise_key": "conventional_deadlift",
  "prescription_data": {
    "target_sets": 3,
    "target_reps": 5,
    "target_weight": {"value": 140, "unit": "kg"}
  }
}
```

**2. Equipment Lookup**

**Raw Text:**
```
"DB Bench Press: 4x8 @ 30kg"
```

**MCP Query:**
```sql
-- Resolve "DB" alias to equipment_key
SELECT eq.equipment_key, eq.display_name
FROM zamm.lib_equipment_aliases ea
JOIN zamm.lib_equipment_catalog eq ON ea.equipment_key = eq.equipment_key
WHERE ea.alias ILIKE 'db'
LIMIT 1;
```

**Result:**
```json
{
  "equipment_key": "dumbbell",
  "display_name": "Dumbbell"
}
```

**Parsed JSON:**
```json
{
  "exercise_name": "Bench Press",
  "exercise_key": "dumbbell_bench_press",
  "equipment_key": "dumbbell",
  "equipment_primary": "dumbbell",
  "prescription_data": {
    "target_sets": 4,
    "target_reps": 8,
    "target_weight": {"value": 30, "unit": "kg"}
  }
}
```

**3. Block Type Normalization**

**Raw Text:**
```
"WU: Mobility work"
"כוח: Squats 5x5"
"METCON: Fran"
```

**MCP Query:**
```sql
-- Normalize block codes via aliases
SELECT bt.block_code, bt.block_type, bt.category
FROM zamm.lib_block_aliases ba
JOIN zamm.lib_block_types bt ON ba.block_code = bt.block_code
WHERE ba.alias IN ('WU', 'כוח', 'METCON');
```

**Result:**
```json
[
  {"alias": "WU", "block_code": "WU", "block_type": "warmup", "category": "preparation"},
  {"alias": "כוח", "block_code": "STR", "block_type": "strength", "category": "strength"},
  {"alias": "METCON", "block_code": "METCON", "block_type": "metabolic_conditioning", "category": "conditioning"}
]
```

### Complete Parsing Example

**Input Text:**
```
Athlete: Tomer
Date: 2025-11-02

WU: Mobility 10min

כוח:
Deadlift: 3x5 @ 140kg
- Set 1: 5 reps easy
- Set 2: 5 reps good
- Set 3: 4 reps hard (back rounding)
```

**AI Agent Process with MCP:**

```
STEP 1: Find athlete "Tomer"
→ MCP: SELECT athlete_id FROM zamm.lib_athletes WHERE full_name ILIKE '%tomer%'
→ Result: athlete_id = "uuid-123"

STEP 2: Check if "Deadlift" is in catalog
→ MCP: SELECT exercise_key FROM zamm.lib_exercise_catalog WHERE display_name ILIKE '%deadlift%'
→ Result: exercise_key = "conventional_deadlift"

STEP 3: Normalize block code "כוח"
→ MCP: SELECT block_code FROM zamm.lib_block_aliases WHERE alias = 'כוח'
→ Result: block_code = "STR"

STEP 4: Generate structured JSON
```

**Output JSON:**
```json
{
  "athlete_id": "uuid-123",
  "workout_date": "2025-11-02",
  "sessions": [
    {
      "sessionInfo": {
        "date": "2025-11-02"
      },
      "blocks": [
        {
          "block_code": "WU",
          "block_type": "warmup",
          "name": "Mobility",
          "prescription": {
            "target_duration": {"value": 10, "unit": "min"}
          },
          "performed": null
        },
        {
          "block_code": "STR",
          "block_type": "strength",
          "name": "Deadlift",
          "items": [
            {
              "exercise_name": "Conventional Deadlift",
              "exercise_key": "conventional_deadlift",
              "equipment_key": "barbell",
              "prescription_data": {
                "target_sets": 3,
                "target_reps": 5,
                "target_weight": {"value": 140, "unit": "kg"}
              },
              "performed_data": {
                "sets": [
                  {"set_index": 1, "reps": 5, "load": {"value": 140, "unit": "kg"}, "notes": "easy"},
                  {"set_index": 2, "reps": 5, "load": {"value": 140, "unit": "kg"}, "notes": "good"},
                  {"set_index": 3, "reps": 4, "load": {"value": 140, "unit": "kg"}, "notes": "hard - back rounding"}
                ]
              }
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Stage 3: Validation & Normalization

### Goal
Validate parsed JSON against schema, catalogs, and business rules.

### Validation Queries with MCP

**1. Check Exercise Exists**
```sql
-- Validate all exercises in parsed JSON
SELECT exercise_key, display_name
FROM zamm.lib_exercise_catalog
WHERE exercise_key IN ('conventional_deadlift', 'back_squat', 'bench_press');
```

**2. Check Equipment Exists**
```sql
-- Validate equipment keys
SELECT equipment_key, display_name
FROM zamm.lib_equipment_catalog
WHERE equipment_key IN ('barbell', 'dumbbell', 'kettlebell');
```

**3. Validate Block Types**
```sql
-- Verify block codes are valid
SELECT block_code, block_type, category
FROM zamm.lib_block_types
WHERE block_code IN ('STR', 'WU', 'METCON', 'PWR')
  AND is_active = true;
```

**4. Value Range Validation**
```sql
-- Use built-in validation function
SELECT zamm.validate_workout_draft('<draft_json>'::jsonb);
```

### Full Validation Example

**AI Agent asks MCP:**
```
"Validate this parsed workout JSON against the database catalogs"
```

**MCP executes:**
```sql
-- Run comprehensive validation
SELECT * FROM zamm.validate_workout_draft(
  '{
    "athlete_id": "uuid-123",
    "sessions": [{
      "blocks": [{
        "block_code": "STR",
        "items": [{
          "exercise_key": "conventional_deadlift",
          "equipment_key": "barbell",
          "prescription_data": {
            "target_sets": 3,
            "target_reps": 5,
            "target_weight": {"value": 140, "unit": "kg"}
          }
        }]
      }]
    }]
  }'::jsonb
);
```

**Validation Response:**
```json
{
  "is_valid": true,
  "errors": [],
  "warnings": [
    "Set 3 had fewer reps (4) than target (5)"
  ]
}
```

---

## Stage 4: Atomic Commit

### Goal
Save validated workout to database using stored procedure.

### Commit with MCP

**AI Agent asks:**
```
"Commit this validated workout JSON to the database"
```

**MCP executes:**
```sql
SELECT zamm.commit_full_workout_v3(
  p_import_id := '<import_uuid>',
  p_draft_id := '<draft_uuid>',
  p_ruleset_id := '<ruleset_uuid>',
  p_athlete_id := '<athlete_uuid>',
  p_normalized_json := '<validated_json>'::jsonb
);
```

**Success Response:**
```json
{
  "workout_id": "new-workout-uuid",
  "status": "committed",
  "sessions_created": 1,
  "blocks_created": 2,
  "items_created": 1,
  "sets_created": 3
}
```

**Verify Commit:**
```sql
-- Check workout was saved
SELECT w.workout_id, w.workout_date, w.status,
       (SELECT COUNT(*) FROM zamm.workout_sessions WHERE workout_id = w.workout_id) as sessions,
       (SELECT COUNT(*) FROM zamm.workout_blocks WHERE session_id IN
         (SELECT session_id FROM zamm.workout_sessions WHERE workout_id = w.workout_id)) as blocks
FROM zamm.workout_main w
WHERE w.workout_id = '<new-workout-uuid>';
```

---

## Complete Parsing Session Example

**User Input:**
```
Parse this workout for Tomer:

Date: 2025-11-02

WU: Mobility 10min

Strength:
Deadlift: 3x5 @ 140kg
- Set 1: 5 reps easy
- Set 2: 5 reps good
- Set 3: 4 reps hard
```

**AI Agent Conversation with MCP:**

**Agent:** "Find athlete Tomer in the database"

**MCP Query:**
```sql
SELECT athlete_id, full_name, email
FROM zamm.lib_athletes
WHERE full_name ILIKE '%tomer%'
LIMIT 1;
```

**MCP Response:**
```json
{"athlete_id": "abc-123", "full_name": "Tomer Cohen"}
```

---

**Agent:** "Get active parser ruleset"

**MCP Query:**
```sql
SELECT ruleset_id, version
FROM zamm.cfg_parser_rules
WHERE is_active = true
LIMIT 1;
```

**MCP Response:**
```json
{"ruleset_id": "xyz-789", "version": "1.2"}
```

---

**Agent:** "Check if 'Deadlift' exercise exists in catalog"

**MCP Query:**
```sql
SELECT exercise_key, display_name, category
FROM zamm.lib_exercise_catalog
WHERE display_name ILIKE '%deadlift%'
LIMIT 1;
```

**MCP Response:**
```json
{
  "exercise_key": "conventional_deadlift",
  "display_name": "Conventional Deadlift",
  "category": "strength"
}
```

---

**Agent:** "Normalize block code 'Strength' to standard code"

**MCP Query:**
```sql
SELECT bt.block_code, bt.block_type
FROM zamm.lib_block_aliases ba
JOIN zamm.lib_block_types bt ON ba.block_code = bt.block_code
WHERE ba.alias ILIKE 'strength'
LIMIT 1;
```

**MCP Response:**
```json
{"block_code": "STR", "block_type": "strength"}
```

---

**Agent generates structured JSON, then:**

**Agent:** "Validate this parsed workout JSON"

**MCP Query:**
```sql
SELECT zamm.validate_workout_draft('<json>'::jsonb);
```

**MCP Response:**
```json
{
  "is_valid": true,
  "errors": [],
  "warnings": ["Set 3: actual_reps (4) < target_reps (5)"]
}
```

---

**Agent:** "Commit the validated workout to database"

**MCP Query:**
```sql
SELECT zamm.commit_full_workout_v3(
  NULL, NULL, 'xyz-789', 'abc-123',
  '<validated_json>'::jsonb
);
```

**MCP Response:**
```json
{
  "workout_id": "new-workout-123",
  "message": "Workout committed successfully"
}
```

---

## Practical Tips

### 1. Cache Catalog Lookups
For common exercises/equipment, cache lookups to avoid repeated queries:

```
First lookup: Query database via MCP
Subsequent uses: Use cached result
Session end: Clear cache
```

### 2. Batch Validation
Validate multiple items in one query:

```sql
-- Check multiple exercises at once
SELECT exercise_key, display_name
FROM zamm.lib_exercise_catalog
WHERE exercise_key = ANY(ARRAY[
  'conventional_deadlift',
  'back_squat',
  'bench_press'
]);
```

### 3. Handle Missing Entries Gracefully

```sql
-- Check if exercise exists, suggest alternatives
SELECT
  exercise_key,
  display_name,
  similarity(display_name, 'deadlift') as match_score
FROM zamm.lib_exercise_catalog
WHERE display_name ILIKE '%deadlift%'
ORDER BY match_score DESC
LIMIT 5;
```

### 4. Use Fuzzy Matching for Names

```sql
-- Find athlete even with typos
SELECT athlete_id, full_name
FROM zamm.lib_athletes
WHERE full_name ILIKE '%tom%'  -- Matches "Tomer", "Tommy", "Tom"
   OR email ILIKE '%tom%'
LIMIT 5;
```

---

## Advantages Over Bash Scripts

| Feature | MCP | Bash Scripts |
|---------|-----|--------------|
| **Speed** | Instant | Shell overhead |
| **Context** | Full conversation history | Stateless |
| **Error Handling** | Automatic retry/suggestions | Manual |
| **Natural Language** | "Find athlete Tomer" | Complex psql command |
| **Caching** | Built-in | Manual |
| **Type Safety** | Schema-aware | Raw SQL strings |

---

## Related Documentation

- [AI_PROMPTS.md](AI_PROMPTS.md) - Parser prompt templates
- [CANONICAL_JSON_SCHEMA.md](../reference/CANONICAL_JSON_SCHEMA.md) - Output schema
- [MCP_SETUP.md](../MCP_SETUP.md) - MCP configuration
- [ARCHITECTURE.md](../architecture/ARCHITECTURE.md) - System design

---

**Last Updated:** 2026-01-11
**Maintained By:** AI Development Team
