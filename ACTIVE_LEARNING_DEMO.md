# 🎓 Active Learning System - Live Demonstration

**Date:** January 10, 2026  
**Status:** ✅ System Operational  
**Purpose:** Demonstrate how the parser learns from corrections

---

## 📋 Overview

The Active Learning System creates a continuous improvement loop:

```
Parser makes mistake → Human corrects → System captures correction → 
Parser learns → Future parsing improves 🧠
```

---

## 🎯 Demonstration Scenario

### The Original Workout Text

```
Block C - Landmine Press Half Kneeling: 3×8/side @ RPE 5.5-6, Tempo 3-0-2-0, Rest 1.5 min

Performance Notes:
Right shoulder hurt 5/10 in set 1. Left rear shoulder pain on lowering. Bar only (20kg).
```

### ❌ Wrong Parser Output (Before Learning)

The parser **violates The Great Divide** by mixing prescription and performed data:

```json
{
  "block_code": "STR",
  "items": [{
    "exercise_name": "Landmine Press",
    "prescription": {
      "target_sets": 3,
      "target_reps": 8,
      "target_weight_kg": 20,  // ❌ WRONG: This is performed, not prescribed!
      "notes": "Pain in shoulder"  // ❌ WRONG: Performance note in prescription!
    }
  }]
}
```

**Problems:**
1. ❌ Actual weight (20kg) placed in prescription (should be in performed)
2. ❌ Pain notes (performance data) in prescription object
3. ❌ Missing prescription/performed separation at block level
4. ❌ Missing target_sets_per_side in prescription

### ✅ Correct Output (After Human Correction)

Following [CANONICAL_JSON_SCHEMA.md](../docs/reference/CANONICAL_JSON_SCHEMA.md) - **Principle #1: The Great Divide**:

```json
{
  "block_code": "STR",
  "block_label": "C",
  "prescription": {
    "description": "Landmine Press Half Kneeling: 3×8/side @ RPE 5.5-6, Tempo 3-0-2-0, Rest 1.5 min"
  },
  "performed": {
    "actual_sets": 3,
    "actual_reps": 8,
    "actual_sets_per_side": 1,
    "actual_weight_kg": 20,
    "notes": "Right shoulder hurt 5/10 in set 1. Left rear shoulder pain on lowering. Bar only (20kg)."
  },
  "items": [{
    "exercise_name": "Landmine Press",
    "prescription": {
      "target_sets": 3,
      "target_reps": 8,
      "target_sets_per_side": 1,
      "target_tempo": "3-0-2-0",
      "equipment": "barbell",
      "position": "half_kneeling"
    },
    "performed": {
      "actual_weight_kg": 20
    }
  }]
}
```

**Fixes:**
1. ✅ Separated prescription (PLANNED) from performed (ACTUAL)
2. ✅ Moved actual weight to performed object
3. ✅ Moved pain notes to performed.notes
4. ✅ Added target_sets_per_side to prescription
5. ✅ Added equipment and position details

---

## 🔄 The Learning Loop Workflow

### Step 1: Capture the Correction

Run this SQL to store the learning example:

```bash
psql -h db.dtzcamerxuonoeujrgsu.supabase.co \
     -U postgres -d postgres \
     -f demo_learning_example.sql
```

This inserts the correction into `zamm.log_learning_examples` with:
- **Priority**: 9 (critical mistake)
- **Error Type**: `prescription_performance_mix`
- **Tags**: `the_great_divide`, `canonical_schema`, `pain_tracking`

### Step 2: Run the Learning Loop

```bash
npm run learn
```

**What happens:**
1. Script connects to zamm.log_learning_examples
2. Fetches untrained examples with priority ≥ 7
3. Formats them as few-shot learning examples
4. Injects into `docs/guides/AI_PROMPTS.md` under "🧠 Dynamic Learning Examples"
5. Marks examples as `is_included_in_training = true`

### Step 3: Parser Learns!

Next time the parser runs, it will see this example in its prompts:

```markdown
### Example: PRESCRIPTION_PERFORMANCE_MIX (Priority 9)

**Original Text:**
Block C - Landmine Press: 3×8/side
Right shoulder hurt 5/10. Bar only (20kg).

**Wrong Output (BEFORE):**
{
  "prescription": {
    "target_weight_kg": 20,  // ❌ ACTUAL weight in prescription!
    "notes": "Pain in shoulder"  // ❌ PERFORMED data in prescription!
  }
}

**Problem:** Parser violated The Great Divide principle from CANONICAL_JSON_SCHEMA.md

**Corrected Output (AFTER):**
{
  "prescription": { "description": "..." },
  "performed": {
    "actual_weight_kg": 20,  // ✅ In performed!
    "notes": "Right shoulder hurt..."  // ✅ In performed!
  }
}

**Why This Matters:** Without prescription/performed separation, we cannot track:
- Program adherence (did athlete follow plan?)
- Progress over time (planned vs actual)
- Injury patterns (pain notes must be in performed)
```

### Step 4: Validation

After running the learning loop, verify:

```bash
# Check if example was injected
grep -A 20 "Dynamic Learning Examples" docs/guides/AI_PROMPTS.md

# Check database was updated
psql ... -c "SELECT error_type, is_included_in_training 
             FROM zamm.log_learning_examples 
             WHERE learning_priority >= 9;"
```

---

## 📊 Expected Results

After running this demonstration:

✅ **Database:** 1 new learning example stored  
✅ **Prompts File:** Updated with formatted example  
✅ **Parser Brain:** Now knows to separate prescription/performed  
✅ **Future Parses:** Will avoid this mistake!  

---

## 🎓 Key Learning Principle

**The Great Divide** (from CANONICAL_JSON_SCHEMA.md):

> Every object MUST separate prescription (plan) from performed (actual execution).

This is the **#1 most critical rule** for data quality. Without it:
- ❌ Cannot analyze program adherence
- ❌ Cannot track progress accurately
- ❌ Cannot distinguish coach's plan from athlete's execution
- ❌ Analytics become meaningless

---

## 🚀 Try It Yourself

1. **Insert the example:**
   ```bash
   cd /workspaces/ParserZamaActive
   psql [connection] -f demo_learning_example.sql
   ```

2. **Run learning loop:**
   ```bash
   npm run learn
   ```

3. **View the result:**
   ```bash
   cat docs/guides/AI_PROMPTS.md | grep -A 50 "Dynamic Learning"
   ```

4. **Parse another workout:**
   The parser will now avoid mixing prescription/performed data!

---

## 📚 Related Documents

- [CANONICAL_JSON_SCHEMA.md](../docs/reference/CANONICAL_JSON_SCHEMA.md) - The Constitution
- [agents.md](../agents.md) - AI Agent Instructions
- [ACTIVE_LEARNING_README.md](../docs/guides/ACTIVE_LEARNING_README.md) - Full system docs

---

**Next Steps:**
- Parse workouts from `/data/golden_set/`
- Run validation to find errors
- Capture corrections
- Run `npm run learn` again
- Watch the parser improve! 🧠📈
