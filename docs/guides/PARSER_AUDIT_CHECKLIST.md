# Parser Audit Checklist

**מסמך ביקורת מקיף לתהליך הפרסור - ZAMM Workout Parser**

---

## 📋 סקירה כללית

מסמך זה מכיל **checklist מלא** לבדיקת איכות הנתונים שעברו פרסור, בהתאם לכל השדות והמבנים שהמערכת תומכת בהם.

**מטרה:** להבטיח שכל נתון שעבר פרסור מדויק, תקין, ותואם את המבנה הצפוי לפני שהוא נשמר בטבלאות הפרודקשן.

**שלב בתהליך:** ביקורת זו מתבצעת ב**Stage 3: Validation**, לאחר הפרסור הראשוני ולפני ה-Commit הסופי.

---

## 🎯 שלבי הביקורת

### שלב 1: ביקורת מבנית (Structure Audit)
בדיקה שהמבנה הכללי של ה-JSON תקין

### שלב 2: ביקורת נתונים (Data Audit)
בדיקה שכל הערכים הגיוניים ותקינים

### שלב 3: ביקורת עקביות (Consistency Audit)
בדיקה שהנתונים עקביים עם הטקסט המקורי

### שלב 4: ביקורת אסטרטגית (Business Logic Audit)
בדיקה שהפרדת Prescription vs Performance נשמרת

---

## ✅ שלב 1: ביקורת מבנית (Structure Audit)

### 1.1 בדיקת שדות חובה ברמת Root

```json
{
  "workout_date": "YYYY-MM-DD",     // ✅ REQUIRED
  "athlete_id": "UUID",              // ✅ REQUIRED
  "sessions": []                     // ✅ REQUIRED, array not empty
}
```

**Checklist:**
- [ ] `workout_date` קיים והוא מסוג string
- [ ] `workout_date` בפורמט תקין `YYYY-MM-DD` (regex: `^\d{4}-\d{2}-\d{2}$`)
- [ ] `workout_date` הוא תאריך הגיוני (לא בעתיד, לא לפני 2015)
- [ ] `athlete_id` קיים והוא UUID תקין
- [ ] `athlete_id` קיים בטבלת `lib_athletes`
- [ ] `sessions` קיים והוא array
- [ ] `sessions` מכיל לפחות session אחד (לא ריק)

---

### 1.2 בדיקת מבנה Session

```json
{
  "session_code": "AM" | "PM" | "SINGLE",  // ✅ REQUIRED
  "blocks": []                              // ✅ REQUIRED
}
```

**Checklist:**
- [ ] כל session מכיל `session_code`
- [ ] `session_code` הוא אחד מהערכים: `"AM"`, `"PM"`, `"SINGLE"`
- [ ] `blocks` קיים והוא array
- [ ] `blocks` מכיל לפחות block אחד

---

### 1.3 בדיקת מבנה Block

```json
{
  "block_code": "STR",               // ✅ REQUIRED
  "block_label": "A",                // ✅ REQUIRED
  "block_type": "strength",          // optional (deprecated)
  "name": "Strength Work",           // optional
  "prescription": {},                // ✅ REQUIRED
  "performed": {} | null             // ✅ REQUIRED (can be null or {})
}
```

**Checklist:**
- [ ] כל block מכיל `block_code`
- [ ] `block_code` הוא אחד מ-17 הקודים התקניים:
  - **PREPARATION**: WU, ACT, MOB
  - **STRENGTH**: STR, ACC, HYP
  - **POWER**: PWR, WL
  - **SKILL**: SKILL, GYM
  - **CONDITIONING**: METCON, INTV, SS, HYROX
  - **RECOVERY**: CD, STRETCH, BREATH
- [ ] `block_label` קיים (לרוב: A, B, C, D)
- [ ] `prescription` קיים (object או null)
- [ ] `performed` קיים (object או null)
- [ ] אם `performed` הוא `{}` ריק, זה תקין (אין נתוני ביצוע)

---

### 1.4 בדיקת מבנה Prescription

**מבנה משתנה לפי סוג Block:**

#### 1.4.1 Strength/Accessory/Hypertrophy (STR, ACC, HYP)

