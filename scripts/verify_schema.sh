#!/bin/bash
# ============================================
# Schema Verification Script
# ============================================
# Purpose: Always run BEFORE writing SQL
# Prevents assumptions about table/column names
# Usage: ./scripts/verify_schema.sh [table_name]

set -e

# Load DB password from .env.local
if [ -f .env.local ]; then
    export $(grep SUPABASE_DB_PASSWORD .env.local | xargs)
fi

DB_HOST="db.dtzcamerxuonoeujrgsu.supabase.co"
DB_USER="postgres"
DB_NAME="postgres"

if [ -z "$SUPABASE_DB_PASSWORD" ]; then
    echo "❌ Error: SUPABASE_DB_PASSWORD not found in .env.local"
    exit 1
fi

echo "🔍 Verifying ZAMM Schema..."
echo ""

# If table name provided, show its structure
if [ -n "$1" ]; then
    echo "📋 Table: zamm.$1"
    echo "─────────────────────────────────"
    PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h $DB_HOST -U $DB_USER -d $DB_NAME --pset=pager=off -c "
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns
        WHERE table_schema = 'zamm' 
          AND table_name = '$1'
        ORDER BY ordinal_position;
    "
else
    # Show all tables
    echo "📊 All Tables in ZAMM Schema:"
    echo "─────────────────────────────────"
    PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h $DB_HOST -U $DB_USER -d $DB_NAME --pset=pager=off -t -A -c "
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'zamm' 
        ORDER BY table_name;
    " | nl
    echo ""
    echo "💡 Tip: Run ./scripts/verify_schema.sh TABLE_NAME for details"
fi

echo ""
echo "✅ Schema verification complete"
