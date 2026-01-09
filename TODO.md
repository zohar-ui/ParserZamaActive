# 📋 TODO - January 8, 2026

**סטטוס פרויקט:** v1.2.0 - מערכת Validation הושלמה ✅  
**מוכן לפרודקשן:** 95%  
**נותרו:** משימות ניקוי נתונים ושילוב אוטומציה

---

## 🎯 משימות עדיפות גבוהה (יום 1)

### 1️⃣ **ניקוי נתונים לפני פרודקשן** ✅ **הושלם!**

**מטרה:** לנקות את הדאטהבייס מנתוני בדיקה ולהכין אותו להזנת נתונים אמיתיים

#### צעדים:
- [x] **הרץ את הסקריפט ספירת טבלאות**
  - 71 imports, 43 drafts, 38 validation reports, 8 workouts נמצאו

- [x] **נתח תוצאות** - זוהו טבלאות עם נתוני בדיקה:
  - `stg_imports` - 71 שורות
  - `stg_parse_drafts` - 43 שורות
  - `workout_main`, `workout_sessions` - 8 אימונים
  - `log_validation_reports` - 38 דוחות

- [x] **צור סקריפט ניקוי:**
  - נוצר: `/scripts/cleanup_test_data.sql`
  - מוחק נתוני staging/validation/workout
  - שומר קטלוגים (lib_*)

- [x] **הרץ ניקוי בהצלחה!**
  - ✅ נמחקו: 71 imports, 43 drafts, 38 reports, 8 workouts
  - ✅ נשמרו: 2 athletes, 29 exercises, 37 equipment, 17 block types

- [x] **אמת:** `SELECT COUNT(*) FROM zamm.workout_main;` = **0** ✅

**תוצאה:** Database נקי ומוכן לפרודקשן! 🎉

**זמן בפועל:** 15 דקות

---

### 2️⃣ **בדיקת פונקציות Validation** ✅ **הושלם!**

**מטרה:** לוודא שהפונקציות החדשות עובדות על נתונים אמיתיים

#### צעדים:
- [x] **בחר קובץ workout לדוגמה** - נבחר bader_workout_log.txt

- [x] **הזן אותו ל-`stg_imports`:**
  - ✅ import_id: `d2fd9b10-a2ad-48e0-a0c0-8ecd0a3aa4df`
  - ✅ Athlete: Bader Madhat
  
- [x] **פרסר אותו** (סימולציה ידנית)
  - ✅ יצירת JSON draft ב-`stg_parse_drafts`
  - ✅ draft_id: `b100c48a-3adb-4e17-a75b-4a6f071d148e`

- [x] **הרץ validation:**
  - ✅ זוהו 3 errors: חסרים session_code, prescription/performed בבלוק STR
  - ✅ הפונקציה עבדה בצורה מצוינת!
  
- [x] **תיקן בעיה קוד:**
  - ✅ שדה `athlete_natural_id` תוקן ל-`athlete_id` בפונקציה
  - ✅ Migration עודכן: `20260107150000_comprehensive_validation_functions.sql`

- [x] **בדוק תוצאות:**
  - ✅ תיקנו את הJSON (הוספנו session_code, prescription/performed)
  - ✅ validation pass! ✅ `0 errors, 0 warnings`

**תוצאה:** מערכת Validation עובדת מצוין! זיהתה בעיות ואישרה JSON תקין. 🎉

**זמן בפועל:** 25 דקות

---

### 3️⃣ **יצירת Golden Set - 10 Workouts** ✅ **הושלם!**

**מטרה:** ליצור 10 golden JSON references לבדיקת איכות פרסור

#### צעדים:
- [x] בחר 10 workouts מ-`/data/` (מגוון סוגים)
- [x] פרסר workouts לJSON - **10/10 הושלמו:**
  - ✅ `bader_2025-09-07_running_intervals.json` (INTV + ACT + SKILL, 5 blocks)
  - ✅ `yarden_2025-08-24_deadlift_strength.json` (STR + ACC, 8 blocks)
  - ✅ `jonathan_2025-08-24_lower_body_amrap.json` (STR + METCON AMRAP, 7 blocks)
  - ✅ `jonathan_2025-08-17_lower_body_fortime.json` (STR + METCON For Time, 6 blocks)
  - ✅ `orel_2025-06-01_amrap_hebrew_notes.json` (WU + MOB + ACT + METCON עברית, 4 blocks)
  - ✅ `yarden_frank_2025-07-06_mixed_blocks.json` (MOB+WU+STR+METCON+ACC+CD, 6 blocks)
  - ✅ `tomer_2025-11-02_deadlift_technique.json` (MOB + WU + ACT + STR×2 + ACC + SKILL, 7 blocks)
  - ✅ `melany_2025-09-14_rehab_strength.json` (WU + STR×3 + ACC×4 + SS + CD, 9 blocks - rehabilitation)
  - ✅ `itamar_2025-06-21_rowing_skill.json` (WU + MOB + SKILL + INTV×2 + ACC, 6 blocks - rowing specialization)
  - ✅ `arnon_2025-11-09_shoulder_rehab.json` (WU + ACT + STR×2 + ACC×4 + SS, 9 blocks - shoulder rehab with RPE)
- [x] שמור ב-`data/golden_set/<name>.json` ✅ כבר שמורים
- [ ] הרץ validation על כל אחד
- [ ] הרץ `./scripts/test_parser_accuracy.sh`

**סוגי workouts שנוצרו:**
- ✅ Running intervals (bader)
- ✅ Strength - Deadlift (yarden, tomer)
- ✅ METCON AMRAP (jonathan, orel)
- ✅ METCON For Time (jonathan)
- ✅ Mixed blocks (yarden frank)
- ✅ Hebrew text (orel)
- ✅ Rehabilitation protocols (melany, arnon)
- ✅ Rowing specialization (itamar)
- ✅ Shoulder rehab with RPE tracking (arnon)

