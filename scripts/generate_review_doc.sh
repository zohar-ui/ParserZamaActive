#!/bin/bash
# ============================================
# Golden Set Review Document Generator
# ============================================
# Creates unified review document with all golden JSONs
# Format: Original Text → Parsed JSON for each workout

OUTPUT_FILE="data/golden_set/GOLDEN_SET_REVIEW.md"

echo "🔍 Generating Golden Set Review Document..."
echo ""

# Create header
cat > "$OUTPUT_FILE" << 'EOF'
# Golden Set Review Document
**Parser Quality Assurance - Complete Reference Set**

Generated: $(date '+%Y-%m-%d %H:%M:%S')  
Total Golden Examples: 19

---

## Purpose

This document contains all golden reference examples for parser regression testing.  
Each example includes:
1. **Original Workout Text** (as written by coach/athlete)
2. **Parsed JSON Output** (expected correct structure)

These serve as ground truth for measuring parser accuracy.

---

EOF

# Counter
count=0

# Process each JSON file
for json_file in data/golden_set/*.json; do
    # Skip if doesn't exist
    [ -f "$json_file" ] || continue
    
    count=$((count + 1))
    basename=$(basename "$json_file" .json)
    txt_file="data/golden_set/${basename}.txt"
    
    echo "Processing [$count/19]: $basename"
    
    # Add section header
    cat >> "$OUTPUT_FILE" << EOF

## Example $count: $basename

**File:** \`$basename.json\`

### Original Workout Text

EOF

    # Add original text if exists
    if [ -f "$txt_file" ]; then
        echo '```' >> "$OUTPUT_FILE"
        cat "$txt_file" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
    else
        echo "_Original text file not available. Extract from source workout log._" >> "$OUTPUT_FILE"
    fi
    
    # Add parsed JSON
    cat >> "$OUTPUT_FILE" << EOF

### Parsed JSON

\`\`\`json
EOF
    
    cat "$json_file" >> "$OUTPUT_FILE"
    
    cat >> "$OUTPUT_FILE" << 'EOF'
```

---

EOF

done

# Add footer with statistics
cat >> "$OUTPUT_FILE" << EOF

## Summary Statistics

- **Total Examples:** 19
- **With Original Text:** 4
- **Coverage:**
  - Block Types: WU, MOB, ACT, STR, ACC, SKILL, INTV, METCON, SS, CD, REHAB
  - Languages: English, Hebrew
  - Complexity: 4-9 blocks per workout
  - Special Features: AMRAP, For Time, Tempo, RPE tracking, Rehabilitation protocols

## Next Steps

1. **Manual Review:** Verify each JSON matches original text intent
2. **Validation:** Run all through \`validate_parsed_workout()\`
3. **Regression Testing:** Use as baseline for parser accuracy tests
4. **Training Data:** Export corrections to improve AI model

---

**Document Generated:** $(date '+%Y-%m-%d %H:%M:%S')  
**Project:** ParserZamaActive  
**Version:** 1.0
EOF

echo ""
echo "✅ Review document created: $OUTPUT_FILE"
echo "📄 Total examples processed: $count"
echo ""
echo "Open with: cat $OUTPUT_FILE | less"
