# Sample Workout Logs

This directory contains 10 real workout logs used for testing and development.

## Files Overview

| File | Size | Lines | Description |
|------|------|-------|-------------|
| bader_workout_log.txt | 5KB | 238 | Small sample for quick testing |
| Workout Log: Arnon Shafir.txt | 23KB | 1,117 | Medium-sized log |
| Workout Log: Jonathan benamou.txt | 34KB | 2,065 | Medium-sized log |
| Workout Log: Melany Zyman.txt | 71KB | 3,577 | Large log with varied formats |
| Workout Log: Orel Ben Haim.txt | 88KB | 4,521 | Large comprehensive log |
| Workout Log: Yarden Arad.txt | 97KB | 4,388 | Large comprehensive log |
| Workout Log: Yarden Frank.txt | 70KB | 3,406 | Large log with varied formats |
| Workout Log: Yehuda Devir.txt | 75KB | 3,696 | Large log with varied formats |
| Workout Log: itamar shatnay.txt | 124KB | 5,207 | **Largest** - most comprehensive |
| Workout Log: tomer yacov.txt | 38KB | 1,565 | Medium-sized log |

**Total:** ~640KB, 29,780 lines

## Usage

### Quick Test
Use `bader_workout_log.txt` for rapid testing (238 lines only).

### Comprehensive Test
Use `Workout Log: itamar shatnay.txt` for testing edge cases (5,207 lines).

### Integration Testing
Process all 10 files to test parser robustness across different:
- Athletes
- Workout styles
- Text formats
- Language mixing (Hebrew + English)
- Date formats
- Block structures

## Format Notes

These logs contain:
- Free-form workout text
- Mixed Hebrew and English
- Various date formats
- Prescription + performance data
- Coach notes and athlete feedback
- Block types: Strength, Metcon, Warm-up, Accessory, etc.
- Exercise variations and aliases

## Testing Strategy

1. **Unit Test**: Parse `bader_workout_log.txt` (fast)
2. **Integration Test**: Parse 3-4 medium logs (representative sample)
3. **Stress Test**: Parse all 10 logs (comprehensive validation)

## Privacy Note

These logs contain real athlete data. Use only for development and testing purposes. Do not share publicly without athlete consent.