```json
{
  "structure": "sets_reps",          // ✅ REQUIRED
  "steps": [                         // ✅ REQUIRED
    {
      "exercise_name": "Back Squat", // ✅ REQUIRED
      "target_sets": 3,              // ✅ REQUIRED
      "target_reps": 5,              // ✅ REQUIRED (or array)
      "target_load": {               // optional
        "value": 100,
        "unit": "kg"
      },
      "equipment_key": "barbell",    // optional
      "tempo": "3010",               // optional
      "rest_seconds": 180,           // optional
      "notes": "Build to heavy"      // optional
    }
  ]
}
```

**Checklist:**
- [ ] `prescription.structure` הוא `"sets_reps"`
- [ ] `prescription.steps` קיים והוא array
- [ ] כל step מכיל `exercise_name` (string)
- [ ] כל step מכיל `target_sets` (integer > 0)
- [ ] כל step מכיל `target_reps` (integer > 0 או array של integers)
- [ ] אם `target_load` קיים:
  - [ ] `target_load.value` הוא מספר > 0
  - [ ] `target_load.unit` הוא `"kg"` או `"lbs"` או `"%"`
- [ ] אם `equipment_key` קיים, הוא תקין בטבלת `lib_equipment_catalog`
- [ ] אם `tempo` קיים, הוא 4 ספרות (regex: `^\d{4}$`)

#### 1.4.2 METCON (AMRAP/For Time)

```json
{
  "structure": "amrap" | "fortime",  // ✅ REQUIRED
  "time_cap_seconds": 600,           // ✅ REQUIRED for AMRAP
  "target_rounds": 5,                // ✅ REQUIRED for For Time
  "steps": [                         // ✅ REQUIRED
    {
      "exercise_name": "Thrusters",
      "target_reps": 15,
      "target_load": {"value": 42.5, "unit": "kg"}
    },
    {
      "exercise_name": "Chest-to-Bar Pull-Ups",
      "target_reps": 12
    }
  ]
}
```

**Checklist:**
- [ ] `prescription.structure` הוא `"amrap"` או `"fortime"` או `"rounds"`
- [ ] אם AMRAP: `time_cap_seconds` קיים (integer > 0)
- [ ] אם For Time: `target_rounds` קיים (integer > 0)
- [ ] `prescription.steps` קיים והוא array
- [ ] כל step מכיל `exercise_name`
- [ ] כל step מכיל `target_reps` או `target_distance` או `target_calories`

#### 1.4.3 Intervals (INTV)

```json
{
  "structure": "intervals",          // ✅ REQUIRED
  "rounds": 8,                       // ✅ REQUIRED
  "work_seconds": 20,                // ✅ REQUIRED
  "rest_seconds": 10,                // ✅ REQUIRED
  "steps": [
    {
      "exercise_name": "Assault Bike",
      "target_metric": "max_calories"
    }
  ]
}
```

**Checklist:**
- [ ] `prescription.structure` הוא `"intervals"`
- [ ] `rounds` קיים (integer > 0)
- [ ] `work_seconds` קיים (integer > 0)
- [ ] `rest_seconds` קיים (integer >= 0)
- [ ] `steps` קיים והוא array

#### 1.4.4 Steady State (SS)

```json
{
  "structure": "steady_state",       // ✅ REQUIRED
  "target_duration_minutes": 30,     // ✅ REQUIRED
  "target_distance_meters": 5000,    // optional
  "target_pace": "2:00/500m",        // optional
  "modality": "row",                 // ✅ REQUIRED
  "intensity_zone": "Z2"             // optional
}
```

**Checklist:**
- [ ] `prescription.structure` הוא `"steady_state"`
- [ ] `target_duration_minutes` קיים או `target_distance_meters` קיים
- [ ] `modality` קיים: `"run"`, `"row"`, `"bike"`, `"ski"`, `"swim"`
- [ ] אם `target_pace` קיים, הוא בפורמט תקין (e.g., `"2:00/500m"`)

---

### 1.5 בדיקת מבנה Performed

#### 1.5.1 Performed - Strength/Sets

```json
{
  "did_complete": true,              // ✅ REQUIRED
  "steps": [                         // ✅ REQUIRED
    {
      "exercise_name": "Back Squat", // ✅ REQUIRED
      "sets": [                      // ✅ REQUIRED
        {
          "set_index": 1,            // ✅ REQUIRED
          "reps": 5,                 // ✅ REQUIRED
          "load_kg": 100,            // optional
          "rpe": 7.5,                // optional
          "rir": 2,                  // optional
          "tempo_actual": "3010",    // optional
          "notes": "felt good"       // optional
        },
        {
          "set_index": 2,
          "reps": 5,
          "load_kg": 100
        },
        {
          "set_index": 3,
          "reps": 4,
          "load_kg": 100,
          "notes": "grip failed"
        }
      ]
    }
  ],
  "notes": "Overall good session"    // optional
}
```

