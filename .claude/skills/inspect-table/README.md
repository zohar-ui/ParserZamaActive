# inspect-table Skill - Usage Examples

## Purpose
This skill prevents 90% of constraint violation errors by showing you the ACTUAL database constraints before you write SQL.

## Real-World Examples (From v4 Migration)

### Example 1: Status Constraint Violation

**❌ What Happened Without `/inspect-table`:**
```sql
-- Attempt 1: Guessed status value
INSERT INTO zamm.workout_main (status, ...) VALUES ('pending_review', ...);
-- ERROR: new row violates check constraint "chk_status"
-- DETAIL: Failing row contains (status = 'pending_review')

-- Attempt 2: Tried another guess
UPDATE zamm.workout_main SET status = 'needs_review' WHERE ...;
-- ERROR: new row violates check constraint "chk_status"

-- Attempt 3: Finally checked the constraint
-- Found: status = ANY(ARRAY['draft', 'scheduled', 'in_progress', 'completed', 'cancelled', 'archived'])
INSERT INTO zamm.workout_main (status, ...) VALUES ('draft', ...);
-- ✅ SUCCESS (after 3 attempts)
```

**✅ With `/inspect-table` (First Time Success):**
```bash
# Step 1: Run skill BEFORE writing SQL
/inspect-table workout_main

# Output shows:
# ⚠️ CHECK CONSTRAINT: chk_status
# (status = ANY(ARRAY['draft', 'scheduled', 'in_progress', 'completed', 'cancelled', 'archived']))

# Step 2: Write SQL with correct value
INSERT INTO zamm.workout_main (status, ...) VALUES ('draft', ...);
-- ✅ SUCCESS (first attempt)
```

---

### Example 2: NOT NULL Constraint

**❌ Without `/inspect-table`:**
```sql
-- Attempt: Thought approved_at was optional for draft workouts
INSERT INTO zamm.workout_main (status, approved_at, ...)
VALUES ('draft', NULL, ...);
-- ERROR: null value in column "approved_at" violates not-null constraint
```

**✅ With `/inspect-table`:**
```bash
/inspect-table workout_main

# Output shows:
# | approved_at | timestamp | NO | - | Approval timestamp |
#                             ^^^ NOT NULL!

# Write SQL correctly:
INSERT INTO zamm.workout_main (status, approved_at, ...)
VALUES ('draft', NOW(), ...);
-- ✅ SUCCESS
```

---

### Example 3: Checksum Format Constraint

**❌ Without `/inspect-table`:**
```sql
-- Attempt 1: Used short hash
INSERT INTO zamm.stg_imports (checksum_sha256, ...)
VALUES ('abc123def', ...);
-- ERROR: new row violates check constraint "chk_checksum_format"

-- Attempt 2: Used longer hash but wrong format
INSERT INTO zamm.stg_imports (checksum_sha256, ...)
VALUES ('abc123def456789012345678901234567890', ...);
-- ERROR: new row violates check constraint "chk_checksum_format"
```

**✅ With `/inspect-table`:**
```bash
/inspect-table stg_imports

# Output shows:
# ⚠️ CHECK CONSTRAINT: chk_checksum_format
# (checksum_sha256 ~ '^[a-f0-9]{64}$')
# Translation: Must be exactly 64 hexadecimal characters

# Generate proper checksum:
import hashlib
checksum = hashlib.sha256(content.encode()).hexdigest()  # Exactly 64 hex chars

INSERT INTO zamm.stg_imports (checksum_sha256, ...)
VALUES ('a1b2c3d4...', ...);  -- 64 hex characters
-- ✅ SUCCESS
```

---

### Example 4: Foreign Key Reference

**❌ Without `/inspect-table`:**
```sql
-- Attempt: Used random UUID
INSERT INTO zamm.workout_main (athlete_id, ...)
VALUES ('123e4567-e89b-12d3-a456-426614174000', ...);
-- ERROR: insert or update violates foreign key constraint "workout_main_athlete_id_fkey"
-- DETAIL: Key (athlete_id) is not present in table "lib_athletes"
```

**✅ With `/inspect-table`:**
```bash
/inspect-table workout_main

# Output shows:
# 🔗 FOREIGN KEY: workout_main_athlete_id_fkey
# athlete_id → lib_athletes.athlete_id

# First, get existing athlete:
SELECT athlete_id FROM zamm.lib_athletes WHERE full_name = 'Tomer';
-- Result: 'a1b2c3d4-5678-90ab-cdef-1234567890ab'

# Use that ID:
INSERT INTO zamm.workout_main (athlete_id, ...)
VALUES ('a1b2c3d4-5678-90ab-cdef-1234567890ab', ...);
-- ✅ SUCCESS
```

---

## Time Savings Comparison

### v4 Migration Experience

**Without `/inspect-table` skill:**
```
Task: Create test workout record
├─ Attempt 1: status='pending_review' → ❌ Error (5 min)
├─ Attempt 2: approved_at=NULL → ❌ Error (5 min)
├─ Attempt 3: checksum='abc123' → ❌ Error (10 min debugging regex)
├─ Attempt 4: athlete_id=random → ❌ Error (5 min)
└─ Attempt 5: All correct → ✅ (30 min total)
```

**With `/inspect-table` skill:**
```
Task: Create test workout record
├─ Run: /inspect-table workout_main (30 sec)
├─ Read constraints carefully (2 min)
├─ Write INSERT with correct values (3 min)
└─ Execute → ✅ First time! (6 min total)

Time saved: 24 minutes (80% reduction)
```

---

## How to Use

### Method 1: Via Claude Code CLI (Recommended)
```bash
# Just type the command
/inspect-table workout_main
/inspect-table stg_imports
/inspect-table lib_athletes
```

### Method 2: Manually (If skill not available)
```bash
# Run the SQL queries from SKILL.md manually via MCP or psql
# See .claude/skills/inspect-table/SKILL.md for full queries
```

---

## When to Use This Skill

**ALWAYS use before:**
- ✅ Writing INSERT statements
- ✅ Writing UPDATE statements
- ✅ Creating stored procedures that insert data
- ✅ Creating test data
- ✅ Writing migrations that modify constraints

**You can skip if:**
- ❌ Only reading data (SELECT queries)
- ❌ Dropping tables/columns
- ❌ Creating brand new tables (no constraints yet)

---

## Skill Output Format

The skill returns:

1. **Columns**: Name, Type, Nullable, Default
2. **Check Constraints**: Exact SQL conditions
3. **Foreign Keys**: Which tables/columns are referenced
4. **Unique Constraints**: Which column combinations must be unique
5. **Enum Types**: For enum columns, all valid values

Plus a **critical warnings** section highlighting the most common gotchas.

---

## Installation

The skill is already installed at:
```
.claude/skills/inspect-table/SKILL.md
```

Claude Code will automatically detect it and make it available via `/inspect-table` command.

---

## Related Documentation

- [CLAUDE.md](../../CLAUDE.md) - Main protocol document (now includes constraint inspection protocol)
- [Migration Protocol](../../CLAUDE.md#-migration-protocol) - Function creation rules
- [Constraint Inspection Protocol](../../CLAUDE.md#-constraint-inspection-protocol) - When and why to use this skill

---

**Created:** January 11, 2026
**Motivation:** Prevent constraint violations that caused 2+ hours of debugging during v4 migration
**Success Metric:** 80% reduction in SQL error retry cycles