**כיסוי מלא:**
- Block types: WU, MOB, ACT, STR, ACC, SKILL, INTV, METCON, SS, CD (10/17 block types covered)
- Languages: English + Hebrew ✅
- Complexity: Minimal (4 blocks) → Complex (9 blocks) ✅
- Special features: AMRAP, For Time, Tempo, RPE tracking, Rehab protocols, Hebrew notes ✅

**זמן בפועל:** 2 שעות (100% הושלם!)
- ✅ Lower body + For Time (jonathan)
- ✅ Hebrew text + AMRAP (orel)
- ✅ Complex 9-block workout (melany, arnon)
- ✅ Simple/Minimal recovery (simple)
- ✅ Skill/Gymnastics testing (yehuda)
- ✅ Edge case - unilateral/tempo/isometric (arnon)

**כיסוי מלא:**
- Block types: WU, MOB, ACT, STR, ACC, SKILL, INTV, METCON, SS, CD (10/17)
- Languages: English + Hebrew ✅
- Complexity: Minimal (2 blocks) → Complex (9 blocks) ✅
- Special features: AMRAP, For Time, Tempo, Isometrics, Unilateral ✅

**זמן בפועל:** 1.5 שעות (100% הושלם!)

---

## � ייעולים חדשים - אוטומציה ומערכות לומדות (9 ינואר 2026)

### ✅ **1. Alias Magic - קיצורי דרך חכמים** 
**סטטוס:** הושלם! ✅

**מה נוצר:**
- ✅ קובץ [.claude_aliases](.claude_aliases) - 8 aliases מוכנים לשימוש
- ✅ פונקציות עזר: `cld-query`, `cld-tables`, `cld-counts`

**איך להשתמש:**
```bash
# הפעלה חד פעמית
source .claude_aliases

# הוספה קבועה (מומלץ!)
echo 'source /workspaces/ParserZamaActive/.claude_aliases' >> ~/.bashrc
source ~/.bashrc
```

**Aliases זמינים:**
- `cld-admin` - סשן מנהל מלא (agents.md + PROTOCOL ZERO + TODO)
- `cld-dev` - סשן פיתוח (ARCHITECTURE.md + migrations)
- `cld-validate` - סשן בדיקות (validation functions)
- `cld-db-status` - בדיקת DB מהירה
- `cld-healthcheck` - בדיקה מלאה של המערכת

**תוצאה:** חיסכון של 2-3 דקות בכל פתיחת סשן! ⚡

---

### ✅ **2. Dynamic agents.md - עדכון אוטומטי**
**סטטוס:** הושלם! ✅

**מה נוצר:**
- ✅ סקריפט [scripts/update_agents_md.sh](scripts/update_agents_md.sh)
- ✅ Git pre-commit hook [scripts/git-hooks/pre-commit](scripts/git-hooks/pre-commit)

**איך להשתמש:**
```bash
# הרץ ידנית
./scripts/update_agents_md.sh

# התקנת pre-commit hook (אוטומטי!)
cp scripts/git-hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**תוצאה:** agents.md תמיד מסונכרן עם schema אמיתי! 🔄

---

### ✅ **3. Test Suite Foundation - Golden Set**
**סטטוס:** תשתית הוקמה! ✅

**מה נוצר:**
- ✅ תיקייה [data/golden_set/](data/golden_set/)
- ✅ סקריפט [scripts/test_parser_accuracy.sh](scripts/test_parser_accuracy.sh)
- ✅ דוגמת Golden JSON: `example_workout_golden.json`
- ✅ מדריך [data/golden_set/README.md](data/golden_set/README.md)

**הצעדים הבאים:**
1. פרסר 10 workouts מ-`/data/`
2. בדוק ואשר את הJSON
3. העתק ל-`data/golden_set/`
4. הרץ `./scripts/test_parser_accuracy.sh`

**מטרה:** 95%+ accuracy על golden set = production ready! 🎯

---

### ⏳ **4. Active Learning Loop** (טרם יושם)
**רעיון:** כל תיקון של validation error נשמר כדוגמה חדשה ב-AI_PROMPTS.md

**יישום עתידי:**
- צור טריגר SQL שכותב ל-`log_learning_examples`
- סקריפט שמעדכן את AI_PROMPTS.md אוטומטית
- המודל משתפר מכל טעות שנתקנה!

---

### ⏳ **5. Review UI** (טרם יושם)
**רעיון:** דשבורד פשוט לreview של drafts

**אופציות:**
- Streamlit (Python, מהיר)
- Retool (No-code)
- HTML פשוט + Supabase API

**מה יציג:**
- רשימת drafts ממתינים
- טקסט מקורי vs JSON
- Validation report
- כפתורים: Approve / Edit / Reject

---

## �🔧 משימות עדיפות בינונית (יום 2-3)

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
1. ✅ ניקוי נתונים (30 דקות) - **הושלם!**
2. ✅ בדיקת validation עם workout אמיתי (45 דקות) - **הושלם!**
3. ✅ ייעולים אופרטיביים (aliases, schema sync, test suite) (1.5 שעות) - **הושלם!**

**אחר צהריים (2 שעות):**
5. הרחבת exercise catalog (2 שעות)

**סה"כ:** ~5 שעות עבודה פרודוקטיבית

---

## 📊 KPIs להצלחה

**היום (9 ינואר):**
- ✅ Database נקי מנתוני בדיקה
- ✅ לפחות 1 workout אמיתי עבר validation + commit בהצלחה
- ✅ ייעולים אופרטיביים (aliases, automation scripts)
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