**Checklist:**
- [ ] `performed.did_complete` קיים (boolean)
- [ ] `performed.steps` קיים והוא array
- [ ] כל step מכיל `sets` array
- [ ] כל set מכיל `set_index` (integer, sequential: 1, 2, 3...)
- [ ] כל set מכיל `reps` (integer >= 0)
- [ ] אם `load_kg` קיים, הוא מספר > 0
- [ ] אם `rpe` קיים, הוא בטווח 1-10 (מותר 0.5 צעדים)
- [ ] אם `rir` קיים, הוא בטווח 0-10
- [ ] `set_index` ייחודי בתוך ה-exercise (אין שני sets עם אותו מספר)

#### 1.5.2 Performed - METCON

```json
{
  "did_complete": true,              // ✅ REQUIRED
  "total_time_sec": 537,             // REQUIRED for "fortime"
  "rounds_completed": 8,             // REQUIRED for "amrap"
  "reps_in_partial_round": 15,      // optional (AMRAP)
  "score_text": "8+15 reps",        // optional
  "steps": [                         // optional (details)
    {
      "exercise_name": "Thrusters",
      "total_reps": 120
    }
  ],
  "notes": "Started too fast"       // optional
}
```

**Checklist:**
- [ ] `performed.did_complete` קיים (boolean)
- [ ] אם Block הוא AMRAP:
  - [ ] `rounds_completed` קיים (integer >= 0)
  - [ ] אופציונלי: `reps_in_partial_round` (integer >= 0)
- [ ] אם Block הוא For Time:
  - [ ] `total_time_sec` קיים (integer > 0)
- [ ] אם `score_text` קיים, הוא תואם למבנה (e.g., `"8:57"` or `"6 rounds + 12 reps"`)

#### 1.5.3 Performed - Intervals

```json
{
  "did_complete": true,              // ✅ REQUIRED
  "rounds_completed": 8,             // ✅ REQUIRED
  "intervals": [                     // optional (detailed splits)
    {
      "interval_number": 1,
      "work_seconds": 20,
      "score": 12,
      "metric": "calories"
    },
    {
      "interval_number": 2,
      "work_seconds": 20,
      "score": 11,
      "metric": "calories"
    }
  ],
  "notes": "Kept consistent pace"   // optional
}
```

**Checklist:**
- [ ] `performed.did_complete` קיים (boolean)
- [ ] `rounds_completed` קיים (integer >= 0)
- [ ] אם `intervals` קיים:
  - [ ] כל interval מכיל `interval_number` (sequential: 1, 2, 3...)
  - [ ] כל interval מכיל `score` (מספר)

#### 1.5.4 Performed - Steady State

```json
{
  "did_complete": true,              // ✅ REQUIRED
  "total_time_sec": 1800,            // ✅ REQUIRED
  "total_distance_meters": 5250,     // optional
  "avg_pace": "2:00/500m",           // optional
  "avg_heart_rate": 145,             // optional
  "calories": 320,                   // optional
  "notes": "Felt strong"             // optional
}
```

**Checklist:**
- [ ] `performed.did_complete` קיים (boolean)
- [ ] `total_time_sec` קיים (integer > 0)
- [ ] אם `total_distance_meters` קיים, הוא מספר > 0
- [ ] אם `avg_pace` קיים, הוא בפורמט תקין
- [ ] אם `avg_heart_rate` קיים, הוא בטווח הגיוני (40-220)

---

## ✅ שלב 2: ביקורת נתונים (Data Audit)

### 2.1 בדיקת ערכים הגיוניים

#### משקלים (Loads)

**Checklist:**
- [ ] כל `load_kg` בטווח 0-500 ק"ג
- [ ] אזהרה אם > 300 ק"ג (אלא אם כן Deadlift/Squat)
- [ ] שגיאה אם > 500 ק"ג (לא סביר)
- [ ] אם `load_kg` קיים, הוא מספר חיובי (לא שלילי, לא אפס)

#### חזרות (Reps)

**Checklist:**
- [ ] כל `reps` בטווח 1-100
- [ ] אזהרה אם > 50 חזרות (נדיר, אך אפשרי בתרגילים קלים)
- [ ] שגיאה אם > 200 חזרות (לא סביר)
- [ ] `reps` הוא integer (לא עשרוני)

