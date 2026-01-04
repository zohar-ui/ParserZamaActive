# 📊 ZAMM Workout Parser - דוח מוכנות מסד נתונים

**תאריך:** 4 ינואר 2026  
**מסד נתונים:** Supabase (dtzcamerxuonoeujrgsu)  
**Schema:** zamm

---

## ✅ מה שכבר קיים (GOOD NEWS!)

### 🟢 טבלאות תשתית (Infrastructure) - **100% מוכן**
| טבלה | סטטוס | הערות |
|------|-------|-------|
| `dim_athletes` | ✅ | יש כל השדות: name, email, height, weight |
| `parser_rulesets` | ✅ | כולל units_catalog, parser_mapping_rules |
| `equipment_catalog` | ✅ | עם equipment_key, category, display_name |
| `equipment_aliases` | ✅ | תמיכה במספר שמות לאותו ציוד |

### 🟢 טבלאות Staging - **100% מוכן**
| טבלה | סטטוס | הערות |
|------|-------|-------|
| `imports` | ✅ | שומר raw_text, source, athlete_id |
| `parse_drafts` | ✅ | כולל parsed_draft, normalized_draft, flags |
| `validation_reports` | ✅ | מדווח errors, warnings |
| `draft_edits` | ✅ | מאפשר מעקב אחרי שינויים ידניים |

### 🟢 טבלאות Workout Prescription - **100% מוכן**
| טבלה | סטטוס | הערות |
|------|-------|-------|
| `workouts` | ✅ | כותרת האימון |
| `workout_sessions` | ✅ | חלוקה לסשנים (בוקר/ערב) |
| `workout_blocks` | ✅ | בלוקים עם prescription (JSON) |
| `workout_items` | ✅ | תרגילים עם prescription_data + performed_data |

### 🟡 טבלאות Performance/Results - **90% מוכן**
| טבלה | סטטוס | הערות |
|------|-------|-------|
| `item_set_results` | ✅ | רמת הסט: reps, load_kg, rpe, rir |
| `workout_block_results` | ✅ | רמת הבלוק: total_time, score, calories |
| `interval_segments` | ✅ | רמת האינטרוואל: work_time, rest_time, pace |

### 🟢 Stored Procedures - **מעולה!**
| פונקציה | סטטוס | הערות |
|---------|-------|-------|
| `commit_full_workout` | ✅ | גרסה 1 - עובדת |
| `commit_full_workout_v2` | ✅ | גרסה 2 - משופרת! |

### 🟢 Views - **אנליטיקה מוכנה**
| View | סטטוס | הערות |
|------|-------|-------|
| `v_analytics_flat_history` | ✅ | תצוגה שטוחה של כל ההיסטוריה |

---

## 🎯 מה שחסר או צריך שיפור

### 🟡 1. Stored Procedure - צריך התאמה קלה
**הבעיה:**
- `commit_full_workout_v2` כבר קורא JSON עם `prescription` ו-`performed`
- אבל הלוגיקה צריכה לוודא שהיא מפצלת נכון ל-2 רבדים

**פתרון מומלץ:**
```sql
-- בתוך הלולאה על Items, צריך:
INSERT INTO zamm.workout_items (
    block_id, 
    item_order, 
    prescription_data,  -- ← תכנון
    performed_data,     -- ← ביצוע
    created_at
) VALUES (
    v_block_id,
    v_item_rec.ordinality,
    v_item_rec.step_data->'prescription',  -- תכנון
    v_item_rec.step_data->'performed',     -- ביצוע
    NOW()
);
```

### 🟡 2. AI Tools - צריך להגדיר
עדיין לא קיימות SQL Tools עבור ה-AI. צריך ליצור:

**Tools שצריכים:**
```typescript
// 1. CheckAthleteExists
SELECT athlete_natural_id, full_name 
FROM zamm.dim_athletes 
WHERE full_name ILIKE '%{{name}}%' AND is_current = true;

// 2. CheckEquipment
SELECT equipment_key, display_name 
FROM zamm.equipment_catalog 
WHERE display_name ILIKE '%{{name}}%' OR equipment_key IN (
  SELECT equipment_key FROM zamm.equipment_aliases WHERE alias ILIKE '%{{name}}%'
);

// 3. GetActiveRuleset
SELECT ruleset_id, units_catalog, parser_mapping_rules 
FROM zamm.parser_rulesets 
WHERE is_active = true;
```

