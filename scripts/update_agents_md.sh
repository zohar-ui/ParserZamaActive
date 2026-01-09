#!/bin/bash
# ============================================
# Update agents.md with Current Schema
# ============================================
# Purpose: Keep agents.md in sync with actual database schema
# Usage: ./scripts/update_agents_md.sh
# Can be used as pre-commit hook

set -e  # Exit on error

AGENTS_FILE="agents.md"
TEMP_FILE="/tmp/agents_schema_update.txt"

echo "🔄 Updating agents.md with current schema..."

# ============================================
# 1. Fetch Current Table List
# ============================================
echo "📊 Fetching table list from Supabase..."

PGPASSWORD="4vdO7rUINWkz061R" psql \
    -h db.dtzcamerxuonoeujrgsu.supabase.co \
    -U postgres \
    -d postgres \
    --pset=pager=off \
    --tuples-only \
    -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'zamm' AND table_type = 'BASE TABLE' ORDER BY table_name;" \
    > "$TEMP_FILE"

# Count tables
TABLE_COUNT=$(wc -l < "$TEMP_FILE" | tr -d ' ')

echo "✅ Found $TABLE_COUNT tables"

# ============================================
# 2. Generate Schema Summary
# ============================================
SCHEMA_SUMMARY="### Key Database Tables ($TABLE_COUNT total in zamm schema)

**📋 Current Tables (Auto-generated on $(date '+%Y-%m-%d %H:%M')):**

\`\`\`
$(cat "$TEMP_FILE" | sed 's/^/ - /' | sed 's/ *$//')
\`\`\`

**Table Categories:**
"

# Count by prefix
LIB_COUNT=$(grep -c "^ lib_" "$TEMP_FILE" || echo 0)
STG_COUNT=$(grep -c "^ stg_" "$TEMP_FILE" || echo 0)
LOG_COUNT=$(grep -c "^ log_" "$TEMP_FILE" || echo 0)
WORKOUT_COUNT=$(grep -c "^ workout_" "$TEMP_FILE" || echo 0)
RES_COUNT=$(grep -c "^ res_" "$TEMP_FILE" || echo 0)
CFG_COUNT=$(grep -c "^ cfg_" "$TEMP_FILE" || echo 0)
EVT_COUNT=$(grep -c "^ evt_" "$TEMP_FILE" || echo 0)
DIM_COUNT=$(grep -c "^ dim_" "$TEMP_FILE" || echo 0)

SCHEMA_SUMMARY+="
- **lib_*** (Libraries/Catalogs): $LIB_COUNT tables
- **stg_*** (Staging): $STG_COUNT tables  
- **log_*** (Logging): $LOG_COUNT tables
- **workout_*** (Core Workouts): $WORKOUT_COUNT tables
- **res_*** (Results): $RES_COUNT tables
- **cfg_*** (Configuration): $CFG_COUNT tables
- **evt_*** (Events): $EVT_COUNT tables
- **dim_*** (Dimensions): $DIM_COUNT tables
"

# ============================================
# 3. Update agents.md
# ============================================
# Note: This is a simple approach that appends.
# For production, use more sophisticated text replacement.

echo ""
echo "📝 Schema summary generated:"
echo "$SCHEMA_SUMMARY"
echo ""
echo "⚠️  Manual step required:"
echo "   Update the 'Key Database Tables' section in agents.md"
echo "   with the content above."
echo ""
echo "💡 Tip: In future, use sed/awk to auto-replace the section"

# Cleanup
rm -f "$TEMP_FILE"

echo "✅ Schema check complete!"
