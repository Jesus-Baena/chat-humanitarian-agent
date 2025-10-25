# MCP Configuration Complete (Archived, Sanitized)

Summary of prior MCP setup. Replace any real tokens and IPs with placeholders when reusing.

Example Portainer launch (sanitized):
```bash
portainer-mcp \
  -server "YOUR_SERVER_IP:PORT" \
  -token "ptr_YOUR_TOKEN" \
  -tools "/tmp/portainer-tools.yaml" \
  -disable-version-check
```

Supabase MCP is configured via HTTP with `project_ref=YOUR_PROJECT_REF&read_only=true`.
