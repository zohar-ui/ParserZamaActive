# 🎯 Stage 2 Parsing Strategy
## אסטרטגיה מקיפה להמרת טקסט ל-JSON ללא טעויות

**מסמך מנחה לפרסור אימונים - שלב 2 (הלב של המערכת)**

---

## 📋 תוכן עניינים

1. [סקירת הבעיה](#סקירת-הבעיה)
2. [עקרונות יסוד](#עקרונות-יסוד)
3. [פיצול לתת-תהליכים](#פיצול-לתת-תהליכים)
4. [תהליך פרסור מובנה](#תהליך-פרסור-מובנה)
5. [כללי זהב](#כללי-זהב)
6. [דפוסי טקסט נפוצים](#דפוסי-טקסט-נפוצים)
7. [בקרת איכות](#בקרת-איכות)
8. [כלי עזר ושפת קוד](#כלי-עזר-ושפת-קוד)

---

## 🔴 סקירת הבעיה

### מה למדנו מה-Golden Set Audit:

| בעיה | תיאור | חומרה |
|------|-------|--------|
| **הזיות (Hallucinations)** | AI המציא athlete_id, session_code | 🔴 קריטי |
| **היסק לא מורשה** | הוספת ערכים שלא בטקסט | 🔴 קריטי |
| **בלבול Prescription/Performance** | הוראות בשדה performed | 🟠 גבוה |
| **שגיאות לוגיקת סטים** | 2×12/12 פורש לא נכון | 🔴 קריטי |
| **חוסר עקביות מבנית** | בלוק A שטוח, בלוק B מפורט | 🟡 בינוני |

### שורש הבעיה:
> **AI נוטה "לעזור" יותר מדי** - ממציא מידע שנראה הגיוני אבל לא קיים בטקסט המקור.

---

## ⚖️ עקרונות יסוד

### 🔒 עיקרון #1: ZERO INFERENCE
```
❌ אסור להסיק
❌ אסור לחשב
❌ אסור להמציא
✅ רק מה שכתוב במפורש
```

**דוגמה:**
```
טקסט: "Back Squat 3x5 @ 100kg"

✅ נכון:
{
  "prescription": { "target_sets": 3, "target_reps": 5, "target_load_kg": 100 }
  "performed": null  // לא צוין מה קרה בפועל!
}

❌ שגוי:
{
  "prescription": { "target_sets": 3, "target_reps": 5, "target_load_kg": 100 }
  "performed": { "actual_sets": 3, "actual_reps": [5,5,5], "actual_loads": [100,100,100] }
  // ← הזיה! לא כתוב שבוצע
}
```

### 🔒 עיקרון #2: הפרדת PRESCRIPTION מ-PERFORMANCE

| סוג | מזהים בטקסט | שדה JSON |
|-----|-------------|----------|
| **Prescription** | "3x5", "@RPE 6", "Rest 2min", "Tempo 3-1-2" | `prescription` |
| **Performance** | "עשיתי", "הצלחתי", "כואב", "100 ק", הערות בעברית | `performed` |

### 🔒 עיקרון #3: NULL עדיף על המצאה
```javascript
// אם לא יודעים - NULL
athlete_id: null        // לא מגלים UUID
session_code: null      // לא מניחים "AM"
performed: null         // לא מניחים שבוצע
```

---

## 🔀 פיצול לתת-תהליכים

### Stage 2 מחולק ל-6 תת-שלבים:

```
┌──────────────────────────────────────────────────────────────────┐
│                        STAGE 2: PARSING                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐          │
│  │  2.1    │   │  2.2    │   │  2.3    │   │  2.4    │          │
│  │ Header  │ → │ Block   │ → │ Item    │ → │ Set     │          │
│  │ Extract │   │ Segment │   │ Parse   │   │ Parse   │          │
│  └─────────┘   └─────────┘   └─────────┘   └─────────┘          │
│       ↓             ↓             ↓             ↓                │
│  ┌─────────────────────────────────────────────────────┐        │
│  │              2.5: Notes Classification               │        │
│  │         (prescription vs performance)                │        │
│  └─────────────────────────────────────────────────────┘        │
│                            ↓                                     │
│  ┌─────────────────────────────────────────────────────┐        │
│  │            2.6: Assembly & Validation                │        │
│  └─────────────────────────────────────────────────────┘        │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📝 תהליך פרסור מובנה

### 2.1 Header Extract (חילוץ כותרת)

**קלט:** טקסט גולמי מלא
**פלט:** מטא-דאטה של האימון

```javascript
// PSEUDO-CODE לחילוץ Header
function extractHeader(rawText) {
    const header = {
        workout_date: null,
        athlete_id: null,      // תמיד null! (יגיע מ-Stage 1)
        title: null,
        warmup_objective: null,
        status: null,
        session_code: null     // תמיד null אלא אם כתוב במפורש!
    };
    
    // חיפוש תאריך - רק פורמטים מפורשים
    const datePatterns = [
        /(\d{4}-\d{2}-\d{2})/,                          // 2025-11-09
        /(\w+)\s+(\w+)\s+(\d{1,2}),?\s+(\d{4})/,       // Sunday November 9, 2025
        /(\d{1,2})\/(\d{1,2})\/(\d{2,4})/              // 9/11/2025
    ];
    
    // חיפוש כותרת
    const titleMatch = rawText.match(/Title:\s*(.+)/i);
    if (titleMatch) {
        header.title = titleMatch[1].trim();
        // אל תוסיף תיאורים! "W1 T1" נשאר "W1 T1"
    }
    
    // חיפוש Warmup Objective
    const warmupMatch = rawText.match(/Warmup:\s*(.+)/i);
    if (warmupMatch) {
        header.warmup_objective = warmupMatch[1].trim();
    }
    
    // סטטוס - רק אם כתוב
    if (/status:\s*completed/i.test(rawText)) {
        header.status = "completed";
    }
    
    return header;
}
```

**⚠️ טעויות נפוצות למניעה:**
- ❌ להמציא `athlete_id` (UUID)
- ❌ להניח `session_code: "AM"` 
- ❌ להרחיב כותרת: "W1 T1" → "W1 T1 - Foundation & Control"

---

### 2.2 Block Segmentation (פיצול לבלוקים)

**קלט:** טקסט גולמי
**פלט:** מערך של בלוקים גולמיים

```javascript
// PSEUDO-CODE לזיהוי בלוקים
function segmentBlocks(rawText) {
    const blocks = [];
    
    // זיהוי תבנית בלוק: אות + סוגריים או נקודותיים
    // A) Warm Up:
    // B) Activations:
    // C) Strength Work
    const blockPattern = /^([A-Z])\)\s*(.+?)(?::|$)/gm;
    
    let match;
    let lastIndex = 0;
    
    while ((match = blockPattern.exec(rawText)) !== null) {
        if (blocks.length > 0) {
            // שמור את התוכן של הבלוק הקודם
            blocks[blocks.length - 1].rawContent = 
                rawText.slice(lastIndex, match.index).trim();
        }
        
        blocks.push({
            label: match[1],           // "A", "B", "C"
            title: match[2].trim(),    // "Warm Up", "Activations"
            block_code: null,          // יקבע בשלב הבא
            rawContent: ""
        });
        
        lastIndex = match.index + match[0].length;
    }
    
    // התוכן של הבלוק האחרון
    if (blocks.length > 0) {
        blocks[blocks.length - 1].rawContent = 
            rawText.slice(lastIndex).trim();
    }
    
    return blocks;
}
```

**זיהוי Block Code:**
```javascript
function classifyBlockType(blockTitle) {
    const mappings = {
        // PREPARATION
        'warm up': 'WU', 'warmup': 'WU', 'חימום': 'WU',
        'activation': 'ACT', 'activations': 'ACT', 'הפעלה': 'ACT',
        'mobility': 'MOB', 'ניידות': 'MOB',
        
        // STRENGTH
        'strength': 'STR', 'כוח': 'STR',
        'accessory': 'ACC', 'עזר': 'ACC',
        'hypertrophy': 'HYP',
        
        // CONDITIONING
        'metcon': 'METCON', 'amrap': 'METCON', 'for time': 'METCON',
        'interval': 'INTV', 'intervals': 'INTV',
        'steady state': 'SS',
        
        // SKILL
        'skill': 'SKILL', 'technique': 'SKILL', 'טכניקה': 'SKILL',
        
        // RECOVERY
        'cool down': 'CD', 'cooldown': 'CD',
        'stretch': 'STRETCH', 'מתיחות': 'STRETCH'
    };
    
    const lowerTitle = blockTitle.toLowerCase();
    for (const [key, code] of Object.entries(mappings)) {
        if (lowerTitle.includes(key)) {
            return code;
        }
    }
    
    return 'STR';  // default לכוח אם לא מזוהה
}
```

---

### 2.3 Item Parse (פרסור תרגילים)

**קלט:** תוכן בלוק גולמי
**פלט:** מערך items עם prescription בלבד

```javascript
// PSEUDO-CODE לפרסור תרגילים
function parseItems(blockContent) {
    const items = [];
    const lines = blockContent.split('\n');
    
    let currentItem = null;
    let itemSequence = 1;
    
    for (const line of lines) {
        // זיהוי שורת תרגיל חדש
        // דפוסים: "Back Squat: 3x5", "10 PVC Thoracic", "3x20/20sec Exercise"
        
        const exerciseMatch = parseExerciseLine(line);
        
        if (exerciseMatch) {
            if (currentItem) {
                items.push(currentItem);
            }
            
            currentItem = {
                item_sequence: itemSequence++,
                exercise_name: exerciseMatch.name,
                prescription: exerciseMatch.prescription,
                performed: null  // ברירת מחדל NULL
            };
        }
        // זיהוי הערת prescription (הוראות)
        else if (currentItem && isPrescriptionNote(line)) {
            currentItem.prescription.notes = 
                (currentItem.prescription.notes || '') + line.trim();
        }
        // זיהוי הערת performance (ביצוע)
        else if (currentItem && isPerformanceNote(line)) {
            if (!currentItem.performed) {
                currentItem.performed = {};
            }
            currentItem.performed.notes = 
                (currentItem.performed.notes || '') + line.trim();
        }
    }
    
    if (currentItem) {
        items.push(currentItem);
    }
    
    return items;
}
```

**פרסור שורת תרגיל:**
```javascript
function parseExerciseLine(line) {
    // דפוס 1: "Exercise Name: 3x5 @ 100kg"
    const pattern1 = /^(.+?):\s*(\d+)\s*[xX×]\s*(\d+)\s*(?:@\s*(\d+(?:\.\d+)?)\s*(kg|lb|%)?)?/;
    
    // דפוס 2: "3x10 Exercise Name"
    const pattern2 = /^(\d+)\s*[xX×]\s*(\d+)(?:\/(\d+))?\s*(.+)/;
    
    // דפוס 3: "10 Exercise Name" (רק חזרות)
    const pattern3 = /^(\d+)\s+([A-Za-z].+)/;
    
    // דפוס 4: "Exercise Name" (ללא מספרים - בהמשך יבוא)
    
    let match;
    
    if ((match = line.match(pattern1))) {
        return {
            name: match[1].trim(),
            prescription: {
                target_sets: parseInt(match[2]),
                target_reps: parseInt(match[3]),
                ...(match[4] && { target_load_kg: parseFloat(match[4]) })
            }
        };
    }
    
    if ((match = line.match(pattern2))) {
        const sets = parseInt(match[1]);
        const reps = parseInt(match[2]);
        const repsPerSide = match[3] ? parseInt(match[3]) : null;
        
        return {
            name: match[4].trim(),
            prescription: {
                target_sets: sets,
                target_reps: reps,
                ...(repsPerSide && { target_reps_per_side: repsPerSide })
            }
        };
    }
    
    // המשך דפוסים...
    
    return null;
}
```

---

### 2.4 Set Parse (פרסור סטים בודדים)

**רלוונטי רק כשיש פירוט של סטים בודדים:**

```javascript
// זיהוי פירוט סטים
// "Set 1: 5 reps @ 80kg"
// "Set 2: 5 reps @ 90kg"
function parseIndividualSets(content) {
    const setPattern = /Set\s*(\d+):\s*(\d+)\s*(?:reps?)?\s*(?:@\s*(\d+(?:\.\d+)?)\s*(kg|lb)?)?/gi;
    
    const sets = [];
    let match;
    
    while ((match = setPattern.exec(content)) !== null) {
        sets.push({
            set_index: parseInt(match[1]),
            reps: parseInt(match[2]),
            ...(match[3] && { load_kg: parseFloat(match[3]) })
        });
    }
    
    return sets.length > 0 ? sets : null;
}
```

---

### 2.5 Notes Classification (סיווג הערות)

**זה השלב הכי קריטי!** - לזהות מה הולך ל-prescription ומה ל-performed.

```javascript
// כללי סיווג הערות
const PRESCRIPTION_INDICATORS = [
    // אנגלית
    /^@\s*RPE/i,              // @RPE 6
    /^Rest\s/i,               // Rest 2 min
    /^Tempo/i,                // Tempo 3-1-2
    /^\*\*/,                  // **Rest between
    /build/i,                 // "build to heavy"
    /keep/i,                  // "keep form strict"
    /focus/i,                 // "focus on..."
    
    // סימנים
    /^\*/,                    // * הערת כוכבית
];

const PERFORMANCE_INDICATORS = [
    // עברית (כמעט תמיד performance!)
    /[\u0590-\u05FF]/,        // כל טקסט בעברית
    
    // אנגלית
    /did\s/i,                 // "did 3 sets"
    /got\s/i,                 // "got only 4"
    /felt/i,                  // "felt heavy"
    /pain/i,                  // "pain in shoulder"
    /failed/i,                // "failed last rep"
    /hard/i,                  // "was hard"
    /easy/i,                  // "felt easy"
    /missed/i,                // "missed last rep"
    /used\s*\d/i,             // "used 95kg"
    
    // מספרים בודדים בשורה (ציון משקל בפועל)
    /^\s*\d+\s*ק/,            // "100 ק" (קילו)
    /^\s*\d+\s*kg$/i,         // "100 kg"
];

function classifyNote(line) {
    // עברית = כמעט תמיד performance
    if (/[\u0590-\u05FF]/.test(line)) {
        // חריגים: הוראות בעברית
        if (/נא ל|יש ל|צריך ל/.test(line)) {
            return 'prescription';  // "נא למצוא..." = הוראה
        }
        return 'performance';
    }
    
    // בדיקת indicators
    for (const pattern of PRESCRIPTION_INDICATORS) {
        if (pattern.test(line)) return 'prescription';
    }
    
    for (const pattern of PERFORMANCE_INDICATORS) {
        if (pattern.test(line)) return 'performance';
    }
    
    // ברירת מחדל: prescription (הוראות)
    return 'prescription';
}
```

**דוגמאות מהשטח:**
```
"@ RPE 5.5 to 6"                    → prescription.notes
"Rest 1.5 min"                      → prescription.rest_sec: 90
"Tempo: 3 sec down, 2 sec up"       → prescription.tempo: "3-0-2-0"
"**Rest 30 sec btw exercise"        → prescription.rest_between_exercises_sec: 30

"כתף ימין כואבת בסט הראשון 5/10"    → performed.notes
"10 ק"                              → performed.actual_load_kg: 10
"התחלתי מ 12 ועברתי ל 18"           → performed.notes (או פירוט סטים)
"נתפס לי מתחת לשכמה"                → performed.notes
```

---

### 2.6 Assembly & Validation (הרכבה ואימות)

```javascript
function assembleWorkout(header, blocks) {
    const workout = {
        ...header,
        sessions: [{
            session_code: null,  // לא להמציא!
            blocks: blocks.map(block => ({
                block_code: block.block_code,
                block_label: block.label,
                block_title: block.title,
                prescription: block.prescription || {},
                performed: block.performed || null,
                items: block.items
            }))
        }]
    };
    
    // VALIDATION PASS
    validateNoHallucinations(workout);
    
    return workout;
}

function validateNoHallucinations(workout) {
    const errors = [];
    
    // בדיקה 1: אין athlete_id מומצא
    if (workout.athlete_id && workout.athlete_id.match(/^[0-9a-f-]{36}$/i)) {
        errors.push("HALLUCINATION: athlete_id UUID detected - should be null");
    }
    
    // בדיקה 2: אין session_code מומצא
    if (workout.sessions[0].session_code === "AM" || 
        workout.sessions[0].session_code === "PM") {
        errors.push("HALLUCINATION: session_code detected without explicit source");
    }
    
    // בדיקה 3: כל performed חייב להיות מבוסס על טקסט מקור
    // (יבדק בשלב validation מול טקסט המקור)
    
    return errors;
}
```

---

## 🏆 כללי זהב

### 1. כלל ה-NULL
```
אם לא כתוב במפורש → null
אין הנחות, אין השלמות, אין "הגיוני ש..."
```

### 2. כלל העברית
```
טקסט בעברית = כמעט תמיד הערת ביצוע (performance)
חריגים: "נא ל...", "יש ל...", "צריך ל..." = הוראות
```

### 3. כלל הסטים
```
"3x5" ללא פירוט נוסף = prescription בלבד
performed = null (לא יודעים מה קרה בפועל)

"3x5, עשיתי" = prescription + performed
"3x5, סט אחרון רק 4" = prescription + performed עם פירוט
```

### 4. כלל המספר הבודד
```
"10 ק" / "100kg" בשורה נפרדת = performed.actual_load_kg
זה המשקל שהאתלט באמת עשה
```

### 5. כלל ה-Title
```
Title = בדיוק מה שכתוב
"W1 T1" → "W1 T1"
לא: "W1 T1 - Foundation & Control" (הרחבה אסורה)
```

### 6. כלל הטווחים (חדש!) ⚠️
```
טווח מספרים = תמיד min/max, לא string ולא ממוצע!

"4-5kg"     → target_weight_kg_min: 4, target_weight_kg_max: 5
"RPE 5.5-6" → target_rpe_min: 5.5, target_rpe_max: 6  
"22-24 spm" → target_spm_min: 22, target_spm_max: 24

❌ שגוי: target_weight_kg: "4-5"  (string)
❌ שגוי: target_weight_kg: 4.5    (ממוצע)
❌ שגוי: target_rpe: 5.75         (ממוצע של 5.5-6)
```

---

## 📊 דפוסי טקסט נפוצים

### דפוס 0: Exercise Options (אופציות תרגיל) ⚠️ חשוב!
```
כאשר יש "/" בשם תרגיל עם אפשרות בחירה:

🔴 מבנה חדש (סקיילבילי) - החל מ-10/01/2026:

Input:  "5 min Bike / Row @ 22-24 spm @ D 5-6"
Output: {
  "exercise_options": [
    {
      "exercise_name": "Bike",
      "prescription": { "target_duration_min": 5 }
    },
    {
      "exercise_name": "Row",
      "prescription": {
        "target_duration_min": 5,
        "target_spm_min": 22,
        "target_spm_max": 24,
        "target_damper_min": 5,
        "target_damper_max": 6
      }
    }
  ]
}

Input:  "Walk / light Jog"
Output: {
  "exercise_options": [
    {
      "exercise_name": "Walk",
      "prescription": { "target_duration_min": 5 }
    },
    {
      "exercise_name": "Light Jog",
      "prescription": { "target_duration_min": 5 }
    }
  ]
}

✅ יתרונות המבנה החדש:
- סקיילבילי: אפשר להוסיף כמה תרגילים שרוצים
- כל תרגיל עם prescription מלא משלו
- אין צורך ב-prescription_if_X לכל תרגיל
- ברור יותר למודל AI

⚠️ שים לב:
- stroke_rate, damper, spm = רלוונטי רק ל-Row!
- לא כל "/" זה אופציה: "90/90" זה שם תרגיל, לא אופציה
- אם prescription זהה לכולם, עדיין חזור על זה בכל exercise
```

### דפוס 1: Sets × Reps
```
Input:  "Back Squat: 3x5 @ 100kg"
Output: { target_sets: 3, target_reps: 5, target_load_kg: 100 }
```

### דפוס 2: Sets × Reps/Side (ימין/שמאל)
```
Input:  "8/8 Lateral Raises"
Output: { target_reps: 16, target_reps_per_side: 8 }

Input:  "3x10/10 Banded Pulldown"
Output: { target_sets: 3, target_reps: 20, target_reps_per_side: 10 }
```

### דפוס 2.5: Reps Forward/Backward (קדימה/אחורה)
```
Input:  "8/8 Scapular CARs (8 forward / 8 backward)"
Output: { 
    target_reps: 16,
    target_reps_forward: 8, 
    target_reps_backward: 8 
}

⚠️ שים לב: סה"כ חזרות = forward + backward
```

### דפוס 3: Duration
```
Input:  "5 min Bike"
Output: { target_duration_min: 5 }

Input:  "3x20/20sec Isometric Hold"
Output: { target_sets: 3, target_duration_sec: 20, target_sets_per_side: true }
```

### דפוס 4: Circuits (Rounds + Multiple Exercises)
```
🔴 מבנה חדש (סקיילבילי) - החל מ-10/01/2026:

Input:  "3 Quality Rounds: 10 PVC Rotation, 16 Scapular CARs, 8 DB Punch"
Output: {
  "circuit_config": {
    "rounds": 3,
    "type": "for_quality",
    "rest_between_rounds_sec": 0
  },
  "exercises": [
    {
      "exercise_name": "PVC Thoracic Rotation",
      "prescription": { "target_reps": 10 }
    },
    {
      "exercise_name": "Scapular CARs",
      "prescription": { "target_reps": 16 }
    },
    {
      "exercise_name": "DB Supine Serratus Punch",
      "prescription": { "target_reps": 8 }
    }
  ]
}

✅ יתרונות המבנה החדש:
- ברור מאוד שזה circuit (לא items נפרדים)
- circuit_config מכיל metadata: rounds, type, rest
- exercises array - כל תרגיל עם prescription משלו (בלי target_rounds!)
- סקיילבילי: אפשר circuits מקוננים בעתיד

⚠️ חשוב:
- ❌ אין target_rounds בתוך prescription של exercise!
- ✅ target_rounds רק ב-circuit_config
- type יכול להיות: "for_quality", "for_time", "amrap"
```

### דפוס 5: RPE/Intensity
```
Input:  "@ RPE 5.5 to 6"
Output: { target_rpe_min: 5.5, target_rpe_max: 6 }

Input:  "@ 70% 1RM"
Output: { target_intensity_percent: 70, target_intensity_reference: "1RM" }
```

### דפוס 6: Tempo
```
Input:  "Tempo: 3 sec down, 2 sec up"
Output: { target_tempo: "3-0-2-0" }  // eccentric-pause-concentric-pause
```

### דפוס 7: Rest
```
Input:  "Rest 1.5 min"
Output: { target_rest_sec: 90 }

Input:  "**Rest 30 sec btw exercise"
Output: { rest_between_exercises_sec: 30 }
```

### דפוס 8: Ranges (טווחים) ⚠️ חשוב!
```
❌ שגוי:
Input:  "@ 22-24 spm"
Output: { target_spm: "22-24" }     // string - שגוי!
Output: { target_spm: 23 }          // ממוצע - שגוי!

✅ נכון:
Input:  "@ 22-24 spm"
Output: { target_spm_min: 22, target_spm_max: 24 }

Input:  "light 4-5kg"
Output: { target_weight_kg_min: 4, target_weight_kg_max: 5 }

Input:  "@ D 5-6"  (damper)
Output: { target_damper_min: 5, target_damper_max: 6 }
```

### דפוס 9: Hebrew Performance Note
```
Input:  "כתף ימין כואבת בסט הראשון 5/10"
Output: performed.notes: "כתף ימין כואבת בסט הראשון 5/10"
        performed.pain_level: 5 (optional parsing)
```

---

## ✅ בקרת איכות

### Checklist לפני Output:

```markdown
□ athlete_id = null (לא UUID מומצא)
□ session_code = null (אלא אם כתוב "AM"/"PM" במפורש)
□ כל performed מבוסס על טקסט מקור (לא הנחות)
□ טקסט בעברית → performed.notes
□ כותרת = בדיוק כמו במקור (לא הרחבה)
□ item_sequence רץ מ-1 בכל בלוק
□ exercise_name (לא exercise_key)
□ prescription לא ריק אם יש הוראות
□ performed = null אם אין מידע על ביצוע
```

### Self-Validation Query:
```javascript
// לרוץ על כל JSON לפני output
function selfValidate(json, sourceText) {
    const issues = [];
    
    // 1. No hallucinated UUIDs
    const uuidPattern = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi;
    if (JSON.stringify(json).match(uuidPattern)) {
        issues.push("CRITICAL: UUID found - likely hallucination");
    }
    
    // 2. No assumed session_code
    if (json.sessions?.[0]?.session_code && 
        !sourceText.match(/\b(AM|PM|morning|afternoon|evening)\b/i)) {
        issues.push("CRITICAL: session_code without source evidence");
    }
    
    // 3. All numbers should exist in source
    const jsonNumbers = JSON.stringify(json).match(/\d+/g) || [];
    for (const num of jsonNumbers) {
        if (parseInt(num) > 10 && !sourceText.includes(num)) {
            issues.push(`WARNING: Number ${num} not found in source`);
        }
    }
    
    return issues;
}
```

---

## 🛠️ כלי עזר ושפת קוד

### Regex Patterns Library:

```javascript
const PATTERNS = {
    // תאריכים
    DATE_ISO: /(\d{4}-\d{2}-\d{2})/,
    DATE_HUMAN: /(\w+)\s+(\w+)\s+(\d{1,2}),?\s+(\d{4})/,
    
    // סטים וחזרות
    SETS_REPS: /(\d+)\s*[xX×]\s*(\d+)/,
    SETS_REPS_LOAD: /(\d+)\s*[xX×]\s*(\d+)\s*@\s*(\d+(?:\.\d+)?)\s*(kg|lb|%)?/,
    REPS_PER_SIDE: /(\d+)\/(\d+)/,
    
    // זמן
    DURATION_MIN: /(\d+(?:\.\d+)?)\s*min/i,
    DURATION_SEC: /(\d+)\s*sec/i,
    REST_TIME: /rest\s*(\d+(?:\.\d+)?)\s*(min|sec)?/i,
    
    // עצימות
    RPE: /@?\s*RPE\s*(\d+(?:\.\d+)?)/i,
    RPE_RANGE: /@?\s*RPE\s*(\d+(?:\.\d+)?)\s*(?:to|-)\s*(\d+(?:\.\d+)?)/i,
    PERCENTAGE: /@?\s*(\d+)%/,
    
    // טמפו
    TEMPO: /tempo[:\s]*(\d+)[\s-]*(\d+)?[\s-]*(\d+)?[\s-]*(\d+)?/i,
    
    // בלוקים
    BLOCK_HEADER: /^([A-Z])\)\s*(.+?)(?::|$)/gm,
    
    // עברית
    HEBREW_TEXT: /[\u0590-\u05FF]+/,
    HEBREW_WEIGHT: /(\d+)\s*ק/,
    
    // הערות
    INSTRUCTION_NOTE: /^\*+/,
    PAIN_SCALE: /(\d+)\/10/,
};
```

### Helper Functions:

```javascript
// המרת טקסט לדקות
function parseToMinutes(text) {
    const minMatch = text.match(/(\d+(?:\.\d+)?)\s*min/i);
    if (minMatch) return parseFloat(minMatch[1]);
    
    const secMatch = text.match(/(\d+)\s*sec/i);
    if (secMatch) return parseInt(secMatch[1]) / 60;
    
    return null;
}

// המרת טקסט לשניות
function parseToSeconds(text) {
    const secMatch = text.match(/(\d+)\s*sec/i);
    if (secMatch) return parseInt(secMatch[1]);
    
    const minMatch = text.match(/(\d+(?:\.\d+)?)\s*min/i);
    if (minMatch) return parseFloat(minMatch[1]) * 60;
    
    return null;
}

// נרמול שם תרגיל
function normalizeExerciseName(name) {
    return name
        .trim()
        .split(/\s+/)
        .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
        .join(' ');
}

// זיהוי אם שורה מכילה תרגיל חדש
function isNewExerciseLine(line) {
    // מתחיל במספר + שם
    if (/^\d+\s+[A-Za-z]/.test(line)) return true;
    // מתחיל בשם + נקודותיים
    if (/^[A-Za-z][^:]+:\s*\d/.test(line)) return true;
    // מתחיל ב-sets x reps
    if (/^\d+\s*[xX×]\s*\d+/.test(line)) return true;
    
    return false;
}
```

---

## 📋 סיכום - תרשים זרימה מלא

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          RAW TEXT INPUT                                  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  2.1 HEADER EXTRACT                                                      │
│  ─────────────────                                                       │
│  • Extract: date, title, status, warmup_objective                        │
│  • Set null: athlete_id, session_code                                    │
│  • NO inference, NO enhancement                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  2.2 BLOCK SEGMENTATION                                                  │
│  ─────────────────────                                                   │
│  • Split by "A)", "B)", "C)" pattern                                     │
│  • Classify block_code (WU/ACT/STR/METCON/etc.)                         │
│  • Preserve raw content per block                                        │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  2.3 ITEM PARSE (per block)                                              │
│  ─────────────────────────                                               │
│  • Identify exercise lines                                               │
│  • Parse: sets, reps, load, duration, tempo, RPE                        │
│  • Create prescription object                                            │
│  • performed = null (default)                                            │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  2.4 SET PARSE (if detailed sets exist)                                  │
│  ─────────────────────────────────────                                   │
│  • "Set 1: 5 @ 80kg" → individual set results                           │
│  • Only if EXPLICITLY listed                                             │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  2.5 NOTES CLASSIFICATION                                                │
│  ───────────────────────                                                 │
│  • Hebrew text → performed.notes (almost always)                         │
│  • @RPE, Rest, Tempo, ** → prescription                                  │
│  • "10 ק", pain notes, feelings → performed                              │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  2.6 ASSEMBLY & VALIDATION                                               │
│  ─────────────────────────                                               │
│  • Build final JSON structure                                            │
│  • Run self-validation checks                                            │
│  • Ensure NO hallucinations                                              │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         STRUCTURED JSON OUTPUT                           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 המלצות ליישום

### Phase 1: בניית Test Suite
1. לקחת 5 דוגמאות מה-Golden Set
2. לכתוב unit tests לכל תת-שלב
3. לוודא שה-output תואם את ה-Golden JSON

### Phase 2: פיתוח Regex Library
1. לבנות ספריית patterns מוכחת
2. לתעד כל pattern עם דוגמאות
3. להוסיף edge cases

### Phase 3: Notes Classifier
1. לבנות מודל סיווג (rules-based)
2. לאמן על הדוגמאות הקיימות
3. להוסיף confidence score

### Phase 4: Self-Validation
1. לבנות מערכת אימות עצמי
2. לדגל כל חשד להזיה
3. לייצר דוח שגיאות

---

**מסמך זה מהווה את המדריך המלא לשלב 2 - הלב של מערכת הפרסור.**

**Last Updated:** January 9, 2026  
**Version:** 1.0.0  
**Author:** Parser Strategy Team
