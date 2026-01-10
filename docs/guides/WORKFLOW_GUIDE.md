# 🔄 AI Workflow Guide - ParserZamaActive

> **How to work efficiently with GitHub Copilot + Claude Code**  
> Last Updated: January 9, 2026

---

## 🎯 The Problem

Working with multiple AI tools feels chaotic:
- You ask Copilot to run commands → It can't
- You ask Claude Code to edit files → It's clunky
- Context gets lost between sessions
- You repeat yourself constantly

**Root Cause:** Trying to make one tool do the other's job.

---

## ✅ The Solution: Clear Division of Labor

### Tool #1: GitHub Copilot (The Micro)
**Location:** Inside VS Code  
**Strength:** Fast, precise code completion  
**Use for:** Editing open files

### Tool #2: Claude Code (The Macro)
**Location:** Terminal  
**Strength:** Autonomous execution  
**Use for:** Running commands, multi-file operations

### Tool #3: agents.md (The Memory)
**Location:** Project root  
**Strength:** Persistent context  
**Use for:** Shared knowledge base

---

## 📋 Daily Workflow (The Protocol)

### 1️⃣ Morning Setup (5 minutes)

**Open Terminal → Start Claude Code:**
```bash
# Load project memory
claude "Read agents.md and DB_READINESS_REPORT.md to restore context. Then run PROTOCOL ZERO handshake."
```

**What this does:**
- ✅ Loads project architecture into Claude's memory
- ✅ Verifies database connection
- ✅ Checks schema structure (27 tables)
- ✅ Reviews critical business rules

**Expected output:**
```
System Connected: [X] athletes, [Y] workouts found.
Ruleset: v1.0
Schema: 27 tables verified.
Ready to operate.
```

---

### 2️⃣ Execute Large Tasks (Claude Code)

**In Terminal:**
```bash
# Ask Claude to check TODO and execute
claude "Read TODO.md and execute the next high-priority task. Report progress."
```

**Examples:**
- "Clean test data from database"
- "Run all validation tests and report failures"
- "Create migration for new feature"
- "Commit all changes and push to git"

**Claude will:**
1. Read the task requirements
2. Verify schema/table names
3. Execute SQL/commands
4. Handle errors automatically
5. Report results

---

### 3️⃣ Write New Code (Choose Your Tool)

#### Option A: Let Claude Create Files
**For:** New migrations, scripts, configs
```bash
claude "Create a new migration to add workout_tags table with the following structure: ..."
```

#### Option B: Use Copilot in VS Code
**For:** Complex function logic, detailed SQL

1. Create file manually (or let Claude create skeleton)
2. Open in VS Code
3. Start typing → Copilot auto-completes
4. Best for: Writing function bodies, complex queries

**Example:**
```sql
-- You type:
CREATE OR REPLACE FUNCTION zamm.calculate_tonnage(

-- Copilot suggests:
p_workout_id UUID
) RETURNS NUMERIC AS $$
DECLARE
    v_total_tonnage NUMERIC := 0;
BEGIN
    SELECT SUM(load_kg * reps * sets)
    INTO v_total_tonnage
    FROM zamm.workout_items
    WHERE workout_id = p_workout_id;
    
    RETURN v_total_tonnage;
END;
$$ LANGUAGE plpgsql;
```

---

### 4️⃣ Verify & Deploy (Claude Code)

**Back to Terminal:**
```bash
# Test the new code
claude "Run verification script and check for errors"

# Deploy if all good
claude "Push migration to production"
```

---

## 🔀 Decision Tree

```
📝 Need to do something?
    ↓
    Is it a single file edit?
    ├─ YES → Open file in VS Code → Use Copilot
    └─ NO → Use Claude Code in terminal
           ↓
           Does it involve running commands?
           ├─ YES → Definitely Claude Code
           └─ NO → Still Claude (multi-file operations)
```

---

## 📊 Practical Examples

### Example 1: "Add a new table"

**❌ Wrong way:**
Ask Copilot: "Create a migration and run it"
→ Copilot writes SQL but can't execute

**✅ Right way:**
```bash
# Terminal (Claude Code)
claude "Create migration to add workout_tags table, then push it to database"
```

---

### Example 2: "Write a complex SQL function"

**❌ Wrong way:**
Ask Claude Code to write 100-line function in terminal
→ Clunky editing, no syntax highlighting

**✅ Right way:**
```bash
# Terminal: Create skeleton
claude "Create empty migration file for tonnage calculation function"

# VS Code: Open the file, use Copilot to write logic
# (Fast, with autocomplete and syntax highlighting)

# Terminal: Deploy
claude "Test and deploy the new function"
```

---

