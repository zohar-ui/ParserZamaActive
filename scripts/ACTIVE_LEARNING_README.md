# 🔄 Active Learning System

**Status:** ✅ Deployed  
**Version:** 1.0.0  
**Created:** January 10, 2026

---

## 🎯 Purpose

Close the feedback loop between **validation corrections** and **AI parser training**.

**The Problem:**
- Humans correct parsing mistakes during validation
- These corrections are lost knowledge
- Parser repeats the same mistakes

**The Solution:**
- Corrections are captured in `log_learning_examples` table
- Script fetches high-priority corrections
- Corrections are injected into AI prompts as few-shot examples
- Parser learns from past mistakes

---

## 📁 System Components

### 1. Database Table: `log_learning_examples`

**Location:** `/supabase/migrations/20260109160000_active_learning_system.sql`

**Schema:**
```sql
CREATE TABLE zamm.log_learning_examples (
    example_id UUID PRIMARY KEY,
    
    -- Source
    draft_id UUID,
    validation_report_id UUID,
    
    -- Data
    original_text TEXT,        -- Raw workout text
    original_json JSONB,       -- Wrong parser output
    corrected_json JSONB,      -- Human-corrected version
    
    -- Error details
    error_type VARCHAR(100),   -- 'missing_field', 'wrong_value', etc.
    error_location VARCHAR(200), -- JSON path
    error_description TEXT,
    
    -- Metadata
    learning_priority INTEGER, -- 1-10 (10 = critical)
    is_included_in_training BOOLEAN,
    tags TEXT[]
);
```

**How Examples Are Created:**
- Manually: Call `zamm.capture_learning_example()` function
- Automatically: Validation system can auto-capture critical errors (future feature)

---

### 2. Learning Loop Script: `update_parser_brain.js`

**Location:** `/workspaces/ParserZamaActive/scripts/update_parser_brain.js`

**What It Does:**
1. Queries `log_learning_examples` for untrained examples (priority >= 7)
2. Formats them as few-shot prompt blocks
3. Injects them into `docs/guides/AI_PROMPTS.md`
4. Marks examples as `is_included_in_training = true`

**Configuration:**
```javascript
const CONFIG = {
  minPriority: 7,              // Only include examples with priority >= 7
  maxExamples: 20,             // Keep total examples under this limit
  maxNewExamples: 5,           // Add max 5 new examples per run
};
```

---

### 3. Prompts File: `AI_PROMPTS.md`

**Location:** `/workspaces/ParserZamaActive/docs/guides/AI_PROMPTS.md`

**Dynamic Section:** `## 🧠 Dynamic Learning Examples`

This section is automatically updated by the learning loop script. It contains:
- Original raw text
- Wrong JSON output (before correction)
- Corrected JSON output (after human fix)
- Explanation of what was wrong
- Why it matters

**Format:**
```markdown
### Example: MISSING_FIELD (Priority 8) [hebrew, metcon]

**Original Text:**
```
עשיתי AMRAP 10 דקות
```

**Wrong Output (BEFORE):**
```json
{
  "prescription": { "target_duration_sec": 600 },
  "performed": null  // ❌ Missing actual performance
}
```

**Problem:** Text says "I did" but parser didn't capture performance
**Location:** `blocks[0].performed`

**Corrected Output (AFTER):**
```json
{
  "prescription": { "target_duration_sec": 600 },
  "performed": { "completed": true }  // ✅ Now captured
}
```

**Why This Matters:** Hebrew past tense verbs indicate actual performance, not just plan.
```

---

## 🚀 Usage

### Method 1: Direct Execution

```bash
# Make sure you're in the project root
cd /workspaces/ParserZamaActive

# Run the script
node scripts/update_parser_brain.js
```

### Method 2: NPM Script (Recommended)

**Setup (one-time):**
```bash
# Create package.json if it doesn't exist
npm init -y

# Add script
npm pkg set scripts.learn="node scripts/update_parser_brain.js"

# Install dependency
npm install @supabase/supabase-js
```

**Usage:**
```bash
npm run learn
```

---

## 📊 Example Workflow

### Step 1: Parser Makes Mistake

**Raw Text:**
```
עשיתי Back Squat 5x5 @ 100kg
הסט האחרון רק 4 חזרות
```

**Parser Output (WRONG):**
```json
{
  "prescription": { "target_sets": 5, "target_reps": 5, "target_weight_kg": 100 },
  "performed": { "actual_sets": 5, "actual_reps": 5 }  // ❌ Wrong! Last set was 4 reps
}
```

---

### Step 2: Human Corrects During Validation

**Corrected JSON:**
```json
{
  "prescription": { "target_sets": 5, "target_reps": 5, "target_weight_kg": 100 },
  "performed": {
    "sets": [
      { "set_index": 1, "reps": 5, "load_kg": 100 },
      { "set_index": 2, "reps": 5, "load_kg": 100 },
      { "set_index": 3, "reps": 5, "load_kg": 100 },
      { "set_index": 4, "reps": 5, "load_kg": 100 },
      { "set_index": 5, "reps": 4, "load_kg": 100, "notes": "Failed last rep" }
    ]
  }
}
```

**Capture Learning Example:**
```sql
SELECT zamm.capture_learning_example(
    p_draft_id := '...',
    p_validation_report_id := '...',
    p_original_text := 'עשיתי Back Squat 5x5 @ 100kg...',
    p_original_json := '{ ... wrong json ... }',
    p_corrected_json := '{ ... corrected json ... }',
    p_error_type := 'wrong_value',
    p_error_location := 'blocks[0].performed.sets[4].reps',
    p_error_description := 'Parser missed Hebrew text "רק 4 חזרות" (only 4 reps)',
    p_corrected_by := 'human',
    p_correction_notes := 'Hebrew text explicitly states last set was only 4 reps',
    p_learning_priority := 9,  -- High priority! Hebrew parsing issue
    p_tags := ARRAY['hebrew', 'set_failure', 'strength']
);
```

