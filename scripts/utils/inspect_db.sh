#!/bin/bash
# scripts/utils/inspect_db.sh
# Purpose: Single source of truth for table structure
# Usage: ./scripts/utils/inspect_db.sh <table_name>

table_name=$1

if [ -z "$table_name" ]; then
  echo "Error: No table name provided"
  echo "Usage: ./scripts/utils/inspect_db.sh <table_name>"
  echo "Example: ./scripts/utils/inspect_db.sh workout_blocks"
  exit 1
fi

# Check if SUPABASE_DB_URL is set
if [ -z "$SUPABASE_DB_URL" ]; then
  echo "Error: SUPABASE_DB_URL environment variable not set"
  exit 1
fi

echo "Inspecting table: zamm.$table_name"
echo "================================================"

psql "$SUPABASE_DB_URL" -c "
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'zamm'
  AND table_name = '$table_name'
ORDER BY ordinal_position;
"

# Also check if table exists
exists=$(psql "$SUPABASE_DB_URL" -t -c "
SELECT EXISTS (
  SELECT FROM information_schema.tables
  WHERE table_schema = 'zamm'
    AND table_name = '$table_name'
);
")

if [[ "$exists" == *"f"* ]]; then
  echo ""
  echo "⚠️  WARNING: Table 'zamm.$table_name' does NOT exist!"
  echo "Available tables in zamm schema:"
  psql "$SUPABASE_DB_URL" -c "
  SELECT table_name
  FROM information_schema.tables
  WHERE table_schema = 'zamm'
  ORDER BY table_name;
  "
  exit 1
fi
