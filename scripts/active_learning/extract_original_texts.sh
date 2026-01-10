#!/bin/bash
# ============================================
# Extract Original Texts for Golden Set
# ============================================
# Extracts workout text from source logs based on dates in golden JSONs

set -e

GOLDEN_DIR="data/golden_set"
DATA_DIR="data"

echo "📝 Extracting original workout texts..."
echo "======================================="
echo ""

extracted=0
skipped=0

# Process each golden JSON
for json_file in "$GOLDEN_DIR"/*.json; do
    basename=$(basename "$json_file" .json)
    
    # Skip examples
    if [[ "$basename" == "example_"* ]] || [[ "$basename" == "GOLDEN_"* ]]; then
        continue
    fi
    
    txt_file="$GOLDEN_DIR/${basename}.txt"
    
    # Skip if already exists
    if [ -f "$txt_file" ]; then
        echo "⏭️  Skip: $basename (already exists)"
        skipped=$((skipped + 1))
        continue
    fi
    
    # Extract athlete name and date from filename
    athlete_name=$(echo "$basename" | cut -d'_' -f1)
    workout_date=$(echo "$basename" | cut -d'_' -f2)
    
    # Find matching workout log file
    log_file=""
    
    # Try different filename patterns
    for pattern in \
        "$DATA_DIR/${athlete_name}_workout_log.txt" \
        "$DATA_DIR/Workout Log: ${athlete_name}*.txt" \
        "$DATA_DIR/Workout Log: $(echo $athlete_name | sed 's/.*/\u&/')*.txt"; do
        
        matches=$(ls $pattern 2>/dev/null | head -1)
        if [ -n "$matches" ]; then
            log_file="$matches"
            break
        fi
    done
    
    if [ -z "$log_file" ]; then
        echo "⚠️  Warn: $basename - no source log found for athlete '$athlete_name'"
        continue
    fi
    
    # Extract date in different formats (YYYY-MM-DD, Month DD, etc)
    year=$(echo "$workout_date" | cut -d'-' -f1)
    month=$(echo "$workout_date" | cut -d'-' -f2)
    day=$(echo "$workout_date" | cut -d'-' -f3)
    
    # Month name
    case $month in
        01) month_name="January" ;;
        02) month_name="February" ;;
        03) month_name="March" ;;
        04) month_name="April" ;;
        05) month_name="May" ;;
        06) month_name="June" ;;
        07) month_name="July" ;;
        08) month_name="August" ;;
        09) month_name="September" ;;
        10) month_name="October" ;;
        11) month_name="November" ;;
        12) month_name="December" ;;
    esac
    
    # Remove leading zero from day
    day_num=$(echo "$day" | sed 's/^0*//')
    
    # Search patterns
    date_pattern1="$month_name $day_num, $year"      # "September 7, 2025"
    date_pattern2="$month_name  $day_num, $year"     # "September  7, 2025" (double space)
    
    # Find the workout section
    temp_extract="/tmp/workout_extract_$$.txt"
    
    # Try to extract from date marker to next date or separator
    awk -v date1="$date_pattern1" -v date2="$date_pattern2" '
        $0 ~ date1 || $0 ~ date2 { found=1; print; next }
        found && /^-----$/ { exit }
        found && /^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)/ && NR > start+5 { exit }
        found { print; if (NR==1) start=NR }
    ' "$log_file" > "$temp_extract"
    
    if [ -s "$temp_extract" ] && [ $(wc -l < "$temp_extract") -gt 10 ]; then
        # Add header
        {
            echo "Workout Log: $(basename "$log_file" .txt) - $workout_date"
            echo "=============================================="
            echo ""
            cat "$temp_extract"
        } > "$txt_file"
        
        line_count=$(wc -l < "$txt_file")
        echo "✅ Extract: $basename ($line_count lines)"
        extracted=$((extracted + 1))
    else
        echo "⚠️  Warn: $basename - couldn't extract workout for date $date_pattern1"
    fi
    
    rm -f "$temp_extract"
done

echo ""
echo "📊 Summary"
echo "=========="
echo "Extracted: $extracted new files"
echo "Skipped:   $skipped existing files"
echo ""
echo "✅ Done! Now regenerate review document:"
echo "   ./scripts/generate_review_doc.sh"
