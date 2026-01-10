# 🚀 Active Learning System - Quick Start Guide

**Created:** January 10, 2026  
**For:** Backend Engineers & AI Developers

---

## 🎯 What Is This?

The **Active Learning Loop** makes your parser **smarter over time** by learning from validation corrections.

```
┌─────────────────────────────────────────────────────────────┐
│                   THE LEARNING CYCLE                        │
└─────────────────────────────────────────────────────────────┘

   Parser makes mistake
          ↓
   Human corrects it
          ↓
   Correction saved to DB (log_learning_examples)
          ↓
   Run: npm run learn
          ↓
   Example injected into AI prompts
          ↓
   Parser sees example next time
          ↓
   Parser doesn't make same mistake! 🎉
          ↓
   (Repeat forever)
```

---

## 📦 What You Got Today

### 1. **The Constitution** 📜

**File:** `docs/reference/CANONICAL_JSON_SCHEMA.md`

- Defines the ONLY allowed JSON schema for parser output
- 5 core principles (prescription/performed, atomic types, ranges, normalization, null safety)
- Test cases the parser MUST pass
- Common errors to avoid

**Why:** Gives parser a strict contract to follow. No more ambiguity!

---

### 2. **Learning Loop Script** 🤖

**File:** `scripts/update_parser_brain.js`

**What it does:**
1. Queries DB for untrained corrections (priority >= 7)
2. Formats as few-shot examples
3. Injects into `AI_PROMPTS.md`
4. Marks as trained

**Run it:**
```bash
npm run learn
```

**Output:**
```
🤖 ACTIVE LEARNING LOOP - Starting...
✅ Supabase client initialized
📥 Fetching untrained learning examples...
   Found 3 examples (priority >= 7)
📝 Updating AI_PROMPTS.md...
   ✅ Added 3 new examples
✅ Marking examples as trained...
   Updated 3 records in database
🎉 ACTIVE LEARNING COMPLETE!
```

---

### 3. **Database Table** 💾

**Table:** `zamm.log_learning_examples`

**Fields:**
- `original_text` - Raw workout text
- `original_json` - Wrong parser output
- `corrected_json` - Fixed version
- `error_type` - What went wrong
- `learning_priority` - 1-10 importance
- `is_included_in_training` - Has it been trained?

**Already exists!** (From previous migration)

---

### 4. **Dynamic Prompt Section** 📝

**File:** `docs/guides/AI_PROMPTS.md`

**New section:** `## 🧠 Dynamic Learning Examples`

This section is **auto-updated** by the learning loop. Shows:
- Original text
- Wrong output (before)
- Correct output (after)
- Explanation

**Format:**
```markdown
### Example: MISSING_FIELD (Priority 8)

**Original Text:**
עשיתי AMRAP 10 דקות

**Wrong Output:**
{ "prescription": {...}, "performed": null }  ❌

**Corrected Output:**
{ "prescription": {...}, "performed": { "completed": true } }  ✅

**Why:** Hebrew past tense "עשיתי" = "I did" = performance happened!
```

---

### 5. **Package.json** 📦

**New scripts:**
```json
{
  "learn": "node scripts/update_parser_brain.js",
  "test:blocks": "./scripts/test_block_types.sh",
  "test:parser": "./scripts/test_parser_accuracy.sh",
  "validate:golden": "./scripts/validate_golden_set.sh"
}
```

**Dependency:** `@supabase/supabase-js`

---

## 🏃 How To Use

### First Time Setup

```bash
# 1. Install dependencies
npm install

# 2. Check DB connection
npx supabase status

# 3. Test the learning loop (will say "no examples" if none exist)
npm run learn
```

---

### Create Your First Learning Example

**Option A: Manual SQL**

```sql
SELECT zamm.capture_learning_example(
    p_draft_id := NULL,
    p_validation_report_id := NULL,
    p_original_text := 'עשיתי Back Squat 5x5 @ 100kg',
    p_original_json := '{"prescription": {"target_reps": 5}, "performed": null}'::jsonb,
    p_corrected_json := '{"prescription": {"target_reps": 5}, "performed": {"actual_reps": 5}}'::jsonb,
    p_error_type := 'missing_field',
    p_error_location := 'blocks[0].performed',
    p_error_description := 'Text says "I did" but parser set performed=null',
    p_corrected_by := 'human',
    p_correction_notes := 'Hebrew past tense indicates actual performance',
    p_learning_priority := 8,
    p_tags := ARRAY['hebrew', 'missing_performed']
);
```

**Option B: During Validation** (Future feature - auto-capture)

---

### Run The Learning Loop

```bash
npm run learn
```

**What happens:**
1. Script connects to Supabase
2. Fetches untrained examples (priority >= 7)
3. Formats them as prompt examples
4. Adds to `AI_PROMPTS.md`
5. Marks as trained in DB

**Output files modified:**
- `docs/guides/AI_PROMPTS.md` (updated with new examples)

**Database:**
- `is_included_in_training` set to `true`
- `included_in_training_at` timestamp recorded

---

### Use Updated Prompts

