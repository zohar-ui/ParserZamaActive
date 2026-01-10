# 🔄 Schema Updates - January 10, 2026

## סיכום שינויים במבנה JSON של Golden Set

**תאריך:** 10 ינואר 2026  
**גרסה:** v2.0.0  
**סטטוס:** ✅ יושם בכל ה-golden set

---

## 🎯 מדוע השינוי?

המבנה הקודם **לא היה סקיילבילי**:
- `prescription_if_row` → מה אם יש 5 אופציות? צריך 5 if statements?
- items מרובים עם `target_rounds: 3` → לא ברור שזה circuit!

---

## 1️⃣ Exercise Options - מבנה חדש

### ❌ מבנה ישן (לא סקיילבילי)
```json
{
  "exercise_options": ["Bike", "Row"],
  "prescription": {
    "target_duration_min": 5
  },
  "prescription_if_row": {
    "target_stroke_rate_min": 22,
    "target_stroke_rate_max": 24,
    "target_damper_min": 5,
    "target_damper_max": 6
  }
}
```

**בעיות:**
- לא סקיילבילי - צריך `prescription_if_X` לכל תרגיל
- מבלבל - prescription משותף או ספציפי?
- קשה להוסיף תרגיל שלישי

### ✅ מבנה חדש (סקיילבילי)
```json
{
  "exercise_options": [
    {
      "exercise_name": "Bike",
      "prescription": {
        "target_duration_min": 5
      }
    },
    {
      "exercise_name": "Row",
      "prescription": {
        "target_duration_min": 5,
        "target_stroke_rate_min": 22,
        "target_stroke_rate_max": 24,
        "target_damper_min": 5,
        "target_damper_max": 6
      }
    }
  ]
}
```

**יתרונות:**
- ✅ כל תרגיל עם prescription מלא משלו
- ✅ ברור וקל לקריאה
- ✅ אפשר להוסיף 10 תרגילים בקלות
- ✅ אין חזרה על prescription אם זהה (זה מכוון!)

---

## 2️⃣ Circuits - מבנה חדש

### ❌ מבנה ישן (מבלבל)
```json
{
  "items": [
    {
      "item_sequence": 2,
      "exercise_name": "PVC Thoracic Rotation",
      "prescription": {
        "target_rounds": 3,
        "target_reps": 10
      }
    },
    {
      "item_sequence": 3,
      "exercise_name": "Scapular Cars",
      "prescription": {
        "target_rounds": 3,
        "target_reps": 16
      }
    },
    {
      "item_sequence": 4,
      "exercise_name": "Db Supine Serratus Punch",
      "prescription": {
        "target_rounds": 3,
        "target_reps": 8
      }
    }
  ]
}
```

**בעיות:**
- לא ברור שזה circuit! נראה כמו 3 items נפרדים
- `target_rounds: 3` חוזר 3 פעמים (DRY violation)
- מודל AI יכול לטעות ולחשוב שזה 9 rounds (3×3)

### ✅ מבנה חדש (ברור)
```json
{
  "items": [
    {
      "item_sequence": 2,
      "circuit_config": {
        "rounds": 3,
        "type": "for_quality",
        "rest_between_rounds_sec": 0
      },
      "exercises": [
        {
          "exercise_name": "PVC Thoracic Rotation",
          "prescription": {
            "target_reps": 10
          }
        },
        {
          "exercise_name": "Scapular Cars",
          "prescription": {
            "target_reps": 16
          }
        },
        {
          "exercise_name": "Db Supine Serratus Punch",
          "prescription": {
            "target_reps": 8
          }
        }
      ]
    }
  ]
}
```

**יתרונות:**
- ✅ **ברור מאוד** שזה circuit של 3 rounds
- ✅ `circuit_config` מכיל metadata (rounds, type, rest)
- ✅ `exercises` array - כל תרגיל עם prescription נקי
- ✅ אין target_rounds בתוך exercise prescription!
- ✅ סקיילבילי - אפשר circuits מקוננים בעתיד

---

## 🔍 חוקים קריטיים

