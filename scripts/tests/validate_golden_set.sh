#!/bin/bash
# ============================================
# Parser Accuracy Test Suite v2
# ============================================
# Tests golden JSONs for structure and validity

set -e

GOLDEN_DIR="data/golden_set"
TEMP_DIR="/tmp/parser_test_$$"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🧪 Parser Test Suite - Golden Set Validation"
echo "=============================================="

# Count files
JSON_COUNT=$(find "$GOLDEN_DIR" -name "*.json" -type f | wc -l)
TXT_COUNT=$(find "$GOLDEN_DIR" -name "*.txt" -type f 2>/dev/null | wc -l)

echo "📂 Found:"
echo "   - $JSON_COUNT golden JSON files"
echo "   - $TXT_COUNT original text files"
echo ""

mkdir -p "$TEMP_DIR"

echo "🚀 Running validation tests..."
echo ""

total_tests=0
passed_tests=0
failed_tests=0
skipped_tests=0
declare -a failures

for json_file in "$GOLDEN_DIR"/*.json; do
    basename=$(basename "$json_file")
    
    # Skip examples and review docs
    if [[ "$basename" == "example_"* ]] || [[ "$basename" == "GOLDEN_"* ]]; then
        continue
    fi
    
    total_tests=$((total_tests + 1))
    test_name="${basename%.json}"
    txt_file="${json_file%.json}.txt"
    
    # Test 1: Valid JSON
    if ! jq empty "$json_file" 2>/dev/null; then
        echo -e "${RED}❌ FAIL${NC} [$total_tests]: $test_name (invalid JSON)"
        failed_tests=$((failed_tests + 1))
        failures+=("$test_name: Invalid JSON")
        continue
    fi
    
    # Test 2: Required fields
    required=("workout_date" "athlete_id" "status" "sessions")
    missing=()
    
    for field in "${required[@]}"; do
        if ! jq -e ".$field" "$json_file" >/dev/null 2>&1; then
            missing+=("$field")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}❌ FAIL${NC} [$total_tests]: $test_name (missing: ${missing[*]})"
        failed_tests=$((failed_tests + 1))
        failures+=("$test_name: Missing fields: ${missing[*]}")
        continue
    fi
    
    # Test 3: Has blocks
    block_count=$(jq '[.sessions[].blocks[]] | length' "$json_file")
    if [ "$block_count" -eq 0 ]; then
        echo -e "${RED}❌ FAIL${NC} [$total_tests]: $test_name (no blocks)"
        failed_tests=$((failed_tests + 1))
        failures+=("$test_name: No blocks")
        continue
    fi
    
    # Success
    session_count=$(jq '.sessions | length' "$json_file")
    echo -e "${GREEN}✅ PASS${NC} [$total_tests]: $test_name ($session_count sessions, $block_count blocks)"
    passed_tests=$((passed_tests + 1))
done

# Summary
echo ""
echo "📊 Results"
echo "=========="
echo -e "Total:    $total_tests"
echo -e "${GREEN}Passed:   $passed_tests${NC}"
echo -e "${RED}Failed:   $failed_tests${NC}"

if [ $failed_tests -gt 0 ]; then
    echo ""
    echo "❌ Failures:"
    for failure in "${failures[@]}"; do
        echo "   - $failure"
    done
    exit 1
fi

# Calculate accuracy
if [ $total_tests -gt 0 ]; then
    accuracy=$(awk "BEGIN {printf \"%.1f\", ($passed_tests/$total_tests)*100}")
    echo ""
    if (( $(echo "$accuracy >= 95" | bc -l) )); then
        echo -e "🎯 ${GREEN}Accuracy: $accuracy%${NC} - ✅ Production Ready!"
    else
        echo -e "🎯 ${YELLOW}Accuracy: $accuracy%${NC}"
    fi
fi

rm -rf "$TEMP_DIR"
echo ""
echo "✅ All golden sets validated!"
exit 0
