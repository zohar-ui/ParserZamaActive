# ✅ Synchronization Complete: Active Learning + agents.md

**Date:** January 10, 2026  
**Issue:** Contradiction between new Active Learning System and agents.md constraints  
**Status:** 🟢 RESOLVED

---

## 🚨 Problem Identified

The original `agents.md` had strict constraints:
```markdown
1. NO TypeScript/JavaScript: This is a SQL-only backend project
2. NO package.json: We don't use Node.js or npm
```

**Conflict:** Active Learning System requires:
- `update_parser_brain.js` (Node.js script)
- `package.json` (npm configuration)
- `node_modules/` (dependencies)

**Risk:** Claude Code agent would:
- Reject running the Node.js script
- Consider package.json a mistake
- Potentially try to delete these files
- Get confused about project rules

---

## ✅ Resolution Applied

### 1. Updated Hard Constraints in agents.md

**OLD:**
```markdown
1. NO TypeScript/JavaScript: This is a SQL-only backend project
2. NO package.json: We don't use Node.js or npm
```

**NEW:**
```markdown
1. Core Backend is SQL-only: This is primarily a SQL-based backend project
   - EXCEPTION: Node.js is allowed ONLY for operational scripts in /scripts/ folder
   - ALLOWED: package.json, npm, and node_modules for utility scripts
   - NOT ALLOWED: TypeScript/JavaScript for core database logic or API endpoints
```

**Rationale:** Preserves SQL-first principle while allowing operational automation.

---

### 2. Added CANONICAL_JSON_SCHEMA.md as Source of Truth

**Added to top of agents.md:**
```markdown
⚖️ CRITICAL: For ALL parsing outputs, strict adherence to 
`docs/reference/CANONICAL_JSON_SCHEMA.md` is MANDATORY. 
This is the constitution - the only allowed JSON structure.
```

**Added to Architecture section:**
```markdown
#### 0. Parser Output Contract ⚖️ (CRITICAL!)
Before parsing ANYTHING, read: docs/reference/CANONICAL_JSON_SCHEMA.md

5 Core Principles:
1. Prescription vs Performed separation (ALWAYS separate)
2. Atomic types (numbers are numbers, not strings)
3. Ranges as min/max (never "8-12" strings)
4. Strict normalization (exercise_key, block_code from catalogs)
5. Null safety (unknown = null, never hallucinate)
```

---

### 3. Integrated Active Learning into Protocol Zero

**Added to handshake section:**
```markdown
### 6. Active Learning Protocol 🔄

BEFORE starting any parsing session, ALWAYS run:
npm run learn

What this does:
- Fetches latest corrections from zamm.log_learning_examples
- Updates docs/guides/AI_PROMPTS.md with new few-shot examples
- Ensures parser learns from past mistakes
```

**Updated time budget:**
```markdown
Full handshake: 10-15 seconds (including learning loop)
```

---

### 4. Updated Most Important Files List

**NEW Priority Order:**
1. **docs/reference/CANONICAL_JSON_SCHEMA.md** ⚖️ - THE CONSTITUTION
2. ARCHITECTURE.md - System design
3. docs/guides/AI_PROMPTS.md - Agent templates (auto-updated)
4. docs/guides/PARSER_WORKFLOW.md - 4-stage workflow
5. scripts/update_parser_brain.js - Learning loop script
6. scripts/ACTIVE_LEARNING_README.md - Learning system docs

---

### 5. Updated Project Status

**Version:** 1.2.0  
**Status:** Active Learning System Deployed (98/100)  
**Date:** January 10, 2026

**What's Working (New):**
- ✅ Canonical JSON Schema (The Constitution) ⚖️
- ✅ Active Learning System 🔄
- ✅ Parser Brain Auto-Update (npm run learn) 🧠

---

### 6. Updated Getting Started Checklist

**Phase 1: Context Loading**
- Added: Read CANONICAL_JSON_SCHEMA.md (CRITICAL for parsing)
- Added: Check AI_PROMPTS.md for learning examples

