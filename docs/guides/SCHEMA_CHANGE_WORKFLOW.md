# Schema Change Documentation System

## 🎯 Problem

When making schema changes, it's easy to forget to update all related documentation files.

## ✅ Solution

We have a **semi-automated** system with reminders:

---

## 1️⃣ Interactive Checklist (Manual Trigger)

**Run after every schema change:**

```bash
./scripts/schema_change_checklist.sh
```

**Shows:**
- ✅ Files updated in last 5 minutes
- ⏸️  Files that need review/update
- ❌ Missing files

**Output Example:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2. Parser Documentation (Stage 2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ docs/guides/STAGE2_PARSING_STRATEGY.md
⏸️  docs/guides/PARSER_WORKFLOW.md
⏸️  docs/guides/AI_PROMPTS.md
```

---

## 2️⃣ Git Hook (Automatic Reminder)

**Install once:**

```bash
# Install post-commit hook
cp scripts/git-hooks/post-commit .git/hooks/post-commit
chmod +x .git/hooks/post-commit
```

**What it does:**
- Runs after every commit
- Detects schema-related changes
- Reminds you to run the checklist

**Triggers on changes to:**
- `data/golden_set/*.json`
- `supabase/migrations/*.sql`
- `docs/guides/STAGE2_PARSING_STRATEGY.md`
- `docs/guides/PARSER_AUDIT_CHECKLIST.md`

---

## 3️⃣ Validation Scripts (Quality Assurance)

**Always run before committing:**

```bash
# Validate schema v2 compliance
./scripts/validate_golden_set_schema_v2.sh

# Test parser accuracy
./scripts/test_parser_accuracy.sh
```

---

## 📋 Complete Workflow

### When Making Schema Changes:

1. **Make your changes** (JSON, SQL, code)

2. **Run validation:**
   ```bash
   ./scripts/validate_golden_set_schema_v2.sh
   ```

3. **Update documentation:**
   ```bash
   ./scripts/schema_change_checklist.sh
   ```
   - Go through each ⏸️  file and update if needed

4. **Run tests:**
   ```bash
   ./scripts/test_parser_accuracy.sh
   ```

5. **Commit:**
   ```bash
   git add .
   git commit -m "Schema v2: Add circuit_config pattern"
   ```
   - Post-commit hook will remind you if you forgot something

6. **Final check:**
   ```bash
   ./scripts/schema_change_checklist.sh
   ```
   - All relevant files should show ✅

---

## 📚 Files That Need Updating (by Type)

### Schema Changes in JSON:
- ✅ `data/golden_set/*.json` - Update examples
- ✅ `docs/guides/STAGE2_PARSING_STRATEGY.md` - Update patterns
- ✅ `docs/guides/PARSER_AUDIT_CHECKLIST.md` - Update validation
- ✅ `docs/guides/SCHEMA_UPDATES_YYYY-MM-DD.md` - Create migration guide
- ✅ `CHANGELOG.md` - Add version entry
- ✅ `docs/INDEX.md` - Update index

### Schema Changes in SQL:
- ✅ `supabase/migrations/*.sql` - Add migration
- ✅ `agents.md` - Auto-update via `update_agents_md.sh`
- ✅ `docs/VALIDATION_SYSTEM_SUMMARY.md` - Update if validation changed
- ✅ `CHANGELOG.md` - Add version entry

### New Parsing Patterns:
- ✅ `docs/guides/STAGE2_PARSING_STRATEGY.md` - Add pattern
- ✅ `docs/guides/AI_PROMPTS.md` - Update AI examples
- ✅ `docs/guides/PARSER_WORKFLOW.md` - Update workflow if needed
- ✅ `data/golden_set/*.json` - Add examples

---

## 🤖 Level of Automation

| Task | Status | Tool |
|------|--------|------|
| **Detect changes** | ✅ Automated | Git hooks |
| **Remind to update** | ✅ Automated | Checklist script |
| **Validate schema** | ✅ Automated | Validation scripts |
| **Update docs** | ⏸️  Manual | You! |
| **Check completion** | ✅ Automated | Checklist script |

**⚠️ Key Point:** Documentation updates are **manual** but **guided**.

---

## 💡 Future Improvements

To make it **fully automated**, we would need:

1. **Template-based docs** with variables
2. **Schema-to-markdown generator**
3. **Pre-commit hook** that blocks commits if docs outdated
4. **CI/CD pipeline** that validates doc freshness

**Current approach:** Balance between automation and flexibility ✅

---

**Last Updated:** January 10, 2026  
**Version:** 1.0