**Next time you parse:**

1. Read `docs/guides/AI_PROMPTS.md`
2. Copy the full prompt (including learning examples)
3. Send to AI parser agent
4. Parser sees mistakes to avoid!

**Result:** Parser is now smarter! 🧠

---

## 📊 Example Learning Cycle

### Day 1: Parser Makes Mistake

**Input:**
```
עשיתי 5x5 squat @ 100kg
הסט האחרון רק 4 חזרות
```

**Parser output (WRONG):**
```json
{
  "prescription": { "target_reps": 5 },
  "performed": { "actual_reps": 5 }  // ❌ Wrong! Last set was 4
}
```

---

### Day 2: Human Corrects It

**Corrected JSON:**
```json
{
  "prescription": { "target_reps": 5 },
  "performed": {
    "sets": [
      { "set_index": 1, "reps": 5 },
      { "set_index": 2, "reps": 5 },
      { "set_index": 3, "reps": 5 },
      { "set_index": 4, "reps": 5 },
      { "set_index": 5, "reps": 4, "notes": "Failed" }  // ✅ Correct!
    ]
  }
}
```

**Capture learning example:**
```sql
SELECT zamm.capture_learning_example(
    p_original_text := 'עשיתי 5x5 squat @ 100kg\nהסט האחרון רק 4 חזרות',
    p_original_json := '...',  -- wrong version
    p_corrected_json := '...',  -- correct version
    p_error_type := 'wrong_value',
    p_error_description := 'Hebrew "רק 4" (only 4) missed by parser',
    p_learning_priority := 9,  -- High priority!
    p_tags := ARRAY['hebrew', 'set_failure']
);
```

---

### Day 3: Train The Parser

```bash
npm run learn
```

**Result:** Example added to `AI_PROMPTS.md`

---

### Day 4: Parser Sees New Prompt

Parser now has this in its system prompt:

```markdown
### Example: WRONG_VALUE (Priority 9) [hebrew, set_failure]

**Original Text:**
עשיתי 5x5 squat @ 100kg
הסט האחרון רק 4 חזרות

**Problem:** Parser missed "רק 4 חזרות" (only 4 reps)

**Correct:** Last set should be reps: 4, not 5

**Why:** Hebrew word "רק" = "only" indicates deviation from plan!
```

---

### Day 5: Similar Text Arrives

**New input:**
```
עשיתי 3x8 deadlift @ 120kg
הסט השני רק 6 חזרות
```

**Parser output (NOW CORRECT!):**
```json
{
  "prescription": { "target_reps": 8 },
  "performed": {
    "sets": [
      { "set_index": 1, "reps": 8 },
      { "set_index": 2, "reps": 6, "notes": "Only 6" },  // ✅ Parser learned!
      { "set_index": 3, "reps": 8 }
    ]
  }
}
```

**Success!** 🎉 Parser learned to recognize "רק" (only)!

---

## 🛠️ Configuration

**File:** `scripts/update_parser_brain.js`

**Tweak these settings:**

```javascript
const CONFIG = {
  minPriority: 7,              // Only train on high-priority examples
  maxExamples: 20,             // Keep prompt file manageable
  maxNewExamples: 5,           // Don't overwhelm with too many at once
};
```

**Priority Guidelines:**
- **10:** Critical data loss or safety issues
- **8-9:** Language errors, structure misinterpretation
- **6-7:** Edge cases, unusual patterns (default)
- **4-5:** Minor issues
- **1-3:** Cosmetic only

---

## 🎓 Best Practices

### ✅ DO:
- Capture corrections during validation review
- Set learning_priority based on impact
- Add descriptive tags for categorization
- Run learning loop regularly (weekly?)
- Review AI_PROMPTS.md to see what parser learned

### ❌ DON'T:
- Set all examples to priority 10 (dilutes importance)
- Capture typos or one-off errors
- Skip error_description (helps AI understand)
- Forget to run `npm run learn` after corrections

---

## 📚 Related Documents

- [CANONICAL_JSON_SCHEMA.md](../docs/reference/CANONICAL_JSON_SCHEMA.md) - Parser output rules
- [ACTIVE_LEARNING_README.md](./ACTIVE_LEARNING_README.md) - Full system documentation
- [AI_PROMPTS.md](../docs/guides/AI_PROMPTS.md) - Parser prompts (auto-updated)

---

## 🚦 Next Steps

### Immediate:
1. ✅ Review `CANONICAL_JSON_SCHEMA.md` to understand parser rules
2. ✅ Run `npm install` to get dependencies
3. ✅ Test `npm run learn` (will say no examples yet)

### Soon:
1. ⏳ Start validation on parsed workouts
2. ⏳ Capture first learning examples
3. ⏳ Run learning loop
4. ⏳ See parser improve!

### Future:
1. 🔜 Automate example capture during validation
2. 🔜 Build web UI for example review
3. 🔜 A/B test parser versions

---

**Last Updated:** January 10, 2026  
**Status:** 🟢 Ready To Use  
**Questions?** Check `scripts/ACTIVE_LEARNING_README.md` for full documentation
