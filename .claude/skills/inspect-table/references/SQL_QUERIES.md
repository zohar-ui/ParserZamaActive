# SQL Queries Reference

**Purpose:** Complete SQL inspection queries for inspect-table skill
**Main Skill:** inspect-table

---

## Full Inspection Query

Replace `<TABLE_NAME>` with the actual table name (without schema prefix).

### Part 1: Column Details

```sql
SELECT
    c.column_name,
    c.data_type,
    c.udt_name,  -- For enums, shows the enum type name
    c.is_nullable,
    c.column_default,
    pgd.description as column_description
FROM information_schema.columns c
LEFT JOIN pg_catalog.pg_statio_all_tables st
    ON c.table_schema = st.schemaname AND c.table_name = st.relname
LEFT JOIN pg_catalog.pg_description pgd
    ON pgd.objoid = st.relid AND pgd.objsubid = c.ordinal_position
WHERE c.table_schema = 'zamm'
  AND c.table_name = '<TABLE_NAME>'
ORDER BY c.ordinal_position;
```

**Returns:**
- `column_name`: Name of the column
- `data_type`: PostgreSQL data type (text, integer, uuid, etc.)
- `udt_name`: User-defined type name (for enums)
- `is_nullable`: 'YES' or 'NO'
- `column_default`: Default value expression
- `column_description`: Comment/description (if set)

---

### Part 2: Check Constraints

```sql
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
```

**Returns:**
- `constraint_name`: Name of the constraint
- `constraint_definition`: Full SQL check expression

**Example Output:**
```
constraint_name: chk_workout_status
constraint_definition: CHECK (status = ANY(ARRAY['draft', 'completed', 'scheduled']))
```

---

### Part 3: Foreign Keys

```sql
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
```

**Returns:**
- `fk_name`: Foreign key constraint name
- `column_name`: Column in this table
- `referenced_table`: Table being referenced
- `referenced_column`: Column in referenced table

**Example Output:**
```
fk_name: fk_workout_athlete
column_name: athlete_id
referenced_table: lib_athletes
referenced_column: athlete_id
```

---

### Part 4: Unique Constraints

```sql
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
```

**Returns:**
- `constraint_name`: Unique constraint name
- `columns`: Array of columns that must be unique together

**Example Output:**
```
constraint_name: unique_athlete_date
columns: {athlete_id, workout_date}
```

---

### Part 5: Enum Values

```sql
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

**Returns:**
- `enum_name`: Name of the enum type
- `valid_values`: Array of all valid enum values

**Example Output:**
```
enum_name: workout_status_enum
valid_values: {draft, scheduled, in_progress, completed, cancelled, archived}
```

---

## Using with MCP

When using Supabase MCP tools, you can query directly:

```javascript
// Example: Get columns for workout_main
const result = await mcp.supabase.execute_sql(`
  SELECT column_name, data_type, is_nullable
  FROM information_schema.columns
  WHERE table_schema = 'zamm' AND table_name = 'workout_main'
  ORDER BY ordinal_position
`);
```

---

## Using with psql

```bash
# Export connection string
export SUPABASE_DB_URL="postgresql://..."

# Run query
psql "$SUPABASE_DB_URL" -c "
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'zamm' AND table_name = 'workout_main'
ORDER BY ordinal_position;
"
```

---

## Quick Queries

### Check if Table Exists

```sql
SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'zamm' AND table_name = '<TABLE_NAME>'
) as table_exists;
```

### Get Column Count

```sql
SELECT COUNT(*) as column_count
FROM information_schema.columns
WHERE table_schema = 'zamm' AND table_name = '<TABLE_NAME>';
```

### Get Primary Key

```sql
SELECT
    con.conname as pk_name,
    array_agg(att.attname) as pk_columns
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
JOIN pg_attribute att ON att.attrelid = con.conrelid AND att.attnum = ANY(con.conkey)
WHERE nsp.nspname = 'zamm'
  AND rel.relname = '<TABLE_NAME>'
  AND con.contype = 'p'  -- Primary key
GROUP BY con.conname;
```

---

**Last Updated:** 2026-01-13
**Version:** 1.0.0