#### סטים (Sets)

**Checklist:**
- [ ] `target_sets` בטווח 1-10
- [ ] אזהרה אם > 8 סטים (נדיר)
- [ ] מספר ה-sets בפועל (`performed.steps[].sets.length`) לא שונה מדי מהתכנון
  - [ ] אם תוכנן 3 סטים ובוצעו 5, זו אזהרה

#### זמנים (Times)

**Checklist:**
- [ ] `total_time_sec` בטווח 1-7200 שניות (עד 2 שעות)
- [ ] אזהרה אם > 3600 שניות (שעה)
- [ ] שגיאה אם > 10800 שניות (3 שעות - לא סביר לאימון רגיל)
- [ ] `time_cap_seconds` בטווח 60-1800 שניות
- [ ] `work_seconds` בטווח 5-300 שניות
- [ ] `rest_seconds` בטווח 0-600 שניות

#### RPE (Rate of Perceived Exertion)

**Checklist:**
- [ ] `rpe` בטווח 1-10
- [ ] מותר: 0.5, 6.5, 7.5, 8.5, 9.5 (צעדים של חצי)
- [ ] שגיאה אם < 1 או > 10
- [ ] אזהרה אם כל הסטים עם אותו RPE בדיוק (לא סביר - צפוי עליה ב-RPE)

#### RIR (Reps in Reserve)

**Checklist:**
- [ ] `rir` בטווח 0-10
- [ ] אזהרה אם RIR גבוה (> 5) בסט אחרון (צפוי RIR נמוך)
- [ ] אזהרה אם RIR יורד במהלך הסטים (צפוי עליה)

#### Tempo

**Checklist:**
- [ ] `tempo` הוא 4 ספרות: `"XXXX"` (e.g., `"3010"`, `"2120"`)
- [ ] כל ספרה בטווח 0-9
- [ ] שגיאה אם לא בפורמט הזה

---

### 2.2 בדיקת קטלוגים (Catalog Validation)

#### Exercise Names

**Checklist:**
- [ ] כל `exercise_name` קיים בטבלת `lib_exercise_catalog` **או** `lib_exercise_aliases`
- [ ] שגיאה אם התרגיל לא קיים (צריך להוסיף לקטלוג)
- [ ] אזהרה אם שם התרגיל דומה אך לא זהה (typo?)
  - דוגמה: `"Back Sqat"` במקום `"Back Squat"`

**פעולה:**
```sql
-- בדיקה
SELECT exercise_key 
FROM zamm.lib_exercise_catalog 
WHERE LOWER(exercise_name) = LOWER('Back Squat');

-- או דרך aliases
SELECT exercise_key 
FROM zamm.lib_exercise_aliases 
WHERE LOWER(alias) = LOWER('back squat');
```

#### Equipment Keys

**Checklist:**
- [ ] כל `equipment_key` קיים בטבלת `lib_equipment_catalog` **או** `lib_equipment_aliases`
- [ ] שגיאה אם הציוד לא קיים
- [ ] אזהרה אם שם הציוד דומה אך לא זהה

**פעולה:**
```sql
SELECT * FROM zamm.check_equipment_exists('barbell');
```

#### Block Codes

**Checklist:**
- [ ] כל `block_code` הוא אחד מ-17 הקודים התקניים
- [ ] אם Block מכיל `block_type` (deprecated), יש להמיר ל-`block_code`
- [ ] שגיאה אם `block_code` לא תקין

**פעולה:**
```sql
SELECT * FROM zamm.normalize_block_type('חימום');
-- Returns: 'WU', 'PREPARATION'
```

---

### 2.3 בדיקת יחידות (Units Validation)

**Checklist:**
- [ ] כל `target_load.unit` הוא אחד מ: `"kg"`, `"lbs"`, `"%"`, `"BW"` (bodyweight)
- [ ] אם `unit` הוא `"%"`, `value` בטווח 1-150 (אחוזי 1RM)
- [ ] אם `unit` הוא `"BW"`, `value` בטווח 0.1-3.0 (כפולות משקל גוף)
- [ ] כל `distance` במטרים (m) או קילומטרים (km)
- [ ] כל `time` בשניות (seconds)
- [ ] כל `pace` בפורמט תקין: `"MM:SS/500m"` או `"MM:SS/km"`

---

## ✅ שלב 3: ביקורת עקביות (Consistency Audit)

