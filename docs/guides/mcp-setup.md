# MCP Setup Guide for Portainer and Supabase

This guide configures Portainer MCP (local binary) and Supabase MCP (hosted HTTP) for use in GitHub Copilot Chat.

## Prerequisites
- VS Code with GitHub Copilot
- Access to Portainer and Supabase

## Portainer MCP

1) Install Portainer MCP binary (example for Linux AMD64):
```bash
curl -Lo portainer-mcp.tar.gz \
  https://github.com/portainer/portainer-mcp/releases/download/v0.6.0/portainer-mcp-v0.6.0-linux-amd64.tar.gz
tar -xzf portainer-mcp.tar.gz
sudo mv portainer-mcp /usr/local/bin/
portainer-mcp --version
```

2) Get an API token in Portainer (User Settings → Access tokens).

3) Configure VS Code settings (settings.json):
```json
{
  "github.copilot.chat.experimental.mcpServers": {
    "portainer": {
      "command": "/usr/local/bin/portainer-mcp",
      "args": [
        "-server", "YOUR_SERVER_IP:PORT",
        "-token", "ptr_YOUR_PORTAINER_TOKEN",
        "-tools", "/tmp/portainer-tools.yaml",
        "-disable-version-check",
        "-read-only"
      ]
    }
  }
}
```

Tip: Copy `tools.yaml` from this repo root to `/tmp/portainer-tools.yaml`.

## Supabase MCP (hosted)

Add to settings.json:
```json
{
  "github.copilot.chat.experimental.mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=YOUR_PROJECT_REF&read_only=true&features=database,docs,debugging,development"
    }
  }
}
```

Security options: use `read_only=true`, scope with `project_ref`, and enable only needed `features`.

## Troubleshooting

If Portainer MCP fails:
- Ensure the server is reachable, token valid, and port open
- Try launching manually with placeholders replaced:
```bash
portainer-mcp \
  -server "YOUR_SERVER_IP:PORT" \
  -token "ptr_YOUR_PORTAINER_TOKEN" \
  -tools "/tmp/portainer-tools.yaml" \
  -disable-version-check \
  -read-only
```

If Supabase MCP fails:
- Ensure correct account and project_ref
- Re-authenticate when prompted

## Security notes
- Prefer read-only mode for Portainer MCP
- Keep tokens out of git; use VS Code settings securely
- For Supabase MCP, default to `read_only=true`