### Rule #1: target_rounds חוקי רק ב-2 מקומות

✅ **חוקי:**
1. **ברמת block prescription** (METCON: AMRAP/For Time/Rounds)
   ```json
   {
     "block_code": "INTV",
     "prescription": {
       "target_rounds": 5  // ✅ OK - זה block-level
     }
   }
   ```

2. **בתוך circuit_config**
   ```json
   {
     "circuit_config": {
       "rounds": 3  // ✅ OK - זה circuit metadata
     }
   }
   ```

❌ **אסור:**
```json
{
  "exercise_name": "Air Squats",
  "prescription": {
    "target_rounds": 3  // ❌ WRONG! אסור ב-item prescription
  }
}
```

### Rule #2: exercise_options = Array of Objects

❌ **אסור:**
```json
"exercise_options": ["Bike", "Row"]  // ❌ WRONG! לא סקיילבילי
```

✅ **נכון:**
```json
"exercise_options": [
  { "exercise_name": "Bike", "prescription": {...} },
  { "exercise_name": "Row", "prescription": {...} }
]  // ✅ OK - סקיילבילי
```

---

## 📊 קבצים שעודכנו

### Exercise Options (4 קבצים):
- ✅ `arnon_2025-11-09_foundation_control.json` (2 locations)
- ✅ `arnon_2025-11-09_shoulder_rehab.json`
- ✅ `bader_2025-09-07_running_intervals.json`
- ✅ `simple_2025-09-08_recovery.json`

### Circuits (11 קבצים):
- ✅ `arnon_2025-11-09_foundation_control.json`
- ✅ `arnon_2025-11-09_shoulder_rehab.json`
- ✅ `itamar_2025-06-21_rowing_skill.json`
- ✅ `jonathan_2025-08-17_lower_body_fortime.json`
- ✅ `jonathan_2025-08-17_lower_fortime.json`
- ✅ `jonathan_2025-08-19_upper_amrap.json`
- ✅ `jonathan_2025-08-24_lower_body_amrap.json`
- ✅ `orel_2025-06-01_hebrew_amrap.json`
- ✅ `orel_2025-06-01_amrap_hebrew_notes.json`
- ✅ `yarden_2025-08-24_deadlift_strength.json`
- ✅ `yarden_frank_2025-07-06_mixed_blocks.json`
- ✅ `yehuda_2025-05-28_upper_screen.json`

**סה"כ:** 12 קבצים ייחודיים עודכנו

---

## 🚀 השפעה על Stage 3 Validation

הפונקציות הבאות צריכות לתמוך במבנה החדש:

1. **validate_parsed_structure()** - לוודא circuit_config structure
2. **validate_prescription_performance_separation()** - לבדוק exercises בתוך circuits
3. **validate_catalog_references()** - לעבור על exercise_options החדש

---

## 📝 הנחיות למודלי AI (Stage 2 Parsing)

כאשר פורס workout עם circuits או exercise options:

### Warmup Circuits:
```
Input: "3 rounds: 10 PVC Rotation, 16 Scapular CARs"

Output structure:
{
  "item_sequence": 1,
  "circuit_config": {
    "rounds": 3,
    "type": "for_quality",
    "rest_between_rounds_sec": 0
  },
  "exercises": [
    { "exercise_name": "...", "prescription": {...} }
  ]
}
```

### Exercise Options:
```
Input: "5 min Bike/Row @ 22-24 spm"

Output structure:
{
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
        "target_spm_max": 24
      }
    }
  ]
}
```

---

## ✅ Validation Checklist

בעת בדיקת JSON חדש:

- [ ] אין `prescription_if_*` בשום מקום
- [ ] אין `target_rounds` בתוך item prescription
- [ ] כל circuit יש לו `circuit_config` + `exercises`
- [ ] כל exercise_options הוא array של objects
- [ ] כל object ב-exercise_options יש לו `exercise_name` + `prescription`

---

**Last Updated:** January 10, 2026  
**Maintained By:** Parser Development Team  
**Version:** 2.0.0
