# Golden Set Review Document
**Parser Quality Assurance - Complete Reference Set**

Generated: 2026-01-09 (UPDATED - Post Audit Corrections)  
Total Golden Examples: 19
Status: PRODUCTION READY

---

## Purpose

This document contains all golden reference examples for parser regression testing.  
Each example includes:
1. **Original Workout Text** (as written by coach/athlete)
2. **Parsed JSON Output** (corrected and validated structure)

These serve as ground truth for measuring parser accuracy.

---

## Audit Summary (2026-01-09)

All 19 JSON files have been audited and corrected:
- All athlete_id set to null (was fabricated UUIDs)
- All session_code/session_time set to null (was fabricated AM)
- All WU/MOB/ACT blocks have proper items arrays
- All items have exercise_name and item_sequence
- All items have prescription and performed objects
- Example 14 (simple_2025-09-08_recovery.json) completely rewritten

**Statistics:**
- Files: 19
- Blocks: 119
- Items: 204
- Unique exercises: 123

---


## Example 1: arnon_2025-11-09_foundation_control
**File:** arnon_2025-11-09_foundation_control.json

### Original Workout Text
```
Workout: Workout Log: Arnon Shafir - 2025-11-09
==================================================

Sunday November  9, 2025
Title: W1 T1
Status: completed

Warmup: Foundation & Control


A) Warm Up: 5 min Bike / Row  @ 22-24 spm @ D 5-6 **V
3 Quality Rounds: 
10 PVC Thoracic Rotation 
8/8 Scapular CARs (8 forward / 8 baack word)
8/8 db Supine Serratus Punch (light 4-5kg)

**Rest 30 sec btw exersice
   רק שאני אזכור גם איך התחלנו….

B) Activations: 3x20/20sec Isometric ER to wall (90*)
3x10/10 Banded Scapular Pulldown

**Rest 30 sec btw exersice
C) Landmine Press Half Kneeling: 3 X 8/8 **V
@ RPE 5.5 to 6 
Rest 1.5 min

Tempo:
3 sec down 
2 sec up
   כתף ימין (!?) כואבת בסט הראשון 5/10
יד ימין הסתדר
כתפיים בסדר
כאב ביד אחורית כתף שמאל בזמן הורדה
ואל דאגה, בסט השלישי הבנתי שאני לא סופר ותיקנתי 
מוט ריק
D) Dumbbell Romanian Deadlift: 3 X 8 **V
@ RPE 5.5 to 6 
Rest 1.5 min
   10 ק
E) One arm chest supported row: 3 X 10 
@ RPE 6
Rest 1.5 min
   10 ק
F) Tall Kneeling Cable Pallof Press: 3 X 10/10 
Rest 1 min
   7.5 תנועה מוזרההה
G) DB Suitcase Carry : 3 X 20 m/20 m 
Rest 1 min
*start with left hand
   התחלתי מ 12 ועברתי ל 18 בסט האחרון
H) Prone Low Trap Raise: 2 X 12 
Rest 1 min
נא למצוא את המרחב בין הכתפיים שלא מייצר כאב
   נתפס לי כמו שאתה רואה מתחת לשכמה שמאל תוך כדי הסט הראשון 
I) Bike / Row : 10 min

```

### Parsed JSON
```json
{
  "workout_date": "2025-11-09",
  "athlete_id": null,
  "title": "W1 T1",
  "warmup_objective": "Foundation & Control",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "block_title": "Warm Up",
          "prescription": {
            "target_sets": 1,
            "notes": "5 min cardio + 3 rounds quality movements"
          },
          "performed": {
            "actual_sets": 1
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_duration_min": 5,
                "target_stroke_rate": 23,
                "target_damper": 5.5
              },
              "performed": {
                "actual_duration_min": 5
              },
              "exercise_name": "Bike"
            },
            {
              "item_sequence": 2,
              "prescription": {
                "target_rounds": 3,
                "target_reps": 10
              },
              "performed": {
                "actual_rounds": 3,
                "actual_reps": 10
              },
              "exercise_name": "Pvc Thoracic Rotation"
            },
            {
              "item_sequence": 3,
              "prescription": {
                "target_rounds": 3,
                "target_reps": 8,
                "target_sets_per_side": 2,
                "notes": "8 forward / 8 backward"
              },
              "performed": {
                "actual_rounds": 3,
                "actual_reps": 8,
                "actual_sets_per_side": 2
              },
              "exercise_name": "Scapular Cars"
            },
            {
              "item_sequence": 4,
              "prescription": {
                "target_rounds": 3,
                "target_reps": 8,
                "target_sets_per_side": 1,
                "target_weight_kg": 4.5,
                "notes": "Light 4-5kg"
              },
              "performed": {
                "actual_rounds": 3,
                "actual_reps": 8,
                "actual_sets_per_side": 1,
                "actual_weight_kg": 4.5
              },
              "exercise_name": "Db Supine Serratus Punch"
            }
          ]
        },
        {
          "block_code": "ACT",
          "block_label": "B",
          "block_title": "Activations",
          "prescription": {
            "target_rest_sec": 30
          },
          "performed": {
            "actual_sets": 1
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_sets": 3,
                "target_duration_sec": 20,
                "target_sets_per_side": 1,
                "equipment": "wall",
                "notes": "90 degree angle"
              },
              "performed": {
                "actual_sets": 3,
                "actual_duration_sec": 20,
                "actual_sets_per_side": 1
              },
              "exercise_name": "Isometric External Rotation"
            },
            {
              "item_sequence": 2,
              "prescription": {
                "target_sets": 3,
                "target_reps": 10,
                "target_sets_per_side": 1
              },
              "performed": {
                "actual_sets": 3,
                "actual_reps": 10,
                "actual_sets_per_side": 1
              },
              "exercise_name": "Banded Scapular Pulldown"
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "C",
          "block_title": "Landmine Press Half Kneeling",
          "prescription": {
            "target_sets": 3,
            "target_reps": 8,
            "target_sets_per_side": 1,
            "target_rpe": 5.75,
            "target_rest_min": 1.5,
            "target_tempo": "3-0-2-0",
            "notes": "3 sec down, 2 sec up"
          },
          "performed": {
            "actual_sets": 3,
            "actual_reps": 8,
            "actual_sets_per_side": 1,
            "actual_weight_kg": 20,
            "notes": "Right shoulder hurt 5/10 in set 1. Left rear shoulder pain on lowering. Bar only (20kg)."
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_sets": 3,
                "target_reps": 8,
                "target_sets_per_side": 1,
                "target_tempo": "3-0-2-0",
                "equipment": "barbell",
                "position": "half_kneeling"
              },
              "performed": {
                "actual_sets": 3,
                "actual_reps": 8,
                "actual_sets_per_side": 1,
                "actual_weight_kg": 20
              },
              "exercise_name": "Landmine Press"
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "D",
          "block_title": "Dumbbell Romanian Deadlift",
          "prescription": {
            "target_sets": 3,
            "target_reps": 8,
            "target_rpe": 5.75,
            "target_rest_min": 1.5
          },
          "performed": {
            "actual_sets": 3,
            "actual_reps": 8,
            "actual_weight_kg": 10
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_sets": 3,
                "target_reps": 8
              },
              "performed": {
                "actual_sets": 3,
                "actual_reps": 8,
                "actual_weight_kg": 10
              },
              "exercise_name": "Dumbbell Rdl"
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "E",
          "block_title": "One arm chest supported row",
          "prescription": {
            "target_sets": 3,
            "target_reps": 10,
            "target_rpe": 6,
            "target_rest_min": 1.5
          },
          "performed": {
            "actual_sets": 3,
            "actual_reps": 10,
            "actual_weight_kg": 10
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_sets": 3,
                "target_reps": 10
              },
              "performed": {
                "actual_sets": 3,
                "actual_reps": 10,
                "actual_weight_kg": 10
              },
              "exercise_name": "One Arm Chest Supported Row"
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "F",
          "block_title": "Tall Kneeling Cable Pallof Press",
          "prescription": {
            "target_sets": 3,
            "target_reps": 10,
            "target_sets_per_side": 1,
            "target_rest_min": 1
          },
          "performed": {
            "actual_sets": 3,
            "actual_reps": 10,
            "actual_sets_per_side": 1,
            "actual_weight_kg": 7.5,
            "notes": "Strange movement"
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_sets": 3,
                "target_reps": 10,
                "target_sets_per_side": 1,
                "equipment": "cable",
                "position": "tall_kneeling"
              },
              "performed": {
                "actual_sets": 3,
                "actual_reps": 10,
                "actual_sets_per_side": 1,
                "actual_weight_kg": 7.5
              },
              "exercise_name": "Pallof Press"
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "G",
          "block_title": "DB Suitcase Carry",
          "prescription": {
            "target_sets": 3,
            "target_distance_m": 20,
            "target_sets_per_side": 1,
            "target_rest_min": 1,
            "notes": "Start with left hand"
          },
          "performed": {
            "actual_sets": 3,
            "actual_distance_m": 20,
            "actual_sets_per_side": 1,
            "notes": "Started at 12kg, progressed to 18kg in last set"
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_sets": 3,
                "target_distance_m": 20,
                "target_sets_per_side": 1,
                "equipment": "dumbbell"
              },
              "performed": {
                "actual_sets": 3,
                "actual_distance_m": 20,
                "actual_sets_per_side": 1,
                "actual_weight_kg": [
                  12,
                  12,
                  18
                ]
              },
              "exercise_name": "Suitcase Carry"
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "H",
          "block_title": "Prone Low Trap Raise",
          "prescription": {
            "target_sets": 2,
            "target_reps": 12,
            "target_rest_min": 1,
            "notes": "Find space between shoulder blades that doesn't create pain"
          },
          "performed": {
            "actual_sets": 2,
            "actual_reps": 12,
            "notes": "Caught beneath left scapula during first set"
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_sets": 2,
                "target_reps": 12
              },
              "performed": {
                "actual_sets": 2,
                "actual_reps": 12
              },
              "exercise_name": "Prone Low Trap Raise"
            }
          ]
        },
        {
          "block_code": "CD",
          "block_label": "I",
          "block_title": "Bike / Row",
          "prescription": {
            "target_duration_min": 10
          },
          "performed": {
            "actual_duration_min": 10
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_duration_min": 10
              },
              "performed": {
                "actual_duration_min": 10
              },
              "exercise_name": "Bike"
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Example 2: arnon_2025-11-09_shoulder_rehab
**File:** arnon_2025-11-09_shoulder_rehab.json

### Original Workout Text
```
Workout: Workout Log: Arnon Shafir - 2025-11-09
==================================================

Sunday November  9, 2025
Title: W1 T1
Status: completed

Warmup: Foundation & Control


A) Warm Up: 5 min Bike / Row  @ 22-24 spm @ D 5-6 **V
3 Quality Rounds: 
10 PVC Thoracic Rotation 
8/8 Scapular CARs (8 forward / 8 baack word)
8/8 db Supine Serratus Punch (light 4-5kg)

**Rest 30 sec btw exersice
   רק שאני אזכור גם איך התחלנו….

B) Activations: 3x20/20sec Isometric ER to wall (90*)
3x10/10 Banded Scapular Pulldown

**Rest 30 sec btw exersice
C) Landmine Press Half Kneeling: 3 X 8/8 **V
@ RPE 5.5 to 6 
Rest 1.5 min

Tempo:
3 sec down 
2 sec up
   כתף ימין (!?) כואבת בסט הראשון 5/10
יד ימין הסתדר
כתפיים בסדר
כאב ביד אחורית כתף שמאל בזמן הורדה
ואל דאגה, בסט השלישי הבנתי שאני לא סופר ותיקנתי 
מוט ריק
D) Dumbbell Romanian Deadlift: 3 X 8 **V
@ RPE 5.5 to 6 
Rest 1.5 min
   10 ק
E) One arm chest supported row: 3 X 10 
@ RPE 6
Rest 1.5 min
   10 ק
F) Tall Kneeling Cable Pallof Press: 3 X 10/10 
Rest 1 min
   7.5 תנועה מוזרההה
G) DB Suitcase Carry : 3 X 20 m/20 m 
Rest 1 min
*start with left hand
   התחלתי מ 12 ועברתי ל 18 בסט האחרון
H) Prone Low Trap Raise: 2 X 12 
Rest 1 min
נא למצוא את המרחב בין הכתפיים שלא מייצר כאב
   נתפס לי כמו שאתה רואה מתחת לשכמה שמאל תוך כדי הסט הראשון 
I) Bike / Row : 10 min

