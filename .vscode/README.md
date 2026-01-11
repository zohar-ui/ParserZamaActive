# VS Code Configuration

## Model Context Protocol (MCP) Setup

This directory contains MCP (Model Context Protocol) server configurations for enhanced AI assistance.

### Supabase MCP Server

**File:** `mcp.json`

**Purpose:** Connects Claude Code to the Supabase MCP server, providing direct database access and query capabilities through the AI assistant.

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

### Usage in Claude Code

Once configured, you can ask Claude Code to:

```
"Show me the structure of the workout_main table"
"Query the first 5 records from lib_athletes"
"Count how many workouts are in the database"
"Check if the equipment_catalog has a bench press entry"
```

Claude will use the MCP connection to execute these queries directly.

### Security Notes

- The MCP URL contains your project reference but no credentials
- Authentication is handled by Supabase's MCP server
- This configuration can be safely committed to version control
- Individual user settings remain in `.vscode/settings.json` (gitignored)

### Related Documentation

- [MCP Integration Guide](../docs/MCP_INTEGRATION_GUIDE.md) - Complete guide to MCP vs bash scripts
- [Model Context Protocol Spec](https://modelcontextprotocol.io/)
- [Supabase MCP Documentation](https://supabase.com/docs/guides/functions/mcp)
- [.claude/CLAUDE.md](../.claude/CLAUDE.md) - AI agent protocols (updated for MCP)
- Project docs: `docs/` directory

---

**Last Updated:** 2026-01-11