### 3.1 עקביות בין Prescription ל-Performed

**Checklist:**
- [ ] מספר ה-exercises ב-`performed.steps` תואם ל-`prescription.steps`
  - אזהרה אם יש exercise בביצוע שלא היה בתכנון
- [ ] סדר ה-exercises זהה (אלא אם כן צוין שינוי)
- [ ] `exercise_name` זהה בשני המקומות (prescription + performed)
- [ ] אם `target_sets` היה 3 ו-`performed.sets.length` הוא 5, זו אזהרה
  - אלא אם כן יש הסבר ב-`notes`

### 3.2 עקביות פנימית ב-Performed

**Checklist:**
- [ ] `set_index` sequential (1, 2, 3...) ללא פערים
- [ ] אין שני sets עם אותו `set_index`
- [ ] סכום החזרות: `SUM(reps)` תואם להצהרות כלליות
  - דוגמה: אם `score_text` = `"120 total reps"`, סכום הרפס צריך להיות 120
- [ ] אם `did_complete = false`, יש `notes` שמסביר למה

### 3.3 עקביות עם הטקסט המקורי

**Checklist (Manual Review):**
- [ ] כל מספר ב-JSON מופיע בטקסט המקורי
  - דוגמה: אם JSON אומר `100kg`, הטקסט חייב להכיל `"100"`
- [ ] שמות תרגילים תואמים או דומים מאוד לטקסט
  - דוגמה: טקסט `"BS"` → JSON `"Back Squat"` ✅
  - דוגמה: טקסט `"Squat"` → JSON `"Bench Press"` ❌
- [ ] אם הטקסט אומר `"לא הצלחתי"`, `did_complete` צריך להיות `false`
- [ ] אם הטקסט מזכיר זמן (`"8:45"`), ה-JSON צריך להכיל `total_time_sec: 525`

### 3.4 עקביות בין Blocks

**Checklist:**
- [ ] `block_label` ייחודי בתוך session (לא שני blocks עם label "A")
- [ ] סדר הלייבלים הגיוני: A → B → C (לא A → C → B)
- [ ] אם יש Warm-Up (WU), הוא בדרך כלל ה-block הראשון
- [ ] אם יש Cool-Down (CD), הוא בדרך כלל ה-block האחרון

---

## ✅ שלב 4: ביקורת אסטרטגית (Business Logic Audit)

### 4.1 הפרדת Prescription vs Performance

**עקרון מרכזי:** כל entity מחזיק **שני שדות נפרדים**:
- `prescription` = מה שתוכנן
- `performed` = מה שבוצע בפועל

**Checklist:**
- [ ] ה-`prescription` **לעולם לא מכיל** נתוני ביצוע בפועל
  - ❌ שגיאה: `prescription.steps[0].reps_performed`
  - ✅ נכון: `performed.steps[0].sets[0].reps`
- [ ] ה-`performed` **לעולם לא מכיל** נתוני תכנון
  - ❌ שגיאה: `performed.steps[0].target_load`
  - ✅ נכון: `prescription.steps[0].target_load`
- [ ] אם יש הבדל בין תכנון לביצוע, הוא מתועד:
  - דוגמה: תוכנן 100kg, בוצע 95kg → מופיע ב-`notes`

### 4.2 Logic by Block Type

#### Strength Blocks (STR, ACC, HYP)

**Checklist:**
- [ ] `prescription.structure` = `"sets_reps"`
- [ ] `target_sets` ו-`target_reps` מוגדרים
- [ ] `performed.steps[].sets` קיים ומכיל פירוט של כל סט
- [ ] כל סט מכיל `reps` + `load_kg` (אם רלוונטי)

#### METCON Blocks

**Checklist:**
- [ ] `prescription.structure` = `"amrap"` או `"fortime"` או `"rounds"`
- [ ] אם AMRAP: `time_cap_seconds` מוגדר
- [ ] אם For Time: `target_rounds` מוגדר
- [ ] `performed` מכיל `total_time_sec` או `rounds_completed`
- [ ] `score_text` תואם לסוג ה-METCON

#### Interval Blocks

**Checklist:**
- [ ] `prescription.structure` = `"intervals"`
- [ ] `rounds`, `work_seconds`, `rest_seconds` מוגדרים
- [ ] `performed.rounds_completed` <= `prescription.rounds`
- [ ] אופציונלי: `performed.intervals` מכיל פירוט של כל interval