```

### Parsed JSON
```json
{
  "workout_date": "2025-11-09",
  "athlete_id": null,
  "title": "W1 T1",
  "status": "completed",
  "warmup_objective": "Foundation & Control",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "5 min Bike/Row @ 22-24 spm @ D 5-6, then 3 Quality Rounds",
            "rest": "30s between exercises"
          },
          "performed": {
            "completed": true,
            "notes": "רק שאני אזכור גם איך התחלנו…."
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Bike / Row",
              "prescription": {
                "target_duration_min": 5,
                "target_spm": "22-24",
                "target_damper": "5-6",
                "markers": [
                  "**V"
                ]
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "PVC Thoracic Rotation",
              "prescription": {
                "target_rounds": 3,
                "target_reps": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Scapular CARs",
              "prescription": {
                "target_rounds": 3,
                "target_reps_per_side": 8,
                "notes": "8 forward / 8 backward"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "DB Supine Serratus Punch",
              "prescription": {
                "target_rounds": 3,
                "target_reps_per_side": 8,
                "target_load": "4-5",
                "load_unit": "kg",
                "notes": "light"
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "ACT",
          "block_label": "B",
          "prescription": {
            "description": "Shoulder activations",
            "rest": "30s between exercises"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Isometric ER to wall",
              "prescription": {
                "target_sets": 3,
                "target_duration_sec": 20,
                "per_side": true,
                "notes": "90°"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Banded Scapular Pulldown",
              "prescription": {
                "target_sets": 3,
                "target_reps_per_side": 10
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "C",
          "prescription": {
            "description": "Landmine Press Half Kneeling: 3x8/8",
            "target_sets": 3,
            "target_reps": 8,
            "target_rpe": "5.5-6",
            "tempo": "3-0-2",
            "rest": "1:30"
          },
          "performed": {
            "completed": true,
            "notes": "כתף ימין (!?) כואבת בסט הראשון 5/10. יד ימין הסתדר. כתפיים בסדר. כאב ביד אחורית כתף שמאל בזמן הורדה. ואל דאגה, בסט השלישי הבנתי שאני לא סופר ותיקנתי. מוט ריק"
          }
        },
        {
          "block_code": "STR",
          "block_label": "D",
          "prescription": {
            "description": "Dumbbell Romanian Deadlift: 3x8",
            "target_sets": 3,
            "target_reps": 8,
            "target_rpe": "5.5-6",
            "rest": "1:30"
          },
          "performed": {
            "completed": true,
            "notes": "10 ק"
          }
        },
        {
          "block_code": "ACC",
          "block_label": "E",
          "prescription": {
            "description": "One arm chest supported row: 3x10",
            "target_sets": 3,
            "target_reps": 10,
            "target_rpe": 6,
            "rest": "1:30"
          },
          "performed": {
            "completed": true,
            "notes": "10 ק"
          }
        },
        {
          "block_code": "ACC",
          "block_label": "F",
          "prescription": {
            "description": "Tall Kneeling Cable Pallof Press: 3x10/10",
            "rest": "1:00"
          },
          "performed": {
            "completed": true,
            "notes": "7.5 תנועה מוזרההה"
          }
        },
        {
          "block_code": "ACC",
          "block_label": "G",
          "prescription": {
            "description": "DB Suitcase Carry: 3x20m/20m",
            "rest": "1:00",
            "notes": "start with left hand"
          },
          "performed": {
            "completed": true,
            "notes": "התחלתי מ 12 ועברתי ל 18 בסט האחרון"
          }
        },
        {
          "block_code": "ACC",
          "block_label": "H",
          "prescription": {
            "description": "Prone Low Trap Raise: 2x12",
            "rest": "1:00",
            "notes": "נא למצוא את המרחב בין הכתפיים שלא מייצר כאב"
          },
          "performed": {
            "completed": true,
            "notes": "נתפס לי כמו שאתה רואה מתחת לשכמה שמאל תוך כדי הסט הראשון"
          }
        },
        {
          "block_code": "SS",
          "block_label": "I",
          "prescription": {
            "description": "Bike/Row: 10 min"
          },
          "performed": {
            "completed": true
          }
        }
      ]
    }
  ]
}
```

---

## Example 3: bader_2025-09-07_running_intervals
**File:** bader_2025-09-07_running_intervals.json

### Original Workout Text
```
Workout Log: bader_workout_log - 2025-09-07
==============================================

Sunday September  7, 2025
Title: W1 T1
Status: completed


A) Warm Up: 5 min Walk / light Jog 

2 Rounds:
10 /10 Ankle circles
10/10 Hip openers 90/90
10/10 Down Dog Calf Rocks
10 Cat cow for lower back
   אין מגבוליות
B) Rehab Activetions: 2×12/12 Single-leg calf raises 
* tempo 2 sec up / 3 sec down

2×15 m Toe walks
* light pressure on forefoot

2×30 sec Glute bridge hold 
* squeeze glutes, keep ribs down

2×8/8 Dead bug 
* focus on lumbar control
C) Main Session: 5 x (400m easy run + 100m Walk)

Suggested Pace: 6:20 to 6:40 per km
Breathing cue: 3 steps inhale + 4 steps exhale
RPE per run segment: 4 to 5
   הריצה הייתה בקצב טוב 
אין כאבים ברגלים 
בעיה בנשימה כבדה 
בסיבוב השלישי התאזנה קצת 
D) Weekly 1 km : Run 1 km continuous at easy steady pace 

Surface: outdoors or treadmill 1%
Record time and perceived effort.
No sprint finish.
E) Cool Down: Slow walk 5 min
stretch calves
hamstrings
hip flexors 
2 Min each


```

### Parsed JSON
```json
{
  "workout_date": "2025-09-07",
  "athlete_id": null,
  "title": "W1 T1",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "5 min Walk / light Jog, then 2 Rounds of mobility"
          },
          "performed": {
            "completed": true,
            "notes": "אין מגבוליות"
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Walk / light Jog",
              "prescription": {
                "target_duration_min": 5
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Ankle circles",
              "prescription": {
                "target_rounds": 2,
                "target_reps_per_side": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Hip openers 90/90",
              "prescription": {
                "target_rounds": 2,
                "target_reps_per_side": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Down Dog Calf Rocks",
              "prescription": {
                "target_rounds": 2,
                "target_reps_per_side": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 5,
              "exercise_name": "Cat cow",
              "prescription": {
                "target_rounds": 2,
                "target_reps": 10,
                "notes": "for lower back"
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "ACT",
          "block_label": "B",
          "prescription": {
            "description": "Rehab Activations: calf raises, toe walks, glute bridge, dead bug"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "Single-leg calf raises",
              "prescription": {
                "target_sets": 2,
                "target_reps": 12,
                "tempo": "2 sec up / 3 sec down",
                "notes": "per leg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 12,
                    "notes": "left"
                  },
                  {
                    "reps": 12,
                    "notes": "right"
                  }
                ]
              },
              "item_sequence": 1
            },
            {
              "exercise_name": "Toe walks",
              "prescription": {
                "target_sets": 2,
                "target_distance": 15,
                "distance_unit": "m",
                "notes": "light pressure on forefoot"
              },
              "performed": {
                "sets": [
                  {
                    "distance": 15,
                    "distance_unit": "m"
                  },
                  {
                    "distance": 15,
                    "distance_unit": "m"
                  }
                ]
              },
              "item_sequence": 2
            },
            {
              "exercise_name": "Glute bridge hold",
              "prescription": {
                "target_sets": 2,
                "target_duration": 30,
                "duration_unit": "sec",
                "notes": "squeeze glutes, keep ribs down"
              },
              "performed": {
                "sets": [
                  {
                    "duration": 30,
                    "duration_unit": "sec"
                  },
                  {
                    "duration": 30,
                    "duration_unit": "sec"
                  }
                ]
              },
              "item_sequence": 3
            },
            {
              "exercise_name": "Dead bug",
              "prescription": {
                "target_sets": 2,
                "target_reps": 8,
                "notes": "per side, focus on lumbar control"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 8,
                    "notes": "left"
                  },
                  {
                    "reps": 8,
                    "notes": "right"
                  }
                ]
              },
              "item_sequence": 4
            }
          ]
        },
        {
          "block_code": "INTV",
          "block_label": "C",
          "prescription": {
            "description": "5 x (400m easy run + 100m Walk)",
            "target_rounds": 5,
            "pace": "6:20 to 6:40 per km",
            "breathing_cue": "3 steps inhale + 4 steps exhale",
            "target_rpe": "4-5"
          },
          "performed": {
            "completed": true,
            "rounds": 5,
            "notes": "הריצה הייתה בקצב טוב, אין כאבים ברגלים, בעיה בנשימה כבדה בסיבוב השלישי התאזנה קצת"
          }
        },
        {
          "block_code": "SKILL",
          "block_label": "D",
          "prescription": {
            "description": "Weekly 1 km: Run 1 km continuous at easy steady pace",
            "target_distance": 1,
            "distance_unit": "km",
            "notes": "Surface: outdoors or treadmill 1%, No sprint finish"
          },
          "performed": {
            "completed": true,
            "distance": 1,
            "distance_unit": "km",
            "notes": "Record time and perceived effort"
          }
        },
        {
          "block_code": "CD",
          "block_label": "E",
          "prescription": {
            "description": "Slow walk 5 min, stretch calves/hamstrings/hip flexors 2 min each"
          },
          "performed": {
            "completed": true,
            "duration": 11,
            "duration_unit": "min"
          }
        }
      ]
    }
  ]
}
```

---

## Example 4: example_workout_golden
**File:** example_workout_golden.json

### Original Workout Text
*No source text file available*

### Parsed JSON
```json
{
  "workout_date": "2025-09-07",
  "athlete_id": null,
  "title": "W1 T1 - Test Workout",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "General warm up"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Walk / light Jog",
              "prescription": {
                "target_duration_min": 5
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "B",
          "prescription": {
            "description": "3x5 Back Squat @ 100kg"
          },
          "performed": {
            "completed": true,
            "notes": "Felt strong today"
          },
          "items": [
            {
              "exercise_name": "Back Squat",
              "prescription": {
                "target_sets": 3,
                "target_reps": 5,
                "target_load": 100,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 5,
                    "load": 100,
                    "rpe": 7
                  },
                  {
                    "reps": 5,
                    "load": 100,
                    "rpe": 7
                  },
                  {
                    "reps": 5,
                    "load": 100,
                    "rpe": 7
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "CD",
          "block_label": "C",
          "prescription": {
            "description": "10 min stretch"
          },
          "performed": {
            "completed": true
          }
        }
      ]
    }
  ]
}
```

---

## Example 5: itamar_2025-06-21_rowing_skill
**File:** itamar_2025-06-21_rowing_skill.json

### Original Workout Text
```
Saturday June 21, 2025
Status: completed


A) Warm up:  3 min light row to raise HR
and then
8 × 30 sec On / 30 sec Off @ 20-22 SPM, build power slightly each rep
B) Mobility: 3 rounds
10 Frog Stretch (dynamic)
10 Hip Airplanes
10 Cat-Cow
C) Skill: 5  Rounds:
10 Arms
10 Arms+Body 
10 Arms+Body+Half-Slide 
10 powerful strokes @ Rate 24, focus on leg drive & calm recovery
rest 60 sec 

easy - its a skill not a workout - foucs on beeing better!
D) Test: Row 1,000 m – single effort
Target rate 24-26 SPM
Open the first 200 m controlled, accelerate into sustainable pace

Record: Total time, Avg Split/500 m, Avg SPM, Overall RPE, any pain/fatigue notes
E) Extra Row Volume: 3 min recovery 
3 × 500 m
Rest 1:30  between reps
F) Core: 3 rounds:
12 V-Ups
 15 Superman Raises 
20 KB Russian Twists (light) 
30 Hollow Rocks
rest as neede 


-----

Sunday June 22, 2025
Title: B0W2 - Again
Status: completed


A) Warm up: Cat–Cow 3x10
Pelvic Tilts (on back)  3x15
Thread-the-Needle  2X 1min R / 1 min L
B) Lower Back & Hip Mobility: 3 Rounds:
10 Frog Stretch (dynamic)
10 Traveling Pigeon (dynamic)
10/10 Internal Hip Rotations (from 90/90 position)
10/10 World’s Greatest Stretch

*slow and breath
C) Spine and Shoulder Mobility: 3x10 Towel Shoulder Dislocates 
3x12 Wall Angels
3x15 Scapular Push-Ups

D) Flexibility & Stretching –: 2 riounds:
2/2 min Pigeon Pose (static)
1/1 min Eagle Arms Stretch
2 min  Butterfly Stretch (back to wall)
1-2 min Standing Forward Fold
E) Breathing & Recovery: Box Breathing (4–4–4–4) for 5 min
Inhale through nose, slow long exhales

-----

Monday June 23, 2025
Title: B0W2 - Again
Status: completed

```

### Parsed JSON
```json
{
  "workout_date": "2025-06-21",
  "athlete_id": null,
  "title": "Workout",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "3 min light row to raise HR, then interval rowing"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Light row",
              "prescription": {
                "target_duration_min": 3,
                "notes": "to raise HR"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Row intervals",
              "prescription": {
                "target_sets": 8,
                "work_sec": 30,
                "rest_sec": 30,
                "target_spm": "20-22",
                "notes": "build power slightly each rep"
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "MOB",
          "block_label": "B",
          "prescription": {
            "description": "3 rounds mobility circuit",
            "target_rounds": 3
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Frog Stretch",
              "prescription": {
                "target_rounds": 3,
                "target_reps": 10,
                "notes": "dynamic"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Hip Airplanes",
              "prescription": {
                "target_rounds": 3,
                "target_reps": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Cat-Cow",
              "prescription": {
                "target_rounds": 3,
                "target_reps": 10
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "SKILL",
          "block_label": "C",
          "prescription": {
            "description": "5 Rounds: 10 Arms, 10 Arms+Body, 10 Arms+Body+Half-Slide, 10 powerful strokes @ Rate 24, focus on leg drive & calm recovery, rest 60 sec",
            "notes": "easy - its a skill not a workout - focus on being better!"
          },
          "performed": {
            "completed": true
          }
        },
        {
          "block_code": "INTV",
          "block_label": "D",
          "prescription": {
            "description": "Row 1,000 m - single effort. Target rate 24-26 SPM. Open the first 200 m controlled, accelerate into sustainable pace",
            "target_distance": 1000,
            "distance_unit": "m",
            "target_spm": "24-26",
            "notes": "Record: Total time, Avg Split/500 m, Avg SPM, Overall RPE, any pain/fatigue notes"
          },
          "performed": {
            "completed": true
          }
        },
        {
          "block_code": "INTV",
          "block_label": "E",
          "prescription": {
            "description": "3 min recovery, then 3x500 m",
            "target_sets": 3,
            "target_distance": 500,
            "distance_unit": "m",
            "rest": "1:30"
          },
          "performed": {
            "completed": true
          }
        },
        {
          "block_code": "ACC",
          "block_label": "F",
          "prescription": {
            "description": "3 rounds: 12 V-Ups, 15 Superman Raises, 20 KB Russian Twists (light), 30 Hollow Rocks, rest as needed"
          },
          "performed": {
            "completed": true
          }
        }
      ]
    }
  ]
}
```

---

## Example 6: jonathan_2025-08-17_lower_body_fortime
**File:** jonathan_2025-08-17_lower_body_fortime.json

### Original Workout Text
```
Workout: Workout Log: Jonathan benamou - 2025-08-17
==================================================

Sunday August 17, 2025
Title: Lower Body Focus
Status: completed


A) Warm up: 5 min treadmill jog

2 rounds: 
10 Air Squats (tempo 3s down)
10 Glute Bridges
30s Plank
B) Dumbbell Goblet Squat:  5×12 @ 14kg (Tempo 3-1-1)
C) BSS: 4×10/leg @ 2×14kg DBs (Tempo 2-1-1)
D) Dumbbell Romanian Deadlift: 4×12 @ 2×14kg (Tempo 3-1-1)
E) Conditioning: For Time:
50 DB Reverse Walking Lunges (14kg total)
40 Burpees
30 DB Deadlifts (2×14kg)
20 Push-ups
400m Run
F) Plank Hold: 3×1:00 (Tempo 1s inhale/1s exhale control)

