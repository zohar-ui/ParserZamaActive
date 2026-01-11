#!/bin/bash
# ============================================
# Update Documentation After Migration
# ============================================
# Purpose: Manually update schema documentation after running migrations
# Usage: ./scripts/docs/update_docs_after_migration.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Post-Migration Documentation Updater                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if SUPABASE_DB_URL is set
if [ -z "$SUPABASE_DB_URL" ]; then
    echo -e "${RED}✗ Error: SUPABASE_DB_URL environment variable not set${NC}"
    echo ""
    echo -e "${YELLOW}Fix:${NC}"
    echo -e "  1. Copy your database URL from Supabase dashboard"
    echo -e "  2. Set it: ${BLUE}export SUPABASE_DB_URL='postgresql://...'${NC}"
    echo -e "  3. Or add to ${BLUE}.env.local${NC} and source it"
    echo ""
    exit 1
fi

echo -e "${YELLOW}[1/3]${NC} Checking database connection..."
if psql "$SUPABASE_DB_URL" -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Database accessible"
else
    echo -e "${RED}✗${NC} Cannot connect to database"
    echo ""
    echo -e "${YELLOW}Check:${NC}"
    echo -e "  • Is SUPABASE_DB_URL correct?"
    echo -e "  • Is database running?"
    echo -e "  • Are you connected to the internet?"
    echo ""
    exit 1
fi

echo ""
echo -e "${YELLOW}[2/3]${NC} Updating schema documentation..."
if npm run update-docs; then
    echo -e "${GREEN}✓${NC} Documentation updated"
else
    echo -e "${RED}✗${NC} Documentation update failed"
    exit 1
fi

echo ""
echo -e "${YELLOW}[3/3]${NC} Checking for changes..."

if git diff --quiet docs/reference/VERIFIED_TABLE_NAMES.md 2>/dev/null; then
    echo -e "${BLUE}ℹ  No changes to documentation (schema unchanged)${NC}"
else
    echo -e "${GREEN}✓${NC} Documentation updated with new schema changes"
    echo ""
    echo -e "${YELLOW}Changes:${NC}"
    git diff --stat docs/reference/VERIFIED_TABLE_NAMES.md 2>/dev/null || echo "  (git not available)"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. Review: ${BLUE}git diff docs/reference/VERIFIED_TABLE_NAMES.md${NC}"
    echo -e "  2. Commit: ${BLUE}git add docs/reference/VERIFIED_TABLE_NAMES.md${NC}"
    echo -e "  3. Commit: ${BLUE}git commit -m 'docs: update schema documentation'${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Post-migration documentation update complete${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
