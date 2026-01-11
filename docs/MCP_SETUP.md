# MCP Setup Guide

**Purpose:** Configure Model Context Protocol (MCP) servers for database access across different AI environments.

**Last Updated:** 2026-01-11

---

## Overview

The ParserZamaActive project uses Supabase MCP to provide AI assistants with direct database access. However, the **setup process differs** depending on which AI environment you're using:

- **VS Code + GitHub Copilot:** Configuration file only (`.vscode/mcp.json`)
- **Claude Code CLI:** Requires manual registration via `claude mcp add` command

## Quick Start

### Automated Setup (Recommended)

```bash
# Run the setup script
./scripts/setup_mcp.sh

# If already configured and need to reconfigure:
./scripts/setup_mcp.sh --force
```

### Manual Setup

#### For VS Code + GitHub Copilot

**Status:** ✅ Already configured

The file `.vscode/mcp.json` is already committed to the repository:

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

**No additional steps needed** - VS Code will automatically load this configuration.

#### For Claude Code CLI

**Status:** ⚠️ Requires manual setup

Claude Code CLI does **not** read `.vscode/mcp.json`. You must register the MCP server:

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

**Important:** MCP tools will only be available in **new conversations** after registration.

---

## Configuration Files Explained

### `.vscode/mcp.json` (VS Code + Copilot)

- **Location:** `/workspaces/ParserZamaActive/.vscode/mcp.json`
- **Purpose:** Configure MCP servers for VS Code IDE and GitHub Copilot
- **Format:** JSON configuration file
- **Loading:** Automatic when VS Code starts
- **Scope:** Project-specific (committed to git)
- **Authentication:** Uses HTTP endpoint (no local credentials needed)

### `~/.claude.json` (Claude Code CLI)