#### Steady State Blocks

**Checklist:**
- [ ] `prescription.structure` = `"steady_state"`
- [ ] `target_duration_minutes` או `target_distance_meters` מוגדר
- [ ] `performed.total_time_sec` תואם (בערך) לתכנון
- [ ] אם `avg_pace` קיים, הוא הגיוני עבור המרחק והזמן

### 4.3 Missing Data Logic

**Checklist:**
- [ ] אם אין נתוני ביצוע (workout לא בוצע עדיין):
  - [ ] `performed = null` או `performed = {}`
  - [ ] זה **תקין** - מותר לשמור prescription בלבד
- [ ] אם יש נתוני ביצוע חלקיים:
  - [ ] `did_complete = false`
  - [ ] `notes` מסביר מה לא הושלם
- [ ] אם exercise דולג:
  - [ ] `performed.steps[X].sets = []` (ריק)
  - [ ] או: לא מופיע ב-`performed.steps`

---

## 🚨 Severity Levels

כל ממצא בביקורת מקבל רמת חומרה:

### ❌ ERROR (שגיאה)
**הגדרה:** נתון לא תקין, מונע commit
**דוגמאות:**
- `workout_date` חסר
- `athlete_id` לא קיים בטבלת athletes
- `block_code` לא תקני
- `exercise_name` לא קיים בקטלוג
- `rpe` מחוץ לטווח 1-10
- `set_index` לא sequential

**פעולה:** עצור, לא לאשר commit עד לתיקון

---

### ⚠️ WARNING (אזהרה)
**הגדרה:** נתון חשוד, מומלץ בדיקה ידנית
**דוגמאות:**
- `load_kg` > 300 (חשוד אבל אפשרי)
- `reps` > 50 (חשוד אבל אפשרי)
- מספר הסטים בביצוע שונה מהתכנון (2 במקום 3)
- `total_time_sec` > 3600 (שעה - אימון ארוך מאוד)
- כל הסטים עם אותו RPE (לא סביר)

**פעולה:** הצג למשתמש, אפשר אישור ידני

---

### ℹ️ INFO (מידע)
**הגדרה:** הערה למידע בלבד, לא דורש פעולה
**דוגמאות:**
- `performed = null` (workout לא בוצע עדיין)
- `notes` ריק (לא חובה)
- `tempo` חסר (אופציונלי)
- exercise חדש נוסף לקטלוג

**פעולה:** הצג רק אם המשתמש מבקש דוח מפורט

---

## 📊 פורמט דוח הביקורת

```json
{
  "validation_status": "pass" | "fail" | "warning",
  "summary": {
    "total_checks": 127,
    "passed": 120,
    "warnings": 6,
    "errors": 1
  },
  "errors": [
    {
      "severity": "error",
      "category": "structure",
      "field": "sessions[0].blocks[1].block_code",
      "issue": "Invalid block_code 'XYZ' - must be one of 17 standard codes",
      "expected": "WU, ACT, MOB, STR, ACC, HYP, PWR, WL, SKILL, GYM, METCON, INTV, SS, HYROX, CD, STRETCH, BREATH",
      "actual": "XYZ",
      "location": "Block B",
      "raw_text_excerpt": "Block B - XYZ work"
    }
  ],
  "warnings": [
    {
      "severity": "warning",
      "category": "data_value",
      "field": "sessions[0].blocks[0].prescription.steps[0].target_load.value",
      "issue": "Load value 350kg exceeds typical range (usually < 300kg)",
      "expected": "< 300",
      "actual": 350,
      "location": "Block A, Exercise 1: Deadlift",
      "suggestion": "Verify this is correct - very heavy load"
    },
    {
      "severity": "warning",
      "category": "consistency",
      "field": "sessions[0].blocks[0].performed.steps[0].sets.length",
      "issue": "Performed sets count (5) differs from target (3)",
      "expected": 3,
      "actual": 5,
      "location": "Block A, Exercise 1: Back Squat",
      "suggestion": "Check if athlete did extra sets intentionally"
    }
  ],
  "info": [
    {
      "severity": "info",
      "category": "missing_data",
      "field": "sessions[0].blocks[2].performed",
      "issue": "No performance data - workout not executed yet",
      "location": "Block C",
      "note": "This is normal for planned-only workouts"
    }
  ],
  "confidence_score": 0.92,
  "reviewed_by": "AI Parser",
  "reviewed_at": "2026-01-07T14:30:00Z"
}
```

