# Equipment System Improvements - Proposal v1.0

**Date:** January 10, 2026  
**Status:** DRAFT  
**Priority:** HIGH (affects parser accuracy and scalability)

---

## 📋 Executive Summary

Current equipment tables (`lib_equipment_catalog` + `lib_equipment_aliases`) work but have **scalability and usability issues**:
1. ❌ No Hebrew aliases (despite `locale` field existing)
2. ❌ Inconsistent categorization (mixing type + usage)
3. ❌ Missing critical metadata (weight ranges, units, subtypes)
4. ❌ No context-aware alias resolution

**Impact:** Parser struggles with Hebrew text, analytics are limited, validation is weak.

---

## 🔍 Current State Analysis

### Tables Structure

#### `zamm.lib_equipment_catalog`
```sql
equipment_key | display_name | category | is_active
--------------+--------------+----------+-----------
barbell       | Barbell      | free_weights | true
dumbbell      | Dumbbell     | free_weights | true
rowing_machine| Rowing Machine | cardio   | true
```

**Issues:**
- `category` mixes equipment TYPE (free_weights, machines) with USAGE (cardio, functional)
- No metadata for validation (e.g., "is 500kg dumbbell valid?")
- No subtype differentiation (single DB vs DB pair)

#### `zamm.lib_equipment_aliases`
```sql
alias   | equipment_key  | locale
--------+----------------+--------
DB      | dumbbell       | en
C2      | rowing_machine | en
מוט     | ???            | he   -- MISSING!
```

**Issues:**
- `locale` field exists but **ALL aliases are English-only**
- No Hebrew aliases (users write "מוט", "משקולות", "גומיות")
- PK on `alias` prevents context-aware resolution

---

## 🎯 Proposed Improvements

### Improvement #1: Real Multi-Language Support

**Add Hebrew aliases immediately:**

```sql
-- Add to lib_equipment_aliases
INSERT INTO zamm.lib_equipment_aliases (alias, equipment_key, locale) VALUES
  -- Free Weights
  ('מוט', 'barbell', 'he'),
  ('מטל', 'barbell', 'he'),
  ('משקולות', 'dumbbell', 'he'),
  ('דמבלים', 'dumbbell', 'he'),
  ('קטלבל', 'kettlebell', 'he'),
  ('קטלבלים', 'kettlebell', 'he'),
  
  -- Cardio
  ('חתירה', 'rowing_machine', 'he'),
  ('רואינג', 'rowing_machine', 'he'),
  ('אופניים', 'bike', 'he'),
  ('הליכון', 'treadmill', 'he'),
  
  -- Bands & Mobility
  ('גומיה', 'resistance_band', 'he'),
  ('גומיות', 'resistance_band', 'he'),
  ('רולר', 'foam_roller', 'he'),
  ('פואם רולר', 'foam_roller', 'he'),
  ('כדור לקרוס', 'lacrosse_ball', 'he'),
  
  -- Functional
  ('כדור קיר', 'wall_ball', 'he'),
  ('חבל', 'jump_rope', 'he'),
  ('סלאם בול', 'slam_ball', 'he'),
  ('שק חול', 'sandbag', 'he'),
  
  -- Bodyweight
  ('משקל גוף', 'bodyweight', 'he'),
  ('ללא ציוד', 'none', 'he')
ON CONFLICT (alias) DO NOTHING;
```

**Why this matters:**
- 90% of workout logs are in Hebrew
- Parser currently fails to recognize equipment in Hebrew text
- User writes "3 סטים עם גומיה" → Parser sees "unknown equipment"

---

### Improvement #2: Add Equipment Metadata Table

**New table: `lib_equipment_properties`**

