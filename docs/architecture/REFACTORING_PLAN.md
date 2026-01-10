# Repository Refactoring Plan

**Date:** January 10, 2026
**Goal:** Clean Root, organize by function, reduce cognitive load for AI agents

---

## 🎯 Target Structure

```
/
├── .claude/                    # AI agent configuration (stays)
├── .github/                    # CI/CD (stays)
├── supabase/                   # Database (stays)
├── data/
│   ├── raw_logs/              # ✨ NEW - Raw workout txt files
│   ├── golden_set/            # Stays - Validated JSON pairs
│   ├── test_v3.2_parsed.json  # Stays - Test outputs
│   └── stress_test_10.txt     # Stays - Test scenarios
├── docs/
│   ├── architecture/          # ✨ NEW - System design docs
│   ├── context/               # ✨ NEW - AI agent context
│   ├── guides/                # Stays - How-to guides
│   ├── reference/             # Stays - Technical specs
│   ├── reports/               # ✨ NEW - Historical reports
│   ├── api/                   # Stays - SQL examples
│   └── archive/               # Stays - Deprecated docs
├── scripts/
│   ├── tests/                 # ✨ NEW - All test scripts
│   ├── ops/                   # ✨ NEW - Operations & maintenance
│   ├── active_learning/       # ✨ NEW - Learning loop
│   └── utils/                 # ✨ NEW - General utilities
├── package.json               # Stays
├── README.md                  # Stays - Main entry point
├── CHANGELOG.md               # Stays
└── TODO.md                    # Stays

```

---

## 📦 Migration Map

### 1. Root → docs/reports/

Move historical reports that document completed work:

```bash
MISSION_COMPLETE.md → docs/reports/
DB_READINESS_REPORT.md → docs/reports/
IMPLEMENTATION_SUMMARY.md → docs/reports/
SYNCHRONIZATION_COMPLETE.md → docs/reports/
SUMMARY_HE.md → docs/reports/
CANONICAL_COMPLIANCE_REPORT_HE.md → docs/reports/
FIXES_APPLIED.md → docs/reports/
QA_STRESS_TEST_REPORT.md → docs/reports/
STRESS_TEST_SUMMARY.md → docs/reports/
PARSER_V3.2_TEST_REPORT.md → docs/reports/
SCHEMA_V3.2_UPGRADE_REPORT.md → docs/reports/
AI_PROMPTS_V3.2_UPDATE.md → docs/reports/
```

### 2. Root → docs/architecture/

Move system design and reference documentation:

```bash
ARCHITECTURE.md → docs/architecture/
SCHEMA_REFERENCE.md → docs/architecture/
REORGANIZATION.md → docs/architecture/
OPERATIONAL_EFFICIENCY_UPGRADES.md → docs/architecture/
```

### 3. Root → docs/context/

Move AI agent instructions and project state:

```bash
agents.md → docs/context/
TODO.md → docs/context/  # Or keep in Root? (decide)
```

**CRITICAL:** Update `.claude/CLAUDE.md` references to agents.md after move!

### 4. Root → docs/guides/

Move user-facing guides:

```bash
ACTIVE_LEARNING_QUICKSTART.md → docs/guides/
ACTIVE_LEARNING_DEMO.md → docs/guides/
WORKFLOW_GUIDE.md → docs/guides/  # Merge with existing?
ENVIRONMENT_SETUP.md → docs/guides/
SUPABASE_CLI_CHEATSHEET.md → docs/guides/
```

### 5. Root - KEEP THESE

Essential files that stay in Root:

```bash
README.md               # Main entry point
CHANGELOG.md            # Version history
package.json            # Node config
.gitignore              # Git config
.env                    # Secrets (not in git)
```

### 6. Root - DEPRECATED FILES

Consider archiving or deleting:

```bash
CLAUDE.md → .claude/CLAUDE.md (already there, delete Root copy)
supabase.md → docs/guides/ or delete if redundant
```

---

## 📂 scripts/ Reorganization

### scripts/tests/ (Testing & Validation)

```bash
test_parser_accuracy.sh
test_block_types.sh
test_execution.sh
validate_golden_set.sh
validate_golden_sets.py
validate_golden_sets.sh
validate_stage2_parsing.sh
parser_patterns.js
```

### scripts/active_learning/ (Learning Loop)

```bash
update_parser_brain.js
fix_hallucinations.js
fix_ranges.js
fix_parser_errors.js
fix_golden_set_parsing.js
extract_original_texts.sh
extract_texts_v2.sh
generate_review_doc.sh
```

### scripts/ops/ (Operations & Maintenance)

```bash
verify_schema.sh
update_agents_md.sh
migrate_schema_v3.js
migrate_schema_v3.py
upgrade_to_v3.2.py
fix_circuit_config_legacy.py
add_equipment_keys.js
add_equipment_keys.py
audit_equipment_keys.js
bulk_add_equipment.py
schema_change_checklist.sh
cleanup_test_data.sql
check_all_tables.sql
check_all_tables_v2.sql
check_tables_simple.sql
list_tables.sql
sql_template.sql
```

### scripts/utils/ (General Utilities)

```bash
claude.sh
git-hooks/
README.md
ACTIVE_LEARNING_README.md
```

---

## 📁 data/ Reorganization

### Create data/raw_logs/

Move all raw workout txt files:

```bash
data/*.txt → data/raw_logs/

Specifically:
- Workout Log: Arnon Shafir.txt
- Workout Log: Jonathan benamou.txt
- Workout Log: Melany Zyman.txt
- Workout Log: Orel Ben Haim.txt
- Workout Log: Yarden Arad.txt
- Workout Log: Yarden Frank.txt
- Workout Log: Yehuda Devir.txt
- Workout Log: itamar shatnay.txt
- Workout Log: tomer yacov.txt
- bader_workout_log.txt
- test_v3.2_sample.txt
- stress_test_10.txt (keep in data/ root for easy access)
```

---

## 🔧 Required Updates After Move

### 1. Update .claude/ Configuration

File: `.claude/CLAUDE.md`

```markdown
# Before:
Read agents.md to restore context

# After:
Read docs/context/agents.md to restore context
```

File: `.claude_aliases` (if exists)

```bash
# Update any paths referencing agents.md
```

### 2. Update package.json Scripts

```json
{
  "scripts": {
    "test": "bash scripts/tests/test_parser_accuracy.sh",
    "validate": "bash scripts/tests/validate_golden_set.sh",
    "learn": "node scripts/active_learning/update_parser_brain.js",
    "verify": "bash scripts/ops/verify_schema.sh"
  }
}
```

### 3. Update Script Internal Paths

Files that reference other scripts or data:

- `scripts/tests/test_parser_accuracy.sh` - may reference data/golden_set/
- `scripts/tests/validate_golden_set.sh` - references data/golden_set/
- `scripts/active_learning/update_parser_brain.js` - may reference docs/guides/AI_PROMPTS.md
- Any script using relative paths to docs/ or data/

### 4. Update Git Hooks

File: `scripts/utils/git-hooks/pre-commit`

Update any paths to verification scripts:

```bash
# Before:
bash scripts/ops/verify_schema.sh

# After:
bash scripts/ops/verify_schema.sh
```

---

## 🚀 Execution Steps

### Phase 1: Create Structure (Safe)

```bash
mkdir -p docs/architecture
mkdir -p docs/context
mkdir -p docs/reports
mkdir -p scripts/tests
mkdir -p scripts/ops
mkdir -p scripts/active_learning
mkdir -p scripts/utils
mkdir -p data/raw_logs
```

### Phase 2: Move Documentation (Low Risk)

```bash
# Move reports
git mv MISSION_COMPLETE.md docs/reports/
git mv DB_READINESS_REPORT.md docs/reports/
# ... (all reports)

# Move architecture docs
git mv ARCHITECTURE.md docs/architecture/
git mv SCHEMA_REFERENCE.md docs/architecture/
# ... (all architecture docs)

# Move guides
git mv ACTIVE_LEARNING_QUICKSTART.md docs/guides/
# ... (all guides)
```

### Phase 3: Move Scripts (Medium Risk)

```bash
# Move test scripts
git mv scripts/tests/test_parser_accuracy.sh scripts/tests/
git mv scripts/test_block_types.sh scripts/tests/
# ... (all test scripts)

# Move ops scripts
git mv scripts/ops/verify_schema.sh scripts/ops/
# ... (all ops scripts)

# Move learning scripts
git mv scripts/active_learning/update_parser_brain.js scripts/active_learning/
# ... (all learning scripts)
```

### Phase 4: Move Data Files (Low Risk)

```bash
# Move raw logs
git mv "data/Workout Log: Arnon Shafir.txt" data/raw_logs/
# ... (all txt files except stress_test_10.txt)
```

### Phase 5: Update References (HIGH RISK)

1. Update `.claude/CLAUDE.md` agents.md path
2. Update `package.json` script paths
3. Update internal script paths (grep for hardcoded paths)
4. Update git hooks paths
5. Test all scripts with new structure

### Phase 6: Validate & Commit

```bash
# Test critical workflows
npm test
npm run validate
./scripts/ops/verify_schema.sh

# If all pass:
git add -A
git commit -m "refactor: Reorganize repository structure for clarity

- Move documentation to docs/ subdirectories (architecture, reports, guides, context)
- Organize scripts/ by function (tests, ops, active_learning, utils)
- Move raw workout logs to data/raw_logs/
- Update all file path references
- Clean Root directory (27 → 5 markdown files)

Goal: Reduce cognitive load for AI agents and improve navigability"
```

---

## ⚠️ Risks & Mitigation

### Risk 1: Broken Script References
**Mitigation:** Grep for all hardcoded paths before committing:
```bash
grep -r "scripts/" scripts/
grep -r "docs/" scripts/
grep -r "data/" scripts/
```

### Risk 2: Git History Loss
**Mitigation:** Use `git mv` (not `mv`) to preserve history

### Risk 3: Broken .claude/ Integration
**Mitigation:** Test agent initialization after changes:
```bash
claude "Read docs/context/agents.md and verify all paths work"
```

### Risk 4: Broken CI/CD
**Mitigation:** Check `.github/workflows/` for hardcoded paths

---

## ✅ Success Criteria

- [ ] Root directory has ≤5 markdown files
- [ ] All scripts organized into functional subdirectories
- [ ] All raw data in data/raw_logs/
- [ ] No broken paths in scripts or configs
- [ ] All tests pass: `npm test`, `npm run validate`
- [ ] AI agent can read docs/context/agents.md successfully
- [ ] Git history preserved (use `git log --follow` to verify)

---

## 🔄 Rollback Plan

If something breaks:

```bash
# Create backup branch before starting
git checkout -b refactoring-backup

# If issues occur on main branch:
git revert HEAD  # Undo refactoring commit
# Or:
git reset --hard HEAD~1  # If not pushed yet
```

---

**Prepared By:** Claude Sonnet 4.5
**Review Status:** Pending user approval
**Estimated Time:** 30-45 minutes (careful execution)