---

## 🛠️ סקריפטים לביצוע ביקורת אוטומטית

### סקריפט 1: בדיקת מבנה בסיסי

```sql
-- Check basic structure
CREATE OR REPLACE FUNCTION zamm.validate_parsed_structure(parsed_json JSONB)
RETURNS TABLE (
    is_valid BOOLEAN,
    error_field TEXT,
    error_message TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check workout_date
    IF NOT (parsed_json ? 'workout_date') THEN
        RETURN QUERY SELECT FALSE, 'workout_date', 'Missing required field';
    END IF;

    -- Check athlete_id
    IF NOT (parsed_json ? 'athlete_id') THEN
        RETURN QUERY SELECT FALSE, 'athlete_id', 'Missing required field';
    END IF;

    -- Check sessions exist
    IF NOT (parsed_json ? 'sessions') THEN
        RETURN QUERY SELECT FALSE, 'sessions', 'Missing required field';
    ELSIF jsonb_array_length(parsed_json->'sessions') = 0 THEN
        RETURN QUERY SELECT FALSE, 'sessions', 'Sessions array is empty';
    END IF;

    -- If all checks passed
    IF NOT FOUND THEN
        RETURN QUERY SELECT TRUE, NULL::TEXT, NULL::TEXT;
    END IF;
END;
$$;
```

### סקריפט 2: בדיקת Block Codes

```sql
-- Validate all block codes
CREATE OR REPLACE FUNCTION zamm.validate_block_codes(parsed_json JSONB)
RETURNS TABLE (
    is_valid BOOLEAN,
    invalid_code TEXT,
    block_location TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_session JSONB;
    v_block JSONB;
    v_block_code TEXT;
    v_session_idx INT := 0;
    v_block_idx INT := 0;
    v_valid_codes TEXT[] := ARRAY['WU','ACT','MOB','STR','ACC','HYP','PWR','WL','SKILL','GYM','METCON','INTV','SS','HYROX','CD','STRETCH','BREATH'];
BEGIN
    -- Loop through sessions
    FOR v_session IN SELECT * FROM jsonb_array_elements(parsed_json->'sessions')
    LOOP
        v_session_idx := v_session_idx + 1;
        v_block_idx := 0;
        
        -- Loop through blocks
        FOR v_block IN SELECT * FROM jsonb_array_elements(v_session->'blocks')
        LOOP
            v_block_idx := v_block_idx + 1;
            v_block_code := v_block->>'block_code';
            
            -- Check if block_code is valid
            IF v_block_code IS NULL THEN
                RETURN QUERY SELECT FALSE, NULL::TEXT, format('Session %s, Block %s', v_session_idx, v_block_idx);
            ELSIF NOT (v_block_code = ANY(v_valid_codes)) THEN
                RETURN QUERY SELECT FALSE, v_block_code, format('Session %s, Block %s', v_session_idx, v_block_idx);
            END IF;
        END LOOP;
    END LOOP;

    -- If all checks passed
    IF NOT FOUND THEN
        RETURN QUERY SELECT TRUE, NULL::TEXT, NULL::TEXT;
    END IF;
END;
$$;
```

### סקריפט 3: בדיקת ערכי RPE/RIR

```sql
-- Validate RPE and RIR values
CREATE OR REPLACE FUNCTION zamm.validate_rpe_rir(parsed_json JSONB)
RETURNS TABLE (
    is_valid BOOLEAN,
    field_name TEXT,
    invalid_value NUMERIC,
    location TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_session JSONB;
    v_block JSONB;
    v_step JSONB;
    v_set JSONB;
    v_rpe NUMERIC;
    v_rir NUMERIC;
BEGIN
    -- Loop through all performed sets
    FOR v_session IN SELECT * FROM jsonb_array_elements(parsed_json->'sessions')
    LOOP
        FOR v_block IN SELECT * FROM jsonb_array_elements(v_session->'blocks')
        LOOP
            IF v_block->'performed' IS NOT NULL THEN
                FOR v_step IN SELECT * FROM jsonb_array_elements(v_block->'performed'->'steps')
                LOOP
                    FOR v_set IN SELECT * FROM jsonb_array_elements(v_step->'sets')
                    LOOP
                        -- Check RPE
                        v_rpe := (v_set->>'rpe')::NUMERIC;
                        IF v_rpe IS NOT NULL AND (v_rpe < 1 OR v_rpe > 10) THEN
                            RETURN QUERY SELECT FALSE, 'rpe', v_rpe, format('Block %s, Set %s', v_block->>'block_label', v_set->>'set_index');
                        END IF;

                        -- Check RIR
                        v_rir := (v_set->>'rir')::NUMERIC;
                        IF v_rir IS NOT NULL AND (v_rir < 0 OR v_rir > 10) THEN
                            RETURN QUERY SELECT FALSE, 'rir', v_rir, format('Block %s, Set %s', v_block->>'block_label', v_set->>'set_index');
                        END IF;
                    END LOOP;
                END LOOP;
            END IF;
        END LOOP;
    END LOOP;

    -- If all checks passed
    IF NOT FOUND THEN
        RETURN QUERY SELECT TRUE, NULL::TEXT, NULL::NUMERIC, NULL::TEXT;
    END IF;
END;
$$;
```