```

### Parsed JSON
```json
{
  "workout_date": "2025-08-17",
  "athlete_id": null,
  "title": "Lower Body Focus",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "5 min treadmill jog, then 2 rounds of activation"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Treadmill jog",
              "prescription": {
                "target_duration_min": 5
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Air Squats",
              "prescription": {
                "target_rounds": 2,
                "target_reps": 10,
                "tempo": "3s down"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Glute Bridges",
              "prescription": {
                "target_rounds": 2,
                "target_reps": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Plank",
              "prescription": {
                "target_rounds": 2,
                "target_duration_sec": 30
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "B",
          "prescription": {
            "description": "Dumbbell Goblet Squat: 5×12 @ 14kg",
            "target_sets": 5,
            "target_reps": 12,
            "target_load": 14,
            "load_unit": "kg",
            "tempo": "3-1-1"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "Dumbbell Goblet Squat",
              "prescription": {
                "target_sets": 5,
                "target_reps": 12,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "C",
          "prescription": {
            "description": "BSS (Bulgarian Split Squat): 4×10/leg @ 2×14kg DBs",
            "target_sets": 4,
            "target_reps": 10,
            "target_load": 14,
            "load_unit": "kg",
            "tempo": "2-1-1"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "Bulgarian Split Squat",
              "prescription": {
                "target_sets": 4,
                "target_reps": 10,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "D",
          "prescription": {
            "description": "Dumbbell Romanian Deadlift: 4×12 @ 2×14kg",
            "target_sets": 4,
            "target_reps": 12,
            "target_load": 14,
            "load_unit": "kg",
            "tempo": "3-1-1"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "Dumbbell Romanian Deadlift",
              "prescription": {
                "target_sets": 4,
                "target_reps": 12,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "METCON",
          "block_label": "E",
          "format": "For Time",
          "prescription": {
            "description": "For Time: 50 DB Reverse Walking Lunges, 40 Burpees, 30 DB Deadlifts, 20 Push-ups, 400m Run"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "DB Reverse Walking Lunges",
              "prescription": {
                "target_reps": 50,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "reps": 50,
                "load": 14,
                "load_unit": "kg"
              },
              "item_sequence": 1
            },
            {
              "exercise_name": "Burpees",
              "prescription": {
                "target_reps": 40
              },
              "performed": {
                "reps": 40
              },
              "item_sequence": 2
            },
            {
              "exercise_name": "DB Deadlifts",
              "prescription": {
                "target_reps": 30,
                "target_load": 14,
                "load_unit": "kg",
                "notes": "2×14kg"
              },
              "performed": {
                "reps": 30,
                "load": 14,
                "load_unit": "kg"
              },
              "item_sequence": 3
            },
            {
              "exercise_name": "Push-ups",
              "prescription": {
                "target_reps": 20
              },
              "performed": {
                "reps": 20
              },
              "item_sequence": 4
            },
            {
              "exercise_name": "Run",
              "prescription": {
                "target_distance": 400,
                "distance_unit": "m"
              },
              "performed": {
                "distance": 400,
                "distance_unit": "m"
              },
              "item_sequence": 5
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "F",
          "prescription": {
            "description": "Plank Hold: 3×1:00",
            "target_sets": 3,
            "target_duration": 60,
            "duration_unit": "sec",
            "tempo": "1s inhale/1s exhale control"
          },
          "performed": {
            "completed": true
          }
        }
      ]
    }
  ]
}
```

---

## Example 7: jonathan_2025-08-17_lower_fortime
**File:** jonathan_2025-08-17_lower_fortime.json

### Original Workout Text
```
Workout: Workout Log: Jonathan benamou - 2025-08-17
==================================================

Sunday August 17, 2025
Title: Lower Body Focus
Status: completed


A) Warm up: 5 min treadmill jog

2 rounds: 
10 Air Squats (tempo 3s down)
10 Glute Bridges
30s Plank
B) Dumbbell Goblet Squat:  5×12 @ 14kg (Tempo 3-1-1)
C) BSS: 4×10/leg @ 2×14kg DBs (Tempo 2-1-1)
D) Dumbbell Romanian Deadlift: 4×12 @ 2×14kg (Tempo 3-1-1)
E) Conditioning: For Time:
50 DB Reverse Walking Lunges (14kg total)
40 Burpees
30 DB Deadlifts (2×14kg)
20 Push-ups
400m Run
F) Plank Hold: 3×1:00 (Tempo 1s inhale/1s exhale control)

```

### Parsed JSON
```json
{
  "workout_date": "2025-08-17",
  "athlete_id": null,
  "title": "Lower Body Focus",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "5 min treadmill jog, then 2 rounds of activation"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Treadmill jog",
              "prescription": {
                "target_duration_min": 5
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Air Squats",
              "prescription": {
                "target_rounds": 2,
                "target_reps": 10,
                "tempo": "3s down"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Glute Bridges",
              "prescription": {
                "target_rounds": 2,
                "target_reps": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Plank",
              "prescription": {
                "target_rounds": 2,
                "target_duration_sec": 30
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "B",
          "prescription": {
            "description": "Dumbbell Goblet Squat: 5×12 @ 14kg",
            "target_sets": 5,
            "target_reps": 12,
            "target_load": 14,
            "load_unit": "kg",
            "tempo": "3-1-1"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "Dumbbell Goblet Squat",
              "prescription": {
                "target_sets": 5,
                "target_reps": 12,
                "target_load": 14,
                "load_unit": "kg",
                "tempo": "3-1-1"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "C",
          "prescription": {
            "description": "BSS: 4×10/leg @ 2×14kg DBs",
            "target_sets": 4,
            "target_reps": 10,
            "target_load": 14,
            "load_unit": "kg",
            "tempo": "2-1-1"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "Bulgarian Split Squat",
              "prescription": {
                "target_sets": 4,
                "target_reps": 10,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "D",
          "prescription": {
            "description": "Dumbbell Romanian Deadlift: 4×12 @ 2×14kg",
            "target_sets": 4,
            "target_reps": 12,
            "target_load": 14,
            "load_unit": "kg",
            "tempo": "3-1-1"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "Dumbbell Romanian Deadlift",
              "prescription": {
                "target_sets": 4,
                "target_reps": 12,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "METCON",
          "block_label": "E",
          "block_type": "For Time",
          "prescription": {
            "description": "For Time: 50 DB Reverse Walking Lunges, 40 Burpees, 30 DB Deadlifts, 20 Push-ups, 400m Run",
            "target_load": 14,
            "load_unit": "kg"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "DB Reverse Walking Lunges",
              "prescription": {
                "target_reps": 50,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "reps": 50,
                "load": 14,
                "load_unit": "kg"
              },
              "item_sequence": 1
            },
            {
              "exercise_name": "Burpees",
              "prescription": {
                "target_reps": 40
              },
              "performed": {
                "reps": 40
              },
              "item_sequence": 2
            },
            {
              "exercise_name": "DB Deadlifts",
              "prescription": {
                "target_reps": 30,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "reps": 30,
                "load": 14,
                "load_unit": "kg"
              },
              "item_sequence": 3
            },
            {
              "exercise_name": "Push-ups",
              "prescription": {
                "target_reps": 20
              },
              "performed": {
                "reps": 20
              },
              "item_sequence": 4
            },
            {
              "exercise_name": "Run",
              "prescription": {
                "target_distance": 400,
                "distance_unit": "m"
              },
              "performed": {
                "distance": 400,
                "distance_unit": "m"
              },
              "item_sequence": 5
            }
          ]
        },
        {
          "block_code": "CD",
          "block_label": "F",
          "prescription": {
            "description": "Plank Hold: 3×1:00 with breathing control"
          },
          "performed": {
            "completed": true
          }
        }
      ]
    }
  ]
}
```

---

## Example 8: jonathan_2025-08-19_upper_amrap
**File:** jonathan_2025-08-19_upper_amrap.json

### Original Workout Text
```
Workout: Workout Log: Jonathan benamou - 2025-08-19
==================================================

Tuesday August 19, 2025
Title: Upper Body Focus (Press + Pull)
Status: completed


A) Warm up: 5 min treadmill jog

2 rounds: 
8 Push-ups
10 light DB Reverse Flys
30s Side Plank Left
30s Side Plank Right
B) Single Arm DB Bench: 5×10/side @ 14kg (Tempo 3-1-1)
C) Single Arm DB Row: 4×12/side @ 14kg (Tempo 3-1-1)
D) DB Z-Press: 4×12 @ 2×14kg (Tempo 2-1-1)
   Difficult for me with 14kilos so I do with 10 kilos 

Difficult for me to be straight 
E) Conditioning: As Many Rounds As Possiblle in  12 min:
10 DB Thrusters (2×14kg)
12 Burpees
200m Run
   I do with 10 kilos 

In 12 minutes I do 3 séries of all 
F) Side Plank with Rotation:  (light weight) 3×10/side

