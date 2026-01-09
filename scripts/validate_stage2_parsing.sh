#!/bin/bash
# ============================================
# Stage 2 Parser Validation Script
# ============================================
# בודק את הדוגמאות ב-Golden Set מול כללי האסטרטגיה
# Usage: ./scripts/validate_stage2_parsing.sh

set -e

GOLDEN_DIR="data/golden_set"
ISSUES_FOUND=0

echo "============================================"
echo "   Stage 2 Parser Validation"
echo "============================================"
echo ""

# צבעים
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# פונקציות בדיקה
# ============================================

check_hallucinated_uuid() {
    local file=$1
    local uuids=$(grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' "$file" 2>/dev/null || true)
    
    if [ -n "$uuids" ]; then
        echo -e "  ${RED}❌ CRITICAL: Hallucinated UUID found${NC}"
        echo "     UUIDs: $uuids"
        return 1
    fi
    return 0
}

check_hallucinated_session_code() {
    local json_file=$1
    local txt_file="${json_file%.json}.txt"
    
    # Check if session_code exists and is not null
    local session_code=$(grep -oP '"session_code":\s*"[^"]*"' "$json_file" 2>/dev/null || true)
    
    if [ -n "$session_code" ]; then
        # Check if source text has time indication
        if [ -f "$txt_file" ]; then
            if ! grep -qiE '\b(AM|PM|morning|afternoon|evening|בוקר|ערב)\b' "$txt_file"; then
                echo -e "  ${RED}❌ CRITICAL: session_code without source evidence${NC}"
                echo "     Found: $session_code"
                return 1
            fi
        fi
    fi
    return 0
}

check_athlete_id_null() {
    local file=$1
    
    # athlete_id should be null
    if grep -qE '"athlete_id":\s*"[0-9a-f-]+"' "$file"; then
        echo -e "  ${RED}❌ CRITICAL: athlete_id should be null${NC}"
        return 1
    fi
    
    if grep -qE '"athlete_id":\s*null' "$file"; then
        echo -e "  ${GREEN}✓ athlete_id is null${NC}"
    fi
    return 0
}

check_item_sequence() {
    local file=$1
    
    # Check if items have item_sequence
    local items_count=$(grep -c '"item_sequence"' "$file" 2>/dev/null || echo "0")
    
    if [ "$items_count" -eq 0 ]; then
        echo -e "  ${YELLOW}⚠ WARNING: No item_sequence found${NC}"
        return 1
    else
        echo -e "  ${GREEN}✓ item_sequence present ($items_count items)${NC}"
    fi
    return 0
}

check_exercise_name_field() {
    local file=$1
    
    # Should use exercise_name, not exercise_key
    if grep -qE '"exercise_key"' "$file"; then
        echo -e "  ${RED}❌ ERROR: Using exercise_key instead of exercise_name${NC}"
        return 1
    fi
    
    local names_count=$(grep -c '"exercise_name"' "$file" 2>/dev/null || echo "0")
    if [ "$names_count" -gt 0 ]; then
        echo -e "  ${GREEN}✓ exercise_name used correctly ($names_count exercises)${NC}"
    fi
    return 0
}

check_prescription_not_empty() {
    local file=$1
    
    # Check for empty prescription objects
    if grep -qE '"prescription":\s*\{\s*\}' "$file"; then
        echo -e "  ${YELLOW}⚠ WARNING: Empty prescription object found${NC}"
        return 1
    fi
    return 0
}

check_hebrew_in_performed() {
    local file=$1
    
    # Hebrew text should be in performed.notes, not prescription
    # This is a heuristic check
    local prescription_hebrew=$(grep -A5 '"prescription"' "$file" | grep -oP '[\u0590-\u05FF]+' 2>/dev/null | head -1 || true)
    
    if [ -n "$prescription_hebrew" ]; then
        echo -e "  ${YELLOW}⚠ WARNING: Hebrew text in prescription (should be in performed)${NC}"
        return 1
    fi
    return 0
}

# ============================================
# Main validation loop
# ============================================

echo "Scanning JSON files in $GOLDEN_DIR..."
echo ""

for json_file in "$GOLDEN_DIR"/*.json; do
    if [ ! -f "$json_file" ]; then
        continue
    fi
    
    filename=$(basename "$json_file")
    
    # Skip non-workout files
    if [[ "$filename" == *"README"* ]] || [[ "$filename" == *"AUDIT"* ]] || [[ "$filename" == *"REVIEW"* ]]; then
        continue
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📄 $filename"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    file_issues=0
    
    # Run all checks
    check_hallucinated_uuid "$json_file" || ((file_issues++))
    check_athlete_id_null "$json_file" || ((file_issues++))
    check_hallucinated_session_code "$json_file" || ((file_issues++))
    check_item_sequence "$json_file" || ((file_issues++))
    check_exercise_name_field "$json_file" || ((file_issues++))
    check_prescription_not_empty "$json_file" || ((file_issues++))
    
    if [ $file_issues -eq 0 ]; then
        echo -e "  ${GREEN}✅ All checks passed${NC}"
    else
        ISSUES_FOUND=$((ISSUES_FOUND + file_issues))
    fi
    
    echo ""
done

# ============================================
# Summary
# ============================================

echo "============================================"
echo "   SUMMARY"
echo "============================================"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ All files passed validation!${NC}"
    echo ""
    echo "Golden Set is ready for Stage 2 testing."
else
    echo -e "${RED}❌ Found $ISSUES_FOUND issues across all files${NC}"
    echo ""
    echo "Please fix issues before using Golden Set as reference."
fi

echo ""
echo "============================================"

exit $ISSUES_FOUND
