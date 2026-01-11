# Pipeline Scripts - Master Orchestrator

**Purpose:** End-to-end automation for parsing workout files into database records.

**Version:** 1.0.0
**Last Updated:** 2026-01-11

---

## Overview

The Master Orchestrator provides a complete workflow for processing raw workout logs:

```
Raw Text → Parse → Validate → Commit → Git Track
```

These scripts work **WITH** Claude Code + MCP, not as standalone parsers. The AI agent performs the actual parsing using MCP database queries.

---

## Files

### 1. `parse_workout.js` - Stages 1-3

**Purpose:** Prepare workout file for parsing, guide AI agent through parsing process.

**Usage:**
```bash
npm run pipeline -- --file=data/golden_set/tomer_2025-11-02_simple_deadlift.txt
npm run pipeline -- --file=path/to/workout.txt --validate-only
npm run pipeline -- --file=path/to/workout.txt --dry-run
```

**What it does:**
- Reads workout file
- Calculates checksum for idempotency
- Extracts athlete name and date from filename
- Saves context to `.tmp/pipeline_context.json`
- Provides step-by-step instructions for AI agent

**Options:**
- `--file=<path>` - Path to workout file (required)
- `--validate-only` - Stop after validation (no commit)
- `--dry-run` - Show what would happen without committing
- `--no-git` - Skip git tracking
- `--force` - Auto-approve warnings

---

### 2. `commit_draft.js` - Stage 4

**Purpose:** Commit validated draft to database using stored procedure.

**Usage:**
```bash
npm run commit-draft -- --draft=<draft_id>
npm run commit-draft -- --draft=abc-123-def --force
npm run commit-draft -- --draft=abc-123-def --dry-run
```

**What it does:**
- Retrieves draft from `stg_parse_drafts`
- Checks validation status
- Calls `commit_full_workout_v3()` stored procedure
- Verifies workout was created successfully
- Updates draft status to 'approved'

**Options:**
- `--draft=<id>` - Draft ID to commit (required)
- `--force` - Skip warning approval
- `--dry-run` - Show what would be committed without executing

---

### 3. `git_helper.js` - Stage 5 (Optional)

**Purpose:** Track processed workouts in git for audit trail.

**Usage:**
```bash
npm run git-track -- --athlete="Tomer Yacov" --date="2025-11-02" --workout-id="abc-123"
```

**What it does:**
- Creates branch: `data/workout-{athlete-slug}-{date}`
- Saves artifacts:
  - `data/processed/{athlete}/{date}_raw.txt`
  - `data/processed/{athlete}/{date}_parsed.json`
  - `data/processed/{athlete}/{date}_validation.json`
- Commits with descriptive message
- Returns to original branch

**Options:**
- `--athlete=<name>` - Athlete full name (required)
- `--date=<YYYY-MM-DD>` - Workout date (required)
- `--workout-id=<id>` - Workout UUID
- `--import-id=<id>` - Import UUID
- `--draft-id=<id>` - Draft UUID
- `--blocks=<n>` - Number of blocks
- `--items=<n>` - Number of items
- `--raw-text=<text>` - Original workout text
- `--parsed-json=<json>` - Parsed JSON
- `--validation-json=<json>` - Validation report

---

### 4. `visual_diff.js` - Utility

**Purpose:** Display prescription vs performance comparison.

**Usage:**
```bash
npm run visual-diff -- --json=path/to/parsed.json

# In code:
const { displayDiff } = require('./scripts/pipeline/visual_diff');
displayDiff(workoutJson);
```

**What it does:**
- Displays side-by-side comparison
- Shows mismatches (e.g., actual reps < target reps)
- Highlights warnings and errors
- Provides visual feedback for AI agent and user

**Output Example:**
```
═══════════════════════════════════════════════════════════
  📋 PRESCRIPTION vs PERFORMANCE
═══════════════════════════════════════════════════════════

Block: STR - strength
Deadlift

  Conventional Deadlift (deadlift) [barbell]

  PRESCRIPTION:                 PERFORMED:
  ├─ Sets: 3                    ├─ Sets: 3 ✓
  ├─ Reps: 5                    ├─ Set 1: 5 reps ✓
  ├─ Load: 140kg                ├─ Set 2: 5 reps ✓
  └─ RPE: 7                     ├─ Set 3: 4 reps ⚠️ (target: 5)
                                └─ Notes: "back rounding"

  Set-by-Set Breakdown:
    Set 1: 5 reps @ 140kg  ✓
    Set 2: 5 reps @ 140kg  ✓
    Set 3: 4 reps @ 140kg ⚠️  (target: 5) - back rounding
```

---

## Complete Workflow Example

### Step 1: Start Pipeline
```bash
npm run pipeline -- --file=data/golden_set/tomer_2025-11-02_simple_deadlift.txt
```

**Output:**
```
🚀 Master Orchestrator - Workout Parsing Pipeline

============================================================
📄 Reading file: tomer_2025-11-02_simple_deadlift.txt
   Size: 1580 characters
   Checksum: 72990e9007ca9afe...
   Detected athlete: tomer
   Detected date: 2025-11-02

✅ Stage 1: Context & Ingestion - Ready

📋 NEXT STEPS FOR AI AGENT:
1️⃣  Find athlete in database...
2️⃣  Get active parser ruleset...
3️⃣  Import raw text...
```

