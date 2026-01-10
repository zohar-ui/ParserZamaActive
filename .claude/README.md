# ParserZamaActive - Enhanced AI Agent System

## 🎯 Overview

This directory contains enhanced AI agent configuration for working with ParserZamaActive efficiently using Claude Desktop, Cursor, or similar AI tools.

---

## 📁 Structure

```
.claude/
├── CLAUDE.md                    # Core principles and workflow
├── settings.json                # Agent configuration and permissions
├── commands/                    # Slash commands
│   ├── verify.md               # /verify - Full test suite
│   ├── db-status.md            # /db-status - Quick health check
│   └── fix-parser.md           # /fix-parser - Auto-repair errors
└── agents/                      # Specialized AI agents
    ├── db-architect.md         # Database expert
    ├── parser-engineer.md      # Parser logic expert
    ├── learning-specialist.md  # Active learning expert
    └── golden-set-curator.md   # Test case manager
```

---

## 🚀 Quick Start

### 1. Use Slash Commands

Instead of remembering which scripts to run:

```bash
# Quick health check (5 seconds)
/db-status

# Full validation suite (30-60 seconds)
/verify

# Auto-fix common parser errors
/fix-parser
```

### 2. Call Specialized Agents

When working on specific tasks, mention the relevant agent:

```
@db-architect - How do I add a new catalog table?
@parser-engineer - The parser is hallucinating weights
@learning-specialist - Update parser brain with latest corrections
@golden-set-curator - Create test case for AMRAP with partial reps
```

The system will automatically load the correct context and follow domain-specific rules.

### 3. Pre-Commit Protection

Git hook runs `/verify` automatically before each commit:

```bash
git commit -m "Your changes"

# Output:
# 🔍 Running pre-commit verification...
# 📊 Step 1/3: Verifying database schema...
# ✅ Schema verification passed
# 🧪 Step 2/3: Validating golden set...
# ✅ Golden set validation passed
# 🏗️  Step 3/3: Testing block types...
# ✅ Block type tests passed
# ✅ All checks passed! Proceeding with commit.
```

To bypass (not recommended):
```bash
git commit --no-verify
```

---

## 🤖 Specialized Agents

### @db-architect
**Domain:** Supabase PostgreSQL, schema migrations, stored procedures

**Use when:**
- Creating/modifying database tables
- Writing SQL migrations
- Working with stored procedures
- Adding indexes or constraints

**Key Rules:**
- ❌ Never INSERT directly into `workout_*` tables
- ✅ Always use `commit_full_workout_v3` procedure
- ✅ Check for existing columns before `ALTER TABLE`
- ✅ Update `docs/SCHEMA_REFERENCE.md` after changes

---

### @parser-engineer
**Domain:** Text-to-JSON parsing, regex patterns, canonical schema

**Use when:**
- Fixing parser bugs
- Adding support for new text formats
- Working with golden set tests
- Updating regex patterns

**Key Rules:**
- ❌ Never hallucinate data (unknown = null)
- ✅ Always separate prescription from performance
- ✅ Follow Canonical JSON Schema v3.0
- ✅ Normalize exercise names via catalog

---

### @learning-specialist
**Domain:** Active learning system, correction capture, training loops

**Use when:**
- Logging parser corrections
- Running learning script (`npm run learn`)
- Analyzing error patterns
- Improving parser accuracy

**Key Rules:**
- ✅ Log corrections in `log_learning_examples` table
- ✅ Set appropriate priority (high/medium/low)
- ✅ Run `npm run learn` after fixes
- ✅ Verify improvements with `/verify`

---

### @golden-set-curator
**Domain:** Test case management, quality assurance, regression testing

**Use when:**
- Creating new test cases
- Reviewing auto-fixed files
- Analyzing test coverage
- Validating schema changes impact

**Key Rules:**
- ❌ Never modify expected output to match bugs
- ✅ One concept per test case
- ✅ Document all test cases in README
- ✅ Ensure no regressions before approval

---

## 📋 Slash Commands Reference

### /verify
**Purpose:** Run full validation suite before committing

**Duration:** ~30-60 seconds

**Steps:**
1. Schema verification (`verify_schema.sh`)
2. Golden set validation (`validate_golden_set.sh`)
3. Block type tests (`test_block_types.sh`)

**When to use:**
- Before every commit (automated by pre-commit hook)
- After making changes to parser logic
- After schema migrations
- After updating golden set

---

### /db-status
**Purpose:** Quick database health check

**Duration:** ~5 seconds

**Checks:**
- Database connectivity
- Table count (should be 32)
- Athlete and workout counts
- Active ruleset version

**When to use:**
- Starting work session
- Debugging connection issues
- Quick status check without full validation

---

### /fix-parser
**Purpose:** Auto-repair common parser errors

**Duration:** ~10-30 seconds

**Fixes:**
1. Type errors (strings → numbers)
2. Range formats ("8-12" → min/max)
3. Field ordering (v3.0 schema)
4. Weight structure (legacy → v3.0)
5. Hallucination detection (flags for review)

**When to use:**
- After updating Canonical Schema
- After finding systematic errors in golden set
- Before manual review of test cases

**Usage:**
```bash
# Fix all files
/fix-parser

# Fix specific file
/fix-parser workout_05

# Dry run (preview changes)
/fix-parser --dry-run
```