### 🟡 3. Validation Logic - לשפר
**מה שקיים:**
- טבלת `validation_reports` קיימת ✅
- אבל אין עדיין לוגיקה שבודקת consistency בין prescription ל-performed

**מה להוסיף:**
- בדיקה: אם יש `performed_data` אבל אין `prescription_data` → דגל warning
- בדיקה: אם מספר הסטים ב-performed לא תואם ל-prescription → דגל
- בדיקה: אם load_kg > 500 → דגל (probably error)

### 🟢 4. Schema Alignment - **מצוין!**
הטבלאות שלך כבר תומכות בהפרדה בין תכנון לביצוע:

| Table | Prescription Field | Performance Field | Status |
|-------|-------------------|-------------------|--------|
| `workout_blocks` | `prescription` (JSONB) | `performed` (JSONB) | ✅ |
| `workout_items` | `prescription_data` (JSONB) | `performed_data` (JSONB) | ✅ |

---

## 🚀 המלצות יישום - Phase by Phase

### Phase 1: Database Polish (1-2 hours)
✅ כבר עשית את רוב העבודה!
- [ ] עדכון `commit_full_workout_v2` לפצל prescription/performed בצורה ברורה
- [ ] הוספת index על `athlete_id`, `workout_date` (לביצועים)

### Phase 2: AI Agent Configuration (2-3 hours)
- [ ] הגדרת SQL Tools ב-n8n
- [ ] System Prompt עבור הפרדת תכנון/ביצוע
- [ ] Structured Output Schema שמכיל `target` ו-`actual`

### Phase 3: Validation Logic (1-2 hours)
- [ ] Cross-checker נוד ב-n8n
- [ ] לוגיקת consistency checks
- [ ] דיווח ל-`validation_reports`

### Phase 4: Testing & Iteration (ongoing)
- [ ] בדיקות עם טקסטים אמיתיים
- [ ] תיקון bugs
- [ ] שיפור prompts

---

## 📈 ציון כללי: **85/100** 🎉

**מה שמעולה:**
- ✅ הסכמה רלציונית מתוכננת היטב
- ✅ הפרדה ברורה בין prescription ל-performance ברמת המבנה
- ✅ יש Stored Procedures עובדות
- ✅ יש כלי Audit (imports, parse_drafts, validation_reports)
- ✅ יש מבנה מדורג: workout → session → block → item → set

**מה שצריך להשלים:**
- 🟡 התאמת הפרוצדורות לפיצול prescription/performed
- 🟡 הגדרת SQL Tools ל-AI
- 🟡 לוגיקת Validation מתקדמת
- 🟡 בדיקות אינטגרציה

**Bottom Line:**
המסד נתונים שלך **מוכן מאוד** לארכיטקטורת ה-AI-SQL Agent! 
רוב העבודה היא בצד ה-n8n (Prompts, Tools, Workflow) ולא בצד ה-DB.

---

## 📝 דוגמת זרימה מלאה

```
טקסט קלט:
"Squat: 3x5 @ 100kg. Last set was hard, only got 4 reps."

↓ Stage 1: Context & Ingestion
- שמירה ב-imports
- זיהוי אתלט (CheckAthleteExists)
- שליפת ruleset

↓ Stage 2: Parsing Agent
- זיהוי תרגיל: "Squat"
- prescription: {sets: 3, reps: 5, load: 100kg}
- performed: [
    {set: 1, reps: 5, load: 100},
    {set: 2, reps: 5, load: 100},
    {set: 3, reps: 4, load: 100, notes: "hard"}
  ]

↓ Stage 3: Validation
- בדיקה: set_index קיים ✅
- בדיקה: load_kg סביר (100 < 500) ✅
- בדיקה: prescription vs performed → דגל: actual_reps < target_reps

↓ Stage 4: Atomic Commit
- workout_items.prescription_data = {sets: 3, reps: 5, load: 100}
- item_set_results × 3 rows:
  - set 1: reps=5, load=100
  - set 2: reps=5, load=100
  - set 3: reps=4, load=100, notes="hard"
```

---

## 🔗 קישורים שימושיים

- [Supabase Dashboard](https://supabase.com/dashboard/project/dtzcamerxuonoeujrgsu)
- [n8n Documentation](https://docs.n8n.io/)
- [SQL Tools בn8n](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.postgres/)
