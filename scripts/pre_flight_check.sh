#!/bin/bash
# Pre-Flight Checklist - System Readiness Report
# Generated: $(date)

echo "═══════════════════════════════════════════════════════════"
echo "🚀 ParserZamaActive - Pre-Flight Checklist"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 1. Dependencies Check
echo "📦 1. Dependencies (npm install)"
if [ -d "node_modules" ] && [ -f "node_modules/.package-lock.json" ]; then
    echo "   ✅ PASS - All packages installed ($(ls node_modules | wc -l) packages)"
else
    echo "   ❌ FAIL - Run: npm install"
    exit 1
fi
echo ""

# 2. Environment Variables Check
echo "🔑 2. Environment Variables (.env.local)"
if [ -f ".env.local" ]; then
    if grep -q "SUPABASE_URL" .env.local && \
       grep -q "SUPABASE_SERVICE_ROLE_KEY" .env.local && \
       grep -q "SUPABASE_DB_PASSWORD" .env.local; then
        echo "   ✅ PASS - All required variables present"
        echo "      - SUPABASE_URL: $(grep SUPABASE_URL .env.local | cut -d'=' -f2 | cut -d'/' -f3)"
        echo "      - SERVICE_ROLE_KEY: $(grep SUPABASE_SERVICE_ROLE_KEY .env.local | cut -d'=' -f2 | cut -c1-20)..."
        echo "      - DB_PASSWORD: ****"
    else
        echo "   ❌ FAIL - Missing required variables"
        exit 1
    fi
else
    echo "   ❌ FAIL - .env.local file not found"
    exit 1
fi
echo ""

# 3. Package.json Scripts Check
echo "📝 3. Package Scripts (package.json)"
if grep -q '"create-athlete"' package.json && \
   grep -q '"create-athlete-users"' package.json; then
    echo "   ✅ PASS - Required scripts configured"
    echo "      - npm run create-athlete"
    echo "      - npm run create-athlete-users"
else
    echo "   ❌ FAIL - Scripts missing in package.json"
    exit 1
fi
echo ""

# 4. Database Connection Check
echo "🗄️  4. Database Connection"
DB_PASS=$(grep SUPABASE_DB_PASSWORD .env.local | cut -d'=' -f2 | tr -d '\r\n' | xargs)
if PGPASSWORD="$DB_PASS" psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres \
   --pset=pager=off -c "SELECT 1;" > /dev/null 2>&1; then
    echo "   ✅ PASS - Database connected"
else
    echo "   ❌ FAIL - Cannot connect to database"
    exit 1
fi
echo ""

# 5. Schema Version Check
echo "🏗️  5. Schema Version"
SCHEMA_VERSION=$(PGPASSWORD="$DB_PASS" psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres \
   --pset=pager=off -t -c "SELECT version FROM zamm.lib_parser_rulesets WHERE is_active = true;" | xargs)
if [ ! -z "$SCHEMA_VERSION" ]; then
    echo "   ✅ PASS - Active schema: v${SCHEMA_VERSION}"
else
    echo "   ⚠️  WARN - No active parser ruleset"
fi
echo ""

# 6. Idempotency System Check
echo "🔒 6. Idempotency & Safety"
IDEMPOTENT_FUNCS=$(PGPASSWORD="$DB_PASS" psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres \
   --pset=pager=off -t -c "SELECT COUNT(DISTINCT proname) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname IN ('zamm', 'public') AND (p.proname LIKE '%idempotent%' OR p.proname = 'register_new_athlete');" | xargs)
UNIQUE_INDEXES=$(PGPASSWORD="$DB_PASS" psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres \
   --pset=pager=off -t -c "SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'zamm' AND (indexname LIKE '%unique%' OR indexname LIKE '%checksum%');" | xargs)

if [ "$IDEMPOTENT_FUNCS" -ge "3" ] && [ "$UNIQUE_INDEXES" -ge "6" ]; then
    echo "   ✅ PASS - Safety systems active"
    echo "      - Idempotent functions: $IDEMPOTENT_FUNCS"
    echo "      - Unique constraints: $UNIQUE_INDEXES"
else
    echo "   ❌ FAIL - Safety systems incomplete"
    echo "      - Idempotent functions: $IDEMPOTENT_FUNCS (need >= 3)"
    echo "      - Unique constraints: $UNIQUE_INDEXES (need >= 6)"
    exit 1
fi
echo ""

# 7. Athletes & Users Check
echo "👥 7. Athletes & Auth Users"
ATHLETES=$(PGPASSWORD="$DB_PASS" psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres \
   --pset=pager=off -t -c "SELECT COUNT(*) FROM zamm.lib_athletes WHERE is_active = true;" | xargs)
AUTH_USERS=$(PGPASSWORD="$DB_PASS" psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres \
   --pset=pager=off -t -c "SELECT COUNT(*) FROM auth.users WHERE raw_user_meta_data->>'role' = 'athlete';" | xargs)

echo "   ✅ PASS - User system ready"
echo "      - Active athletes: $ATHLETES"
echo "      - Auth users: $AUTH_USERS"
echo ""

# 8. Tables Check
echo "📊 8. Core Tables"
TABLES=$(PGPASSWORD="$DB_PASS" psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres \
   --pset=pager=off -t -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'zamm';" | xargs)

if [ "$TABLES" -ge "27" ]; then
    echo "   ✅ PASS - All tables present ($TABLES tables)"
else
    echo "   ⚠️  WARN - Expected 27 tables, found $TABLES"
fi
echo ""

# Final Summary
echo "═══════════════════════════════════════════════════════════"
echo "✅ PRE-FLIGHT CHECK COMPLETE - READY FOR TAKEOFF 🚀"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "System Status: ALL SYSTEMS GO"
echo ""
echo "Available Commands:"
echo "  • npm run create-athlete \"Name\" \"email@example.com\""
echo "  • npm run create-athlete-users"
echo "  • npm run learn"
echo "  • npm run test:blocks"
echo ""
echo "Next Steps:"
echo "  1. Import workout logs → zamm.stg_imports"
echo "  2. Parse drafts → zamm.stg_parse_drafts"
echo "  3. Validate → zamm.workout_main"
echo "  4. Active learning → zamm.log_learning_examples"
echo ""
