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

- `example_workout_golden.json` - Basic 3-block workout (WU, STR, CD)

**TODO:** Add 9 more real workouts from `/data/` folder.
