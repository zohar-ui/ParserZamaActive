---
name: add-entity
description: Adds a new exercise or equipment to the system catalogs safely with automatic duplicate checking, proper normalization (lowercase keys, proper formatting), alias creation, and referential integrity maintenance. Use this skill when: (1) Parser fails to find an exercise or equipment in catalogs, (2) Adding new training movements before processing workouts, (3) Expanding exercise/equipment vocabulary for parser recognition, (4) Creating canonical entries with proper categorization and metadata, or (5) Normalizing training terminology across the system with common aliases and abbreviations
---

# Add Entity Skill

## Purpose
Safely add new exercises or equipment to the system catalogs while:
- Preventing duplicates
- Ensuring proper normalization (lowercase keys, proper formatting)
- Adding common aliases automatically
- Maintaining referential integrity

## Usage
```
/add-entity <type> <name>
```

**Arguments:**
- `type`: Either "exercise" or "equipment"
- `name`: The canonical name for the entity (e.g., "bench press", "barbell")

**Examples:**
```
/add-entity exercise "bench press"
/add-entity equipment "resistance band"
```

## What It Does

### For Exercises:
1. **Search for duplicates** using `check_exercise_exists()`
2. **Show similar matches** if found
3. **Ask user** if they want to add as alias to existing exercise
4. **If new:** Insert into `lib_exercise_catalog` with required fields
5. **Prompt for aliases** (common variations, abbreviations)
6. **Insert aliases** into `lib_exercise_aliases`

### For Equipment:
1. **Search** in `lib_equipment_catalog` and `lib_equipment_aliases`
2. **Show similar matches** if found
3. **Ask user** if they want to add as alias
4. **If new:** Insert into `lib_equipment_catalog`
5. **Prompt for aliases**
6. **Insert aliases** into `lib_equipment_aliases`

---

## Instructions for Claude

### Step 1: Parse Arguments
```
Type: [exercise|equipment]
Name: [user-provided name]
```

### Step 2: Search for Existing Entities

**For Exercise:**
```sql
SELECT * FROM zamm.check_exercise_exists('<name>');
```

**For Equipment:**
```sql
SELECT
    ec.equipment_key,
    ec.display_name,
    ea.alias,
    'alias' as matched_via
FROM zamm.lib_equipment_catalog ec
LEFT JOIN zamm.lib_equipment_aliases ea ON ec.equipment_key = ea.equipment_key
WHERE
    ec.display_name ILIKE '%<name>%'
    OR ec.equipment_key ILIKE '%<name>%'
    OR ea.alias ILIKE '%<name>%'
LIMIT 10;
```

### Step 3: Handle Results

**If matches found:**
```
Found similar entities:
1. bench_press (Bench Press) - matched via display_name
2. incline_bench_press (Incline Bench Press) - matched via exercise_key

Options:
A) Add "<name>" as an alias to one of the above
B) Create a new entity (if this is genuinely different)

Which would you like to do?
```

Use `AskUserQuestion` tool to get user choice.

**If user chooses to add as alias:**
- Skip to Step 5 with the selected exercise_key

**If user chooses to create new:**
- Proceed to Step 4

### Step 4: Create New Entity

**For Exercise:**
Before inserting, you MUST ask the user for required fields:

```
Creating new exercise: "Bench Press"

Required information:
- Category (e.g., "strength", "cardio", "mobility")
- Movement Pattern (e.g., "horizontal_push", "vertical_pull", "squat")
- Primary Muscles (array, e.g., ["pectorals", "triceps"])
- Is Compound? (true/false)
```

Use `AskUserQuestion` to collect these fields.

Then insert:
```sql
INSERT INTO zamm.lib_exercise_catalog (
    exercise_key,
    display_name,
    category,
    movement_pattern,
    primary_muscles,
    is_compound,
    is_active
) VALUES (
    '<normalized_key>',  -- lowercase, underscores (e.g., 'bench_press')
    '<display_name>',    -- Proper case (e.g., 'Bench Press')
    '<category>',
    '<movement_pattern>',
    ARRAY[<primary_muscles>],
    <is_compound>,
    true
)
RETURNING exercise_key;
```

**For Equipment:**
```sql
INSERT INTO zamm.lib_equipment_catalog (
    equipment_key,
    display_name,
    category,
    is_active
) VALUES (
    '<normalized_key>',  -- lowercase, underscores (e.g., 'resistance_band')
    '<display_name>',    -- Proper case (e.g., 'Resistance Band')
    'standard',          -- Default category
    true
)
RETURNING equipment_key;
```

