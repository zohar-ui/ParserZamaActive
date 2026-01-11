#!/bin/bash
#
# setup_mcp.sh - Configure MCP (Model Context Protocol) servers for ParserZamaActive
#
# Purpose: Automatically configure Supabase MCP server for different AI environments:
#   - VS Code + GitHub Copilot: Uses .vscode/mcp.json (already configured)
#   - Claude Code CLI: Requires manual registration via `claude mcp add`
#
# Usage:
#   ./scripts/setup_mcp.sh [--force]
#
# Options:
#   --force    Remove and re-add MCP server even if already configured
#
# Requirements:
#   - SUPABASE_ACCESS_TOKEN in .env.local
#   - Claude CLI installed (for Claude Code setup)
#   - npx available for running @supabase/mcp-server-supabase

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_REF="dtzcamerxuonoeujrgsu"
MCP_SERVER_NAME="supabase"
ENV_FILE=".env.local"

# Flags
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            echo "Usage: $0 [--force]"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}=== MCP Setup for ParserZamaActive ===${NC}\n"

# Step 1: Check environment file
echo -e "${YELLOW}[1/5]${NC} Checking environment configuration..."
if [[ ! -f "$ENV_FILE" ]]; then
    echo -e "${RED}✗ Error: $ENV_FILE not found${NC}"
    echo "Please create $ENV_FILE with SUPABASE_ACCESS_TOKEN"
    exit 1
fi

# Load environment variables
source "$ENV_FILE"

if [[ -z "$SUPABASE_ACCESS_TOKEN" ]]; then
    echo -e "${RED}✗ Error: SUPABASE_ACCESS_TOKEN not found in $ENV_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Environment configured${NC}"
echo "  Token length: ${#SUPABASE_ACCESS_TOKEN} characters"

# Step 2: Check VS Code MCP config
echo -e "\n${YELLOW}[2/5]${NC} Checking VS Code/Copilot configuration..."
if [[ -f ".vscode/mcp.json" ]]; then
    echo -e "${GREEN}✓ VS Code MCP config exists${NC}"
    echo "  File: .vscode/mcp.json"
    echo "  Note: This is automatically loaded by VS Code + GitHub Copilot"
else
    echo -e "${YELLOW}⚠ Warning: .vscode/mcp.json not found${NC}"
    echo "  VS Code + GitHub Copilot may not have MCP access"
fi

# Step 3: Check Claude CLI availability
echo -e "\n${YELLOW}[3/5]${NC} Checking Claude Code CLI..."
if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}⚠ Claude CLI not found${NC}"
    echo "  Claude Code CLI setup skipped"
    echo "  If using VS Code + Copilot, you're all set!"
    exit 0
fi

CLAUDE_VERSION=$(claude --version 2>&1 || echo "unknown")
echo -e "${GREEN}✓ Claude CLI found${NC}"
echo "  Version: $CLAUDE_VERSION"

# Step 4: Check if MCP server is already configured
echo -e "\n${YELLOW}[4/5]${NC} Checking existing MCP configuration..."
if claude mcp list 2>&1 | grep -q "^$MCP_SERVER_NAME:"; then
    echo -e "${GREEN}✓ Supabase MCP server already configured${NC}"

    if [[ "$FORCE" == "true" ]]; then
        echo -e "${YELLOW}  --force flag set, removing and re-adding...${NC}"
        claude mcp remove "$MCP_SERVER_NAME" -s local || true
    else
        echo "  To reconfigure, run: $0 --force"

        # Verify connection
        echo -e "\n${YELLOW}[5/5]${NC} Verifying MCP server connection..."
        if claude mcp list 2>&1 | grep -q "✓ Connected"; then
            echo -e "${GREEN}✓ MCP server is connected and healthy${NC}"
        else
            echo -e "${RED}✗ MCP server connection failed${NC}"
            echo "  Try running: $0 --force"
            exit 1
        fi

        echo -e "\n${GREEN}=== Setup Complete ===${NC}"
        echo "MCP server is ready to use in new Claude Code sessions"
        exit 0
    fi
fi

# Step 5: Add MCP server
echo -e "\n${YELLOW}[5/5]${NC} Adding Supabase MCP server..."
if claude mcp add "$MCP_SERVER_NAME" \
    -e SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" \
    -- npx -y @supabase/mcp-server-supabase@latest --project-ref "$PROJECT_REF"; then
    echo -e "${GREEN}✓ MCP server added successfully${NC}"
else
    echo -e "${RED}✗ Failed to add MCP server${NC}"
    exit 1
fi

# Verify the configuration
echo -e "\n${BLUE}Verifying configuration...${NC}"
if claude mcp list 2>&1 | grep -q "✓ Connected"; then
    echo -e "${GREEN}✓ MCP server is connected and healthy${NC}"
else
    echo -e "${RED}✗ MCP server connection check failed${NC}"
    echo "Run 'claude mcp list' to diagnose"
    exit 1
fi

# Success summary
echo -e "\n${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "MCP server configured successfully!"
echo ""
echo "Next steps:"
echo "  1. Start a NEW Claude Code conversation"
echo "  2. Test with: 'List tables in zamm schema'"
echo "  3. You should see mcp_supabase_* tools available"
echo ""
echo "Available MCP tools (after starting new session):"
echo "  - mcp_supabase_execute_sql         Execute raw SQL queries"
echo "  - mcp_supabase_list_tables         List tables in schemas"
echo "  - mcp_supabase_apply_migration     Apply DDL migrations"
echo "  - mcp_supabase_list_migrations     List applied migrations"
echo "  - And 15+ more database tools"
echo ""
echo "To view current configuration:"
echo "  claude mcp get supabase"
echo ""
echo "To remove MCP server:"
echo "  claude mcp remove supabase -s local"
