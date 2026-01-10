#!/bin/bash

# validate_golden_set_schema_v2.sh
# Validates that all golden set JSON files follow schema v2 rules

set -euo pipefail

GOLDEN_SET_DIR="/workspaces/ParserZamaActive/data/golden_set"
ERRORS=0
WARNINGS=0

echo "🔍 Validating Golden Set Schema v2 Compliance"
echo "=============================================="
echo ""

# Rule #1: No prescription_if_* anywhere
echo "Rule #1: Checking for prescription_if_* patterns..."
if grep -r "prescription_if_" "$GOLDEN_SET_DIR"/*.json 2>/dev/null; then
    echo "❌ FAIL: Found prescription_if_* pattern (not scalable!)"
    ((ERRORS++))
else
    echo "✅ PASS: No prescription_if_* found"
fi
echo ""

# Rule #2: No target_rounds in item prescriptions
echo "Rule #2: Checking for target_rounds in wrong places..."
SUSPICIOUS_FILES=$(grep -l '"target_rounds"' "$GOLDEN_SET_DIR"/*.json 2>/dev/null || true)

if [ -n "$SUSPICIOUS_FILES" ]; then
    echo "⚠️  Found target_rounds in files (checking context):"
    for file in $SUSPICIOUS_FILES; do
        filename=$(basename "$file")
        
        # Check if it's in circuit_config (OK) or block prescription (OK)
        if grep -B5 '"target_rounds"' "$file" | grep -q '"circuit_config"\|"block_code"\|"structure"'; then
            echo "  ✅ $filename - OK (block-level or circuit_config)"
        else
            echo "  ❌ $filename - FAIL (item-level target_rounds not allowed!)"
            ((ERRORS++))
        fi
    done
else
    echo "✅ PASS: No target_rounds found (or only in valid contexts)"
fi
echo ""

# Rule #3: exercise_options must be array of objects
echo "Rule #3: Checking exercise_options structure..."
# This is trickier - we need to check if exercise_options exists and is array of strings
if grep -r '"exercise_options"' "$GOLDEN_SET_DIR"/*.json 2>/dev/null | grep -q '\["[^{]'; then
    echo "❌ FAIL: Found exercise_options as array of strings (should be array of objects!)"
    grep -r '"exercise_options"' "$GOLDEN_SET_DIR"/*.json | grep '\["[^{]' || true
    ((ERRORS++))
else
    echo "✅ PASS: All exercise_options are array of objects"
fi
echo ""

# Rule #4: circuit_config should have rounds, type, rest_between_rounds_sec
echo "Rule #4: Checking circuit_config structure..."
CIRCUIT_FILES=$(grep -l '"circuit_config"' "$GOLDEN_SET_DIR"/*.json 2>/dev/null || true)

if [ -n "$CIRCUIT_FILES" ]; then
    echo "Found circuits in $(echo "$CIRCUIT_FILES" | wc -l) files"
    
    for file in $CIRCUIT_FILES; do
        filename=$(basename "$file")
        
        # Check if circuit_config has required fields
        if ! grep -A5 '"circuit_config"' "$file" | grep -q '"rounds"'; then
            echo "  ⚠️  $filename - Missing 'rounds' in circuit_config"
            ((WARNINGS++))
        fi
        
        if ! grep -A5 '"circuit_config"' "$file" | grep -q '"type"'; then
            echo "  ⚠️  $filename - Missing 'type' in circuit_config"
            ((WARNINGS++))
        fi
    done
    
    if [ $WARNINGS -eq 0 ]; then
        echo "✅ PASS: All circuit_configs have required fields"
    fi
else
    echo "ℹ️  No circuits found in golden set"
fi
echo ""

# Summary
echo "=============================================="
echo "📊 Validation Summary"
echo "=============================================="
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo "✅ Golden Set is Schema v2 Compliant!"
    exit 0
else
    echo "❌ Golden Set has Schema v2 violations!"
    exit 1
fi