```sql
CREATE TABLE zamm.lib_equipment_properties (
  equipment_key TEXT PRIMARY KEY REFERENCES zamm.lib_equipment_catalog(equipment_key),
  
  -- Weight Properties
  typical_weight_unit TEXT CHECK (typical_weight_unit IN ('kg', 'lbs', 'g', 'none')),
  min_weight_kg NUMERIC(6,2),  -- Minimum typical weight
  max_weight_kg NUMERIC(6,2),  -- Maximum typical weight
  
  -- Physical Properties
  requires_setup BOOLEAN DEFAULT false,
  space_requirement TEXT CHECK (space_requirement IN ('small', 'medium', 'large', 'none')),
  portability TEXT CHECK (portability IN ('portable', 'semi_portable', 'fixed')),
  
  -- Classification
  equipment_type TEXT NOT NULL,  -- 'free_weight', 'machine', 'bodyweight', 'cardio', 'accessory'
  primary_usage TEXT[],          -- ['strength', 'hypertrophy', 'power']
  
  -- Subtypes
  has_variants BOOLEAN DEFAULT false,
  variant_type TEXT,             -- 'single_pair', 'adjustable_fixed', etc.
  
  -- Other
  manufacturer_info JSONB,       -- {brand: "Concept2", model: "Model D"}
  notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Example data
INSERT INTO zamm.lib_equipment_properties VALUES
  ('dumbbell', 'kg', 1, 50, false, 'small', 'portable', 'free_weight', 
   ARRAY['strength', 'hypertrophy', 'accessory'], 
   true, 'single_pair', NULL, 'Available as singles or pairs'),
   
  ('rowing_machine', 'none', NULL, NULL, true, 'large', 'fixed', 'cardio',
   ARRAY['conditioning', 'intervals', 'steady_state'],
   false, NULL, '{"brand": "Concept2", "models": ["Model D", "Model E"]}', 
   'Stroke rate 18-32 typical');
```

**Benefits:**
1. **Validation:** "500kg dumbbell? Flag as suspicious"
2. **Analytics:** "Total volume lifted with free_weights vs machines"
3. **UI Filtering:** "Show only portable equipment"
4. **Smart Suggestions:** "User has no 'large' space? Hide rower"

---

### Improvement #3: Consistent Categorization

**Replace single `category` field with TWO dimensions:**

```sql
ALTER TABLE zamm.lib_equipment_catalog 
  ADD COLUMN equipment_type TEXT,  -- WHAT it is
  ADD COLUMN primary_usage TEXT[]  -- HOW it's used
;

-- Update existing data
UPDATE zamm.lib_equipment_catalog SET
  equipment_type = CASE
    WHEN category = 'free_weights' THEN 'free_weight'
    WHEN category = 'cardio' THEN 'cardio_machine'
    WHEN category = 'machines' THEN 'machine'
    WHEN category = 'bodyweight' THEN 'bodyweight'
    WHEN category = 'bands' THEN 'resistance'
    WHEN category = 'mobility' THEN 'accessory'
    WHEN category = 'functional' THEN 'functional'
    WHEN category = 'specialty' THEN 'specialty'
  END,
  primary_usage = CASE
    WHEN equipment_key IN ('barbell', 'dumbbell', 'kettlebell') 
      THEN ARRAY['strength', 'hypertrophy', 'power']
    WHEN equipment_key IN ('rowing_machine', 'bike', 'ski_erg') 
      THEN ARRAY['conditioning', 'intervals', 'warmup']
    WHEN equipment_key IN ('foam_roller', 'lacrosse_ball') 
      THEN ARRAY['mobility', 'recovery']
    WHEN equipment_key IN ('resistance_band', 'mini_band') 
      THEN ARRAY['mobility', 'activation', 'assistance']
    ELSE ARRAY['general']
  END
;

-- Keep old category for backward compatibility
ALTER TABLE zamm.lib_equipment_catalog 
  ALTER COLUMN category SET DEFAULT 'general';
```

**Why this is better:**
- Kettlebell is a `free_weight` (type) used for `strength` + `power` + `functional` (usage)
- Resistance Band is `resistance` (type) used for `mobility` + `activation` + `strength` (usage)
- Clear separation enables better filtering and analytics

---

### Improvement #4: Context-Aware Alias Resolution

**Problem:** Single alias can mean different equipment based on context.

**Solution:** Add `context` column to aliases table:

```sql
ALTER TABLE zamm.lib_equipment_aliases 
  ADD COLUMN context TEXT CHECK (context IN ('general', 'rowing', 'strength', 'mobility', 'cardio'));

-- Set default
UPDATE zamm.lib_equipment_aliases SET context = 'general';

-- Add context-specific aliases
INSERT INTO zamm.lib_equipment_aliases (alias, equipment_key, locale, context) VALUES
  ('band', 'resistance_band', 'en', 'mobility'),
  ('band', 'heavy_band', 'en', 'strength'),
  ('strap', 'rowing_machine', 'en', 'rowing'),  -- foot strap
  ('strap', 'trx', 'en', 'strength')            -- suspension strap
ON CONFLICT (alias) DO UPDATE SET context = EXCLUDED.context;
```

**Usage in parser:**
```javascript
// Parser sees: "3 sets band pull-aparts"
const context = detectContext(sentence);  // → 'mobility'
const equipment = resolveAlias('band', context);  // → 'resistance_band'

// Parser sees: "heavy band assisted pull-ups"
const context = detectContext(sentence);  // → 'strength'
const equipment = resolveAlias('band', context);  // → 'heavy_band'
```

---

## 📊 Implementation Priority

### Phase 1: IMMEDIATE (This Week)
- ✅ Add Hebrew aliases (30 most common terms)
- ✅ Update validation to use aliases with locale
- ✅ Test parser with Hebrew workout logs

**Impact:** Fixes 80% of parser equipment detection failures

### Phase 2: SHORT-TERM (Next Sprint)
- ⏳ Create `lib_equipment_properties` table
- ⏳ Populate with basic metadata (weight ranges, type, usage)
- ⏳ Update validation functions to use properties

**Impact:** Enables validation ("500kg DB" flagged), better analytics

### Phase 3: MEDIUM-TERM (Next Month)
- ⏸️ Add `equipment_type` + `primary_usage` columns
- ⏸️ Migrate existing `category` data
- ⏸️ Update all queries to use new structure

**Impact:** Consistent categorization, better filtering

### Phase 4: LONG-TERM (Future)
- ⏸️ Implement context-aware alias resolution
- ⏸️ Add manufacturer metadata (Concept2, Rogue, etc.)
- ⏸️ Build equipment recommendation engine

**Impact:** Advanced features, manufacturer tracking

---

## 🧪 Testing Strategy

### Test Case 1: Hebrew Alias Resolution
```
Input: "3 סטים עם משקולות של 20 ק״ג"
Expected: equipment_key = "dumbbell"
Current: FAIL (unknown equipment)
After Phase 1: PASS
```

### Test Case 2: Weight Validation
```
Input: "Dumbbell 500kg"
Expected: WARNING flag ("suspicious weight")
Current: No validation
After Phase 2: PASS (flagged as suspicious)
```

### Test Case 3: Context-Aware Resolution
```
Input: "Band pull-aparts" (mobility)
Expected: equipment_key = "resistance_band"

Input: "Heavy band assisted pull-ups" (strength)
Expected: equipment_key = "heavy_band"

Current: Both → "resistance_band" (incorrect for 2nd case)
After Phase 4: PASS (both correct)
```

---

## 📚 Related Documents

- [CANONICAL_JSON_SCHEMA.md](../reference/CANONICAL_JSON_SCHEMA.md) - Schema v3.0 includes `equipment_key`
- [agents.md](../../agents.md) - Equipment normalization rules
- Migration: `20260110170000_populate_equipment_catalog.sql` - Current equipment data

---

## 💡 Questions for Discussion

1. **Hebrew aliases:** Should we include slang/abbreviations? (e.g., "DB" is used in Hebrew too)
2. **Weight validation:** Should we auto-correct obvious mistakes (500kg → 50kg) or just flag?
3. **Context resolution:** Should context be manual (predefined) or ML-based?
4. **Manufacturer tracking:** Do we need this for analytics or just metadata?

---

**Next Steps:**
1. Review this proposal with team
2. Get approval for Phase 1 (Hebrew aliases)
3. Create migration script
4. Test with golden set files
5. Update parser to use `locale` parameter

**Estimated Effort:**
- Phase 1: 2-3 hours
- Phase 2: 1 day
- Phase 3: 2-3 days
- Phase 4: 1 week