---

### Step 3: Run Learning Loop

```bash
npm run learn
```

**Output:**
```
🤖 ACTIVE LEARNING LOOP - Starting...

✅ Supabase client initialized
📥 Fetching untrained learning examples...
   Found 1 examples (priority >= 7)

📝 Updating AI_PROMPTS.md...
   Currently 0 examples in prompts file
   ✅ Added 1 new examples to AI_PROMPTS.md

✅ Marking examples as trained...
   Updated 1 records in database

🎉 ACTIVE LEARNING COMPLETE!
   📚 1 new examples added to parser brain
   📄 Updated: /workspaces/ParserZamaActive/docs/guides/AI_PROMPTS.md
   💾 Database marked 1 examples as trained

💡 Next steps:
   1. Review the updated AI_PROMPTS.md
   2. Use the updated prompts in your next parsing session
   3. The parser should now avoid these mistakes!
```

---

### Step 4: Parser Learns

**Next Time:**
The parser sees this in its prompt:
```markdown
### Example: WRONG_VALUE (Priority 9) [hebrew, set_failure, strength]

**Original Text:**
עשיתי Back Squat 5x5 @ 100kg
הסט האחרון רק 4 חזרות

**Wrong Output (BEFORE):**
{ actual_reps: 5 }  ❌

**Corrected Output (AFTER):**
{ sets: [..., { set_index: 5, reps: 4, notes: "Failed last rep" }] }  ✅

**Why This Matters:** Hebrew text "רק 4 חזרות" means "only 4 reps" - parser must parse Hebrew correctly!
```

Parser now knows to look for Hebrew keywords like "רק" (only) and parse set failures correctly! 🎉

---

## 🛠️ Manual Example Creation

If you want to manually create a learning example (outside of validation flow):

```sql
SELECT zamm.capture_learning_example(
    p_draft_id := NULL,  -- Optional
    p_validation_report_id := NULL,  -- Optional
    p_original_text := 'Your raw workout text here',
    p_original_json := '{ "wrong": "json" }'::jsonb,
    p_corrected_json := '{ "correct": "json" }'::jsonb,
    p_error_type := 'missing_field',  -- or 'wrong_value', 'wrong_structure', etc.
    p_error_location := 'blocks[0].prescription.target_reps',
    p_error_description := 'Clear explanation of what was wrong',
    p_corrected_by := 'human',  -- or 'ai_assisted', 'automated'
    p_correction_notes := 'Why this correction is important',
    p_learning_priority := 8,  -- 1-10 scale
    p_tags := ARRAY['edge_case', 'hebrew', 'metcon']  -- Optional tags
);
```

---

## 📈 Priority Guidelines

**Priority 10 (Critical):**
- Data loss (missing entire blocks)
- Complete misunderstanding of workout structure
- Safety issues (wrong weight parsing)

**Priority 8-9 (High):**
- Language-specific parsing errors (Hebrew/English)
- Complex structure misinterpretation (circuits, AMRAPs)
- Prescription/performance separation failures

**Priority 6-7 (Medium):**
- Edge cases (unusual rep schemes, weird equipment)
- Nuanced differences (tempo, position variations)

**Priority 4-5 (Low):**
- Minor formatting issues
- Alias mismatches (easily fixable)

**Priority 1-3 (Very Low):**
- Typos in notes
- Cosmetic issues

**Default:** 7 (included in training by default)

---

## 🔧 Troubleshooting

### Issue: "SUPABASE_SERVICE_KEY not found"

**Solution:**
```bash
# Check .env.local file
cat .env.local | grep SUPABASE

# Should see:
# SUPABASE_URL=https://...
# SUPABASE_ANON_KEY=...
# or SUPABASE_SERVICE_KEY=...

# If missing, add them
```

---

### Issue: "No new examples to train"

**Reason:** No corrections have been made yet, or all corrections are already trained.

**Solution:**
1. Run validation on parsed workouts
2. Make corrections
3. Capture learning examples using `capture_learning_example()` function
4. Re-run `npm run learn`

---

### Issue: Script fails with "Cannot find module '@supabase/supabase-js'"

**Solution:**
```bash
npm install @supabase/supabase-js
```

---

## 📚 Related Documents

- [CANONICAL_JSON_SCHEMA.md](../reference/CANONICAL_JSON_SCHEMA.md) - Parser output schema
- [AI_PROMPTS.md](./AI_PROMPTS.md) - Parser agent instructions (updated by this system)
- [PARSER_WORKFLOW.md](./PARSER_WORKFLOW.md) - Full parsing pipeline
- [VALIDATION_SYSTEM_SUMMARY.md](../VALIDATION_SYSTEM_SUMMARY.md) - Validation system

---

## 🚦 Status & Roadmap

### ✅ Completed (v1.0.0)
- [x] Database table for learning examples
- [x] Learning loop script
- [x] AI_PROMPTS.md dynamic section
- [x] Manual example creation function
- [x] Priority-based filtering
- [x] Tag system for categorization

### 🔜 Planned (v1.1.0)
- [ ] Automated example capture during validation
- [ ] Web UI for example review
- [ ] Example quality scoring
- [ ] Automatic example pruning (remove obsolete examples)
- [ ] A/B testing of parser versions

---

**Last Updated:** January 10, 2026  
**Maintainer:** AI Development Team  
**Status:** 🟢 Production Ready
