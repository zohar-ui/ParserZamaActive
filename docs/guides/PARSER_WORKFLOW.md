# Parser Workflow Guide

**Complete guide to the ZAMM Workout Parser data flow and processing pipeline**

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [The 4-Stage Pipeline](#the-4-stage-pipeline)
3. [Tables Involved](#tables-involved)
4. [AI Tools Available](#ai-tools-available)
5. [Detailed Stage Breakdown](#detailed-stage-breakdown)
6. [Example Workflow](#example-workflow)
7. [Error Handling](#error-handling)
8. [Best Practices](#best-practices)

---

## 🎯 Overview

The ZAMM Parser transforms **raw workout text** into **structured relational data** through a 4-stage pipeline designed for data quality, traceability, and flexibility.

### Core Principle: Prescription vs Performance

Every parsed entity separates:
- **Prescription**: What was PLANNED ("3x5 @ 100kg")
- **Performance**: What actually HAPPENED ("completed 3x4, 5 reps on last set")

This separation is **critical** and must be maintained throughout all stages.

### Pipeline Architecture

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│   Stage 1:      │      │   Stage 2:      │      │   Stage 3:      │      │   Stage 4:      │
│   INGESTION     │ ───> │   PARSING       │ ───> │   VALIDATION    │ ───> │   COMMIT        │
│                 │      │                 │      │                 │      │                 │
│  Raw Text       │      │  Draft JSON     │      │  Normalized     │      │  Relational     │
│  (imports)      │      │  (parse_drafts) │      │  JSON           │      │  Tables         │
└─────────────────┘      └─────────────────┘      └─────────────────┘      └─────────────────┘
        ↓                        ↓                        ↓                        ↓
    Immutable             AI Generated           Human Reviewed          Final Data Store
    Audit Trail           First Pass             Quality Control         Production Ready
```

---

## 🔄 The 4-Stage Pipeline

### Stage 1: Ingestion
**Input**: Raw text workout log  
**Output**: Stored in `stg_imports`  
**Purpose**: Create immutable audit trail

**Key Points:**
- Original text is **never modified**
- Each import gets unique UUID
- Timestamp recorded
- Athlete linked via `athlete_id`

### Stage 2: Parsing
**Input**: Text from `stg_imports`  
**Output**: Draft JSON in `stg_parse_drafts`  
**Purpose**: AI converts text to structured JSON

**Key Points:**
- AI agent reads text, outputs JSON
- Uses `lib_parser_rulesets` for parsing rules
- Calls AI tools for validation (athletes, exercises, equipment)
- Draft can be edited via `stg_draft_edits` table
- Maintains link to original import

### Stage 3: Validation
**Input**: Draft JSON from `stg_parse_drafts`  
**Output**: Validation report in `log_validation_reports`  
**Purpose**: Quality control before commit

**Key Points:**
- Checks data completeness
- Validates foreign key references
- Normalizes exercise names via catalog
- Normalizes block types (17 standard types)
- Reports errors for human review

### Stage 4: Commit
**Input**: Validated JSON  
**Output**: Relational data in `workout_*` tables  
**Purpose**: Final storage in production schema

**Key Points:**
- Uses stored procedure `commit_full_workout_v3()`
- **Atomic transaction** (all-or-nothing)
- Inserts into 5 related tables in correct order
- Creates UUIDs for all workout entities
- Maintains referential integrity

---

## 🗄️ Tables Involved

### Staging Tables (Temporary Data)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| **stg_imports** | Raw text storage | `import_id`, `athlete_id`, `raw_text` |
| **stg_parse_drafts** | AI-generated JSON | `draft_id`, `import_id`, `parsed_draft` |
| **stg_draft_edits** | Manual corrections | `edit_id`, `draft_id`, `edited_draft` |

### Validation Tables (Quality Control)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| **log_validation_reports** | Error/warning logs | `report_id`, `draft_id`, `validation_status` |

### Reference Tables (Lookups)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| **lib_athletes** | Athlete master data | `athlete_natural_id`, `full_name` |
| **lib_parser_rulesets** | Parsing configurations | `ruleset_id`, `version`, `is_active` |
| **lib_exercise_catalog** | Canonical exercise names | `exercise_key`, `exercise_name` |
| **lib_exercise_aliases** | Alternative exercise names | `alias`, `exercise_key` |
| **lib_equipment_catalog** | Equipment types | `equipment_key`, `equipment_name` |
| **lib_equipment_aliases** | Alternative equipment names | `alias`, `equipment_key` |
| **lib_block_types** | 17 standard block types | `block_code`, `block_category` |
| **lib_block_aliases** | Block type variations | `alias`, `block_code` |

### Production Tables (Final Data)

| Table | Purpose | Hierarchy Level |
|-------|---------|-----------------|
| **workout_main** | Workout header | Level 1 (Root) |
| **workout_sessions** | AM/PM sessions | Level 2 (Child of main) |
| **workout_blocks** | Training blocks (A, B, C) | Level 3 (Child of session) |
| **workout_items** | Individual exercises | Level 4 (Child of block) |
| **workout_item_set_results** | Individual sets | Level 5 (Child of item) |

---

## 🛠️ AI Tools Available

The AI parser can call these SQL functions during parsing:

### 1. `check_athlete_exists(full_name TEXT)`
**Purpose**: Verify athlete exists in database  
**Returns**: `athlete_id`, `full_name`, `current_weight_kg`  
**Example**:
```sql
SELECT * FROM zamm.check_athlete_exists('Jonathan Benamou');
-- Returns: athlete_id, full_name, weight
```

### 2. `check_equipment_exists(equipment_name TEXT)`
**Purpose**: Validate equipment and get canonical key  
**Returns**: `equipment_key`, `equipment_name`  
**Example**:
```sql
SELECT * FROM zamm.check_equipment_exists('barbell');
-- Returns: 'barbell', 'Barbell'
```

### 3. `get_active_ruleset()`
**Purpose**: Get current parsing rules  
**Returns**: Full ruleset configuration (JSON)  
**Example**:
```sql
SELECT * FROM zamm.get_active_ruleset();
-- Returns: version, units_catalog, parser_rules
```

### 4. `get_athlete_context(athlete_id UUID)`
**Purpose**: Get athlete details + recent workouts  
**Returns**: Athlete info + last 10 workouts  
**Example**:
```sql
SELECT * FROM zamm.get_athlete_context('uuid-here');
-- Returns: athlete data + workout history
```

### 5. `normalize_block_type(input_type TEXT)`
**Purpose**: Convert any block name to standard code  
**Returns**: `block_code`, `block_category`  
**Example**:
```sql
SELECT * FROM zamm.normalize_block_type('חימום');
-- Returns: 'WU', 'PREPARATION'
```

---

## 📝 Detailed Stage Breakdown

### Stage 1: Ingestion (INSERT)

```sql
-- User submits workout text
INSERT INTO zamm.stg_imports (
    athlete_id,
    raw_text,
    import_date,
    import_source
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000', -- athlete UUID
    '📅 2025-01-05
    
    Block A - Strength
    Back Squat: 3x5 @ 100kg
    Bench Press: 3x8 @ 80kg',
    NOW(),
    'manual_entry'
)
RETURNING import_id;
```

**Output**: `import_id` (UUID)

---

### Stage 2: Parsing (AI Processing)

#### 2.1: AI Agent Initialization

The AI agent loads context:

```sql
-- Get active parsing rules
SELECT * FROM zamm.get_active_ruleset();

-- Verify athlete
SELECT * FROM zamm.check_athlete_exists('Jonathan Benamou');

-- Get athlete history
SELECT * FROM zamm.get_athlete_context(athlete_id);
```

#### 2.2: AI Generates Draft JSON

The AI reads raw text and produces:

```json
{
  "workout_date": "2025-01-05",
  "athlete_id": "550e8400-e29b-41d4-a716-446655440000",
  "sessions": [
    {
      "session_code": "AM",
      "blocks": [
        {
          "block_code": "STR",
          "block_label": "A",
          "items": [
            {
              "exercise_key": "back_squat",
              "prescription": {
                "target_sets": 3,
                "target_reps": 5,
                "target_load_kg": 100
              },
              "performed": {
                "actual_sets": 3,
                "actual_reps": [5, 5, 5],
                "actual_loads_kg": [100, 100, 100]
              }
            }
          ]
        }
      ]
    }
  ]
}
```

#### 2.3: Store Draft

```sql
INSERT INTO zamm.stg_parse_drafts (
    import_id,
    ruleset_id,
    parser_version,
    stage,
    parsed_draft
) VALUES (
    import_id, -- from stage 1
    (SELECT ruleset_id FROM zamm.lib_parser_rulesets WHERE is_active = true),
    'v1.0.0',
    'draft',
    jsonb_draft -- the JSON above
)
RETURNING draft_id;
```

---

### Stage 3: Validation (Quality Control)

#### 3.1: Check Data Completeness

```sql
-- Validate required fields exist
SELECT 
    draft_id,
    parsed_draft->>'workout_date' IS NOT NULL as has_date,
    parsed_draft->>'athlete_id' IS NOT NULL as has_athlete,
    jsonb_array_length(parsed_draft->'sessions') > 0 as has_sessions
FROM zamm.stg_parse_drafts
WHERE draft_id = 'uuid-here';
```

#### 3.2: Normalize Exercise Names

```sql
-- For each exercise in JSON, validate against catalog
SELECT exercise_key 
FROM zamm.lib_exercise_catalog
WHERE exercise_key = 'back_squat';

-- Check aliases
SELECT exercise_key
FROM zamm.lib_exercise_aliases
WHERE LOWER(alias) = LOWER('back squat');
```

#### 3.3: Normalize Block Types

```sql
-- Ensure block types are canonical
SELECT * FROM zamm.normalize_block_type('Strength');
-- Returns: 'STR', 'STRENGTH'
```

#### 3.4: Log Validation Report

```sql
INSERT INTO zamm.log_validation_reports (
    draft_id,
    validation_status,
    error_details,
    validated_at
) VALUES (
    draft_id,
    'pass', -- or 'fail' / 'warning'
    NULL, -- or JSONB of errors
    NOW()
);
```

---

### Stage 4: Commit (Production Storage)

#### 4.1: Call Stored Procedure

```sql
SELECT zamm.commit_full_workout_v3(
    import_id := 'uuid-from-stage-1',
    draft_id := 'uuid-from-stage-2',
    ruleset_id := 'uuid-from-rulesets',
    athlete_id := 'uuid-of-athlete',
    normalized_json := validated_json_blob
);
```

#### 4.2: Atomic Transaction (Inside Procedure)

The stored procedure performs these operations **in one transaction**:

```sql
BEGIN TRANSACTION;

-- 1. Insert workout header
INSERT INTO zamm.workout_main (
    workout_id, athlete_id, workout_date, workout_title
) VALUES (...);

-- 2. Insert sessions
INSERT INTO zamm.workout_sessions (
    session_id, workout_id, session_code
) VALUES (...);

-- 3. Insert blocks
INSERT INTO zamm.workout_blocks (
    block_id, session_id, block_code, block_label
) VALUES (...);

-- 4. Insert exercises
INSERT INTO zamm.workout_items (
    item_id, block_id, exercise_key, prescription, performed
) VALUES (...);

-- 5. Insert set results
INSERT INTO zamm.workout_item_set_results (
    set_result_id, item_id, set_number, reps, load_kg
) VALUES (...);

COMMIT;
```

**If ANY step fails, entire transaction rolls back!**

---

## 💡 Example Workflow

### Complete End-to-End Example

**Input Text**:
```
📅 2025-01-05 AM Session

Block A - חימום (Warm-up)
Bike: 5min easy

Block B - Strength  
Back Squat
- Set 1: 5 reps @ 80kg
- Set 2: 5 reps @ 90kg  
- Set 3: 5 reps @ 100kg

Bench Press: 3x8 @ 75kg
```

**Stage 1: Import**
```sql
-- Stored as-is in stg_imports
import_id: 'abc-123'
athlete_id: 'def-456'
raw_text: <text above>
```

**Stage 2: Parse**
```json
{
  "workout_date": "2025-01-05",
  "sessions": [{
    "session_code": "AM",
    "blocks": [
      {
        "block_code": "WU",  -- normalized from "חימום"
        "block_label": "A",
        "items": [{
          "exercise_key": "air_bike",  -- normalized from "Bike"
          "prescription": {"duration_minutes": 5, "intensity": "easy"},
          "performed": {"duration_minutes": 5}
        }]
      },
      {
        "block_code": "STR",
        "block_label": "B",
        "items": [
          {
            "exercise_key": "back_squat",
            "prescription": {"target_sets": 3, "target_reps": 5, "target_loads_kg": [80, 90, 100]},
            "performed": {"actual_sets": 3, "actual_reps": [5, 5, 5], "actual_loads_kg": [80, 90, 100]}
          },
          {
            "exercise_key": "bench_press",
            "prescription": {"target_sets": 3, "target_reps": 8, "target_load_kg": 75},
            "performed": {"actual_sets": 3, "actual_reps": [8, 8, 8], "actual_loads_kg": [75, 75, 75]}
          }
        ]
      }
    ]
  }]
}
```

**Stage 3: Validate**
```
✅ workout_date present
✅ athlete_id valid
✅ block_code "WU" exists in lib_block_types
✅ block_code "STR" exists in lib_block_types
✅ exercise_key "back_squat" exists in lib_exercise_catalog
✅ exercise_key "bench_press" exists in lib_exercise_catalog
✅ All required fields present
```

**Stage 4: Commit**
```
workout_main: 1 row inserted (workout_id: xyz-789)
workout_sessions: 1 row inserted (session_id: uvw-101)
workout_blocks: 2 rows inserted (WU block, STR block)
workout_items: 3 rows inserted (bike, squat, bench)
workout_item_set_results: 7 rows inserted (1 bike + 3 squat + 3 bench)
```

---

## ⚠️ Error Handling

### Common Errors & Solutions

#### 1. **Unknown Athlete**
```
Error: Athlete "John Doe" not found
Solution: 
- Add athlete to lib_athletes table first
- OR correct spelling in raw text
```

#### 2. **Unknown Exercise**
```
Error: Exercise "leg curl" not in catalog
Solution:
- Add to lib_exercise_catalog: INSERT INTO zamm.lib_exercise_catalog (exercise_key, exercise_name) VALUES ('leg_curl', 'Leg Curl')
- OR add alias: INSERT INTO zamm.lib_exercise_aliases (alias, exercise_key) VALUES ('leg curl', 'leg_curl')
```

#### 3. **Unknown Block Type**
```
Error: Block type "xyz" not recognized
Solution:
- Add to lib_block_aliases: INSERT INTO zamm.lib_block_aliases (alias, block_code) VALUES ('xyz', 'STR')
- OR use standard block code
```

#### 4. **Missing Prescription/Performed**
```
Error: workout_items requires both 'prescription' and 'performed' fields
Solution:
- Always include both, even if one is empty {}
- Example: "prescription": {}, "performed": {"actual_reps": [5, 5, 5]}
```

#### 5. **Commit Failure**
```
Error: Foreign key violation
Cause: workout_blocks.session_id references non-existent session
Solution:
- Stored procedure handles this automatically
- If manual INSERT, ensure parent records exist first
```

---

## ✅ Best Practices

### For AI Agents

1. **Always Call AI Tools First**
   ```sql
   -- Before parsing, validate:
   SELECT * FROM zamm.check_athlete_exists(athlete_name);
   SELECT * FROM zamm.get_active_ruleset();
   ```

2. **Normalize Everything**
   - Exercise names → via `lib_exercise_catalog`
   - Equipment → via `lib_equipment_catalog`
   - Block types → via `normalize_block_type()`

3. **Maintain Prescription vs Performance**
   ```json
   // ✅ CORRECT
   {
     "prescription": {"target_reps": 5},
     "performed": {"actual_reps": [5, 5, 4]}
   }
   
   // ❌ WRONG
   {
     "reps": 5  // ambiguous!
   }
   ```

4. **Handle Missing Data Gracefully**
   ```json
   // If no performance data:
   {
     "prescription": {"target_reps": 5},
     "performed": null  // or {}
   }
   ```

### For Developers

1. **Never Skip Staging**
   - Always go through all 4 stages
   - Don't INSERT directly into `workout_*` tables

2. **Use Stored Procedure**
   ```sql
   -- ✅ CORRECT
   SELECT zamm.commit_full_workout_v3(...);
   
   -- ❌ WRONG
   INSERT INTO zamm.workout_main (...);
   ```

3. **Preserve Audit Trail**
   - Never delete from `stg_imports`
   - Never delete from `stg_parse_drafts`
   - These tables are your debugging lifeline

4. **Add Aliases Proactively**
   ```sql
   -- When you encounter new variations, add them:
   INSERT INTO zamm.lib_exercise_aliases (alias, exercise_key)
   VALUES ('back squat', 'back_squat'),
          ('backsquat', 'back_squat'),
          ('bs', 'back_squat');
   ```

---

## 📊 Tables Summary (18 Tables)

### By Category

**Staging (3)**:
- stg_imports
- stg_parse_drafts
- stg_draft_edits

**Validation (1)**:
- log_validation_reports

**Configuration (2)**:
- lib_parser_rulesets
- cfg_parser_rules

**Reference/Catalogs (7)**:
- lib_athletes
- lib_exercise_catalog
- lib_exercise_aliases
- lib_equipment_catalog
- lib_equipment_aliases
- lib_block_types
- lib_block_aliases

**Production/Workout (5)**:
- workout_main
- workout_sessions
- workout_blocks
- workout_items
- workout_item_set_results

---

## 🔗 Related Documentation

- [AI_PROMPTS.md](./AI_PROMPTS.md) - AI agent system prompts
- [N8N_INTEGRATION_GUIDE.md](./N8N_INTEGRATION_GUIDE.md) - n8n workflow setup
- [BLOCK_TYPES_REFERENCE.md](../reference/BLOCK_TYPES_REFERENCE.md) - 17 block types catalog
- [ARCHITECTURE.md](../../ARCHITECTURE.md) - Full system architecture
- [agents.md](../../agents.md) - AI agent operational guide

---

**Last Updated**: January 7, 2026  
**Version**: 1.0.0  
**Author**: ZAMM Development Team
