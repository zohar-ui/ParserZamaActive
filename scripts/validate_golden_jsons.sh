#!/bin/bash
# validate_golden_jsons.sh - Test validation on all golden JSONs

set -euo pipefail

GOLDEN_DIR="/workspaces/ParserZamaActive/data/golden_set"
TEMP_SQL="/tmp/validate_golden.sql"

echo "🧪 Testing Validation on Golden JSONs..."
echo "========================================="
echo ""

# Count files
json_count=$(find "$GOLDEN_DIR" -name "*.json" -type f | wc -l)
echo "📊 Found $json_count golden JSON files"
echo ""

# Test each JSON
pass_count=0
fail_count=0

for json_file in "$GOLDEN_DIR"/*.json; do
    filename=$(basename "$json_file")
    echo "Testing: $filename"
    
    # Read JSON content and escape for SQL
    json_content=$(cat "$json_file" | jq -c '.')
    
    # Create SQL query
    cat > "$TEMP_SQL" <<EOSQL
SELECT 
    validation_status,
    error_count,
    warning_count,
    errors,
    warnings
FROM zamm.validate_parsed_workout(
    json_content := '$json_content'::jsonb
);
EOSQL
    
    # Execute via Supabase CLI (linked connection)
    result=$(npx supabase db execute --file "$TEMP_SQL" 2>&1 || echo "ERROR")
    
    if echo "$result" | grep -q "ERROR"; then
        echo "  ❌ FAILED - SQL execution error"
        echo "  $result"
        ((fail_count++))
    elif echo "$result" | grep -q "validation_status.*PASS"; then
        echo "  ✅ PASS"
        ((pass_count++))
    else
        echo "  ⚠️  UNKNOWN - Check output:"
        echo "  $result"
        ((fail_count++))
    fi
    
    echo ""
done

# Summary
echo "========================================="
echo "📈 Summary:"
echo "  ✅ Passed: $pass_count/$json_count"
echo "  ❌ Failed: $fail_count/$json_count"
echo ""

if [ $fail_count -eq 0 ]; then
    echo "🎉 All golden JSONs validated successfully!"
    exit 0
else
    echo "⚠️  Some validations failed. Review output above."
    exit 1
fi
