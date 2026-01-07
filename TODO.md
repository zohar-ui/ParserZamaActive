# 📋 TODO - January 8, 2026

**סטטוס פרויקט:** v1.2.0 - מערכת Validation הושלמה ✅  
**מוכן לפרודקשן:** 95%  
**נותרו:** משימות ניקוי נתונים ושילוב אוטומציה

---

## 🎯 משימות עדיפות גבוהה (יום 1)

### 1️⃣ **ניקוי נתונים לפני פרודקשן** 🔴

**מטרה:** לנקות את הדאטהבייס מנתוני בדיקה ולהכין אותו להזנת נתונים אמיתיים

#### צעדים:
- [ ] **הרץ את הסקריפט `/tmp/check_all_tables.sql`** בSupabase SQL Editor
  ```sql
  -- עותק מוכן ב-/tmp/check_all_tables.sql
  -- מציג ספירת שורות בכל 32 הטבלאות
  ```

- [ ] **נתח תוצאות** - אילו טבלאות מכילות נתונים:
  - `stg_imports` - נתוני בדיקה מהפרסר
  - `stg_parse_drafts` - drafts ישנים
  - `workout_main`, `workout_sessions`, `workout_blocks`, `workout_items` - workouts ישנים
  - `log_validation_reports` - דוחות בדיקה ישנים

- [ ] **צור סקריפט ניקוי:**
  ```sql
  -- אל תמחק:
  -- - lib_* tables (קטלוגים)
  -- - cfg_* tables (קונפיגורציה)
  
  -- מחק:
  DELETE FROM zamm.stg_imports WHERE created_at < '2026-01-08';
  DELETE FROM zamm.stg_parse_drafts WHERE created_at < '2026-01-08';
  DELETE FROM zamm.log_validation_reports WHERE validated_at < '2026-01-08';
  DELETE FROM zamm.workout_item_set_results; -- cascade
  DELETE FROM zamm.workout_items;
  DELETE FROM zamm.workout_blocks;
  DELETE FROM zamm.workout_sessions;
  DELETE FROM zamm.workout_main;
  ```

- [ ] **הרץ ניקוי** (אחרי backup!)
- [ ] **אמת:** `SELECT COUNT(*) FROM zamm.workout_main;` = 0

**זמן משוער:** 30 דקות

---

### 2️⃣ **בדיקת פונקציות Validation** 🟡

**מטרה:** לוודא שהפונקציות החדשות עובדות על נתונים אמיתיים

#### צעדים:
- [ ] **בחר קובץ workout לדוגמה** מ-`/data/`
  - מומלץ: `data/bader_workout_log.txt`

- [ ] **הזן אותו ל-`stg_imports`:**
  ```sql
  INSERT INTO zamm.stg_imports (
      athlete_id,
      raw_text,
      import_date,
      import_source
  ) VALUES (
      (SELECT athlete_natural_id FROM zamm.lib_athletes LIMIT 1),
      'טקסט האימון כאן...',
      NOW(),
      'manual_test'
  ) RETURNING import_id;
  ```

- [ ] **פרסר אותו** (ידנית או דרך n8n)
  - צור JSON draft ב-`stg_parse_drafts`

- [ ] **הרץ validation:**
  ```sql
  SELECT * FROM zamm.validate_parsed_workout(
      'draft-id-here',
      parsed_json_here
  );
  ```

- [ ] **בדוק תוצאות:**
  - יש errors? → תקן את הJSON
  - יש warnings? → בדוק אם הגיוני
  - pass? → נסה commit

- [ ] **נסה auto_validate_and_commit:**
  ```sql
  SELECT * FROM zamm.auto_validate_and_commit('draft-id-here');
  ```

**זמן משוער:** 45 דקות

---

### 3️⃣ **שילוב n8n Workflow** 🟢

**מטרה:** לשלב את `auto_validate_and_commit()` ב-n8n workflow קיים

#### צעדים:
- [ ] **פתח את n8n workflow** הקיים (אם יש)
- [ ] **הוסף Node חדש:** "Execute Query" (PostgreSQL)
- [ ] **Query:**
  ```sql
  SELECT * FROM zamm.auto_validate_and_commit({{$json.draft_id}});
  ```

- [ ] **הוסף IF Node:**
  ```
  IF success = true:
    → Success notification
  ELSE:
    → Error alert with message
  ```

- [ ] **בדוק Flow:**
  1. WhatsApp message → Parse → Validate & Commit → Notification

**זמן משוער:** 1 שעה

---

## 🔧 משימות עדיפות בינונית (יום 2-3)

### 4️⃣ **הרחבת Exercise Catalog**

**מטרה:** להוסיף תרגילים נפוצים לקטלוג

- [ ] עבור על 10 קבצי ה-workout ב-`/data/`
- [ ] רשום כל תרגיל שלא קיים בקטלוג
- [ ] הוסף ל-`lib_exercise_catalog`:
  ```sql
  INSERT INTO zamm.lib_exercise_catalog (exercise_key, exercise_name, category)
  VALUES ('pull_up', 'Pull-Up', 'bodyweight');
  ```
