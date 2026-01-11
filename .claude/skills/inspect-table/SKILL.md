---
name: inspect-table
description: Shows COMPLETE table structure including columns, types, nullability, defaults, and ALL constraints (CHECK, FK, UNIQUE, ENUM values)
---

# Inspect Table Skill

## Purpose
Before writing ANY SQL that inserts/updates data or creates functions, run this skill to see the ACTUAL database constraints. This prevents errors like:
- Inserting invalid enum values (e.g., 'pending_review' when only 'draft' allowed)
- Violating check constraints (e.g., checksum format)
- Missing required NOT NULL columns
- Wrong foreign key references

## Usage
```
/inspect-table <table_name>
```

Example:
```
/inspect-table workout_main
/inspect-table stg_imports
```

## What It Shows

1. **Columns**: Name, Type, Nullable, Default Value
2. **Check Constraints**: Exact SQL condition (e.g., `status = ANY(ARRAY['draft', 'completed', ...])`)
3. **Foreign Keys**: Which columns reference which tables
4. **Unique Constraints**: Which columns must be unique
5. **Enum Types**: For enum columns, shows all valid values

## Instructions for Claude

### Step 1: Extract Table Name
Parse the table name from the user's command (after `/inspect-table `).

### Step 2: Run Full Inspection Query

Use Supabase MCP or psql to execute this query:

```sql
-- Part 1: Column Details
SELECT
    c.column_name,
    c.data_type,
    c.udt_name,  -- For enums, shows the enum type name
    c.is_nullable,
    c.column_default,
    pgd.description as column_description
FROM information_schema.columns c
LEFT JOIN pg_catalog.pg_statio_all_tables st ON c.table_schema = st.schemaname AND c.table_name = st.relname
LEFT JOIN pg_catalog.pg_description pgd ON pgd.objoid = st.relid AND pgd.objsubid = c.ordinal_position
WHERE c.table_schema = 'zamm'
  AND c.table_name = '<TABLE_NAME>'
ORDER BY c.ordinal_position;

-- Part 2: Check Constraints
SELECT
    con.conname as constraint_name,
    pg_get_constraintdef(con.oid) as constraint_definition
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
WHERE nsp.nspname = 'zamm'
  AND rel.relname = '<TABLE_NAME>'
  AND con.contype = 'c'  -- Check constraints only
ORDER BY con.conname;

-- Part 3: Foreign Keys
SELECT
    con.conname as fk_name,
    att.attname as column_name,
    cl.relname as referenced_table,
    att2.attname as referenced_column
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
JOIN pg_attribute att ON att.attrelid = con.conrelid AND att.attnum = ANY(con.conkey)
JOIN pg_class cl ON cl.oid = con.confrelid
JOIN pg_attribute att2 ON att2.attrelid = con.confrelid AND att2.attnum = ANY(con.confkey)
WHERE nsp.nspname = 'zamm'
  AND rel.relname = '<TABLE_NAME>'
  AND con.contype = 'f'  -- Foreign keys only
ORDER BY con.conname;

-- Part 4: Unique Constraints
SELECT
    con.conname as constraint_name,
    array_agg(att.attname ORDER BY u.attposition) as columns
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
JOIN LATERAL unnest(con.conkey) WITH ORDINALITY AS u(attnum, attposition) ON true
JOIN pg_attribute att ON att.attrelid = con.conrelid AND att.attnum = u.attnum
WHERE nsp.nspname = 'zamm'
  AND rel.relname = '<TABLE_NAME>'
  AND con.contype = 'u'  -- Unique constraints only
GROUP BY con.conname
ORDER BY con.conname;

-- Part 5: Enum Values (if any columns use enums)
SELECT
    t.typname as enum_name,
    array_agg(e.enumlabel ORDER BY e.enumsortorder) as valid_values
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE t.typname IN (
    SELECT udt_name
    FROM information_schema.columns
    WHERE table_schema = 'zamm'
      AND table_name = '<TABLE_NAME>'
      AND data_type = 'USER-DEFINED'
)
GROUP BY t.typname;
```

### Step 3: Present Results

Format the output clearly:

```
📋 Table: zamm.<table_name>

## Columns
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ... | ... | ... | ... | ... |

## ⚠️ Check Constraints
- constraint_name: <SQL condition>
- ...

## 🔗 Foreign Keys
- column_name → referenced_table.referenced_column
- ...

## 🔒 Unique Constraints
- columns: [col1, col2, ...]
- ...

## 📝 Enum Types (Valid Values)
- enum_name: ['value1', 'value2', ...]
- ...
```

### Step 4: Critical Warnings

After showing the data, add specific warnings:

```
⚠️ CRITICAL CONSTRAINTS TO RESPECT:

1. Status Column: Only accepts ['draft', 'completed', ...] - NOT 'pending_review'!
2. Checksum Format: Must be 64 hex characters (SHA-256)
3. NOT NULL Columns: [list them] - MUST provide values
4. Foreign Keys: [list them] - MUST reference existing records
```

## Example Output

```
📋 Table: zamm.workout_main

## Columns
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| workout_id | uuid | NO | gen_random_uuid() | Primary key |
| status | text | NO | 'draft' | Workout status |
| requires_review | boolean | NO | false | Needs human review |
| approved_at | timestamp | NO | - | Approval timestamp |

## ⚠️ Check Constraints
- chk_status: `(status = ANY(ARRAY['draft', 'scheduled', 'in_progress', 'completed', 'cancelled', 'archived']))`
- chk_workout_date: `(workout_date <= CURRENT_DATE)`

## 🔗 Foreign Keys
- athlete_id → lib_athletes.athlete_id

## 🔒 Unique Constraints
- unique_athlete_date: [athlete_id, workout_date]

⚠️ CRITICAL CONSTRAINTS TO RESPECT:

1. ❌ Status MUST be one of: 'draft', 'scheduled', 'in_progress', 'completed', 'cancelled', 'archived'
   - Do NOT use 'pending_review', 'active', or any other value!

2. ❌ approved_at is NOT NULL - MUST always provide a timestamp
   - Cannot set to NULL even for draft workouts

3. ❌ athlete_id MUST reference existing record in lib_athletes table
```

## When to Use This Skill

**ALWAYS use before:**
- ✅ Writing INSERT statements
- ✅ Writing UPDATE statements
- ✅ Creating functions that insert data
- ✅ Writing migration ALTER TABLE statements
- ✅ Creating test data

**Example Workflow:**
1. User: "Create a test workout record"
2. Claude: First runs `/inspect-table workout_main`
3. Claude: Sees that status only allows specific values, approved_at is NOT NULL
4. Claude: Writes INSERT with correct values

## Notes

- This skill uses **live database inspection** - always accurate
- Replaces guessing/documentation (which may be outdated)
- Shows the actual constraints enforced by PostgreSQL
- Prevents 90% of constraint violation errors
