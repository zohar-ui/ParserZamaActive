# ParserZamaActive

🏋️‍♂️ **ZAMM Workout Parser** - AI-SQL Agent Architecture

## Project Overview

מערכת פרסור חכמה הממירה טקסט חופשי (תוכנית אימון + תוצאות ביצוע) למבנה נתונים רלציוני מורכב, באמצעות AI Agents עם SQL Tools.

## Database Connection

**Supabase Project:** `dtzcamerxuonoeujrgsu`  
**Schema:** `zamm`  
**Status:** ✅ Connected & Ready

### Quick Commands
```bash
# Check connection
supabase status

# Pull latest schema
supabase db pull

# Generate TypeScript types
supabase gen types typescript --linked > types/database.ts

# Reset local database (if running locally)
supabase db reset
```

## Documentation

- 📊 [Database Readiness Report](./DB_READINESS_REPORT.md) - מצב מוכנות המסד נתונים (**85/100**)
- 📁 [Schema Migration](./supabase/migrations/) - היסטוריית שינויי סכמה

## Architecture Highlights

### 4-Stage Workflow
1. **Context & Ingestion** - קליטת טקסט + זיהוי אתלט
2. **Parsing Agent** - הפרדת תכנון (prescription) מביצוע (performance)
3. **Validation & Normalization** - בקרת איכות + תיקון שגיאות
4. **Atomic Commit** - שמירה למסד נתונים בטרנזקציה אחת

### Key Separation: Prescription vs Performance
המערכת מפרידה בין:
- **Prescription (תכנון):** מה אמור להתבצע ("3x5 @ 100kg")
- **Performance (ביצוע):** מה קרה בפועל ("הצלחתי רק 4 חזרות בסט אחרון")

## Database Structure

### 🏗️ Core Tables
```
workouts
  └─ workout_sessions
       └─ workout_blocks (prescription + performed JSONs)
            └─ workout_items (prescription_data + performed_data)
                 └─ item_set_results (actual results per set)
```

### 📊 Infrastructure Tables
- `dim_athletes` - פרטי אתלטים (גובה, משקל, גיל)
- `parser_rulesets` - חוקי המרת יחידות ומבנה
- `equipment_catalog` + `equipment_aliases` - ניהול ציוד

### 🔄 Staging Tables
- `imports` - טקסט גולמי מקורי
- `parse_drafts` - טיוטות ניתוח (JSON)
- `validation_reports` - דוחות שגיאות
- `draft_edits` - מעקב אחרי תיקונים ידניים

### 📈 Results Tables
- `item_set_results` - תוצאות ברמת הסט (reps, load, RPE, RIR)
- `workout_block_results` - תוצאות ברמת הבלוק (זמן, calories, HR)
- `interval_segments` - תוצאות אינטרוואלים (work/rest splits)

## Stored Procedures

### `commit_full_workout_v2()`
מקבל JSON מנורמל ומפרק אותו לטבלאות רלציוניות:
```sql
SELECT zamm.commit_full_workout_v2(
  p_import_id := '...',
  p_draft_id := '...',
  p_ruleset_id := '...',
  p_athlete_id := '...',
  p_normalized_json := '{"sessions": [...]}'::jsonb
);
```

## Example Parsing Flow

```
Input Text:
"Squat: 3x5 @ 100kg. Last set was hard, only got 4 reps."

↓ Stage 1: Context & Ingestion
- Save to imports table
- Identify athlete (SQL Tool: CheckAthleteExists)
- Get active ruleset

↓ Stage 2: Parsing Agent
- Exercise: "Squat"
- Prescription: {sets: 3, reps: 5, load_kg: 100}
- Performance: [
    {set: 1, reps: 5, load: 100},
    {set: 2, reps: 5, load: 100},
    {set: 3, reps: 4, load: 100, notes: "hard"}
  ]

↓ Stage 3: Validation
✅ set_index exists
✅ load_kg is reasonable (< 500kg)
⚠️  Warning: actual_reps (4) < target_reps (5) in set 3

↓ Stage 4: Atomic Commit
workout_items:
  - prescription_data: {sets: 3, reps: 5, load: 100}

item_set_results (3 rows):
  - set 1: reps=5, load_kg=100
  - set 2: reps=5, load_kg=100
  - set 3: reps=4, load_kg=100, notes="hard"
```

## Implementation Status

### ✅ Phase 1: Database Polish - **COMPLETE**
- ✅ All tables and stored procedures ready
- ✅ Schema optimized for prescription/performance separation
- ✅ Performance indexes in place

### ✅ Phase 2: AI Agent Configuration - **COMPLETE**
- ✅ 5 SQL Tools created and deployed
- ✅ System Prompts written and documented
- ✅ Structured Output Schema defined

### ✅ Phase 3: Validation Logic - **COMPLETE**
- ✅ 5 Validation functions created
- ✅ Consistency checks implemented
- ✅ Auto-reporting to validation_reports

### 🟡 Phase 4: n8n Integration - **READY TO START**
- 📚 Complete integration guide available
- 🧪 Test queries ready
- ⏳ Waiting for n8n workflow setup

## Quick Links

- 🚀 **[Start Here: Implementation Complete](./docs/IMPLEMENTATION_COMPLETE.md)** - Summary of everything built
- 📊 **[DB Readiness Report](./DB_READINESS_REPORT.md)** - Database assessment (85/100)
- 📚 **[n8n Integration Guide](./docs/N8N_INTEGRATION_GUIDE.md)** - Step-by-step n8n setup
- 🤖 **[AI Prompts](./docs/AI_PROMPTS.md)** - Ready-to-use prompt templates
- 🧪 **[Quick Test Queries](./docs/QUICK_TEST_QUERIES.sql)** - Verify functions work

## What's Ready

### SQL Functions Deployed ✅

**AI Tools (5):**
- `check_athlete_exists(name)` - Find athlete by name
- `check_equipment_exists(name)` - Validate equipment
- `get_active_ruleset()` - Get parser rules
- `get_athlete_context(id)` - Full athlete context
- `normalize_block_type(type)` - Validate block types

**Validation Functions (5):**
- `validate_workout_draft()` - Comprehensive validation
- `check_prescription_performance_consistency()` - Compare plan vs actual
- `validate_and_save_report()` - Auto-save validation
- `get_draft_validation_status()` - Quick status
- `validate_pending_drafts()` - Batch validation

### Documentation Complete ✅

All prompts, guides, and examples are ready in the `docs/` folder.

---

**Built with:** Supabase, n8n, PostgreSQL, AI Agents  
**License:** MIT
