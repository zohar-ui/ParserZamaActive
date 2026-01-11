#!/bin/bash
# ============================================
# Install Git Hooks
# ============================================
# Purpose: Copy git hooks from .git-hooks/ to .git/hooks/
# Usage: ./scripts/install_hooks.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Installing Git Hooks                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if .git directory exists
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}⚠  Error: Not a git repository${NC}"
    echo -e "  Run this script from the project root"
    exit 1
fi

# Create .git/hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy pre-commit hook
if [ -f ".git-hooks/pre-commit" ]; then
    cp .git-hooks/pre-commit .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo -e "${GREEN}✓${NC} Installed: pre-commit hook"
    echo -e "  ${BLUE}→ Runs schema version check before every commit${NC}"
else
    echo -e "${YELLOW}⚠  Warning: .git-hooks/pre-commit not found${NC}"
fi

# Copy post-merge hook
if [ -f ".git-hooks/post-merge" ]; then
    cp .git-hooks/post-merge .git/hooks/post-merge
    chmod +x .git/hooks/post-merge
    echo -e "${GREEN}✓${NC} Installed: post-merge hook"
    echo -e "  ${BLUE}→ Auto-updates schema docs after pulling migrations${NC}"
else
    echo -e "${YELLOW}⚠  Warning: .git-hooks/post-merge not found${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Git hooks installed successfully${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}What happens now:${NC}"
echo -e "  • Before every commit, schema version will be verified"
echo -e "  • If mismatch detected, commit will be blocked"
echo -e "  • After pulling migrations, docs auto-update"
echo -e "  • You'll get clear instructions on how to fix issues"
echo ""
echo -e "${YELLOW}Test it:${NC}"
echo -e "  ${BLUE}git add .${NC}"
echo -e "  ${BLUE}git commit -m \"test commit\"${NC}"
echo ""
echo -e "${YELLOW}To uninstall:${NC}"
echo -e "  ${BLUE}rm .git/hooks/pre-commit${NC}"
echo ""