- [ ] הוסף aliases נפוצים:
  ```sql
  INSERT INTO zamm.lib_exercise_aliases (alias, exercise_key)
  VALUES 
    ('pull ups', 'pull_up'),
    ('pullups', 'pull_up'),
    ('PU', 'pull_up');
  ```

**זמן משוער:** 2 שעות

---

### 5️⃣ **יצירת View לדשבורד**

**מטרה:** View נוח לממשק UI (אם/כאשר יבנה)

- [ ] צור View עם סטטיסטיקות:
  ```sql
  CREATE OR REPLACE VIEW zamm.v_validation_dashboard AS
  SELECT 
      DATE(validated_at) as date,
      validation_status,
      COUNT(*) as count,
      AVG((error_details->'summary'->>'total_checks')::int) as avg_checks
  FROM zamm.log_validation_reports
  GROUP BY DATE(validated_at), validation_status
  ORDER BY date DESC;
  ```

**זמן משוער:** 30 דקות

---

### 6️⃣ **בדיקת Coverage של Validation**

**מטרה:** לוודא שכל סוגי ה-Blocks מכוסים

- [ ] צור test JSON לכל סוג block:
  - STR (Strength)
  - METCON (AMRAP + For Time)
  - INTV (Intervals)
  - SS (Steady State)
  - WU (Warm-up)

- [ ] הרץ validation על כל אחד
- [ ] תעד מקרי edge שלא מטופלים

**זמן משוער:** 1.5 שעות

---

## 📚 משימות תיעוד (עדיפות נמוכה)

### 7️⃣ **README עדכון**

- [ ] עדכן את `README.md` עם:
  - גרסה 1.2.0
  - קישור ל-VALIDATION_SYSTEM_SUMMARY.md
  - הסבר קצר על Stage 3 Validation

**זמן משוער:** 15 דקות

---

### 8️⃣ **וידאו/GIF להדגמה**

- [ ] הקלט סרטון קצר (2-3 דקות):
  1. הזנת workout text
  2. פרסור
  3. Validation (עם errors)
  4. תיקון + Commit מצליח

**זמן משוער:** 1 שעה (כולל עריכה)

---

## 🚀 משימות עתידיות (backlog)

### 🔮 שבוע הבא:

- [ ] **UI פשוט לreview:**
  - עמוד HTML עם:
    - Parsed JSON
    - Raw text לצד
    - Validation report (errors/warnings)
    - כפתורים: Approve / Edit / Reject

- [ ] **Analytics Dashboard:**
  - כמה workouts נכנסו
  - כמה עברו validation
  - תרגילים פופולריים
  - ממוצע RPE/RIR

- [ ] **Integration Tests:**
  - Pytest עם fixtures
  - בדיקות סוף-לסוף

---

## ✅ סיכום יום מחר (8 ינואר)

**בוקר (3 שעות):**
1. ניקוי נתונים (30 דקות)
2. בדיקת validation עם workout אמיתי (45 דקות)
3. שילוב n8n (1 שעה)
4. תיעוד תוצאות (45 דקות)

**אחר צהריים (2 שעות):**
5. הרחבת exercise catalog (2 שעות)

**סה"כ:** ~5 שעות עבודה פרודוקטיבית

---

## 📊 KPIs להצלחה

**יום מחר:**
- ✅ Database נקי מנתוני בדיקה
- ✅ לפחות 1 workout אמיתי עבר validation + commit בהצלחה
- ✅ n8n workflow משולב ועובד
- ✅ תיעוד מעודכן

**סוף שבוע:**
- ✅ 20+ תרגילים בקטלוג
- ✅ 10+ workouts אמיתיים במערכת
- ✅ אפס validation errors על נתונים אמיתיים
- ✅ Dashboard view מוכן

---

## 🔗 קישורים מהירים

**מסמכים שיעזרו מחר:**
- [VALIDATION_SYSTEM_SUMMARY.md](docs/VALIDATION_SYSTEM_SUMMARY.md) - מדריך מהיר
- [VALIDATION_WORKFLOW_EXAMPLES.sql](docs/guides/VALIDATION_WORKFLOW_EXAMPLES.sql) - 7 תרחישי שימוש
- [PARSER_AUDIT_CHECKLIST.md](docs/guides/PARSER_AUDIT_CHECKLIST.md) - Checklist מפורט
- `/tmp/check_all_tables.sql` - סקריפט ספירת נתונים

**סקריפטים מוכנים:**
- `/tmp/check_all_tables.sql` - בדיקת 32 הטבלאות
- `docs/guides/VALIDATION_WORKFLOW_EXAMPLES.sql` - דוגמאות copy-paste

---

**סטטוס:** 🟢 מערכת מוכנה, רק נותרו משימות הטמעה  
**עדכון אחרון:** 7 ינואר 2026, 22:00  
**צפי סיום פרודקשן:** 10 ינואר 2026