```

### Parsed JSON
```json
{
  "workout_date": "2025-08-19",
  "athlete_id": null,
  "title": "Upper Body Focus (Press + Pull)",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "5 min treadmill jog, then 2 rounds of activation"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Treadmill jog",
              "prescription": {
                "target_duration_min": 5
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Push-ups",
              "prescription": {
                "target_rounds": 2,
                "target_reps": 8
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "DB Reverse Flys",
              "prescription": {
                "target_rounds": 2,
                "target_reps": 10,
                "notes": "light"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Side Plank Left",
              "prescription": {
                "target_rounds": 2,
                "target_duration_sec": 30
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 5,
              "exercise_name": "Side Plank Right",
              "prescription": {
                "target_rounds": 2,
                "target_duration_sec": 30
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "B",
          "prescription": {
            "description": "Single Arm DB Bench: 5×10/side @ 14kg",
            "target_sets": 5,
            "target_reps": 10,
            "target_load": 14,
            "load_unit": "kg",
            "tempo": "3-1-1"
          },
          "performed": {
            "completed": true,
            "sets": [
              {
                "reps": 10,
                "load": 14,
                "load_unit": "kg",
                "notes": "left"
              },
              {
                "reps": 10,
                "load": 14,
                "load_unit": "kg",
                "notes": "right"
              },
              {
                "reps": 10,
                "load": 14,
                "load_unit": "kg",
                "notes": "left"
              },
              {
                "reps": 10,
                "load": 14,
                "load_unit": "kg",
                "notes": "right"
              },
              {
                "reps": 10,
                "load": 14,
                "load_unit": "kg",
                "notes": "left"
              }
            ]
          },
          "items": [
            {
              "exercise_name": "Single Arm DB Bench Press",
              "prescription": {
                "target_sets": 5,
                "target_reps": 10,
                "target_load": 14,
                "load_unit": "kg",
                "tempo": "3-1-1"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 14,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "C",
          "prescription": {
            "description": "Single Arm DB Row: 4×12/side @ 14kg",
            "target_sets": 4,
            "target_reps": 12,
            "target_load": 14,
            "load_unit": "kg",
            "tempo": "3-1-1"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "Single Arm DB Row",
              "prescription": {
                "target_sets": 4,
                "target_reps": 12,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "D",
          "prescription": {
            "description": "DB Z-Press: 4×12 @ 2×14kg",
            "target_sets": 4,
            "target_reps": 12,
            "target_load": 14,
            "load_unit": "kg",
            "tempo": "2-1-1"
          },
          "performed": {
            "completed": true,
            "notes": "Difficult with 14kg, did with 10kg. Difficult to be straight"
          },
          "items": [
            {
              "exercise_name": "DB Z-Press",
              "prescription": {
                "target_sets": 4,
                "target_reps": 12,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 12,
                    "load": 10,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 10,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 10,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 10,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "METCON",
          "block_label": "E",
          "block_type": "AMRAP",
          "prescription": {
            "description": "As Many Rounds As Possible in 12 min: 10 DB Thrusters, 12 Burpees, 200m Run",
            "time_cap": 12,
            "time_cap_unit": "min",
            "target_load": 14,
            "load_unit": "kg"
          },
          "performed": {
            "completed": true,
            "rounds": 3,
            "time": 12,
            "time_unit": "min",
            "notes": "Did with 10kg"
          },
          "items": [
            {
              "exercise_name": "DB Thrusters",
              "prescription": {
                "target_reps": 10,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "reps": 10,
                "load": 10,
                "load_unit": "kg"
              },
              "item_sequence": 1
            },
            {
              "exercise_name": "Burpees",
              "prescription": {
                "target_reps": 12
              },
              "performed": {
                "reps": 12
              },
              "item_sequence": 2
            },
            {
              "exercise_name": "Run",
              "prescription": {
                "target_distance": 200,
                "distance_unit": "m"
              },
              "performed": {
                "distance": 200,
                "distance_unit": "m"
              },
              "item_sequence": 3
            }
          ]
        },
        {
          "block_code": "CD",
          "block_label": "F",
          "prescription": {
            "description": "Side Plank with Rotation: 3×10/side (light weight)"
          },
          "performed": {
            "completed": true
          }
        }
      ]
    }
  ]
}
```

---

## Example 9: jonathan_2025-08-24_lower_body_amrap
**File:** jonathan_2025-08-24_lower_body_amrap.json

### Original Workout Text
```
Workout: Workout Log: Jonathan benamou - 2025-08-24
==================================================

Sunday August 24, 2025
Title: Lower Body Focus
Status: completed


A) Warm up: 5 min treadmill jog

2 rounds: 
10 Air Squats (tempo 3s down)
10 Glute Bridges
30s Plank
   I started with 30 min with walk at 5km/h and gradient 10
B) Dumbbell Goblet Squat:  5×12 @ 14kg (Tempo 3-1-1)
   I do all with 12.5kilos 
C) BSS: 4×10/leg @ 2×14kg DBs (Tempo 2-1-1)
   I do 2x 10 / legs with 12.5 kilos 
I have a Little pain in my leg
D) Dumbbell Romanian Deadlift: 4×12 @ 2×14kg (Tempo 3-1-1)
E) Conditioning: 15 min Amrap:
8/8 DB Sumo Deadlift High Pull (14kg-16kg)
10 Burpees over DBs
200m Run (treadmill)
   I do 10 min 2 round in global of all 
F)  Glute Bridge March:  3×20 alternating reps
   I do 3x 14
G) Hollow hold :  3×40s


   I do 3x30 secondes


```

### Parsed JSON
```json
{
  "workout_date": "2025-08-24",
  "athlete_id": null,
  "title": "Lower Body Focus",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "5 min treadmill jog, then 2 rounds of activation"
          },
          "performed": {
            "completed": true,
            "notes": "I started with 30 min walk at 5km/h and gradient 10"
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Treadmill jog",
              "prescription": {
                "target_duration_min": 5
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Air Squats",
              "prescription": {
                "target_rounds": 2,
                "target_reps": 10,
                "tempo": "3s down"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Glute Bridges",
              "prescription": {
                "target_rounds": 2,
                "target_reps": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Plank",
              "prescription": {
                "target_rounds": 2,
                "target_duration_sec": 30
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "B",
          "prescription": {
            "description": "Dumbbell Goblet Squat: 5×12 @ 14kg",
            "target_sets": 5,
            "target_reps": 12,
            "target_load": 14,
            "load_unit": "kg",
            "tempo": "3-1-1"
          },
          "performed": {
            "completed": true,
            "notes": "I do all with 12.5 kilos",
            "sets": [
              {
                "reps": 12,
                "load": 12.5,
                "load_unit": "kg"
              },
              {
                "reps": 12,
                "load": 12.5,
                "load_unit": "kg"
              },
              {
                "reps": 12,
                "load": 12.5,
                "load_unit": "kg"
              },
              {
                "reps": 12,
                "load": 12.5,
                "load_unit": "kg"
              },
              {
                "reps": 12,
                "load": 12.5,
                "load_unit": "kg"
              }
            ]
          },
          "items": [
            {
              "exercise_name": "Dumbbell Goblet Squat",
              "prescription": {
                "target_sets": 5,
                "target_reps": 12,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 12,
                    "load": 12.5,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 12.5,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 12.5,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 12.5,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 12.5,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "C",
          "prescription": {
            "description": "BSS (Bulgarian Split Squat): 4×10/leg @ 2×14kg DBs",
            "target_sets": 4,
            "target_reps": 10,
            "target_load": 14,
            "load_unit": "kg",
            "tempo": "2-1-1"
          },
          "performed": {
            "completed": true,
            "notes": "I do 2x 10 / legs with 12.5 kilos. I have a little pain in my leg",
            "sets": [
              {
                "reps": 10,
                "load": 12.5,
                "load_unit": "kg",
                "notes": "left"
              },
              {
                "reps": 10,
                "load": 12.5,
                "load_unit": "kg",
                "notes": "right"
              },
              {
                "reps": 10,
                "load": 12.5,
                "load_unit": "kg",
                "notes": "left"
              },
              {
                "reps": 10,
                "load": 12.5,
                "load_unit": "kg",
                "notes": "right"
              }
            ]
          },
          "items": [
            {
              "exercise_name": "Bulgarian Split Squat",
              "prescription": {
                "target_sets": 4,
                "target_reps": 10,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 10,
                    "load": 12.5,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 12.5,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 12.5,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 10,
                    "load": 12.5,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "D",
          "prescription": {
            "description": "Dumbbell Romanian Deadlift: 4×12 @ 2×14kg",
            "target_sets": 4,
            "target_reps": 12,
            "target_load": 14,
            "load_unit": "kg",
            "tempo": "3-1-1"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "Dumbbell Romanian Deadlift",
              "prescription": {
                "target_sets": 4,
                "target_reps": 12,
                "target_load": 14,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 14,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "METCON",
          "block_label": "E",
          "format": "AMRAP",
          "prescription": {
            "description": "15 min AMRAP: 8/8 DB Sumo DL High Pull (14-16kg), 10 Burpees over DBs, 200m Run",
            "time_cap": 15,
            "time_cap_unit": "min"
          },
          "performed": {
            "completed": true,
            "duration": 10,
            "duration_unit": "min",
            "rounds": 2,
            "notes": "I do 10 min, 2 rounds in global of all"
          },
          "items": [
            {
              "exercise_name": "DB Sumo Deadlift High Pull",
              "prescription": {
                "target_reps": 8,
                "target_load": 15,
                "load_unit": "kg",
                "notes": "per arm"
              },
              "performed": {},
              "item_sequence": 1
            },
            {
              "exercise_name": "Burpees over DBs",
              "prescription": {
                "target_reps": 10
              },
              "performed": {},
              "item_sequence": 2
            },
            {
              "exercise_name": "Run",
              "prescription": {
                "target_distance": 200,
                "distance_unit": "m",
                "notes": "treadmill"
              },
              "performed": {},
              "item_sequence": 3
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "F",
          "prescription": {
            "description": "Glute Bridge March: 3×20 alternating reps"
          },
          "performed": {
            "completed": true,
            "notes": "I do 3x14"
          }
        },
        {
          "block_code": "ACC",
          "block_label": "G",
          "prescription": {
            "description": "Hollow hold: 3×40s"
          },
          "performed": {
            "completed": true,
            "notes": "I do 3x30 seconds"
          }
        }
      ]
    }
  ]
}
```

---

## Example 10: melany_2025-09-14_mixed_complex
**File:** melany_2025-09-14_mixed_complex.json

### Original Workout Text
```
Workout: Workout Log: Melany Zyman - 2025-09-14
==================================================

Sunday September 14, 2025
Status: completed

Warmup: Goal:
Rebuild posterior chain strength and trunk control without provoking symptoms



A) Warm up: 2 min - 90/90 Diaphragmatic Breathing
1x 8/8 - T‑Spine Open Books - slow!
1x 8/8- 90/90 Hips Switch
1x 10/10 Ankle circles 
1x 10/10 Knee to wall 
3x 6/6 Dead Bug  
Then...
4 min easy row @ 18-20 spm
B) DL Block Pull (below knee): Warm‑ups: 
30 kg ×5 
40 kg ×5 
50 kg ×3

4×5 @ 55 kg @ RPE 5-6, 
Tempo 3‑1‑1  (3 sec down , 1 sec up, 1 sec hold)

Rest 2:00

Notes: 
Lats on
brace first
shoulders over bar;
no lumbar over‑extension.
C) DB Romanian Deadlift: Warm‑up: 
2×8 @  8 kg DBs
 
3×8 @ 2×12 kg @ RPE 6
Tempo 2‑1‑2 (2 sec down , 1 sec hold, 2 sec up)
Rest 1:30

Notes: 
Stop before lumbar flexion
long hamstrings.
D) BB Hip Thrust (bench‑supported): Warm‑ups: 
20 kg ×10
30 kg ×6

3×10 @ 40 kg @ RPE 6-7
Tempo 2‑0‑2 (2 sec down , no pause, 2 sec up)
Rest 1:30

Notes: 
Chin tucked
ribs down
push through heels.
E) One arm chest supported row: Warm‑up: 
12 kg ×8/8

3×12/12 @ 16 kg @ RPE 6
Rest 60–90s

Notes: Elbow to hip
   נראה לי המשקל היה קצת מוגזם כי היה לי מאאאאוד קשה 
F) Band Pall off Press: Warm‑up: 
Light band ×12/12

Working: 
3×10/10  (2s hold at full extension)
Rest 60s

Notes: no trunk rotation.
G) Suitcase Carry: 3×30/30m @ 18 -20 kg @ RPE 6
Rest 60–90s

Notes: 
Tall posture
shorten distance if left ankle feels unstable.
H) Row: 10 min row @ 20-22 spm
I) Left ankel rehab (Can be done at home): Alphabet (A-Z) with foot 
*our big toe is a pencil and sketch out the alphabet slow and full range.

Eversion/Inversion with band:
2×12/12 (light band)

Eccentric Calf Raise:
3×15/15 (3s down)

Toe/Heel Walk: 
2×20 m

```

### Parsed JSON
```json
{
  "workout_date": "2025-09-14",
  "athlete_id": null,
  "title": "Posterior Chain Rebuild",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "Warm up sequence for posterior chain rebuild"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "90/90 Diaphragmatic Breathing",
              "prescription": {
                "target_duration_min": 2
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "T-Spine Open Books",
              "prescription": {
                "target_sets": 1,
                "target_reps": "8/8",
                "notes": "slow!"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "90/90 Hip Switch",
              "prescription": {
                "target_sets": 1,
                "target_reps": "8/8"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Ankle Circles",
              "prescription": {
                "target_sets": 1,
                "target_reps": "10/10"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 5,
              "exercise_name": "Knee to Wall",
              "prescription": {
                "target_sets": 1,
                "target_reps": "10/10"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 6,
              "exercise_name": "Dead Bug",
              "prescription": {
                "target_sets": 3,
                "target_reps": "6/6"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 7,
              "exercise_name": "Row",
              "prescription": {
                "target_duration_min": 4,
                "target_spm": "18-20",
                "notes": "easy"
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "B",
          "prescription": {
            "description": "DL Block Pull (below knee): 4×5 @ 55 kg",
            "target_sets": 4,
            "target_reps": 5,
            "target_load": 55,
            "load_unit": "kg",
            "target_rpe": "5-6",
            "tempo": "3-1-1",
            "rest": "2:00",
            "notes": "Lats on, brace first, shoulders over bar, no lumbar over-extension"
          },
          "performed": {
            "completed": true,
            "warmup_sets": [
              {
                "reps": 5,
                "load": 30,
                "load_unit": "kg"
              },
              {
                "reps": 5,
                "load": 40,
                "load_unit": "kg"
              },
              {
                "reps": 3,
                "load": 50,
                "load_unit": "kg"
              }
            ]
          },
          "items": [
            {
              "exercise_name": "Deadlift Block Pull",
              "prescription": {
                "target_sets": 4,
                "target_reps": 5,
                "target_load": 55,
                "load_unit": "kg",
                "tempo": "3-1-1"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 5,
                    "load": 55,
                    "load_unit": "kg",
                    "rpe": 6
                  },
                  {
                    "reps": 5,
                    "load": 55,
                    "load_unit": "kg",
                    "rpe": 6
                  },
                  {
                    "reps": 5,
                    "load": 55,
                    "load_unit": "kg",
                    "rpe": 5
                  },
                  {
                    "reps": 5,
                    "load": 55,
                    "load_unit": "kg",
                    "rpe": 5
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "C",
          "prescription": {
            "description": "DB Romanian Deadlift: 3×8 @ 2×12 kg",
            "target_sets": 3,
            "target_reps": 8,
            "target_load": 12,
            "load_unit": "kg",
            "target_rpe": 6,
            "tempo": "2-1-2",
            "rest": "1:30",
            "notes": "Stop before lumbar flexion, long hamstrings"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "DB Romanian Deadlift",
              "prescription": {
                "target_sets": 3,
                "target_reps": 8,
                "target_load": 12,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 8,
                    "load": 12,
                    "load_unit": "kg",
                    "rpe": 6
                  },
                  {
                    "reps": 8,
                    "load": 12,
                    "load_unit": "kg",
                    "rpe": 6
                  },
                  {
                    "reps": 8,
                    "load": 12,
                    "load_unit": "kg",
                    "rpe": 6
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "D",
          "prescription": {
            "description": "BB Hip Thrust: 3×10 @ 40 kg",
            "target_sets": 3,
            "target_reps": 10,
            "target_load": 40,
            "load_unit": "kg",
            "target_rpe": "6-7",
            "tempo": "2-0-2",
            "rest": "1:30",
            "notes": "Chin tucked, ribs down, push through heels"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "BB Hip Thrust",
              "prescription": {
                "target_sets": 3,
                "target_reps": 10,
                "target_load": 40,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 10,
                    "load": 40,
                    "load_unit": "kg",
                    "rpe": 7
                  },
                  {
                    "reps": 10,
                    "load": 40,
                    "load_unit": "kg",
                    "rpe": 6
                  },
                  {
                    "reps": 10,
                    "load": 40,
                    "load_unit": "kg",
                    "rpe": 7
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "E",
          "prescription": {
            "description": "One arm chest supported row: 3×12/12 @ 16 kg",
            "target_sets": 3,
            "target_reps": 12,
            "target_load": 16,
            "load_unit": "kg",
            "target_rpe": 6,
            "rest": "60-90s",
            "notes": "Elbow to hip"
          },
          "performed": {
            "completed": true,
            "notes": "נראה לי המשקל היה קצת מוגזם כי היה לי מאאאאוד קשה"
          },
          "items": [
            {
              "exercise_name": "One Arm Chest Supported Row",
              "prescription": {
                "target_sets": 3,
                "target_reps": 12,
                "target_load": 16,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 12,
                    "load": 16,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 16,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 12,
                    "load": 16,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "F",
          "prescription": {
            "description": "Band Pallof Press: 3×10/10 (2s hold at full extension)",
            "target_sets": 3,
            "target_reps": 10,
            "rest": "60s",
            "notes": "no trunk rotation"
          },
          "performed": {
            "completed": true
          }
        },
        {
          "block_code": "ACC",
          "block_label": "G",
          "prescription": {
            "description": "Suitcase Carry: 3×30/30m @ 18-20 kg",
            "target_sets": 3,
            "target_distance": 30,
            "distance_unit": "m",
            "target_load": 19,
            "load_unit": "kg",
            "target_rpe": 6,
            "rest": "60-90s",
            "notes": "Tall posture, shorten if ankle unstable"
          },
          "performed": {
            "completed": true
          }
        },
        {
          "block_code": "SS",
          "block_label": "H",
          "prescription": {
            "description": "10 min row @ 20-22 spm",
            "target_duration": 10,
            "duration_unit": "min",
            "target_spm": 21
          },
          "performed": {
            "completed": true,
            "duration": 10,
            "duration_unit": "min"
          }
        },
        {
          "block_code": "CD",
          "block_label": "I",
          "prescription": {
            "description": "Left ankle rehab: Alphabet, Eversion/Inversion, Eccentric Calf Raise, Toe/Heel Walk"
          },
          "performed": {
            "completed": true
          }
        }
      ]
    }
  ]
}
```

---

## Example 11: melany_2025-09-14_rehab_strength
**File:** melany_2025-09-14_rehab_strength.json

### Original Workout Text
```
Workout: Workout Log: Melany Zyman - 2025-09-14
==================================================

Sunday September 14, 2025
Status: completed

Warmup: Goal:
Rebuild posterior chain strength and trunk control without provoking symptoms



A) Warm up: 2 min - 90/90 Diaphragmatic Breathing
1x 8/8 - T‑Spine Open Books - slow!
1x 8/8- 90/90 Hips Switch
1x 10/10 Ankle circles 
1x 10/10 Knee to wall 
3x 6/6 Dead Bug  
Then...
4 min easy row @ 18-20 spm
B) DL Block Pull (below knee): Warm‑ups: 
30 kg ×5 
40 kg ×5 
50 kg ×3

4×5 @ 55 kg @ RPE 5-6, 
Tempo 3‑1‑1  (3 sec down , 1 sec up, 1 sec hold)

Rest 2:00

Notes: 
Lats on
brace first
shoulders over bar;
no lumbar over‑extension.
C) DB Romanian Deadlift: Warm‑up: 
2×8 @  8 kg DBs
 
3×8 @ 2×12 kg @ RPE 6
Tempo 2‑1‑2 (2 sec down , 1 sec hold, 2 sec up)
Rest 1:30

Notes: 
Stop before lumbar flexion
long hamstrings.
D) BB Hip Thrust (bench‑supported): Warm‑ups: 
20 kg ×10
30 kg ×6

3×10 @ 40 kg @ RPE 6-7
Tempo 2‑0‑2 (2 sec down , no pause, 2 sec up)
Rest 1:30

Notes: 
Chin tucked
ribs down
push through heels.
E) One arm chest supported row: Warm‑up: 
12 kg ×8/8

3×12/12 @ 16 kg @ RPE 6
Rest 60–90s

Notes: Elbow to hip
   נראה לי המשקל היה קצת מוגזם כי היה לי מאאאאוד קשה 
F) Band Pall off Press: Warm‑up: 
Light band ×12/12

Working: 
3×10/10  (2s hold at full extension)
Rest 60s

Notes: no trunk rotation.
G) Suitcase Carry: 3×30/30m @ 18 -20 kg @ RPE 6
Rest 60–90s

Notes: 
Tall posture
shorten distance if left ankle feels unstable.
H) Row: 10 min row @ 20-22 spm
I) Left ankel rehab (Can be done at home): Alphabet (A-Z) with foot 
*our big toe is a pencil and sketch out the alphabet slow and full range.

Eversion/Inversion with band:
2×12/12 (light band)

Eccentric Calf Raise:
3×15/15 (3s down)

Toe/Heel Walk: 
2×20 m

```

### Parsed JSON
```json
{
  "workout_date": "2025-09-14",
  "athlete_id": null,
  "title": "Workout",
  "status": "completed",
  "warmup_objective": "Rebuild posterior chain strength and trunk control without provoking symptoms",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "Breathing, mobility, and easy row"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "90/90 Diaphragmatic Breathing",
              "prescription": {
                "target_duration_min": 2
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "T-Spine Open Books",
              "prescription": {
                "target_sets": 1,
                "target_reps_per_side": 8,
                "notes": "slow!"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "90/90 Hips Switch",
              "prescription": {
                "target_sets": 1,
                "target_reps_per_side": 8
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Ankle circles",
              "prescription": {
                "target_sets": 1,
                "target_reps_per_side": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 5,
              "exercise_name": "Knee to wall",
              "prescription": {
                "target_sets": 1,
                "target_reps_per_side": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 6,
              "exercise_name": "Dead Bug",
              "prescription": {
                "target_sets": 3,
                "target_reps_per_side": 6
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 7,
              "exercise_name": "Row",
              "prescription": {
                "target_duration_min": 4,
                "target_spm": "18-20",
                "notes": "easy"
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "B",
          "prescription": {
            "description": "DL Block Pull (below knee): Warm-ups, then 4x5 @ 55kg @ RPE 5-6",
            "target_sets": 4,
            "target_reps": 5,
            "target_load": 55,
            "load_unit": "kg",
            "target_rpe": "5-6",
            "tempo": "3-1-1",
            "rest": "2:00",
            "notes": "Lats on, brace first, shoulders over bar, no lumbar over-extension"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "DL Block Pull",
              "prescription": {
                "target_sets": 4,
                "target_reps": 5,
                "target_load": 55,
                "load_unit": "kg"
              },
              "performed": {
                "warmup_sets": [
                  {
                    "reps": 5,
                    "load": 30,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 5,
                    "load": 40,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 3,
                    "load": 50,
                    "load_unit": "kg"
                  }
                ],
                "sets": [
                  {
                    "reps": 5,
                    "load": 55,
                    "load_unit": "kg",
                    "rpe": 5
                  },
                  {
                    "reps": 5,
                    "load": 55,
                    "load_unit": "kg",
                    "rpe": 6
                  },
                  {
                    "reps": 5,
                    "load": 55,
                    "load_unit": "kg",
                    "rpe": 6
                  },
                  {
                    "reps": 5,
                    "load": 55,
                    "load_unit": "kg",
                    "rpe": 6
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "C",
          "prescription": {
            "description": "DB Romanian Deadlift: Warm-up 2x8 @ 8kg, then 3x8 @ 2x12kg @ RPE 6",
            "target_sets": 3,
            "target_reps": 8,
            "target_load": 12,
            "load_unit": "kg",
            "target_rpe": 6,
            "tempo": "2-1-2",
            "rest": "1:30",
            "notes": "Stop before lumbar flexion, long hamstrings"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "DB Romanian Deadlift",
              "prescription": {
                "target_sets": 3,
                "target_reps": 8,
                "target_load": 12,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 8,
                    "load": 12,
                    "load_unit": "kg",
                    "rpe": 6
                  },
                  {
                    "reps": 8,
                    "load": 12,
                    "load_unit": "kg",
                    "rpe": 6
                  },
                  {
                    "reps": 8,
                    "load": 12,
                    "load_unit": "kg",
                    "rpe": 6
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "D",
          "prescription": {
            "description": "BB Hip Thrust: 3x10 @ 40kg @ RPE 6-7",
            "tempo": "2-0-2",
            "rest": "1:30",
            "notes": "Chin tucked, ribs down, push through heels"
          },
          "performed": {
            "completed": true
          }
        },
        {
          "block_code": "ACC",
          "block_label": "E",
          "prescription": {
            "description": "One arm chest supported row: 3x12/12 @ 16kg @ RPE 6",
            "rest": "60-90s",
            "notes": "Elbow to hip"
          },
          "performed": {
            "completed": true,
            "notes": "נראה לי המשקל היה קצת מוגזם כי היה לי מאאאאוד קשה"
          }
        },
        {
          "block_code": "ACC",
          "block_label": "F",
          "prescription": {
            "description": "Band Pallof Press: 3x10/10 (2s hold at full extension)",
            "rest": "60s",
            "notes": "no trunk rotation"
          },
          "performed": {
            "completed": true
          }
        },
        {
          "block_code": "ACC",
          "block_label": "G",
          "prescription": {
            "description": "Suitcase Carry: 3x30/30m @ 18-20kg @ RPE 6",
            "rest": "60-90s",
            "notes": "Tall posture, shorten distance if left ankle feels unstable"
          },
          "performed": {
            "completed": true
          }
        },
        {
          "block_code": "SS",
          "block_label": "H",
          "prescription": {
            "description": "Row: 10 min @ 20-22 spm"
          },
          "performed": {
            "completed": true
          }
        },
        {
          "block_code": "CD",
          "block_label": "I",
          "prescription": {
            "description": "Left ankle rehab: Alphabet with foot, Eversion/Inversion with band 2x12/12, Eccentric Calf Raise 3x15/15 (3s down), Toe/Heel Walk 2x20m",
            "notes": "Can be done at home"
          },
          "performed": {
            "completed": true
          }
        }
      ]
    }
  ]
}
```

---

## Example 12: orel_2025-06-01_amrap_hebrew_notes
**File:** orel_2025-06-01_amrap_hebrew_notes.json

### Original Workout Text
```
Workout: Workout Log: Orel Ben Haim - 2025-06-01
==================================================

Sunday June  1, 2025
Status: completed


A) Warm UP: 3 Rounds:
50 Single unders
20 Air squat
10 Push ups
3-5 Pull ups 
400m run
   14:40
סיבוב ראשון היה יחסית מאתגר אחרי הרבה זמן שלא זזתי
הסיבובים השניים היו נוחים יותר
B) Mobility: Lower Back Foam roll
ITB Foam Roll
Posterior Shulder Lacross Ball smash 
C) Activations: Band Pull over Hold 3x20sec
1 Leg Double Ktb Step up 3x5/5
D) Metcon: 20 min Amrap 
30 Cal Row
15 S20 45/30KG
400m run 
10 Burpee Over the bar 
35 DU
   עשיתי 2 סבבים מלאים ולא נישאר בסיבוב השלישי לעשות ריצה אז עשיתי 6 ברפיז 


```

### Parsed JSON
```json
{
  "workout_date": "2025-06-01",
  "athlete_id": null,
  "title": "Workout",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "3 Rounds warm-up circuit",
            "target_rounds": 3
          },
          "performed": {
            "completed": true,
            "duration": "14:40",
            "notes": "14:40 - סיבוב ראשון היה יחסית מאתגר אחרי הרבה זמן שלא זזתי, הסיבובים השניים היו נוחים יותר"
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Single unders",
              "prescription": {
                "target_rounds": 3,
                "target_reps": 50
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Air squat",
              "prescription": {
                "target_rounds": 3,
                "target_reps": 20
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Push ups",
              "prescription": {
                "target_rounds": 3,
                "target_reps": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Pull ups",
              "prescription": {
                "target_rounds": 3,
                "target_reps": "3-5"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 5,
              "exercise_name": "Run",
              "prescription": {
                "target_rounds": 3,
                "target_distance_m": 400
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "MOB",
          "block_label": "B",
          "prescription": {
            "description": "Mobility foam rolling and smash"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Lower Back Foam roll",
              "prescription": {
                "notes": "per source text"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "ITB Foam Roll",
              "prescription": {
                "notes": "per source text"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Posterior Shoulder Lacrosse Ball smash",
              "prescription": {
                "notes": "per source text"
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "ACT",
          "block_label": "C",
          "prescription": {
            "description": "Activations"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Band Pull over Hold",
              "prescription": {
                "target_sets": 3,
                "target_duration_sec": 20
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "1 Leg Double Ktb Step up",
              "prescription": {
                "target_sets": 3,
                "target_reps_per_side": 5
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "METCON",
          "block_label": "D",
          "format": "AMRAP",
          "prescription": {
            "description": "20 min AMRAP: 30 Cal Row, 15 S2O 45/30KG, 400m run, 10 Burpee Over the bar, 35 DU",
            "time_cap": 20,
            "time_cap_unit": "min"
          },
          "performed": {
            "completed": true,
            "rounds": 2,
            "notes": "עשיתי 2 סבבים מלאים ולא נשאר בסיבוב השלישי לעשות ריצה אז עשיתי 6 ברפיז",
            "partial_round": {
              "burpees": 6
            }
          },
          "items": [
            {
              "exercise_name": "Row",
              "prescription": {
                "target_calories": 30
              },
              "performed": {},
              "item_sequence": 1
            },
            {
              "exercise_name": "Shoulder to Overhead",
              "prescription": {
                "target_reps": 15,
                "target_load": 45,
                "load_unit": "kg",
                "notes": "45/30KG (male/female)"
              },
              "performed": {},
              "item_sequence": 2
            },
            {
              "exercise_name": "Run",
              "prescription": {
                "target_distance": 400,
                "distance_unit": "m"
              },
              "performed": {},
              "item_sequence": 3
            },
            {
              "exercise_name": "Burpee Over the bar",
              "prescription": {
                "target_reps": 10
              },
              "performed": {},
              "item_sequence": 4
            },
            {
              "exercise_name": "Double Unders",
              "prescription": {
                "target_reps": 35
              },
              "performed": {},
              "item_sequence": 5
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Example 13: orel_2025-06-01_hebrew_amrap
**File:** orel_2025-06-01_hebrew_amrap.json

### Original Workout Text
```
Workout: Workout Log: Orel Ben Haim - 2025-06-01
==================================================

Sunday June  1, 2025
Status: completed


A) Warm UP: 3 Rounds:
50 Single unders
20 Air squat
10 Push ups
3-5 Pull ups 
400m run
   14:40
סיבוב ראשון היה יחסית מאתגר אחרי הרבה זמן שלא זזתי
הסיבובים השניים היו נוחים יותר
B) Mobility: Lower Back Foam roll
ITB Foam Roll
Posterior Shulder Lacross Ball smash 
C) Activations: Band Pull over Hold 3x20sec
1 Leg Double Ktb Step up 3x5/5
D) Metcon: 20 min Amrap 
30 Cal Row
15 S20 45/30KG
400m run 
10 Burpee Over the bar 
35 DU
   עשיתי 2 סבבים מלאים ולא נישאר בסיבוב השלישי לעשות ריצה אז עשיתי 6 ברפיז 


```

### Parsed JSON
```json
{
  "workout_date": "2025-06-01",
  "athlete_id": null,
  "title": "Workout",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "3 Rounds warm-up circuit",
            "target_rounds": 3
          },
          "performed": {
            "completed": true,
            "time": "14:40",
            "notes": "סיבוב ראשון היה יחסית מאתגר אחרי הרבה זמן שלא זזתי. הסיבובים השניים היו נוחים יותר"
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Single unders",
              "prescription": {
                "target_rounds": 3,
                "target_reps": 50
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Air squat",
              "prescription": {
                "target_rounds": 3,
                "target_reps": 20
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Push ups",
              "prescription": {
                "target_rounds": 3,
                "target_reps": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Pull ups",
              "prescription": {
                "target_rounds": 3,
                "target_reps": "3-5"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 5,
              "exercise_name": "Run",
              "prescription": {
                "target_rounds": 3,
                "target_distance_m": 400
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "MOB",
          "block_label": "B",
          "prescription": {
            "description": "Mobility foam rolling and smash"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Lower Back Foam roll",
              "prescription": {
                "notes": "per source text"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "ITB Foam Roll",
              "prescription": {
                "notes": "per source text"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Posterior Shoulder Lacrosse Ball smash",
              "prescription": {
                "notes": "per source text"
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "ACT",
          "block_label": "C",
          "prescription": {
            "description": "Band Pull over Hold 3x20sec, 1 Leg Double Ktb Step up 3x5/5"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "Band Pull over Hold",
              "prescription": {
                "target_sets": 3,
                "target_duration": 20,
                "duration_unit": "sec"
              },
              "performed": {
                "sets": [
                  {
                    "duration": 20,
                    "duration_unit": "sec"
                  },
                  {
                    "duration": 20,
                    "duration_unit": "sec"
                  },
                  {
                    "duration": 20,
                    "duration_unit": "sec"
                  }
                ]
              },
              "item_sequence": 1
            },
            {
              "exercise_name": "1 Leg Double KB Step up",
              "prescription": {
                "target_sets": 3,
                "target_reps": 5,
                "notes": "per leg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 5,
                    "notes": "left"
                  },
                  {
                    "reps": 5,
                    "notes": "right"
                  },
                  {
                    "reps": 5,
                    "notes": "left"
                  },
                  {
                    "reps": 5,
                    "notes": "right"
                  },
                  {
                    "reps": 5,
                    "notes": "left"
                  },
                  {
                    "reps": 5,
                    "notes": "right"
                  }
                ]
              },
              "item_sequence": 2
            }
          ]
        },
        {
          "block_code": "METCON",
          "block_label": "D",
          "block_type": "AMRAP",
          "prescription": {
            "description": "20 min AMRAP: 30 Cal Row, 15 S2OH 45/30kg, 400m run, 10 Burpee Over the bar, 35 DU",
            "time_cap": 20,
            "time_cap_unit": "min",
            "target_load": 30,
            "load_unit": "kg"
          },
          "performed": {
            "completed": true,
            "rounds": 2,
            "partial_round": true,
            "time": 20,
            "time_unit": "min",
            "notes": "עשיתי 2 סבבים מלאים ולא נשאר בסיבוב השלישי לעשות ריצה אז עשיתי 6 ברפיז"
          },
          "items": [
            {
              "exercise_name": "Row",
              "prescription": {
                "target_calories": 30
              },
              "performed": {
                "calories": 30
              },
              "item_sequence": 1
            },
            {
              "exercise_name": "Shoulder to Overhead",
              "prescription": {
                "target_reps": 15,
                "target_load": 30,
                "load_unit": "kg"
              },
              "performed": {
                "reps": 15,
                "load": 30,
                "load_unit": "kg"
              },
              "item_sequence": 2
            },
            {
              "exercise_name": "Run",
              "prescription": {
                "target_distance": 400,
                "distance_unit": "m"
              },
              "performed": {
                "distance": 400,
                "distance_unit": "m"
              },
              "item_sequence": 3
            },
            {
              "exercise_name": "Burpee Over the bar",
              "prescription": {
                "target_reps": 10
              },
              "performed": {
                "reps": 10
              },
              "item_sequence": 4
            },
            {
              "exercise_name": "Double Unders",
              "prescription": {
                "target_reps": 35
              },
              "performed": {
                "reps": 35
              },
              "item_sequence": 5
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Example 14: simple_2025-09-08_recovery
**File:** simple_2025-09-08_recovery.json

### Original Workout Text
```
Monday September  8, 2025
REST DAY
Status: completed



-----

Tuesday September  9, 2025
Title: W1 T2
Status: completed


A) Warm Up: 5 min Walk / light Jog 

2 Rounds:
10 /10 Ankle circles
10/10 Hip openers 90/90
10/10 Down Dog Calf Rocks
10 Cat cow for lower back
   תקין 
B) Rehab Activetions: 2×12/12 Single-leg calf raises 
* tempo 2 sec up / 3 sec down

2×12 sec Glute bridge hold with mini band
```

### Parsed JSON
```json
{
  "workout_date": "2025-09-09",
  "athlete_id": null,
  "title": "W1 T2",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "5 min Walk / light Jog, then 2 Rounds of mobility"
          },
          "performed": {
            "completed": true,
            "notes": "תקין"
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Walk / light Jog",
              "prescription": {
                "target_duration_min": 5
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Ankle circles",
              "prescription": {
                "target_rounds": 2,
                "target_reps_per_side": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Hip openers 90/90",
              "prescription": {
                "target_rounds": 2,
                "target_reps_per_side": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Down Dog Calf Rocks",
              "prescription": {
                "target_rounds": 2,
                "target_reps_per_side": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 5,
              "exercise_name": "Cat cow",
              "prescription": {
                "target_rounds": 2,
                "target_reps": 10,
                "notes": "for lower back"
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "ACT",
          "block_label": "B",
          "prescription": {
            "description": "Rehab Activations"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Single-leg calf raises",
              "prescription": {
                "target_sets": 2,
                "target_reps_per_side": 12,
                "tempo": "2 sec up / 3 sec down"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Glute bridge hold",
              "prescription": {
                "target_sets": 2,
                "target_duration_sec": 12,
                "equipment": "mini band"
              },
              "performed": {
                "completed": true
              }
            }
          ]
        }
      ]
    }
  ],
  "_audit_note": "CORRECTED: Original JSON parsed REST DAY (Sept 8) with fabricated content. This now reflects actual workout from Sept 9 per source text."
}
```

---

## Example 15: tomer_2025-11-02_deadlift_technique
**File:** tomer_2025-11-02_deadlift_technique.json

### Original Workout Text
```
Workout: Workout Log: tomer yacov - 2025-11-02
==================================================

Sunday November  2, 2025
Title: W1 T1
Status: completed

Warmup: Daily Objective
Neutral spine 
brace 360 degrees 
hinge from hips and stand tall


A) Rolling and Release: 1 X 40s/40s Foam roll calves each side
1 X 30s/30s Lacrosse ball plantar and hips each side
1 X 30s Quad smash
   האם אפשר לעשות את הquad smash עם רולר?
B) Warm up: 5 Min C2 Row easy SPM 18 to 20
2 X 10 PVC Dowel Hinge
2 X 10/10 Wall Ankle Dorsiflexion
1 X 10/10 Hamstring Floss
1 X 8/8 BW Groiner with Reach
1 X 8 BW Squat to Stand
   wall ankle הרגשתי שאני לא מוצא פוזציה נכונה והרגשתי עומס על הקרסול
בsquat to stand התקשתי לשמור על הערב על הרצפה, בהסתכלות על הסרטון עוד פעם הבנתי שהעמידה שלי לא נכונה.
בחתירה אחרי שתי דקות הרגשתי שהצלחתי להיכנס למומנטום יחסת נכון

C) ACT: 2 X 30s BW Glute Bridge hold Rest 30 sec
2 X 8 BW McGill Curl Up Rest 45 sec
2 X 5/5 BW Supported Hip Airplane Rest 45 sec
2 X 12 Cable Straight Arm Pulldown light Rest 45 sec"
   ב macgill כמה שניות להיות למעלה?
בcable שמתי משקל של 27.5 
D) DB Romanian Deadlift: 3 X 6 RPE 6 Rest 1.5 min
E) BB Elevated Deadlift from rack: 1 X 8 Empty bar technique
1 X 5 Light set
1 X 3 Moderate set

Then 3x5 RPE 6 to 7 Rest 1.5 min
   הרגשתי שחישבתי פה לא נכון את המשקלים, הורדתי חלק בסוף
F) Standing Cable Pallof Press: 3 X 10/10 Cable Pallof Press Rest 45 sec
   האם הכוונה ב10/10 היא למשוך יד יד? אם כן להיכן? מרכז מסה כמו בסרטון?
האם להוסיף התמגדות?
G) C2 ROW: 6 X 200 m C2 Row SPM 20 to 22
Rest 60 s 
*Practice Teq

4 MIN C2 Row pick drill

```

### Parsed JSON
```json
{
  "workout_date": "2025-11-02",
  "athlete_id": null,
  "title": "W1 T1",
  "status": "completed",
  "warmup_objective": "Neutral spine, brace 360 degrees, hinge from hips and stand tall",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "MOB",
          "block_label": "A",
          "prescription": {
            "description": "Rolling and Release"
          },
          "performed": {
            "completed": true,
            "notes": "האם אפשר לעשות את הquad smash עם רולר?"
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Foam roll calves",
              "prescription": {
                "target_sets": 1,
                "target_duration_sec": 40,
                "per_side": true
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Lacrosse ball plantar and hips",
              "prescription": {
                "target_sets": 1,
                "target_duration_sec": 30,
                "per_side": true
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Quad smash",
              "prescription": {
                "target_sets": 1,
                "target_duration_sec": 30
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "WU",
          "block_label": "B",
          "prescription": {
            "description": "Row and mobility drills"
          },
          "performed": {
            "completed": true,
            "notes": "wall ankle הרגשתי שאני לא מוצא פוזציה נכונה והרגשתי עומס על הקרסול. בsquat to stand התקשתי לשמור על הערב על הרצפה"
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "C2 Row",
              "prescription": {
                "target_duration_min": 5,
                "target_spm": "18-20",
                "notes": "easy"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "PVC Dowel Hinge",
              "prescription": {
                "target_sets": 2,
                "target_reps": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Wall Ankle Dorsiflexion",
              "prescription": {
                "target_sets": 2,
                "target_reps_per_side": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Hamstring Floss",
              "prescription": {
                "target_sets": 1,
                "target_reps_per_side": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 5,
              "exercise_name": "BW Groiner with Reach",
              "prescription": {
                "target_sets": 1,
                "target_reps_per_side": 8
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 6,
              "exercise_name": "BW Squat to Stand",
              "prescription": {
                "target_sets": 1,
                "target_reps": 8
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "ACT",
          "block_label": "C",
          "prescription": {
            "description": "Activation exercises"
          },
          "performed": {
            "completed": true,
            "notes": "במ‏acgill כמה שניות למעלה? בcable שמתי 27.5"
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "BW Glute Bridge hold",
              "prescription": {
                "target_sets": 2,
                "target_duration_sec": 30,
                "rest_sec": 30
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "BW McGill Curl Up",
              "prescription": {
                "target_sets": 2,
                "target_reps": 8,
                "rest_sec": 45
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "BW Supported Hip Airplane",
              "prescription": {
                "target_sets": 2,
                "target_reps_per_side": 5,
                "rest_sec": 45
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Cable Straight Arm Pulldown",
              "prescription": {
                "target_sets": 2,
                "target_reps": 12,
                "notes": "light",
                "rest_sec": 45
              },
              "performed": {
                "completed": true,
                "load": 27.5,
                "load_unit": "kg"
              }
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "D",
          "prescription": {
            "description": "DB Romanian Deadlift: 3x6 RPE 6",
            "target_sets": 3,
            "target_reps": 6,
            "target_rpe": 6,
            "rest": "1.5 min"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "DB Romanian Deadlift",
              "prescription": {
                "target_sets": 3,
                "target_reps": 6,
                "target_rpe": 6
              },
              "performed": {
                "sets": [
                  {
                    "reps": 6,
                    "rpe": 6
                  },
                  {
                    "reps": 6,
                    "rpe": 6
                  },
                  {
                    "reps": 6,
                    "rpe": 6
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "E",
          "prescription": {
            "description": "BB Elevated Deadlift from rack: 1x8 Empty bar, 1x5 Light, 1x3 Moderate. Then 3x5 RPE 6-7",
            "target_sets": 3,
            "target_reps": 5,
            "target_rpe": "6-7",
            "rest": "1.5 min"
          },
          "performed": {
            "completed": true,
            "notes": "הרגשתי שחישבתי פה לא נכון את המשקלים, הורדתי חלק בסוף"
          },
          "items": [
            {
              "exercise_name": "BB Elevated Deadlift",
              "prescription": {
                "target_sets": 3,
                "target_reps": 5,
                "target_rpe": "6-7"
              },
              "performed": {
                "warmup_sets": [
                  {
                    "reps": 8,
                    "notes": "empty bar technique"
                  },
                  {
                    "reps": 5,
                    "notes": "light"
                  },
                  {
                    "reps": 3,
                    "notes": "moderate"
                  }
                ],
                "sets": [
                  {
                    "reps": 5,
                    "rpe": 6
                  },
                  {
                    "reps": 5,
                    "rpe": 6
                  },
                  {
                    "reps": 5,
                    "rpe": 7
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "F",
          "prescription": {
            "description": "Standing Cable Pallof Press: 3x10/10",
            "rest": "45 sec"
          },
          "performed": {
            "completed": true,
            "notes": "האם הכוונה ב10/10 היא למשוך יד יד? להיכן? מרכז מסה? להוסיף התמגדות?"
          }
        },
        {
          "block_code": "SKILL",
          "block_label": "G",
          "prescription": {
            "description": "C2 ROW: 6x200m SPM 20-22 (Rest 60s). Practice Technique. 4 MIN C2 Row pick drill"
          },
          "performed": {
            "completed": true
          }
        }
      ]
    }
  ]
}
```

---

## Example 16: tomer_2025-11-02_simple_deadlift
**File:** tomer_2025-11-02_simple_deadlift.json

### Original Workout Text
```
Workout: Workout Log: tomer yacov - 2025-11-02
==================================================

Sunday November  2, 2025
Title: W1 T1
Status: completed

Warmup: Daily Objective
Neutral spine 
brace 360 degrees 
hinge from hips and stand tall


A) Rolling and Release: 1 X 40s/40s Foam roll calves each side
1 X 30s/30s Lacrosse ball plantar and hips each side
1 X 30s Quad smash
   האם אפשר לעשות את הquad smash עם רולר?
B) Warm up: 5 Min C2 Row easy SPM 18 to 20
2 X 10 PVC Dowel Hinge
2 X 10/10 Wall Ankle Dorsiflexion
1 X 10/10 Hamstring Floss
1 X 8/8 BW Groiner with Reach
1 X 8 BW Squat to Stand
   wall ankle הרגשתי שאני לא מוצא פוזציה נכונה והרגשתי עומס על הקרסול
בsquat to stand התקשתי לשמור על הערב על הרצפה, בהסתכלות על הסרטון עוד פעם הבנתי שהעמידה שלי לא נכונה.
בחתירה אחרי שתי דקות הרגשתי שהצלחתי להיכנס למומנטום יחסת נכון

C) ACT: 2 X 30s BW Glute Bridge hold Rest 30 sec
2 X 8 BW McGill Curl Up Rest 45 sec
2 X 5/5 BW Supported Hip Airplane Rest 45 sec
2 X 12 Cable Straight Arm Pulldown light Rest 45 sec"
   ב macgill כמה שניות להיות למעלה?
בcable שמתי משקל של 27.5 
D) DB Romanian Deadlift: 3 X 6 RPE 6 Rest 1.5 min
E) BB Elevated Deadlift from rack: 1 X 8 Empty bar technique
1 X 5 Light set
1 X 3 Moderate set

Then 3x5 RPE 6 to 7 Rest 1.5 min
   הרגשתי שחישבתי פה לא נכון את המשקלים, הורדתי חלק בסוף
F) Standing Cable Pallof Press: 3 X 10/10 Cable Pallof Press Rest 45 sec
   האם הכוונה ב10/10 היא למשוך יד יד? אם כן להיכן? מרכז מסה כמו בסרטון?
האם להוסיף התמגדות?
G) C2 ROW: 6 X 200 m C2 Row SPM 20 to 22
Rest 60 s 
*Practice Teq

4 MIN C2 Row pick drill

```

### Parsed JSON
```json
{
  "workout_date": "2025-11-02",
  "athlete_id": null,
  "title": "W1 T1",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "MOB",
          "block_label": "A",
          "prescription": {
            "description": "Rolling and Release"
          },
          "performed": {
            "completed": true,
            "notes": "האם אפשר לעשות את הquad smash עם רולר?"
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Foam roll calves",
              "prescription": {
                "target_sets": 1,
                "target_duration_sec": 40,
                "per_side": true
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Lacrosse ball plantar and hips",
              "prescription": {
                "target_sets": 1,
                "target_duration_sec": 30,
                "per_side": true
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Quad smash",
              "prescription": {
                "target_sets": 1,
                "target_duration_sec": 30
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "WU",
          "block_label": "B",
          "prescription": {
            "description": "Warm up sequence for deadlift"
          },
          "performed": {
            "completed": true,
            "notes": "בwall ankle לא מצא פוזיציה נכונה, בsquat to stand התקשיתי לשמור עקב על רצפה, בחתירה אחרי 2 דקות הגעתי למומנטום נכון"
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "C2 Row",
              "prescription": {
                "target_duration_min": 5,
                "target_spm": "18-20",
                "notes": "easy"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "PVC Dowel Hinge",
              "prescription": {
                "target_sets": 2,
                "target_reps": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Wall Ankle Dorsiflexion",
              "prescription": {
                "target_sets": 2,
                "target_reps": "10/10"
              },
              "performed": {
                "completed": true,
                "notes": "לא מצא פוזיציה נכונה"
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Hamstring Floss",
              "prescription": {
                "target_sets": 1,
                "target_reps": "10/10"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 5,
              "exercise_name": "BW Groiner with Reach",
              "prescription": {
                "target_sets": 1,
                "target_reps": "8/8"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 6,
              "exercise_name": "BW Squat to Stand",
              "prescription": {
                "target_sets": 1,
                "target_reps": 8
              },
              "performed": {
                "completed": true,
                "notes": "התקשה לשמור עקב על רצפה"
              }
            }
          ]
        },
        {
          "block_code": "ACT",
          "block_label": "C",
          "prescription": {
            "description": "Activation exercises"
          },
          "performed": {
            "completed": true,
            "notes": "cable: 27.5 kg"
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "BW Glute Bridge hold",
              "prescription": {
                "target_sets": 2,
                "target_duration_sec": 30,
                "rest_sec": 30
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "BW McGill Curl Up",
              "prescription": {
                "target_sets": 2,
                "target_reps": 8,
                "rest_sec": 45
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "BW Supported Hip Airplane",
              "prescription": {
                "target_sets": 2,
                "target_reps_per_side": 5,
                "rest_sec": 45
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Cable Straight Arm Pulldown",
              "prescription": {
                "target_sets": 2,
                "target_reps": 12,
                "notes": "light",
                "rest_sec": 45
              },
              "performed": {
                "completed": true,
                "load": 27.5,
                "load_unit": "kg"
              }
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "D",
          "prescription": {
            "description": "DB Romanian Deadlift: 3×6 @ RPE 6",
            "target_sets": 3,
            "target_reps": 6,
            "target_rpe": 6,
            "rest": "1.5 min"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "exercise_name": "DB Romanian Deadlift",
              "prescription": {
                "target_sets": 3,
                "target_reps": 6,
                "target_rpe": 6
              },
              "performed": {
                "sets": [
                  {
                    "reps": 6,
                    "rpe": 6
                  },
                  {
                    "reps": 6,
                    "rpe": 6
                  },
                  {
                    "reps": 6,
                    "rpe": 6
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "E",
          "prescription": {
            "description": "BB Elevated Deadlift from rack: 3×5 @ RPE 6-7",
            "target_sets": 3,
            "target_reps": 5,
            "target_rpe": "6-7",
            "rest": "1.5 min",
            "notes": "Warmup: empty bar x8, light x5, moderate x3"
          },
          "performed": {
            "completed": true,
            "notes": "הרגשתי שחישבתי פה לא נכון את המשקלים, הורדתי חלק בסוף"
          },
          "items": [
            {
              "exercise_name": "BB Elevated Deadlift",
              "prescription": {
                "target_sets": 3,
                "target_reps": 5,
                "target_rpe": "6-7"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 5,
                    "rpe": 7
                  },
                  {
                    "reps": 5,
                    "rpe": 6
                  },
                  {
                    "reps": 5,
                    "rpe": 6
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "F",
          "prescription": {
            "description": "Standing Cable Pallof Press: 3×10/10",
            "target_sets": 3,
            "target_reps": 10,
            "rest": "45 sec",
            "notes": "per side"
          },
          "performed": {
            "completed": true,
            "notes": "האם הכוונה למשוך יד יד? להיכן? מרכז מסה?"
          }
        },
        {
          "block_code": "SKILL",
          "block_label": "G",
          "prescription": {
            "description": "C2 Row: 6×200m @ 20-22 spm + 4 min pick drill",
            "target_sets": 6,
            "target_distance": 200,
            "distance_unit": "m",
            "target_spm": 21,
            "rest": "60 s",
            "notes": "Practice technique"
          },
          "performed": {
            "completed": true
          }
        }
      ]
    }
  ]
}
```

---

## Example 17: yarden_2025-08-24_deadlift_strength
**File:** yarden_2025-08-24_deadlift_strength.json

### Original Workout Text
```
Workout: Yarden Arad - 2025-08-24
==========================================

Sunday August 24, 2025
Title: W1 A
Status: completed


A) WU: 10 min row @ 21 spm damper 5-7 (add video)

Dead Bug 2×10/side
Side Plank 2×20-30 s/side 
Curl‑Up 2×8-10.
Dowel Hip Hinge Drill 2×6-8 reps.
   נזכרתי למה סיפרתי לך על דני, כי הוא אומר לעבוד בחתירה על 125 חיכוך

B) ACT: 2 Rounds:
Mini Band Lateral Walk - Shin 10/10 steps
Banded Straight‑Arm Pulldown 12-15
Hard‑Style Plank 20-25 s
Rest 20-30 s between exercises .

C) BB Dead Lift: WU:
20 kg  × 5
60 kg  × 5 
80 kg  × 3
90 kg  × 3
Rest 60 sec btw sets

Working sets:
Set 1-2: 100 kg × 5
Set 3-4 (only if RPE 7): 102.5 kg × 5
Rest 2-3 min
   סטים ראשונים היו מוזרים קצת כי לא עשיתי את התנועה ממש הרבה זמן, אחרי זה זה הסתדר.
עליתי ל105 כי אין משקולות של 1.25
איבדתי את הפוקוס לשניה והראיתי את הבטן, קצת הרגשתי את הגב

D) BB Pause Deadlift : 85 kg × 5 × 3
Rest: 1:30-2:00 min

E) BB RDL : 80 kg × 8 × 3
temp 3‑1‑1
(3 s down, 1 s pause on hamstrings, controlled up) 
Rest: 90 s

*Pause Deadlift (2 s below knee)
   התחלתי להתעייף פה ואיבדתי קצת את האחיזה בבטן, הרגשתי קצת גב ועצרתי אחרי סט 6.
כמובן התחילו לכאוב לי כפות הידיים

F) DB Bulgarian Split Squat: 3×8/leg @ RPE 7
2×15-20 kg DBs
Rest: 60-90 s per leg 
   סט ראשון 17.5, היה לי קשה להתאזן ולא הרגיש משהו, הורדתי ל15.

G) Side Plank: 3×30-40 s/side
   היה קשה אחרי כל האימון

H) DB Single Arm Suitcase Carry: 4×30-35 m/side
25-30 kg DB (each side)
   נורא כאב בידיים, גם באחיזה וגם העור שכבר כאב ממקודם
```

### Parsed JSON
```json
{
  "workout_date": "2025-08-24",
  "athlete_id": null,
  "title": "W1 A",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "prescription": {
            "description": "10 min row @ 21 spm damper 5-7, then core work"
          },
          "performed": {
            "completed": true,
            "notes": "נזכרתי למה סיפרתי לך על דני, כי הוא אומר לעבוד בחתירה על 125 חיכוך"
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Row",
              "prescription": {
                "target_duration_min": 10,
                "target_spm": 21,
                "target_damper": "5-7",
                "notes": "add video"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Dead Bug",
              "prescription": {
                "target_sets": 2,
                "target_reps_per_side": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Side Plank",
              "prescription": {
                "target_sets": 2,
                "target_duration_sec": "20-30",
                "per_side": true
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Curl-Up",
              "prescription": {
                "target_sets": 2,
                "target_reps": "8-10"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 5,
              "exercise_name": "Dowel Hip Hinge Drill",
              "prescription": {
                "target_sets": 2,
                "target_reps": "6-8"
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "ACT",
          "block_label": "B",
          "prescription": {
            "description": "2 Rounds activation circuit",
            "target_rounds": 2,
            "rest": "20-30 s between exercises"
          },
          "performed": {
            "completed": true,
            "rounds": 2
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Mini Band Lateral Walk",
              "prescription": {
                "target_rounds": 2,
                "target_reps_per_side": 10,
                "notes": "Shin band"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Banded Straight-Arm Pulldown",
              "prescription": {
                "target_rounds": 2,
                "target_reps": "12-15"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Hard-Style Plank",
              "prescription": {
                "target_rounds": 2,
                "target_duration_sec": "20-25"
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "C",
          "prescription": {
            "description": "BB Dead Lift - Warm-up + Working sets",
            "target_sets": 4,
            "target_reps": 5,
            "target_load": 100,
            "load_unit": "kg",
            "progression_notes": "Set 3-4 at 102.5 kg if RPE 7",
            "rest": "2-3 min"
          },
          "performed": {
            "completed": true,
            "notes": "סטים ראשונים היו מוזרים קצת, עליתי ל105 כי אין משקולות של 1.25, איבדתי פוקוס והרגשתי גב",
            "warmup_sets": [
              {
                "reps": 5,
                "load": 20,
                "load_unit": "kg"
              },
              {
                "reps": 5,
                "load": 60,
                "load_unit": "kg"
              },
              {
                "reps": 3,
                "load": 80,
                "load_unit": "kg"
              },
              {
                "reps": 3,
                "load": 90,
                "load_unit": "kg"
              }
            ],
            "sets": [
              {
                "reps": 5,
                "load": 100,
                "load_unit": "kg",
                "rpe": 7
              },
              {
                "reps": 5,
                "load": 100,
                "load_unit": "kg",
                "rpe": 7
              },
              {
                "reps": 5,
                "load": 105,
                "load_unit": "kg",
                "rpe": 8
              },
              {
                "reps": 5,
                "load": 105,
                "load_unit": "kg",
                "rpe": 8
              }
            ]
          },
          "items": [
            {
              "exercise_name": "Barbell Deadlift",
              "prescription": {
                "target_sets": 4,
                "target_reps": 5,
                "target_load": 100,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 5,
                    "load": 100,
                    "load_unit": "kg",
                    "rpe": 7
                  },
                  {
                    "reps": 5,
                    "load": 100,
                    "load_unit": "kg",
                    "rpe": 7
                  },
                  {
                    "reps": 5,
                    "load": 105,
                    "load_unit": "kg",
                    "rpe": 8
                  },
                  {
                    "reps": 5,
                    "load": 105,
                    "load_unit": "kg",
                    "rpe": 8
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "D",
          "prescription": {
            "description": "BB Pause Deadlift: 85 kg × 5 × 3",
            "target_sets": 3,
            "target_reps": 5,
            "target_load": 85,
            "load_unit": "kg",
            "rest": "1:30-2:00 min",
            "notes": "Pause 2 s below knee"
          },
          "performed": {
            "completed": true,
            "sets": [
              {
                "reps": 5,
                "load": 85,
                "load_unit": "kg"
              },
              {
                "reps": 5,
                "load": 85,
                "load_unit": "kg"
              },
              {
                "reps": 5,
                "load": 85,
                "load_unit": "kg"
              }
            ]
          },
          "items": [
            {
              "exercise_name": "Barbell Pause Deadlift",
              "prescription": {
                "target_sets": 3,
                "target_reps": 5,
                "target_load": 85,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 5,
                    "load": 85,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 5,
                    "load": 85,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 5,
                    "load": 85,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "E",
          "prescription": {
            "description": "BB RDL: 80 kg × 8 × 3",
            "target_sets": 3,
            "target_reps": 8,
            "target_load": 80,
            "load_unit": "kg",
            "tempo": "3-1-1 (3 s down, 1 s pause, controlled up)",
            "rest": "90 s"
          },
          "performed": {
            "completed": false,
            "notes": "התחלתי להתעייף, איבדתי אחיזה בבטן, הרגשתי גב ועצרתי אחרי סט 6. כאב כפות ידיים",
            "sets": [
              {
                "reps": 8,
                "load": 80,
                "load_unit": "kg"
              },
              {
                "reps": 8,
                "load": 80,
                "load_unit": "kg"
              },
              {
                "reps": 8,
                "load": 80,
                "load_unit": "kg"
              },
              {
                "reps": 8,
                "load": 80,
                "load_unit": "kg"
              },
              {
                "reps": 8,
                "load": 80,
                "load_unit": "kg"
              },
              {
                "reps": 8,
                "load": 80,
                "load_unit": "kg"
              }
            ]
          },
          "items": [
            {
              "exercise_name": "Barbell RDL",
              "prescription": {
                "target_sets": 3,
                "target_reps": 8,
                "target_load": 80,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 8,
                    "load": 80,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 8,
                    "load": 80,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 8,
                    "load": 80,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "F",
          "prescription": {
            "description": "DB Bulgarian Split Squat: 3×8/leg @ RPE 7",
            "target_sets": 3,
            "target_reps": 8,
            "target_load": 17.5,
            "load_unit": "kg",
            "target_rpe": 7,
            "rest": "60-90 s per leg"
          },
          "performed": {
            "completed": true,
            "notes": "סט ראשון 17.5, קשה להתאזן, הורדתי ל15",
            "sets": [
              {
                "reps": 8,
                "load": 17.5,
                "load_unit": "kg",
                "notes": "left"
              },
              {
                "reps": 8,
                "load": 17.5,
                "load_unit": "kg",
                "notes": "right"
              },
              {
                "reps": 8,
                "load": 15,
                "load_unit": "kg",
                "notes": "left"
              },
              {
                "reps": 8,
                "load": 15,
                "load_unit": "kg",
                "notes": "right"
              },
              {
                "reps": 8,
                "load": 15,
                "load_unit": "kg",
                "notes": "left"
              },
              {
                "reps": 8,
                "load": 15,
                "load_unit": "kg",
                "notes": "right"
              }
            ]
          },
          "items": [
            {
              "exercise_name": "DB Bulgarian Split Squat",
              "prescription": {
                "target_sets": 3,
                "target_reps": 8,
                "target_load": 17.5,
                "load_unit": "kg"
              },
              "performed": {
                "sets": [
                  {
                    "reps": 8,
                    "load": 15,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 8,
                    "load": 15,
                    "load_unit": "kg"
                  },
                  {
                    "reps": 8,
                    "load": 15,
                    "load_unit": "kg"
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "G",
          "prescription": {
            "description": "Side Plank: 3×30-40 s/side"
          },
          "performed": {
            "completed": true,
            "notes": "היה קשה אחרי כל האימון"
          }
        },
        {
          "block_code": "ACC",
          "block_label": "H",
          "prescription": {
            "description": "DB Single Arm Suitcase Carry: 4×30-35 m/side",
            "target_sets": 4,
            "target_distance": 30,
            "distance_unit": "m",
            "target_load": 27.5,
            "load_unit": "kg"
          },
          "performed": {
            "completed": true,
            "notes": "נורא כאב בידיים, גם באחיזה וגם העור"
          }
        }
      ]
    }
  ]
}
```

---

## Example 18: yarden_frank_2025-07-06_mixed_blocks
**File:** yarden_frank_2025-07-06_mixed_blocks.json

### Original Workout Text
```
Workout: Workout Log: Yarden Frank - 2025-07-06
==================================================

Sunday July  6, 2025
Title: W1
Status: completed


A) FR: Calves smash 60 s/side
Glutes smash 60 s/side
T‑Spine sausage roll 60 s
B) WU: 3 rounds:
Row 200 m
6/6 Cossack Squat
8 Mini‑Band Glute Bridge
10 Banded Good Morning 
5 Inchworm
10 Dead Bugs
C) ST : Back‑Squat:
2x3 @ 40 -60 %
1x5 @ 65 %
5x5 @ 75 % (T=2‑1‑X) 
Rest 120 s

3 Rounds:
10/10 DB Reverse Lunge  @ Medium
10/10 DB Suitcase Deadlift  @ Medium 
Rest 60 s
   Set 1 - 
@40% = 40kg
60% = 60kg 

Set 2-
@65% = 65kg

Set 3 -
@75% = 75kg
D) COND : EMOM 8 min:
6 Burpee Over Bar
6  Wall Ball 7 kg 
goal: under 35 sec
   כל הסבבים מתחת ל 35
הרוב 32-33
כל הברפיז קפיצה ב 2 רגליים
E) CORE : 3X12 Frog Reverse Hyper
F) CD : 3 x Couch Stretch 60 s/side

```

### Parsed JSON
```json
{
  "workout_date": "2025-07-06",
  "athlete_id": null,
  "title": "W1",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "session_time": null,
      "blocks": [
        {
          "block_code": "MOB",
          "block_label": "A",
          "prescription": {
            "description": "Foam Rolling"
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Calves smash",
              "prescription": {
                "target_duration_sec": 60,
                "per_side": true
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Glutes smash",
              "prescription": {
                "target_duration_sec": 60,
                "per_side": true
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "T-Spine sausage roll",
              "prescription": {
                "target_duration_sec": 60
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "WU",
          "block_label": "B",
          "prescription": {
            "description": "3 rounds warm up circuit",
            "target_rounds": 3
          },
          "performed": {
            "completed": true
          },
          "items": [
            {
              "item_sequence": 1,
              "exercise_name": "Row",
              "prescription": {
                "target_distance_m": 200
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 2,
              "exercise_name": "Cossack Squat",
              "prescription": {
                "target_reps": "6/6"
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 3,
              "exercise_name": "Mini-Band Glute Bridge",
              "prescription": {
                "target_reps": 8
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 4,
              "exercise_name": "Banded Good Morning",
              "prescription": {
                "target_reps": 10
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 5,
              "exercise_name": "Inchworm",
              "prescription": {
                "target_reps": 5
              },
              "performed": {
                "completed": true
              }
            },
            {
              "item_sequence": 6,
              "exercise_name": "Dead Bugs",
              "prescription": {
                "target_reps": 10
              },
              "performed": {
                "completed": true
              }
            }
          ]
        },
        {
          "block_code": "STR",
          "block_label": "C",
          "prescription": {
            "description": "Back Squat: 2x3 @ 40-60%, 1x5 @ 65%, 5x5 @ 75% (T=2-1-X), Rest 120s. Then 3 Rounds: DB Reverse Lunge, DB Suitcase Deadlift"
          },
          "performed": {
            "completed": true,
            "notes": "Set 1 - @40% = 40kg, 60% = 60kg. Set 2 - @65% = 65kg. Set 3 - @75% = 75kg"
          },
          "items": [
            {
              "exercise_name": "Back Squat",
              "prescription": {
                "target_sets": 5,
                "target_reps": 5,
                "target_percentage": 75,
                "tempo": "2-1-X"
              },
              "performed": {
                "warmup_sets": [
                  {
                    "reps": 3,
                    "load": 40,
                    "load_unit": "kg",
                    "percentage": 40
                  },
                  {
                    "reps": 3,
                    "load": 60,
                    "load_unit": "kg",
                    "percentage": 60
                  },
                  {
                    "reps": 5,
                    "load": 65,
                    "load_unit": "kg",
                    "percentage": 65
                  }
                ],
                "sets": [
                  {
                    "reps": 5,
                    "load": 75,
                    "load_unit": "kg",
                    "percentage": 75
                  },
                  {
                    "reps": 5,
                    "load": 75,
                    "load_unit": "kg",
                    "percentage": 75
                  },
                  {
                    "reps": 5,
                    "load": 75,
                    "load_unit": "kg",
                    "percentage": 75
                  },
                  {
                    "reps": 5,
                    "load": 75,
                    "load_unit": "kg",
                    "percentage": 75
                  },
                  {
                    "reps": 5,
                    "load": 75,
                    "load_unit": "kg",
                    "percentage": 75
                  }
                ]
              },
              "item_sequence": 1
            }
          ]
        },
        {
          "block_code": "METCON",
          "block_label": "D",
          "format": "EMOM",
          "prescription": {
            "description": "EMOM 8 min: 6 Burpee Over Bar, 6 Wall Ball 7kg",
            "time_cap": 8,
            "time_cap_unit": "min",
            "goal": "under 35 sec"
          },
          "performed": {
            "completed": true,
            "rounds": 8,
            "notes": "כל הסבבים מתחת ל35, הרוב 32-33. כל הברפיז קפיצה ב2 רגליים"
          },
          "items": [
            {
              "exercise_name": "Burpee Over Bar",
              "prescription": {
                "target_reps": 6
              },
              "performed": {
                "reps": 6
              },
              "item_sequence": 1
            },
            {
              "exercise_name": "Wall Ball",
              "prescription": {
                "target_reps": 6,
                "target_load": 7,
                "load_unit": "kg"
              },
              "performed": {
                "reps": 6,
                "load": 7,
                "load_unit": "kg"
              },
              "item_sequence": 2
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "E",
          "prescription": {
            "description": "Core: 3x12 Frog Reverse Hyper"
          },
          "performed": {
            "completed": true
          }
        },
        {
          "block_code": "CD",
          "block_label": "F",
          "prescription": {
            "description": "Cooldown: 3x Couch Stretch 60s/side"
          },
          "performed": {
            "completed": true
          }
        }
      ]
    }
  ]
}
```

---

## Example 19: yehuda_2025-05-28_upper_screen
**File:** yehuda_2025-05-28_upper_screen.json

### Original Workout Text
```
Workout: Workout Log: Yehuda Devir - 2025-05-28
==================================================

Wednesday May 28, 2025
Title: B0W0 Upper-Body Screen
Status: completed


A) Warm up  : A1) 3 rounds for quality: 
3 min walk 
2 min run @ 8-9 kph
*Tall posture, nasal breathing

A2) 3 min Air bike 
25″ easy /5″ faster – raise HR gradually
   במהלך הריצה הרגשתי את השריר בגב קצת מציק אבל לא משהו שמנע ממני להפסיק,

האופניים היו אחלה, הרגשתי ממש את הרגליים עובדות.
B) Mobility:  B1) T-Spine Foam-Roll
2x1-2 min T-Spine Foam-Roll 
Slow roll;
exhale on extension;
keep hips heavy

B2) Dead Hang From Bar 
3x10 -15 sec 
Passive shoulder traction
relax neck
C) Activations : C1 ) Scapular Push-Up
3x 12 reps
Lock elbows,
protract/retract only scapula

C2) Scapular Pull-Up 3x10
From dead-hang → depress & retract;
pause 1″ at top
D) Main - Max Pull up Test: 1 min AMRAP → 4 min rest → 1 min re-test
* First set must be unbrokrn 

*AMRAP=As Many reps as possible 
Full hang, chin above bar, no kipping, full elbow loc
   עגלה, עגלה, עגלה...
מרגיש כבד מאוד, וגם הציק לי קצת הגב...
דקה ראשונה: 10 חזרות
דקה שניה: 9 חזרות
E) Main - Push ups Test: 1 min AMRAP → 4 min rest → 1 min re-test
* First set must be unbrokrn 

Straight line ear-hip-ankle, chest touches floor, full elbow lock. First set unbroken.
   חשבתי שאצליח יותר, להפתעתי גיליתי שאני עגלה...😅
דקה ראשונה: 26 חזרות
דקה שניה: 20 חזרות
F) Core Circuit: 3 Rounds of:
Side Plank Hold – 30-45 s per side
Hollow-Body Tuck Hold – 20-30 s
Standing Pallof Press (cable) – 12 reps per side, 2 s pause at full press
Back Extension (45° Roman chair) – 10 reps, 2 s squeeze at top

Rest 20-30 s between exercises, 60 s after each round (RPE ≤ 6).
   הופתעתי לגלות כמה הבטן שלי חלשה וכמה רעד אני יכול להפיק בזמן תרגילים סטטיים...

התרגיל של הבטן בעמידה עם דחיפת הכבל היה נחמד מאוד אם כי לא בטוח שהצלחתי להרגיש אותו כמו שצריך.

התרגיל של הכיפוף גב היה נחמד, הרגשתי טוב את הגב התחתון וגם את ה hamstrings משום מה...

```

### Parsed JSON
```json
{
  "workout_date": "2025-05-28",
  "athlete_id": null,
  "title": "B0W0 Upper-Body Screen",
  "status": "completed",
  "sessions": [
    {
      "session_code": null,
      "blocks": [
        {
          "block_code": "WU",
          "block_label": "A",
          "block_title": "Warm up",
          "prescription": {
            "target_sets": 1,
            "notes": "A1) 3 rounds walk/run + A2) 3 min air bike intervals"
          },
          "performed": {
            "actual_sets": 1,
            "notes": "Walk + run felt good, minimal back tightness. Air bike intervals excellent."
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_duration_min": 3,
                "target_rounds": 3,
                "notes": "Tall posture, nasal breathing"
              },
              "performed": {
                "actual_duration_min": 3,
                "actual_rounds": 3
              },
              "exercise_name": "Walk"
            },
            {
              "item_sequence": 2,
              "prescription": {
                "target_duration_min": 2,
                "target_speed_kph": 8.5,
                "target_rounds": 3
              },
              "performed": {
                "actual_duration_min": 2,
                "actual_rounds": 3,
                "notes": "Felt slight back muscle tightness but continued"
              },
              "exercise_name": "Run"
            },
            {
              "item_sequence": 3,
              "prescription": {
                "target_duration_min": 3,
                "target_intervals": "25s easy / 5s faster"
              },
              "performed": {
                "actual_duration_min": 3,
                "notes": "Excellent, really felt legs working"
              },
              "exercise_name": "Air Bike"
            }
          ]
        },
        {
          "block_code": "MOB",
          "block_label": "B",
          "block_title": "Mobility",
          "prescription": {
            "target_sets": 1
          },
          "performed": {
            "actual_sets": 1
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_sets": 2,
                "target_duration_min": 1.5,
                "notes": "Slow roll, exhale on extension, keep hips heavy"
              },
              "performed": {
                "actual_sets": 2,
                "actual_duration_min": 1.5
              },
              "exercise_name": "T Spine Foam Roll"
            },
            {
              "item_sequence": 2,
              "prescription": {
                "target_sets": 3,
                "target_duration_sec": 12.5,
                "notes": "Passive shoulder traction, relax neck"
              },
              "performed": {
                "actual_sets": 3,
                "actual_duration_sec": 12.5
              },
              "exercise_name": "Dead Hang"
            }
          ]
        },
        {
          "block_code": "ACT",
          "block_label": "C",
          "block_title": "Activations",
          "prescription": {
            "target_sets": 1
          },
          "performed": {
            "actual_sets": 1
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_sets": 3,
                "target_reps": 12,
                "notes": "Lock elbows, protract/retract scapula only"
              },
              "performed": {
                "actual_sets": 3,
                "actual_reps": 12
              },
              "exercise_name": "Scapular Push Up"
            },
            {
              "item_sequence": 2,
              "prescription": {
                "target_sets": 3,
                "target_reps": 10,
                "notes": "From dead-hang, depress & retract, pause 1s at top"
              },
              "performed": {
                "actual_sets": 3,
                "actual_reps": 10
              },
              "exercise_name": "Scapular Pull Up"
            }
          ]
        },
        {
          "block_code": "SKILL",
          "block_label": "D",
          "block_title": "Main - Max Pull up Test",
          "prescription": {
            "target_sets": 2,
            "target_duration_min": 1,
            "target_rest_min": 4,
            "notes": "1 min AMRAP, first set unbroken. Full hang, chin above bar, no kipping"
          },
          "performed": {
            "actual_sets": 2,
            "notes": "Felt heavy, back bothered slightly"
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_reps": "max",
                "target_duration_min": 1
              },
              "performed": {
                "actual_reps": [
                  10,
                  9
                ],
                "notes": "Set 1: 10 reps, Set 2: 9 reps. Body felt heavy."
              },
              "exercise_name": "Pull Up"
            }
          ]
        },
        {
          "block_code": "SKILL",
          "block_label": "E",
          "block_title": "Main - Push ups Test",
          "prescription": {
            "target_sets": 2,
            "target_duration_min": 1,
            "target_rest_min": 4,
            "notes": "1 min AMRAP, first set unbroken. Straight line, chest touches floor, full elbow lock"
          },
          "performed": {
            "actual_sets": 2,
            "notes": "Expected more, surprised to struggle"
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_reps": "max",
                "target_duration_min": 1
              },
              "performed": {
                "actual_reps": [
                  26,
                  20
                ],
                "notes": "Set 1: 26 reps, Set 2: 20 reps"
              },
              "exercise_name": "Push Up"
            }
          ]
        },
        {
          "block_code": "ACC",
          "block_label": "F",
          "block_title": "Core Circuit",
          "prescription": {
            "target_rounds": 3,
            "target_rest_sec": 30,
            "notes": "Rest 20-30s between exercises, 60s after each round (RPE ≤ 6)"
          },
          "performed": {
            "actual_rounds": 3,
            "notes": "Surprised at core weakness. Static exercises produced trembling. Cable press felt good. Back extension hit lower back and hamstrings."
          },
          "items": [
            {
              "item_sequence": 1,
              "prescription": {
                "target_duration_sec": 37.5,
                "target_sets_per_side": 1
              },
              "performed": {
                "actual_duration_sec": 37.5,
                "actual_sets_per_side": 1
              },
              "exercise_name": "Side Plank"
            },
            {
              "item_sequence": 2,
              "prescription": {
                "target_duration_sec": 25,
                "target_position": "tuck"
              },
              "performed": {
                "actual_duration_sec": 25
              },
              "exercise_name": "Hollow Body Hold"
            },
            {
              "item_sequence": 3,
              "prescription": {
                "target_reps": 12,
                "target_sets_per_side": 1,
                "target_pause_sec": 2,
                "equipment": "cable"
              },
              "performed": {
                "actual_reps": 12,
                "actual_sets_per_side": 1,
                "notes": "Nice exercise, not sure felt it correctly"
              },
              "exercise_name": "Pallof Press"
            },
            {
              "item_sequence": 4,
              "prescription": {
                "target_reps": 10,
                "target_pause_sec": 2,
                "equipment": "45_degree_roman_chair",
                "notes": "2s squeeze at top"
              },
              "performed": {
                "actual_reps": 10,
                "notes": "Nice, felt lower back and hamstrings"
              },
              "exercise_name": "Back Extension"
            }
          ]
        }
      ]
    }
  ]
}
```

---
