#!/bin/bash

# schema_change_checklist.sh
# Interactive checklist for schema changes to ensure all docs are updated

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         📝 Schema Change Documentation Checklist              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "When making schema changes, ensure ALL these are updated:"
echo ""

# Function to check if file was modified recently (last 5 minutes)
check_recent_update() {
    local file=$1
    if [ -f "$file" ]; then
        local mod_time=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
        local now=$(date +%s)
        local diff=$((now - mod_time))
        
        if [ $diff -lt 300 ]; then
            echo "✅"
        else
            echo "⏸️ "
        fi
    else
        echo "❌"
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Core Schema Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

STATUS=$(check_recent_update "data/golden_set/*.json")
echo "$STATUS data/golden_set/*.json"
echo "      └─ Update golden set examples with new pattern"

STATUS=$(check_recent_update "supabase/migrations/*.sql")
echo "$STATUS supabase/migrations/*.sql"
echo "      └─ Add migration if schema changed in DB"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Parser Documentation (Stage 2)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

STATUS=$(check_recent_update "docs/guides/STAGE2_PARSING_STRATEGY.md")
echo "$STATUS docs/guides/STAGE2_PARSING_STRATEGY.md"
echo "      └─ Update parsing patterns (דפוסים)"

STATUS=$(check_recent_update "docs/guides/PARSER_WORKFLOW.md")
echo "$STATUS docs/guides/PARSER_WORKFLOW.md"
echo "      └─ Update workflow if process changed"

STATUS=$(check_recent_update "docs/guides/AI_PROMPTS.md")
echo "$STATUS docs/guides/AI_PROMPTS.md"
echo "      └─ Update AI prompts with new examples"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Validation Documentation (Stage 3)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

STATUS=$(check_recent_update "docs/guides/PARSER_AUDIT_CHECKLIST.md")
echo "$STATUS docs/guides/PARSER_AUDIT_CHECKLIST.md"
echo "      └─ Update validation rules"

STATUS=$(check_recent_update "docs/VALIDATION_SYSTEM_SUMMARY.md")
echo "$STATUS docs/VALIDATION_SYSTEM_SUMMARY.md"
echo "      └─ Update validation system docs"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Project Metadata"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

STATUS=$(check_recent_update "CHANGELOG.md")
echo "$STATUS CHANGELOG.md"
echo "      └─ Add entry with version bump"

STATUS=$(check_recent_update "docs/INDEX.md")
echo "$STATUS docs/INDEX.md"
echo "      └─ Update documentation index"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Migration Guide (for breaking changes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if there's a migration guide for today
TODAY=$(date +%Y-%m-%d)
MIGRATION_GUIDE="docs/guides/SCHEMA_UPDATES_${TODAY}.md"

if [ -f "$MIGRATION_GUIDE" ]; then
    STATUS=$(check_recent_update "$MIGRATION_GUIDE")
    echo "$STATUS $MIGRATION_GUIDE"
else
    echo "⏸️  docs/guides/SCHEMA_UPDATES_${TODAY}.md"
fi
echo "      └─ Create migration guide for breaking changes"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Validation & Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "   Run these commands:"
echo ""
echo "   ./scripts/validate_golden_set_schema_v2.sh"
echo "   ./scripts/test_parser_accuracy.sh"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Legend:"
echo "  ✅ = Updated in last 5 minutes"
echo "  ⏸️  = Needs review/update"
echo "  ❌ = File not found"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  TIP: Run this script after every schema change!              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
