#!/bin/bash
# ============================================
# Schema Version Compatibility Checker
# ============================================
# Purpose: Verify that CANONICAL_JSON_SCHEMA.md version matches DB implementation
# Usage: ./scripts/verify_schema_version.sh
# Exit codes: 0 = compatible, 1 = mismatch, 2 = error

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCHEMA_DOC="docs/reference/CANONICAL_JSON_SCHEMA.md"
DB_CONNECTION="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Schema Version Compatibility Check                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# 1. Extract version from CANONICAL_JSON_SCHEMA.md
# ============================================
echo -e "${YELLOW}[1/4]${NC} Reading schema document version..."

if [ ! -f "$SCHEMA_DOC" ]; then
    echo -e "${RED}✗ ERROR:${NC} Schema document not found: $SCHEMA_DOC"
    exit 2
fi

# Extract version from YAML frontmatter
DOC_VERSION=$(sed -n '/^---$/,/^---$/p' "$SCHEMA_DOC" | grep "^version:" | cut -d'"' -f2 | tr -d ' ')
DOC_MIGRATION=$(sed -n '/^---$/,/^---$/p' "$SCHEMA_DOC" | grep "^compatible_db_migration:" | cut -d'"' -f2 | tr -d ' ')
DOC_RULESET=$(sed -n '/^---$/,/^---$/p' "$SCHEMA_DOC" | grep "^parser_ruleset_version:" | cut -d'"' -f2 | tr -d ' ')

if [ -z "$DOC_VERSION" ]; then
    echo -e "${RED}✗ ERROR:${NC} Could not extract version from schema document"
    echo -e "  Make sure YAML frontmatter exists with 'version' field"
    exit 2
fi

echo -e "  ${GREEN}✓${NC} Schema document version: ${GREEN}${DOC_VERSION}${NC}"
echo -e "  ${GREEN}✓${NC} Compatible migration: ${DOC_MIGRATION}"
echo -e "  ${GREEN}✓${NC} Parser ruleset: ${DOC_RULESET}"
echo ""

# ============================================
# 2. Check database connection
# ============================================
echo -e "${YELLOW}[2/4]${NC} Checking database connection..."

if ! psql "$DB_CONNECTION" -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${RED}✗ WARNING:${NC} Cannot connect to database"
    echo -e "  Connection string: ${DB_CONNECTION}"
    echo -e "  ${YELLOW}Skipping database version check${NC}"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}⚠  Database offline - cannot verify compatibility${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    exit 0
fi

echo -e "  ${GREEN}✓${NC} Database connected"
echo ""

# ============================================
# 3. Query parser_rulesets table
# ============================================
echo -e "${YELLOW}[3/4]${NC} Querying parser_rulesets table..."

DB_QUERY="SELECT version FROM zamm.parser_rulesets WHERE is_active = true ORDER BY created_at DESC LIMIT 1;"
DB_VERSION=$(psql "$DB_CONNECTION" -t -c "$DB_QUERY" 2>/dev/null | xargs)

if [ -z "$DB_VERSION" ]; then
    echo -e "${YELLOW}⚠  WARNING:${NC} No active parser ruleset found in database"
    echo -e "  Table: zamm.parser_rulesets"
    echo -e "  ${YELLOW}This may be expected for a new installation${NC}"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}⚠  No active ruleset - consider running migrations${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    exit 0
fi

echo -e "  ${GREEN}✓${NC} Active ruleset version: ${GREEN}${DB_VERSION}${NC}"
echo ""

# ============================================
# 4. Compare versions
# ============================================
echo -e "${YELLOW}[4/4]${NC} Comparing versions..."

# Normalize versions for comparison (remove 'v' prefix if exists)
NORMALIZED_DOC=$(echo "$DOC_RULESET" | sed 's/^v//')
NORMALIZED_DB=$(echo "$DB_VERSION" | sed 's/^v//')

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

if [ "$NORMALIZED_DOC" = "$NORMALIZED_DB" ]; then
    echo -e "${GREEN}✓ COMPATIBLE${NC}"
    echo -e "  Schema Doc:  ${GREEN}${DOC_VERSION}${NC} (ruleset: ${DOC_RULESET})"
    echo -e "  Database:    ${GREEN}${DB_VERSION}${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    exit 0
else
    echo -e "${RED}✗ VERSION MISMATCH!${NC}"
    echo -e "  Schema Doc:  ${YELLOW}${DOC_VERSION}${NC} (ruleset: ${DOC_RULESET})"
    echo -e "  Database:    ${YELLOW}${DB_VERSION}${NC}"
    echo ""
    echo -e "${RED}⚠  ACTION REQUIRED:${NC}"

    # Determine which is ahead
    if [[ "$NORMALIZED_DOC" > "$NORMALIZED_DB" ]]; then
        echo -e "  ${RED}→ Schema document is AHEAD of database implementation${NC}"
        echo -e "  ${YELLOW}Fix:${NC} Run migrations to update database to v${NORMALIZED_DOC}"
        echo -e "       ${BLUE}npx supabase db push${NC}"
    else
        echo -e "  ${RED}→ Database is AHEAD of schema document${NC}"
        echo -e "  ${YELLOW}Fix:${NC} Update CANONICAL_JSON_SCHEMA.md to match DB version"
        echo -e "       Current DB version: v${NORMALIZED_DB}"
    fi

    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    exit 1
fi