---

## 📝 תהליך ביקורת ידנית (Manual Review Checklist)

### לפני Commit סופי

**צעדים:**

1. **הצג את ה-JSON המפורסר לצד הטקסט המקורי**
   - בדוק שכל מספר תואם
   - בדוק ששמות תרגילים תואמים

2. **הרץ סקריפטי ביקורת אוטומטיים**
   ```sql
   SELECT * FROM zamm.validate_parsed_structure(parsed_json);
   SELECT * FROM zamm.validate_block_codes(parsed_json);
   SELECT * FROM zamm.validate_rpe_rir(parsed_json);
   ```

3. **בדוק Errors**
   - אם יש errors, **עצור** ואל תאשר commit
   - תקן את הבעיות ב-`stg_draft_edits`

4. **סקור Warnings**
   - הצג למשתמש (אם אפשר)
   - אשר ידנית או תקן

5. **אשר Commit**
   ```sql
   SELECT zamm.commit_full_workout_v3(
       import_id,
       draft_id,
       ruleset_id,
       athlete_id,
       validated_json
   );
   ```

6. **תעד בדוח הביקורת**
   ```sql
   INSERT INTO zamm.log_validation_reports (
       draft_id,
       validation_status,
       error_details,
       validated_at
   ) VALUES (
       draft_id,
       'pass', -- או 'warning' / 'fail'
       validation_report_json,
       NOW()
   );
   ```

---

## 🔗 קישורים למסמכים נוספים

- [PARSER_WORKFLOW.md](./PARSER_WORKFLOW.md) - תהליך הפרסור המלא
- [AI_PROMPTS.md](./AI_PROMPTS.md) - Prompts לסוכני AI
- [BLOCK_TYPES_REFERENCE.md](../reference/BLOCK_TYPES_REFERENCE.md) - 17 סוגי Blocks
- [ARCHITECTURE.md](../../ARCHITECTURE.md) - ארכיטקטורת המערכת
- [agents.md](../../agents.md) - מדריך לסוכני AI

---

## 📌 Summary Checklist (קצר)

**השתמש ב-checklist הזה לביקורת מהירה:**

### מבנה כללי
- [ ] `workout_date` קיים ותקין
- [ ] `athlete_id` קיים וקיים בטבלה
- [ ] `sessions` מכיל לפחות session אחד

### Blocks
- [ ] כל block מכיל `block_code` תקני (1 מ-17)
- [ ] כל block מכיל `prescription` ו-`performed`
- [ ] `block_label` ייחודי (A, B, C...)

### Prescription
- [ ] `structure` מוגדר ותואם לסוג ה-block
- [ ] `steps` קיים ומכיל exercises
- [ ] כל exercise מכיל `exercise_name`
- [ ] ערכים מספריים בטווח הגיוני

### Performed
- [ ] `did_complete` מוגדר
- [ ] `sets` עם `set_index` sequential
- [ ] `rpe` בטווח 1-10 (אם קיים)
- [ ] `load_kg` בטווח 0-500 (אם קיים)

### Catalogs
- [ ] כל `exercise_name` קיים בקטלוג
- [ ] כל `equipment_key` קיים בקטלוג
- [ ] כל `block_code` תקני

### Prescription vs Performance
- [ ] הפרדה מוחלטת בין תכנון לביצוע
- [ ] לא מערבבים שדות בין prescription ל-performed

---

**גרסה:** 1.0.0  
**עדכון אחרון:** 7 ינואר 2026  
**מטרה:** להבטיח איכות נתונים גבוהה לפני commit סופי