### Step 5: Add Aliases

**Prompt user for common variations:**
```
Exercise "Bench Press" created with key: bench_press

Common aliases (comma-separated):
Examples: "BP, bench, flat bench, barbell bench"

Enter aliases (or press Enter to skip):
```

**For each alias provided:**
```sql
-- For exercises:
INSERT INTO zamm.lib_exercise_aliases (
    alias,
    exercise_key,
    locale,
    is_abbreviation,
    is_common
) VALUES (
    '<alias>',
    '<exercise_key>',
    'en',
    <is_abbreviation>,  -- true if 2-3 chars, false otherwise
    true
)
ON CONFLICT (alias, exercise_key) DO NOTHING;

-- For equipment:
INSERT INTO zamm.lib_equipment_aliases (
    alias,
    equipment_key,
    locale,
    is_common
) VALUES (
    '<alias>',
    '<equipment_key>',
    'en',
    true
)
ON CONFLICT (alias, equipment_key) DO NOTHING;
```

### Step 6: Verify and Report

```sql
-- Verify the entity was created
SELECT * FROM zamm.lib_exercise_catalog WHERE exercise_key = '<key>';

-- Show all aliases
SELECT alias FROM zamm.lib_exercise_aliases WHERE exercise_key = '<key>';
```

**Output:**
```
✅ Successfully created exercise: bench_press

Details:
- Display Name: Bench Press
- Category: strength
- Movement Pattern: horizontal_push
- Aliases: BP, bench, flat bench, barbell bench (4 total)

You can now reference this exercise in workouts using any of these names.
```

---

## Normalization Rules

### exercise_key / equipment_key Format:
- **Lowercase only**
- **Replace spaces with underscores**
- **Remove special characters** (except underscores)
- **No leading/trailing underscores**

**Examples:**
```
"Bench Press"        → bench_press
"Pull-Up"            → pull_up
"Back Squat (Pause)" → back_squat_pause
"DB Row"             → db_row
```

### display_name Format:
- **Title Case** (capitalize each word)
- **Keep hyphens and parentheses**
- **No abbreviations** (use full words)

**Examples:**
```
"bench press"    → Bench Press
"pull-up"        → Pull-Up
"db row"         → Dumbbell Row (expand abbreviations)
```

---

## Common Aliases to Suggest

### For Exercises:
- **Abbreviations:** BP (bench press), DL (deadlift), OHP (overhead press)
- **Variations:** flat bench, incline bench, decline bench
- **Equipment prefix:** barbell bench, dumbbell bench
- **Regional names:** press (UK) vs bench press (US)

### For Equipment:
- **Abbreviations:** DB (dumbbell), BB (barbell), KB (kettlebell)
- **Plural forms:** dumbbells, barbells
- **Alternative spellings:** dumb bell, dumbells

---

## Error Handling

### Duplicate Key Error
If you get a unique constraint violation on `exercise_key`:
```
ERROR: duplicate key value violates unique constraint "lib_exercise_catalog_pkey"
```

**Solution:**
- The key already exists (search missed it)
- Add as alias instead
- Or modify the key slightly (e.g., `bench_press_variant`)

### Missing Required Field
If you get a NOT NULL constraint violation:
```
ERROR: null value in column "category" violates not-null constraint
```

**Solution:**
- Go back and ask user for missing field
- Do NOT guess or use placeholders

---

## Example Session

```
User: /add-entity exercise "bench press"

Claude: Searching for existing exercises matching "bench press"...

Found 2 similar exercises:
1. bench_press (Bench Press) - exact match
2. incline_bench_press (Incline Bench Press)

It looks like "Bench Press" already exists in the catalog.

Options:
A) View existing aliases for "bench_press"
B) Add a new alias to "bench_press"
C) Create a new exercise (if this is different)

User: B

Claude: Current aliases for "bench_press":
- BP
- flat bench

What alias would you like to add?

User: barbell bench

Claude: ✅ Added alias "barbell bench" to bench_press

Total aliases: BP, flat bench, barbell bench (3 total)
```

---

## Notes

- This skill uses **MCP Supabase tools** for all database operations
- Always **search before creating** to prevent duplicates
- Always **normalize keys** to lowercase_underscore format
- Always **ask for aliases** - they're critical for parser accuracy
- If unsure about category/movement_pattern, ask the user (don't guess!)
