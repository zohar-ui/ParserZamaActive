# Golden Set - Parser Test Reference

## Purpose
This directory contains **approved, validated JSON outputs** that serve as the "ground truth" for parser testing.

## How It Works

### 1. Creating Golden Set
When you have a workout that parsed perfectly:
1. Parse the workout text
2. Run validation - ensure it passes
3. Manually review the JSON
4. If perfect, copy to this directory with meaningful name

### 2. Naming Convention
```
<athlete_name>_<date>_<workout_type>.json

Examples:
- bader_2025-09-07_strength.json
- yarden_2025-10-15_metcon.json
```

### 3. Test Coverage Goals
Aim for at least **10 golden files** covering:
- ✅ Strength workouts (STR blocks)
- ✅ METCON workouts (AMRAP, For Time)
- ✅ Interval training (INTV blocks)
- ✅ Mixed sessions (multiple blocks)
- ✅ Edge cases (Hebrew text, unusual formats)

## Usage

### Run Test Suite
```bash
./scripts/test_parser_accuracy.sh
```

This will:
1. Load all `.txt` files from `/data/`
2. Parse them automatically
3. Compare output to golden JSONs
4. Report accuracy score

### Expected Score
- **95%+** = Production ready ✅
- **90-95%** = Good, minor issues ⚠️
- **<90%** = Needs work ❌

## Maintenance

### When to Update
- After fixing a parser bug
- When adding new block types
- After schema changes

### How to Update
1. Re-parse the workout
2. Validate the new output
3. If better, replace the golden file
4. Document the change in git commit

## Current Golden Set

**Status:** ✅ PRODUCTION READY (Audited 2026-01-09)

| Stat | Count |
|------|-------|
| Files | 19 |
| Blocks | 119 |
| Items | 204 |
| Unique Exercises | 123 |

### Files Included:
- `arnon_2025-11-09_foundation_control.json` - Foundation & Control workout
- `arnon_2025-11-09_shoulder_rehab.json` - Shoulder rehab focus
- `bader_2025-09-07_running_intervals.json` - Running intervals
- `example_workout_golden.json` - Basic 3-block workout (WU, STR, CD)
- `itamar_2025-06-21_rowing_skill.json` - Rowing skill session
- `jonathan_2025-08-17_lower_body_fortime.json` - Lower body For Time
- `jonathan_2025-08-17_lower_fortime.json` - Lower body For Time (alt)
- `jonathan_2025-08-19_upper_amrap.json` - Upper body AMRAP
- `jonathan_2025-08-24_lower_body_amrap.json` - Lower body AMRAP
- `melany_2025-09-14_mixed_complex.json` - Mixed complex workout
- `melany_2025-09-14_rehab_strength.json` - Rehab & strength
- `orel_2025-06-01_amrap_hebrew_notes.json` - AMRAP with Hebrew notes
- `orel_2025-06-01_hebrew_amrap.json` - Hebrew AMRAP
- `simple_2025-09-08_recovery.json` - Recovery workout
- `tomer_2025-11-02_deadlift_technique.json` - Deadlift technique
- `tomer_2025-11-02_simple_deadlift.json` - Simple deadlift
- `yarden_2025-08-24_deadlift_strength.json` - Deadlift strength
- `yarden_frank_2025-07-06_mixed_blocks.json` - Mixed blocks
- `yehuda_2025-05-28_upper_screen.json` - Upper body screen

### Related Documentation
- `GOLDEN_SET_REVIEW.md` - Full text + JSON for each example
- `GOLDEN_SET_AUDIT_REPORT.md` - Audit findings and corrections