### Step 2: AI Agent Parses (Using MCP)

The AI agent now:
1. Finds athlete: "Tomer Yacov" → `athlete_id`
2. Gets ruleset: "units_v1" version 1.2
3. Imports text to `stg_imports` with checksum
4. Parses workout into structured JSON
5. Validates JSON against schema
6. Displays visual diff

### Step 3: Commit Draft
```bash
npm run commit-draft -- --draft=abc-123-def
```

**Output:**
```
💾 Stage 4: Atomic Commit to Database

============================================================
📝 Draft ID: abc-123-def

📋 NEXT STEPS FOR AI AGENT:
1️⃣  Retrieve draft...
2️⃣  Check validation...
3️⃣  Call commit_full_workout_v3()...
```

### Step 4: Track in Git (Optional)
```bash
npm run git-track -- --athlete="Tomer Yacov" --date="2025-11-02" --workout-id="xyz-789"
```

**Output:**
```
🎯 Stage 5: Git Tracking

============================================================
👤 Athlete: Tomer Yacov
📅 Date: 2025-11-02
🌿 Branch: data/workout-tomer-yacov-2025-11-02

🔨 Creating workout branch...
💾 Saving artifacts...
   ✓ Raw text: data/processed/tomer_yacov/2025-11-02_raw.txt
   ✓ Parsed JSON: data/processed/tomer_yacov/2025-11-02_parsed.json
   ✓ Validation: data/processed/tomer_yacov/2025-11-02_validation.json

📦 Staging files...
✍️  Committing changes...
🔙 Returning to main...

✅ Git tracking complete
```

---

## Integration with /process-workout Command

The `/process-workout` Claude Code command orchestrates all these scripts:

```
User: /process-workout

Claude: Which workout file should I process?
User: data/golden_set/tomer_2025-11-02_simple_deadlift.txt

Claude: [Runs npm run pipeline]
Claude: [Uses MCP to parse workout]
Claude: [Displays visual diff]
Claude: [Asks for approval]
Claude: [Runs npm run commit-draft]
Claude: [Runs npm run git-track]
Claude: ✅ Workout processed successfully!
```

---

## Error Handling

### File Not Found
```
❌ Error: File not found: data/missing.txt
```
**Solution:** Check file path, ensure file exists

### Athlete Not Found
AI agent queries database:
```sql
SELECT * FROM zamm.lib_athletes WHERE full_name ILIKE '%tomer%'
```
If no results:
```
❌ Error: Athlete "Tomer" not found
Suggestions: Create athlete first with npm run create-athlete
```

### Validation Failed
```
❌ Validation Failed: Cannot commit

Errors:
1. Block code "STRENGTH" is invalid → Use "STR"
2. Exercise key "unknown" does not exist
```
**Solution:** Fix errors manually or update parser logic

### Commit Failed
```
❌ Commit Failed: Foreign key constraint violated
```
**Solution:** Re-run validation, check catalog entries exist

---

## Development

### Adding New Features

**1. Add new stage:**
- Create script: `scripts/pipeline/my_stage.js`
- Add npm script: `"my-stage": "node scripts/pipeline/my_stage.js"`
- Update `/process-workout` command documentation
- Test workflow end-to-end

**2. Modify existing stage:**
- Edit script file
- Update README if behavior changes
- Test with sample workouts
- Run `/verify` to ensure no regressions

### Testing

```bash
# Test individual stages
npm run pipeline -- --file=data/golden_set/tomer_2025-11-02_simple_deadlift.txt --dry-run
npm run commit-draft -- --draft=test-123 --dry-run
npm run visual-diff -- --json=.tmp/test_parsed.json

# Test complete workflow
/process-workout  # In Claude Code
```

---

## Troubleshooting

### "Cannot find module"
```
Error: Cannot find module './visual_diff'
```
**Solution:** Run `npm install` to ensure dependencies are installed

### "Permission denied"
```
Error: EACCES: permission denied
```
**Solution:** Make scripts executable: `chmod +x scripts/pipeline/*.js`

### "MCP not available"
AI agent cannot use MCP tools.
**Solution:**
- Check MCP configuration: `claude mcp list`
- Verify Supabase connection: `/db-status`
- Reconfigure MCP: `./scripts/setup_mcp.sh --force`

### "Git working directory not clean"
```
⚠️  Warning: Working directory has uncommitted changes
```
**Solution:** Commit or stash changes before running git-track

---

## Related Documentation

- [/process-workout command](.claude/commands/process-workout.md) - Full command documentation
- [MCP Parsing Workflow](../../docs/guides/MCP_PARSING_WORKFLOW.md) - How MCP integrates with parsing
- [CANONICAL_JSON_SCHEMA.md](../../docs/reference/CANONICAL_JSON_SCHEMA.md) - Output format specification

---

**Maintained By:** AI Development Team
**Status:** ✅ Production Ready