---

## ⚙️ Configuration

### settings.json

Controls agent behavior, permissions, and shortcuts.

**Key sections:**

```json
{
  "session": {
    "defaultMode": "plan",           // Plan before executing
    "autoAcceptEdits": false         // Ask before modifying files
  },
  "permissions": {
    "mode": "ask",                   // Ask before running commands
    "allow": [                       // Pre-approved commands
      "Bash(./scripts/verify_schema.sh)",
      "Bash(git status)"
    ],
    "deny": [                        // Blocked commands
      "Bash(rm -rf*)",
      "Bash(DROP TABLE*)"
    ]
  },
  "verification": {
    "requiredBeforeCommit": true,    // Must pass /verify
    "autoRunOnEdit": false           // Manual trigger only
  },
  "git": {
    "preCommitHook": {
      "enabled": true,               // Git hook active
      "path": ".git/hooks/pre-commit",
      "runVerify": true
    }
  }
}
```

---

## 🎯 Workflows

### Adding a New Feature

```
1. @db-architect - Plan database changes
   → Reviews schema, suggests migration structure

2. Create migration file
   → supabase/migrations/YYYYMMDDHHMMSS_feature_name.sql

3. /db-status
   → Verify connection before applying migration

4. Deploy migration
   → npx supabase db push

5. @parser-engineer - Update parser logic
   → Modify regex patterns or prompts

6. @golden-set-curator - Create test case
   → Add to data/golden_set/

7. /verify
   → Ensure all tests pass

8. git commit
   → Pre-commit hook runs /verify automatically
```

---

### Fixing a Parser Bug

```
1. @golden-set-curator - Reproduce bug as test case
   → Add failing case to golden set

2. /verify
   → Confirm test fails (expected)

3. @parser-engineer - Fix parser logic
   → Update patterns or prompts

4. /verify
   → Confirm test now passes

5. @learning-specialist - Log correction
   → INSERT into log_learning_examples

6. npm run learn
   → Update parser brain with correction

7. /verify
   → Ensure no regressions

8. git commit
   → Automatic verification passes
```

---

### Migrating to New Schema Version

```
1. @db-architect - Review CANONICAL_JSON_SCHEMA.md
   → Understand new requirements (e.g., v3.0 field ordering)

2. /fix-parser --dry-run
   → Preview what would be fixed

3. Review changes
   → Ensure fixes are correct

4. /fix-parser
   → Apply fixes to all golden set files

5. @golden-set-curator - Manual review
   → Check for any edge cases missed

6. /verify
   → All tests should pass

7. git commit
   → Large commit, ensure good description
```

---

## 🛡️ Safety Features

### Pre-Commit Hook
- Runs automatically on `git commit`
- Blocks commit if tests fail
- Can bypass with `--no-verify` (not recommended)
- Creates detailed failure reports

### Permissions System
- Ask before running destructive commands
- Block dangerous operations (DELETE, DROP, rm -rf)
- Pre-approve safe read-only operations
- Logs all command executions

### Backup Creation
- `/fix-parser` creates `.backup` files
- Easy rollback with git
- Version control tracks all changes

---

## 📚 Related Documents

- [agents.md](../agents.md) - Full AI agent instructions
- [ARCHITECTURE.md](../ARCHITECTURE.md) - System design
- [CANONICAL_JSON_SCHEMA.md](../docs/reference/CANONICAL_JSON_SCHEMA.md) - Parser spec
- [VALIDATION_SYSTEM_SUMMARY.md](../docs/VALIDATION_SYSTEM_SUMMARY.md) - Validation rules

---

## 🔧 Troubleshooting

### Pre-commit hook not running
```bash
# Check if hook is executable
ls -l .git/hooks/pre-commit

# If not, make executable
chmod +x .git/hooks/pre-commit
```

### Agent not loading context
```bash
# Ensure context files exist
ls -l agents.md ARCHITECTURE.md docs/reference/CANONICAL_JSON_SCHEMA.md

# Check settings.json has correct paths
cat .claude/settings.json | jq .agents
```

### /verify command not found
```bash
# Commands are defined in settings.json
cat .claude/settings.json | jq .shortcuts

# Should show:
# {
#   "/verify": ".claude/commands/verify.md",
#   "/db-status": ".claude/commands/db-status.md",
#   "/fix-parser": ".claude/commands/fix-parser.md"
# }
```

---

## 🎓 Best Practices

1. **Start sessions with context loading**
   ```
   Load agents.md and DB_READINESS_REPORT.md to restore project memory
   ```

2. **Use specific agents for specific tasks**
   ```
   Don't: "Fix this SQL"
   Do: "@db-architect - How should I structure this migration?"
   ```

3. **Run /verify frequently**
   ```
   After every significant change
   Before every commit (automated)
   When debugging issues
   ```

4. **Document all changes**
   ```
   Update CHANGELOG.md for user-facing changes
   Update agents.md if adding new patterns
   Update SCHEMA_REFERENCE.md after migrations
   ```

5. **Trust the golden set**
   ```
   It's the source of truth
   Never modify to match bugs
   Add test cases for edge cases
   ```

---

**Version:** 1.0.0  
**Last Updated:** January 10, 2026  
**Maintained By:** AI Development Team