- **Location:** `$HOME/.claude.json` (user's home directory)
- **Purpose:** Store MCP server configurations for Claude Code CLI
- **Format:** JSON configuration file (managed by CLI)
- **Loading:** Automatic in new conversations
- **Scope:** User-specific per project
- **Authentication:** Requires `SUPABASE_ACCESS_TOKEN` environment variable

### `.claude/settings.json` (Project Settings)

- **Location:** `/workspaces/ParserZamaActive/.claude/settings.json`
- **Purpose:** Define MCP server configuration template
- **Status:** ⚠️ **Not automatically loaded by Claude Code CLI**
- **Use Case:** Documentation reference and IDE integration

**Note:** The `mcpServers` section in `.claude/settings.json` is for documentation only. Claude CLI requires manual `claude mcp add` command.

---

## Environment Requirements

### Prerequisites

1. **Environment Variables**
   - `SUPABASE_ACCESS_TOKEN` must be set in `.env.local`
   - Token should be 40+ characters (Supabase project access token)

2. **Dependencies**
   - `npx` available (comes with Node.js)
   - `@supabase/mcp-server-supabase` package (auto-downloaded by npx)

3. **For Claude Code CLI**
   - Claude CLI v2.1.4 or higher installed
   - Run `claude --version` to verify

### Obtaining SUPABASE_ACCESS_TOKEN

```bash
# Already configured in .env.local
# If you need to regenerate:
# 1. Go to https://supabase.com/dashboard/project/dtzcamerxuonoeujrgsu/settings/api
# 2. Navigate to "Access Tokens" section
# 3. Generate new token with appropriate permissions
# 4. Update .env.local
```

---

## Verification

### Check VS Code + Copilot Setup

1. Open VS Code in this project
2. Enable GitHub Copilot
3. Ask Copilot: "List tables in zamm schema"
4. Should see tables listed using MCP

### Check Claude Code CLI Setup

```bash
# 1. List configured MCP servers
claude mcp list

# Expected output:
# supabase: npx -y @supabase/mcp-server-supabase@latest --project-ref dtzcamerxuonoeujrgsu - ✓ Connected

# 2. Get server details
claude mcp get supabase

# 3. Start NEW conversation and test
# (MCP tools only available in new sessions)
```

---

## Available MCP Tools

Once configured, these tools are available to AI assistants:

| Tool Name | Purpose |
|-----------|---------|
| `mcp_supabase_execute_sql` | Execute raw SQL queries |
| `mcp_supabase_list_tables` | List tables in schemas |
| `mcp_supabase_apply_migration` | Apply DDL migrations |
| `mcp_supabase_list_migrations` | List applied migrations |
| `mcp_supabase_list_extensions` | List database extensions |
| `mcp_supabase_get_project_url` | Get project API URL |
| `mcp_supabase_get_publishable_keys` | Get anon/public keys |
| `mcp_supabase_get_logs` | Get service logs |
| `mcp_supabase_get_advisors` | Security/performance checks |
| `mcp_supabase_search_docs` | Search Supabase docs |
| `mcp_supabase_list_edge_functions` | List Edge Functions |
| `mcp_supabase_get_edge_function` | Get function code |
| `mcp_supabase_deploy_edge_function` | Deploy Edge Function |
| `mcp_supabase_generate_typescript_types` | Generate TS types |
| `mcp_supabase_create_branch` | Create dev branch |
| `mcp_supabase_list_branches` | List branches |
| `mcp_supabase_merge_branch` | Merge to production |
| `mcp_supabase_rebase_branch` | Rebase branch |
| `mcp_supabase_reset_branch` | Reset branch |
| `mcp_supabase_delete_branch` | Delete branch |

**Note:** In VS Code/Copilot, tool names may use different prefixes.

---

## Troubleshooting

### "No MCP servers configured"

**Problem:** `claude mcp list` shows no servers

**Solution:**
```bash
# Run setup script
./scripts/setup_mcp.sh

# Or manually add server
source .env.local
claude mcp add supabase \
  -e SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" \
  -- npx -y @supabase/mcp-server-supabase@latest \
  --project-ref dtzcamerxuonoeujrgsu
```

### "MCP tools not available in conversation"

**Problem:** Started conversation before MCP server was added

**Solution:**
- MCP servers only load in **NEW conversations**
- Exit current conversation and start a new one
- Verify with `claude mcp list` before starting

### "Invalid environment variable format"

**Problem:** Wrong syntax for `claude mcp add` command

**Solution:**
```bash
# ❌ WRONG - Environment flag after server name
claude mcp add -e TOKEN=xxx supabase -- command

# ✅ CORRECT - Name first, then environment flag
claude mcp add supabase -e TOKEN=xxx -- command
```

### "Connection failed" or "Server unhealthy"

**Problem:** MCP server cannot connect to Supabase

**Possible Causes:**
1. Invalid `SUPABASE_ACCESS_TOKEN`
2. Network connectivity issues
3. Supabase project access restrictions

**Solution:**
```bash
# 1. Verify token is correct
source .env.local
echo "Token length: ${#SUPABASE_ACCESS_TOKEN}"  # Should be 40+

# 2. Test connection manually
npx -y @supabase/mcp-server-supabase@latest \
  --project-ref dtzcamerxuonoeujrgsu

# 3. Regenerate token from Supabase dashboard if needed
```

### "Tools use wrong prefix"

**Problem:** Expected `mcp_supabase_*` but seeing different prefix

**Solution:**
- Tool prefixes vary by environment:
  - VS Code/Copilot: May use `mcp_supabase_*` or custom prefix
  - Claude Code CLI: Uses `mcp_supabase_*`
- Check available tools in your specific environment

---

## Comparison: MCP vs Bash Scripts

| Feature | MCP | Bash Scripts |
|---------|-----|--------------|
| **Setup** | One-time registration | Load `.env.local` each time |
| **Speed** | Instant | Requires shell execution |
| **Interface** | Natural language | Command-line syntax |
| **Error handling** | Automated | Manual |
| **CI/CD support** | ❌ No | ✅ Yes |
| **Offline mode** | ❌ No | ❌ No |
| **Type safety** | ✅ Schema-aware | ❌ Raw SQL |
| **Authentication** | Automatic | Manual env vars |

**Recommendation:**
- **Development:** Use MCP (faster, simpler)
- **CI/CD:** Use bash scripts (automation support)
- **Fallback:** Bash scripts always available

---

## Related Documentation

- [MCP Integration Guide](MCP_INTEGRATION_GUIDE.md) - When to use MCP vs bash scripts
- [.vscode/README.md](../.vscode/README.md) - VS Code configuration details
- [.claude/CLAUDE.md](../.claude/CLAUDE.md) - AI agent protocols
- [Model Context Protocol Spec](https://modelcontextprotocol.io/) - Official MCP documentation
- [Supabase MCP Documentation](https://supabase.com/docs/guides/functions/mcp) - Supabase-specific guide

---

## Maintenance

### Update MCP Server Version

```bash
# Remove old configuration
claude mcp remove supabase -s local

# Re-add with latest version (npx -y auto-updates)
./scripts/setup_mcp.sh
```

### Change Project Reference

If switching to a different Supabase project:

1. Update `PROJECT_REF` in `scripts/setup_mcp.sh`
2. Update `.vscode/mcp.json` URL
3. Run `./scripts/setup_mcp.sh --force`

### Remove MCP Configuration

```bash
# Remove from Claude Code CLI
claude mcp remove supabase -s local

# Remove VS Code config (not recommended)
# rm .vscode/mcp.json
```

---

## Summary

✅ **VS Code + Copilot:** Uses `.vscode/mcp.json` (already configured)
✅ **Claude Code CLI:** Run `./scripts/setup_mcp.sh` (one-time setup)
✅ **Bash scripts:** Always available as fallback
✅ **New conversations:** Required after MCP registration

**Key Principle:** Different AI environments use different MCP configuration methods. Use the automated setup script for simplicity.

---

**Last Updated:** 2026-01-11
**Maintained By:** AI Development Team
