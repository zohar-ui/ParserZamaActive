# AI_PROMPTS.md v3.2 Update Report

**Date:** January 10, 2026
**File Updated:** `docs/guides/AI_PROMPTS.md`
**Status:** ✅ COMPLETE

---

## Summary

Successfully updated AI_PROMPTS.md to reflect Schema v3.2 requirements. All examples and instructions now use the unified `{value, unit}` structure for measurements.

### Changes Statistics
```
1 file changed
178 insertions(+)
18 deletions(-)
```

---

## Key Updates

### 1. Added Schema Version Badge
Added at top of document:
```markdown
**Schema Version:** 3.2.0 (January 10, 2026)
```

### 2. Updated System Prompt with v3.2 Warning
Added prominent warning in main parser agent prompt:
```markdown
**⚠️ SCHEMA v3.2 REQUIREMENT:**
ALL measurements MUST use `{value, unit}` structure. Never use plain numbers for:
- Weight/Load (e.g., use `load: {value: 100, unit: "kg"}` NOT `load_kg: 100`)
- Duration (e.g., use `target_duration: {value: 5, unit: "min"}` NOT `target_duration_min: 5`)
- Distance (e.g., use `target_distance: {value: 400, unit: "m"}` NOT `target_meters: 400`)
```

### 3. Updated Main Structure Example
**Before (v3.1):**
```json
{
  "target_load": {"value": 100, "unit": "kg"},
  "total_time_sec": 600,
  "load_kg": 100
}
```

**After (v3.2):**
```json
{
  "target_weight": {"value": 100, "unit": "kg"},
  "actual_duration": {"value": 10, "unit": "min"},
  "load": {"value": 100, "unit": "kg"}
}
```

### 4. Updated All Parsing Examples
Updated 3 existing examples:
- **Example 1:** Plan Only
- **Example 2:** Plan + Performance
- **Example 3:** Performance Different from Plan

All now use v3.2 format with `{value, unit}` structure.

### 5. Added 3 New Examples for v3.2
Added new examples to demonstrate duration and distance handling:

**Example 4: AMRAP with Duration**
```json
{
  "target_amrap_duration": {"value": 12, "unit": "min"}
}
```

**Example 5: Distance Work**
```json
{
  "target_distance": {"value": 500, "unit": "m"},
  "target_rest": {"value": 90, "unit": "sec"}
}
```

**Example 6: Time-Based Hold**
```json
{
  "target_duration": {"value": 60, "unit": "sec"},
  "sets": [
    {"duration": {"value": 60, "unit": "sec"}},
    {"duration": {"value": 55, "unit": "sec"}}
  ]
}
```

### 6. Enhanced Validation Checklist
Added v3.2-specific validation requirements:
```markdown
- [ ] **ALL measurements use {value, unit} structure:**
  - [ ] Weight/load: `{value, unit: "kg"|"lbs"|"g"}`
  - [ ] Duration: `{value, unit: "sec"|"min"|"hours"}`
  - [ ] Distance: `{value, unit: "m"|"km"|"yards"|"miles"}`
- [ ] **NO plain number fields for measurements**
```

### 7. Updated Validation Report Example
Changed field path from:
```json
"field": "blocks[0].prescription.steps[0].load_kg"
```

To:
```json
"field": "blocks[0].prescription.steps[0].target_weight.value"
```

### 8. Added Migration Notes Section
Added comprehensive migration guide at end of document:
- Breaking changes overview
- Before/After examples
- Supported units list
- Rationale for the change
- Migration checklist

---

## Impact on Parser Behavior

### What Changed
1. **Field Names:** All `*_kg`, `*_lbs`, `*_sec`, `*_min`, `*_meters` fields → `{value, unit}`
2. **Structure:** Plain numbers → Nested objects
3. **Validation:** More strict - rejects old format

### What Stayed the Same
1. **Core Logic:** Prescription vs Performance separation unchanged
2. **Exercise Names:** Still use canonical names
3. **Set-by-set tracking:** Still supports detailed breakdowns
4. **Language Support:** Still handles Hebrew/English

---

## Benefits for AI Parser

### 1. **Clearer Instructions**
Parser now has explicit examples of v3.2 format in every scenario.

### 2. **Error Prevention**
Prominent warnings help prevent accidental use of old format.

### 3. **Complete Coverage**
New examples cover all measurement types:
- Weight ✅
- Duration ✅
- Distance ✅

### 4. **Validation Guidance**
Enhanced checklist ensures parser validates its own output.

---

## Testing Recommendations

### 1. Test Basic Strength Work
```
Input: "Back Squat: 5x5 @ 100kg"
Expected: target_weight: {value: 100, unit: "kg"}
```

### 2. Test AMRAP Duration
```
Input: "AMRAP 12 minutes: 10 Pull-ups, 20 Push-ups"
Expected: target_amrap_duration: {value: 12, unit: "min"}
```

### 3. Test Distance Work
```
Input: "Row: 3x500m"
Expected: target_distance: {value: 500, unit: "m"}
```

### 4. Test Mixed Units
```
Input: "5 min row, rest 30 sec, 400m run"
Expected:
- target_duration: {value: 5, unit: "min"}
- target_rest: {value: 30, unit: "sec"}
- target_distance: {value: 400, unit: "m"}
```

### 5. Reject Old Format
```
Input: Parser generates "load_kg": 100
Expected: Validation error - must use {value, unit}
```

---

## Next Steps

### For Parser Development
1. ✅ Update AI_PROMPTS.md (COMPLETE)
2. ⏳ Test parser with new prompts
3. ⏳ Update parser training examples
4. ⏳ Run through golden set validation
5. ⏳ Document any edge cases discovered

### For Integration
1. ⏳ Update API consumers to expect v3.2 format
2. ⏳ Update database queries to extract from nested structure
3. ⏳ Update UI components to display {value, unit}
4. ⏳ Add validation layer to reject old format

---

## Related Documents

- **CANONICAL_JSON_SCHEMA.md** - Schema specification (v3.2)
- **SCHEMA_V3.2_UPGRADE_REPORT.md** - Upgrade documentation
- **scripts/upgrade_to_v3.2.py** - Conversion script
- **scripts/validate_golden_sets.py** - Validation script

---

## Support

For questions about using these prompts:
1. Review examples in AI_PROMPTS.md
2. Check CANONICAL_JSON_SCHEMA.md for field definitions
3. Test with validation script: `python3 scripts/validate_golden_sets.py`

---

**Parser prompts are now v3.2 compliant! 🎉**

All AI agents using these prompts will generate correctly structured v3.2 JSON output.
