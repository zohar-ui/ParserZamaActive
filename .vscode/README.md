# VS Code Configuration

## Model Context Protocol (MCP) Setup

This directory contains MCP (Model Context Protocol) server configurations for enhanced AI assistance.

**Important:** This configuration is for **VS Code + GitHub Copilot** only. If you're using **Claude Code CLI**, see the [Setup Script](#claude-code-cli-setup) section below.

### Supabase MCP Server

**File:** `mcp.json`

**Purpose:** Connects VS Code + GitHub Copilot to the Supabase MCP server, providing direct database access and query capabilities through the AI assistant.

**Configuration:**
```json
{
  "servers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=dtzcamerxuonoeujrgsu"
    }
  }
}
```

### What This Enables

With the Supabase MCP connection, Claude Code can:

1. **Query Database Directly** - Run SQL queries without manual psql commands
2. **Inspect Schema** - View table structures, columns, and relationships
3. **Verify Data** - Check actual data in tables to validate migrations
4. **Debug Issues** - Investigate database state during troubleshooting
5. **Generate Queries** - Create complex SQL queries with schema awareness

### Usage in VS Code + Copilot

Once configured, you can ask GitHub Copilot to:

```
"Show me the structure of the workout_main table"
"Query the first 5 records from lib_athletes"
"Count how many workouts are in the database"
"Check if the equipment_catalog has a bench press entry"
```

Copilot will use the MCP connection to execute these queries directly.

**Note:** This configuration is automatically loaded by VS Code. No manual setup required.

### Security Notes

- The MCP URL contains your project reference but no credentials
- Authentication is handled by Supabase's MCP server
- This configuration can be safely committed to version control
- Individual user settings remain in `.vscode/settings.json` (gitignored)

---

## Claude Code CLI Setup

**Important:** Claude Code CLI does **not** automatically read `.vscode/mcp.json`. It requires a separate registration step.

### Automated Setup (Recommended)

Run the setup script from the project root:

```bash
./scripts/setup_mcp.sh
```

This script will:
1. ✅ Verify environment configuration (.env.local)
2. ✅ Check VS Code MCP config exists
3. ✅ Detect Claude CLI installation
4. ✅ Check for existing MCP configuration
5. ✅ Add Supabase MCP server if needed
6. ✅ Verify server connection

### Manual Setup

If you prefer manual setup:

```bash
# 1. Load environment variables
source .env.local

# 2. Add MCP server to Claude Code
claude mcp add supabase \
  -e SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" \
  -- npx -y @supabase/mcp-server-supabase@latest \
  --project-ref dtzcamerxuonoeujrgsu

# 3. Verify configuration
claude mcp list
```

### Important Notes

- ⚠️ MCP tools are only available in **NEW conversations** after registration
- ✅ To verify: Start a new Claude Code session and ask "List tables in zamm schema"
- ✅ Run `./scripts/setup_mcp.sh --force` to reconfigure if needed

### Related Documentation

- **[MCP Setup Guide](../docs/MCP_SETUP.md)** - Comprehensive setup instructions for all environments
- [MCP Integration Guide](../docs/MCP_INTEGRATION_GUIDE.md) - Complete guide to MCP vs bash scripts
- [.claude/CLAUDE.md](../.claude/CLAUDE.md) - AI agent protocols (updated for MCP)
- [Model Context Protocol Spec](https://modelcontextprotocol.io/) - Official MCP documentation
- [Supabase MCP Documentation](https://supabase.com/docs/guides/functions/mcp) - Supabase-specific guide
- Project docs: `docs/` directory

---

**Last Updated:** 2026-01-11