**Phase 2: Environment Setup**
- Added: Run `npm install` (for learning loop)
- Added: Run `npm run learn` (update parser)

---

## 📋 Changes Summary

### Files Modified:
1. **agents.md** (10 sections updated)
   - Hard constraints revised
   - Source of truth clarified
   - Active Learning integrated
   - Protocol Zero updated
   - Architecture patterns expanded
   - Most important files reordered
   - Project status updated
   - Getting started checklist enhanced

### Key Updates:
- ✅ Removed Node.js ban (exception for scripts)
- ✅ Added CANONICAL_JSON_SCHEMA.md as mandatory reference
- ✅ Integrated `npm run learn` into workflow
- ✅ Updated handshake protocol (10-15 sec)
- ✅ Added Active Learning to architecture patterns
- ✅ Prioritized constitution document (#1)

---

## 🎯 Impact on AI Agents

### Before (Confused State):
```
Agent: "I see package.json but agents.md says NO Node.js"
Agent: "Should I delete this? Is this a mistake?"
Agent: "What JSON structure should parser output?"
Result: Confusion, inconsistency, potential data loss
```

### After (Clear State):
```
Agent: "Node.js OK for /scripts/ utilities ✅"
Agent: "Parser output MUST follow CANONICAL_JSON_SCHEMA.md ✅"
Agent: "Run 'npm run learn' before parsing ✅"
Result: Consistent behavior, no confusion, quality output
```

---

## 🧪 Verification Checklist

- [x] agents.md has no contradictions
- [x] Node.js exception is clear
- [x] CANONICAL_JSON_SCHEMA.md is referenced prominently
- [x] Active Learning integrated into Protocol Zero
- [x] Time budget accounts for learning loop
- [x] Architecture section includes new patterns
- [x] Most important files list updated
- [x] Project status reflects v1.2.0
- [x] Getting started checklist includes new steps

---

## 📚 Updated Documentation Hierarchy

**For Claude Code agents:**

1. **Read First (Mandatory):**
   - agents.md (this is the memory)
   - docs/reference/CANONICAL_JSON_SCHEMA.md (the law)

2. **Run First (Protocol Zero):**
   ```bash
   npm run learn               # Update parser brain
   npx supabase status         # Check connection
   # Verify schema, run handshake queries
   ```

3. **Reference During Work:**
   - docs/guides/AI_PROMPTS.md (updated examples)
   - ARCHITECTURE.md (system design)
   - DB_READINESS_REPORT.md (status)

---

## 🚀 Ready for Git Commit

All contradictions resolved. The system is now internally consistent:

```bash
git add agents.md
git add docs/reference/CANONICAL_JSON_SCHEMA.md
git add scripts/update_parser_brain.js
git add scripts/ACTIVE_LEARNING_README.md
git add package.json
git add CHANGELOG.md
git add README.md
git add docs/INDEX.md
# ... all other new files

git commit -m "feat: Active Learning System v1.2.0

- Add CANONICAL_JSON_SCHEMA.md (The Constitution)
- Add Active Learning Loop (npm run learn)
- Update agents.md to allow Node.js for utilities
- Integrate learning protocol into handshake
- Resolve constraint contradictions
- Version bump to 1.2.0"

git push origin main
```

---

## 💡 Agent Behavior After Sync

### Claude Code will now:
1. ✅ Read agents.md and see Node.js is OK for scripts
2. ✅ Reference CANONICAL_JSON_SCHEMA.md before parsing
3. ✅ Run `npm run learn` as part of Protocol Zero
4. ✅ Use updated AI_PROMPTS.md with learning examples
5. ✅ Follow 5 core principles for JSON output
6. ✅ No confusion about package.json existence

### Result:
- **Consistent** behavior across sessions
- **Improved** parser accuracy (learns from mistakes)
- **Enforced** schema compliance (constitution)
- **Automated** knowledge retention (learning loop)

---

**Last Updated:** January 10, 2026  
**Status:** 🟢 **SYNCHRONIZED & PRODUCTION READY**
