---
name: debug-parse
description: Test parser logic on specific text snippet without full pipeline or database commit
---

# Debug Parse Skill

## Purpose
Isolate and test parser behavior on specific text snippets to:
- Debug why parser misinterpreted a line
- Test regex patterns against edge cases
- Validate parser changes before full deployment
- Understand which rule triggered extraction

## Usage
```
/debug-parse "<text snippet>"
```

**Examples:**
```
/debug-parse "3x5 @ 80kg"
/debug-parse "Back Squat: 5x3 @ RPE 8"
/debug-parse "METCON: 21-15-9 Thrusters @ 95lb"
/debug-parse "Rest 2 min between sets"
```

## What It Does

1. **Parses text snippet** using parser pattern library
2. **Shows matched patterns** (which regex triggered)
3. **Displays extracted JSON** (raw parser output)
4. **Explains parsing logic** (why it matched this way)
5. **Suggests fixes** if parsing failed or was wrong

---

## Instructions for Claude

### Step 1: Extract Text Snippet

Parse the user's input to get the text to test:
```
Input: /debug-parse "3x5 @ 80kg"
Text to parse: "3x5 @ 80kg"
```

### Step 2: Load Parser Patterns

```javascript
const {
    PATTERNS,
    parseExerciseLine,
    parsePrescriptionModifiers
} = require('./scripts/tests/parser_patterns.js');
```

### Step 3: Test Against Pattern Categories

Run the text through each pattern type:

**A) Sets & Reps Patterns:**
```javascript
const setsRepsMatch = PATTERNS.SETS_REPS.WITH_LOAD.exec(text);
if (setsRepsMatch) {
    console.log('✅ Matched: SETS_REPS.WITH_LOAD');
    console.log('Groups:', setsRepsMatch);
}
```

**B) Duration Patterns:**
```javascript
const durationMatch = PATTERNS.DURATION.MINUTES.exec(text);
if (durationMatch) {
    console.log('✅ Matched: DURATION.MINUTES');
    console.log('Groups:', durationMatch);
}
```

**C) Intensity Patterns:**
```javascript
const intensityMatch = PATTERNS.INTENSITY.RPE.exec(text);
if (intensityMatch) {
    console.log('✅ Matched: INTENSITY.RPE');
    console.log('Groups:', intensityMatch);
}
```

**D) Rest Patterns:**
```javascript
const restMatch = PATTERNS.REST.BASIC.exec(text);
if (restMatch) {
    console.log('✅ Matched: REST.BASIC');
    console.log('Groups:', restMatch);
}
```

### Step 4: Run Full Parser

Execute the complete parsing logic:

```javascript
const result = parseExerciseLine(text);
console.log('Parser Output:', JSON.stringify(result, null, 2));
```

### Step 5: Format Output for User

Present results in clear format:

```
🔍 Parsing: "3x5 @ 80kg"

Pattern Matches:
✅ SETS_REPS.WITH_LOAD
   - Regex: /(\d+)\s*[xX×]\s*(\d+)\s*@\s*(\d+(?:\.\d+)?)\s*(kg|lb|%)?/i
   - Groups: ["3x5 @ 80kg", "3", "5", "80", "kg"]

Parser Output:
{
  "prescription": {
    "target_sets": 3,
    "target_reps": 5,
    "target_load": 80,
    "load_unit": "kg"
  },
  "performed": null
}

Explanation:
- Pattern "WITH_LOAD" matched the format "SETSxREPS @ LOAD UNIT"
- Extracted: 3 sets, 5 reps, 80kg load
- No performance data detected (prescription only)

✅ Parsing successful - this would be stored correctly in the database.
```

---

## Test Scenarios

### Scenario 1: Basic Sets & Reps
```
Input: "3x5"

Expected Match: SETS_REPS.BASIC
Expected Output:
{
  "prescription": {
    "target_sets": 3,
    "target_reps": 5
  }
}
```

### Scenario 2: Sets, Reps, Load
```
Input: "5x3 @ 100kg"

Expected Match: SETS_REPS.WITH_LOAD
Expected Output:
{
  "prescription": {
    "target_sets": 5,
    "target_reps": 3,
    "target_load": 100,
    "load_unit": "kg"
  }
}
```

### Scenario 3: Per Side Notation
```
Input: "3x10/10"

Expected Match: SETS_REPS.SETS_REPS_SIDE
Expected Output:
{
  "prescription": {
    "target_sets": 3,
    "target_reps": 10,
    "per_side": true
  }
}
```

### Scenario 4: Duration
```
Input: "5 min easy jog"

Expected Match: DURATION.MINUTES
Expected Output:
{
  "prescription": {
    "duration_minutes": 5
  }
}
```

### Scenario 5: Intensity (RPE)
```
Input: "3x5 @ RPE 8"

Expected Match: SETS_REPS.BASIC + INTENSITY.RPE
Expected Output:
{
  "prescription": {
    "target_sets": 3,
    "target_reps": 5,
    "rpe": 8
  }
}
```

### Scenario 6: Rest Instruction
```
Input: "Rest 2 min between sets"

Expected Match: REST.DETAILED
Expected Output:
{
  "type": "rest",
  "duration_minutes": 2,
  "context": "between sets"
}
```

---

## Debugging Failed Parses

### Problem: "Parser extracted wrong values"

**Example:**
```
Input: "3x5 @ 80%"
Parser Output: { target_sets: 3, target_reps: 5, target_load: 80, load_unit: "%" }
Expected: { target_sets: 3, target_reps: 5, intensity_percent: 80 }
```

