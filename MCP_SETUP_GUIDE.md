# MCP Setup Guide for Portainer and Supabase

## Overview

This guide will help you set up Model Context Protocol (MCP) servers for both Portainer and Supabase in GitHub Copilot (VS Code).

## What is MCP?

Model Context Protocol (MCP) is an open protocol that standardizes how AI assistants connect to external services and data sources. Think of it like USB-C for AI - a universal way to connect your AI assistant to various tools and services.

## Prerequisites

- VS Code with GitHub Copilot installed
- Access to your Portainer instance
- Access to your Supabase project

---

## Part 1: Portainer MCP Setup

### Step 1: Install Portainer MCP Binary

Download the latest binary for your system from [Portainer MCP Releases](https://github.com/portainer/portainer-mcp/releases/latest):

```bash
# For Linux AMD64
curl -Lo portainer-mcp-v0.6.0-linux-amd64.tar.gz \
  https://github.com/portainer/portainer-mcp/releases/download/v0.6.0/portainer-mcp-v0.6.0-linux-amd64.tar.gz

# Extract
tar -xzf portainer-mcp-v0.6.0-linux-amd64.tar.gz

# Move to PATH
sudo mv portainer-mcp /usr/local/bin/

# Verify installation
portainer-mcp --version
```

### Step 2: Get Your Portainer API Token

1. Log in to your Portainer instance
2. Go to **User Settings** → **Access tokens**
3. Click **Add access token**
4. Give it a name (e.g., "MCP Server")
5. Copy the token (starts with `ptr_...`)

### Step 3: Copy Tools Configuration

```bash
# Copy the tools.yaml from your project to /tmp
cp /home/jbi-laptop/Git/chat-humanitarian-agent/tools.yaml /tmp/portainer-tools.yaml
```

### Step 4: Configure VS Code Settings

Open your VS Code settings file:

```bash
code ~/.config/Code/User/settings.json
```

Add the Portainer MCP configuration:

```json
{
  "github.copilot.chat.experimental.mcpServers": {
    "portainer": {
      "command": "/usr/local/bin/portainer-mcp",
      "args": [
        "-server",
        "YOUR_SERVER_IP:PORT",
        "-token",
        "YOUR_PORTAINER_TOKEN",
        "-tools",
        "/tmp/portainer-tools.yaml",
        "-disable-version-check"
      ]
    }
  }
}
```

**Replace:**
- `YOUR_SERVER_IP:PORT` with your Portainer server address (e.g., `100.120.229.13:9443`)
- `YOUR_PORTAINER_TOKEN` with your API token (e.g., `ptr_+M3qGt...`)

### Step 5: Enable Read-Only Mode (Recommended)

For safety, you can enable read-only mode by adding `-read-only` to the args:

```json
"args": [
  "-server",
  "YOUR_SERVER_IP:PORT",
  "-token",
  "YOUR_PORTAINER_TOKEN",
  "-tools",
  "/tmp/portainer-tools.yaml",
  "-disable-version-check",
  "-read-only"
]
```

### Step 6: Restart VS Code

Close and reopen VS Code to load the MCP server.

### Step 7: Test Portainer MCP

Open GitHub Copilot Chat and try:
- "List all my Docker environments"
- "Show me the running stacks"
- "What containers are running on environment 2?"

---

## Part 2: Supabase MCP Setup

### Overview

Supabase MCP is hosted by Supabase and uses OAuth authentication. No binary installation required!

### Step 1: Configure VS Code Settings

Add the Supabase MCP configuration to your settings:

```json
{
  "github.copilot.chat.experimental.mcpServers": {
    "portainer": {
      // ... existing portainer config
    },
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=YOUR_PROJECT_REF&read_only=true&features=database,docs,debugging,development"
    }
  }
}
```

**Replace:**
- `YOUR_PROJECT_REF` with your Supabase project ID (found in Project Settings → General)

### Step 2: Recommended Security Options

Use these query parameters for maximum security:

```
?project_ref=qecdwuwkxgwkpopmdewl    # Scope to your project
&read_only=true                       # Prevent write operations
&features=database,docs,debugging,development  # Only enable needed features
```

### Available Feature Groups:
- `account` - Project management (list/create projects, orgs)
- `database` - Tables, migrations, SQL execution
- `docs` - Search Supabase documentation
- `debugging` - Logs and advisors
- `development` - API URLs, anon keys, type generation
- `functions` - Edge Functions deployment
- `storage` - Storage bucket management
- `branching` - Database branching (paid plans)

### Step 3: Authenticate

1. Restart VS Code
2. Open GitHub Copilot Chat
3. Try a Supabase command (e.g., "List my Supabase tables")
4. You'll be prompted to authenticate via browser
5. Sign in to Supabase and grant access

### Step 4: Test Supabase MCP

Try these commands in Copilot Chat:
- "Show me all tables in my Supabase database"
- "Search the Supabase docs for authentication"
- "Get logs from my Supabase project"
- "Generate TypeScript types for my database"

---

## Complete Configuration Example

Here's a complete VS Code settings.json with both MCPs configured securely:

```json
{
  "github.copilot.chat.experimental.mcpServers": {
    "portainer": {
      "command": "/usr/local/bin/portainer-mcp",
      "args": [
        "-server",
        "100.120.229.13:9443",
        "-token",
        "ptr_YOUR_TOKEN_HERE",
        "-tools",
        "/tmp/portainer-tools.yaml",
        "-disable-version-check",
        "-read-only"
      ]
    },
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=qecdwuwkxgwkpopmdewl&read_only=true&features=database,docs,debugging,development"
    }
  }
}
```

---

## Security Best Practices

### For Portainer MCP:
1. ✅ Use `-read-only` mode by default
2. ✅ Store API tokens securely (not in git)
3. ✅ Use environment-specific tokens (not production)
4. ✅ Review tool calls before executing them
5. ✅ Customize tools.yaml to disable unwanted operations

### For Supabase MCP:
1. ✅ Always use `read_only=true` by default
2. ✅ Scope to specific project with `project_ref`
3. ✅ Only enable needed feature groups
4. ✅ Connect to development/staging projects, not production
5. ✅ Review all tool calls before accepting

---

## Troubleshooting

### Portainer MCP Not Working

**Check if binary is installed:**
```bash
which portainer-mcp
portainer-mcp --version
```

**Test connection manually:**
```bash
portainer-mcp \
  -server "YOUR_SERVER:PORT" \
  -token "YOUR_TOKEN" \
  -tools "/tmp/portainer-tools.yaml" \
  -disable-version-check
```

**Check VS Code Output:**
1. Open Output panel (View → Output)
2. Select "GitHub Copilot Chat" from dropdown
3. Look for MCP server startup messages

### Supabase MCP Not Working

**Authentication issues:**
- Make sure you're signed into the correct Supabase account
- Check browser console for OAuth errors
- Try disconnecting and reconnecting

**Feature not available:**
- Check if feature is included in your `features` parameter
- Verify your Supabase plan supports the feature (e.g., branching requires paid plan)

**Read-only errors:**
- Remove `read_only=true` if you need write access (not recommended)
- Check that you're not trying write operations in read-only mode

---

## Available Tools

### Portainer MCP Tools

When configured, you'll have access to:
- **Environments**: List, update tags, manage access
- **Stacks**: List, get stack files, create, update
- **Users & Teams**: Manage users, teams, permissions
- **Docker Proxy**: Execute any Docker API command
- **Settings**: Get Portainer settings

### Supabase MCP Tools

Depending on your feature groups:
- **Database**: List tables, execute SQL, apply migrations
- **Docs**: Search Supabase documentation
- **Debugging**: Get logs, view advisors
- **Development**: Get API URLs, anon keys, generate types
- **Functions**: List, deploy Edge Functions
- **Account**: List projects, organizations (if not scoped)

---

## Testing Your Setup

Run this script to verify Portainer MCP:

```bash
./test-portainer-mcp.sh
```

For Supabase, just ask Copilot:
```
@workspace List my Supabase tables
```

---

## Useful MCP Commands

### With Portainer:
- "List all Docker services in environment 2"
- "Show me the chat service configuration"
- "Create a new secret called 'api_key' in Docker Swarm"
- "Update the web stack with new environment variables"

### With Supabase:
- "Show me the schema for the chats table"
- "Execute this SQL: SELECT * FROM profiles LIMIT 10"
- "Search the docs for Row Level Security"
- "Generate TypeScript types for my database"
- "Get the last 50 API logs"

---

## Next Steps

1. Test both MCP servers in Copilot Chat
2. Customize feature groups and permissions
3. Create specific tools.yaml for your use cases
4. Set up separate tokens for development vs production
5. Document your MCP commands for your team

## References

- [Portainer MCP GitHub](https://github.com/portainer/portainer-mcp)
- [Supabase MCP GitHub](https://github.com/supabase-community/supabase-mcp)
- [Model Context Protocol Docs](https://modelcontextprotocol.io/introduction)
- [GitHub Copilot MCP Documentation](https://code.visualstudio.com/docs/copilot/copilot-extensibility-overview)

---

**Last Updated**: October 16, 2025
**Status**: Ready for configuration