### Example 3: "Debug a failing migration"

**❌ Wrong way:**
Copy error to Copilot chat, manually fix, manually re-run

**✅ Right way:**
```bash
# Terminal (Claude Code)
claude "The last migration failed. Read the error, fix the issue, and re-run it."
```
→ Claude reads error, fixes SQL, re-executes automatically

---

## 🧠 Context Management

### The Memory Problem
AI tools don't remember previous sessions.

### The Solution: agents.md

**agents.md is your "shared brain":**
- Project architecture
- Business rules
- Table schemas
- Common pitfalls
- Workflows

**Loading context:**

For Claude Code:
```bash
claude "Read agents.md to restore context"
```

For Copilot:
Create `.github/copilot-instructions.md`:
```
Your source of truth is agents.md.
Before complex tasks, read it to understand project rules.
```

---

## 💡 Pro Tips

### Tip 1: Start Every Claude Session with Init
```bash
# Make this a habit (or create an alias)
alias claude-init='claude "Read agents.md and DB_READINESS_REPORT.md. Run PROTOCOL ZERO."'
```

### Tip 2: Use Copilot for "Flow State" Coding
When you're in the zone writing logic, stay in VS Code with Copilot. Don't context-switch to terminal.

### Tip 3: Use Claude for "Orchestration"
When you need to coordinate multiple things (verify → execute → commit), stay in terminal with Claude.

### Tip 4: Update agents.md After Major Changes
Changed architecture? Updated schema? Add it to agents.md so both tools know.

### Tip 5: Keep TODO.md Current
Claude reads this to know what to do next. Keep it updated.

---

## 🚫 Common Anti-Patterns

### ❌ Don't: Ask Copilot to Run Commands
**Why:** It can't execute anything.  
**Instead:** Switch to Claude Code in terminal.

### ❌ Don't: Ask Claude to Write 100+ Line Functions
**Why:** Terminal editing is painful.  
**Instead:** Let Claude create file, then open in VS Code with Copilot.

### ❌ Don't: Repeat Context Every Time
**Why:** Wastes time and tokens.  
**Instead:** Load agents.md once at session start.

### ❌ Don't: Assume Schema Without Verifying
**Why:** Table names might have changed.  
**Instead:** Always run `./scripts/ops/verify_schema.sh` first.

### ❌ Don't: Work Without TODO.md
**Why:** Lose track of progress.  
**Instead:** Keep TODO.md updated with current tasks.

---

## 📈 Efficiency Gains

**Before (Chaotic):**
- Asking wrong tool for wrong job: 40% time wasted
- Repeating context: 30% time wasted
- Manual error fixing: 20% time wasted
- **Total efficiency: 10%**

**After (Protocol):**
- Right tool for right job: 0% waste
- Load context once: 0% waste
- Automated error handling: 0% waste
- **Total efficiency: 90%+**

---

## 🎯 Quick Reference Card

### When to Use What

| Task | Tool | Why |
|------|------|-----|
| Write SQL function body | Copilot | Fast autocomplete |
| Run migration | Claude Code | Can execute commands |
| Edit open file | Copilot | IDE integration |
| Multi-file refactor | Claude Code | Sees all files |
| Add documentation | Copilot | Context of current file |
| Execute TODO tasks | Claude Code | Autonomous execution |
| Debug error | Claude Code | Can read logs and re-run |
| Write complex query | Copilot | Syntax highlighting |
| Commit and push | Claude Code | Git operations |
| Check schema | Claude Code | Database access |

---

## 🔄 The Complete Workflow Loop

```
1. START DAY
   ↓
2. LOAD CONTEXT (Claude: read agents.md)
   ↓
3. GET NEXT TASK (Claude: read TODO.md)
   ↓
4. EXECUTE
   ├─ Large task? → Claude Code
   ├─ Code writing? → Copilot
   └─ Both? → Claude creates, Copilot edits
   ↓
5. VERIFY (Claude: run tests)
   ↓
6. DEPLOY (Claude: push changes)
   ↓
7. UPDATE TODO.md
   ↓
8. REPEAT from step 3
```

---

## 📚 Related Files

- [agents.md](./agents.md) - Source of truth (read first!)
- [CLAUDE.md](./CLAUDE.md) - Claude-specific config
- [TODO.md](./TODO.md) - Current tasks
- [DB_READINESS_REPORT.md](./DB_READINESS_REPORT.md) - System status
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System design

---

**Remember:** 
- **Copilot** = The fast typer (inside files)
- **Claude Code** = The operator (in terminal)
- **agents.md** = The memory (context for both)

Work with each tool's strengths, not against them! 🚀

---

*Last Updated: January 9, 2026*
