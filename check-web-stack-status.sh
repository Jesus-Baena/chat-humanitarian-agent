#!/bin/bash
# Portainer MCP Direct Query - Check web stack status
# This bypasses VS Code and calls the MCP server directly

MCP_CMD="/usr/local/bin/portainer-mcp"
SERVER="100.120.229.13:9443"
TOKEN="ptr_+M3qGtgXBSrUvGcC4XKdy7RMoY43i20OJEKJlho6y7Q="
TOOLS="/tmp/portainer-tools.yaml"

echo "🔍 Querying Portainer MCP for web stack status..."
echo ""

# List all stacks
echo "📦 Available Stacks:"
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}}}
{"jsonrpc":"2.0","method":"notifications/initialized"}
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"listStacks","arguments":{}}}' | \
$MCP_CMD -server "$SERVER" -token "$TOKEN" -tools "$TOOLS" -disable-version-check 2>/dev/null | \
grep -o '{"jsonrpc":"2.0","id":2,"result".*' | \
jq -r '.result.content[0].text' 2>/dev/null | \
jq -r '.[] | "  - \(.Name) (ID: \(.Id)) - Status: \(.Status // "N/A") - Environment: \(.EndpointId)"' 2>/dev/null || echo "Failed to parse stacks"

echo ""
echo "📋 Getting web stack details..."
# Get web stack ID first
STACK_ID=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}}}
{"jsonrpc":"2.0","method":"notifications/initialized"}
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"listStacks","arguments":{}}}' | \
$MCP_CMD -server "$SERVER" -token "$TOKEN" -tools "$TOOLS" -disable-version-check 2>/dev/null | \
grep -o '{"jsonrpc":"2.0","id":2,"result".*' | \
jq -r '.result.content[0].text' 2>/dev/null | \
jq -r '.[] | select(.Name == "web") | .Id' 2>/dev/null)

if [ -n "$STACK_ID" ]; then
    echo "✅ Found web stack (ID: $STACK_ID)"
    echo ""
    echo "📄 Stack Compose File:"
    echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}}}
{"jsonrpc":"2.0","method":"notifications/initialized"}
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"getStackFile","arguments":{"id":'$STACK_ID'}}}' | \
    $MCP_CMD -server "$SERVER" -token "$TOKEN" -tools "$TOOLS" -disable-version-check 2>/dev/null | \
    grep -o '{"jsonrpc":"2.0","id":2,"result".*' | \
    jq -r '.result.content[0].text' 2>/dev/null | head -20
else
    echo "❌ Web stack not found"
fi

echo ""
echo "💡 To see full details, use Portainer UI: https://100.120.229.13:9443"