**Debug Steps:**
1. Check which pattern matched
2. Look at regex groups
3. Identify if pattern is too greedy or wrong category
4. Suggest fix to pattern

**Output:**
```
⚠️ Parsing Issue Detected

Input: "3x5 @ 80%"

Current Behavior:
- Matched: SETS_REPS.WITH_LOAD
- Treated "%" as load_unit (wrong!)

Root Cause:
- Pattern /(\d+)\s*@\s*(\d+)/ is too greedy
- Should check for "%" and route to INTENSITY pattern instead

Suggested Fix:
- Modify parser to check for "%" suffix first
- Route to INTENSITY.PERCENT pattern before SETS_REPS.WITH_LOAD
- Expected: { intensity_percent: 80 }

Would you like me to create a fix for this pattern?
```

### Problem: "Parser didn't extract anything"

**Example:**
```
Input: "Twenty reps of push-ups"
Parser Output: null
```

**Debug Steps:**
1. Test against all patterns
2. Show which patterns were tried
3. Identify missing pattern
4. Suggest new pattern

**Output:**
```
❌ No Match Found

Input: "Twenty reps of push-ups"

Patterns Tested:
❌ SETS_REPS.BASIC - requires digits (e.g., "3x5")
❌ SETS_REPS.REPS_ONLY - requires leading digit (e.g., "10 push-ups")
❌ DURATION.MINUTES - no time reference
❌ REST.BASIC - no "rest" keyword

Root Cause:
- Parser doesn't handle written numbers ("Twenty" instead of "20")
- Requires numeric digits for all patterns

Suggested Fix:
1. Add word-to-number conversion: "twenty" → 20
2. Then re-test with "20 reps of push-ups"
3. Or add pattern: /\b(one|two|...|twenty)\s+reps?\s+(?:of\s+)?(\w+)/i

Would you like me to add word-to-number conversion?
```

---

## Advanced Debugging

### Test Multiple Variations

Test parser robustness by trying variations:

```
Base: "3x5 @ 80kg"

Variations to test:
1. "3X5 @ 80kg"     (uppercase X)
2. "3 x 5 @ 80kg"   (spaces)
3. "3×5 @ 80kg"     (multiplication symbol)
4. "3x5 @80kg"      (no space before load)
5. "3x5@ 80kg"      (no space after @)
6. "3x5 @ 80 kg"    (space in unit)

Expected: All should parse identically to "3x5 @ 80kg"
```

**Run test:**
```javascript
const variations = [
    "3x5 @ 80kg",
    "3X5 @ 80kg",
    "3 x 5 @ 80kg",
    "3×5 @ 80kg",
    "3x5 @80kg",
    "3x5@ 80kg",
    "3x5 @ 80 kg"
];

variations.forEach(v => {
    const result = parseExerciseLine(v);
    console.log(v, '→', result);
});
```

**Output:**
```
Testing Parser Robustness:

✅ "3x5 @ 80kg"    → {sets:3, reps:5, load:80, unit:"kg"}
✅ "3X5 @ 80kg"    → {sets:3, reps:5, load:80, unit:"kg"}
✅ "3 x 5 @ 80kg"  → {sets:3, reps:5, load:80, unit:"kg"}
✅ "3×5 @ 80kg"    → {sets:3, reps:5, load:80, unit:"kg"}
✅ "3x5 @80kg"     → {sets:3, reps:5, load:80, unit:"kg"}
❌ "3x5@ 80kg"     → null (parser failed - space before @ required)
❌ "3x5 @ 80 kg"   → {sets:3, reps:5, load:80, unit:" kg"} (extra space)

Issues Found: 2
- Pattern requires space before @
- Pattern captures extra space in unit

Recommendation: Update regex to handle optional whitespace more flexibly.
```

---

## Integration with Full Pipeline

This skill tests **parser logic only** (step 2 of the pipeline).

**Full Pipeline:**
1. **Import** - Text → stg_imports table
2. **Parse** - Text → JSON (this skill tests this step)
3. **Validate** - JSON → quality checks
4. **Commit** - JSON → normalized database tables

**To test full pipeline:**
- Use `/process-workout <file>` instead (runs all steps)
- Use this skill only when debugging specific pattern issues

---

## Example Session

```
User: /debug-parse "5x3 @ RPE 8"

Claude: 🔍 Parsing: "5x3 @ RPE 8"

Running parser tests...

Pattern Matches:
✅ SETS_REPS.BASIC
   - Matched: "5x3"
   - Extracted: sets=5, reps=3

✅ INTENSITY.RPE
   - Matched: "@ RPE 8"
   - Extracted: rpe=8

Parser Output:
{
  "prescription": {
    "target_sets": 5,
    "target_reps": 3,
    "rpe": 8
  },
  "performed": null
}

Explanation:
- Pattern SETS_REPS.BASIC matched "5x3"
- Pattern INTENSITY.RPE matched "@ RPE 8"
- Combined into single prescription object
- No performance data (only prescription)

✅ Parsing successful!

This would be stored as:
- Target: 5 sets of 3 reps at RPE 8
- Actual: null (not performed yet)
```

---

## Files Used

- `scripts/tests/parser_patterns.js` - Pattern library and parsing functions
- `docs/guides/AI_PROMPTS.md` - Parser prompt templates (for context)
- `docs/reference/CANONICAL_JSON_SCHEMA.md` - Expected output format

---

## Notes

- This skill is for **debugging parser logic**, not full workflow testing
- Use Node.js to run parser functions (require('./scripts/tests/parser_patterns.js'))
- Always test edge cases (spaces, capitalization, punctuation)
- If parser fails, suggest specific pattern improvements
- Keep parser patterns documented in `parser_patterns.js`
