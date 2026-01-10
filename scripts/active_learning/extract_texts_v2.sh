#!/bin/bash
# ============================================
# Extract Original Texts - Manual Mapping
# ============================================

set -e

GOLDEN_DIR="data/golden_set"
DATA_DIR="data"

# Athlete name mapping (golden_prefix -> log_file)
declare -A ATHLETE_MAP
ATHLETE_MAP["arnon"]="data/Workout Log: Arnon Shafir.txt"
ATHLETE_MAP["bader"]="data/bader_workout_log.txt"
ATHLETE_MAP["itamar"]="data/Workout Log: itamar shatnay.txt"
ATHLETE_MAP["jonathan"]="data/Workout Log: Jonathan benamou.txt"
ATHLETE_MAP["melany"]="data/Workout Log: Melany Zyman.txt"
ATHLETE_MAP["orel"]="data/Workout Log: Orel Ben Haim.txt"
ATHLETE_MAP["simple"]="data/bader_workout_log.txt"  # Simple is from Bader
ATHLETE_MAP["tomer"]="data/Workout Log: tomer yacov.txt"
ATHLETE_MAP["yarden"]="data/Workout Log: Yarden Arad.txt"
ATHLETE_MAP["yarden_frank"]="data/Workout Log: Yarden Frank.txt"
ATHLETE_MAP["yehuda"]="data/Workout Log: Yehuda Devir.txt"

echo "📝 Extracting original workout texts..."
echo "======================================="
echo ""

extracted=0
skipped=0
failed=0

for json_file in "$GOLDEN_DIR"/*.json; do
    basename=$(basename "$json_file" .json)
    
    # Skip examples
    if [[ "$basename" == "example_"* ]] || [[ "$basename" == "GOLDEN_"* ]]; then
        continue
    fi
    
    txt_file="$GOLDEN_DIR/${basename}.txt"
    
    # Skip if exists
    if [ -f "$txt_file" ]; then
        echo "⏭️  Skip: $basename"
        skipped=$((skipped + 1))
        continue
    fi
    
    # Extract athlete prefix (first part before date)
    if [[ "$basename" =~ ^([a-z_]+)_([0-9]{4}-[0-9]{2}-[0-9]{2})_ ]]; then
        athlete_prefix="${BASH_REMATCH[1]}"
        workout_date="${BASH_REMATCH[2]}"
    else
        echo "⚠️  Warn: $basename - couldn't parse filename"
        failed=$((failed + 1))
        continue
    fi
    
    # Get log file
    log_file="${ATHLETE_MAP[$athlete_prefix]}"
    
    if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
        echo "⚠️  Warn: $basename - no log file for '$athlete_prefix'"
        failed=$((failed + 1))
        continue
    fi
    
    # Parse date
    year=$(echo "$workout_date" | cut -d'-' -f1)
    month=$(echo "$workout_date" | cut -d'-' -f2)
    day=$(echo "$workout_date" | cut -d'-' -f3)
    
    # Month names
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
    
    day_num=$(echo "$day" | sed 's/^0*//')
    
    # Search patterns
    date_pattern="$month_name  *$day_num, $year"
    
    # Extract workout
    temp="/tmp/extract_$$.txt"
    
    awk -v pattern="$date_pattern" '
        $0 ~ pattern { 
            found=1
            start_line=NR
            print
            next
        }
        found && /^-----$/ { 
            exit 
        }
        found && /^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday) (January|February|March|April|May|June|July|August|September|October|November|December)/ && NR > start_line + 10 { 
            exit 
        }
        found { 
            print 
        }
    ' "$log_file" > "$temp"
    
    if [ -s "$temp" ] && [ $(wc -l < "$temp") -gt 5 ]; then
        {
            echo "Workout: $(basename "${log_file%.txt}") - $workout_date"
            echo "=========================================="
            echo ""
            cat "$temp"
        } > "$txt_file"
        
        lines=$(wc -l < "$txt_file")
        echo "✅ Extract: $basename ($lines lines from $(basename "$log_file"))"
        extracted=$((extracted + 1))
    else
        echo "⚠️  Fail: $basename - couldn't find workout for $date_pattern"
        failed=$((failed + 1))
    fi
    
    rm -f "$temp"
done

echo ""
echo "📊 Summary"
echo "=========="
echo "Extracted: $extracted"
echo "Skipped:   $skipped"
echo "Failed:    $failed"
echo ""

if [ $extracted -gt 0 ]; then
    echo "✅ Success! Now regenerate review:"
    echo "   ./scripts/generate_review_doc.sh"
fi
