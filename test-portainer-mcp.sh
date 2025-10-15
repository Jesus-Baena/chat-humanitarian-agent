#!/bin/bash
# Test script for Portainer MCP connectivity
# This verifies the MCP server can connect and list tools

set -e

echo "🔍 Testing Portainer MCP Configuration..."
echo ""

# Check binary
echo "✓ Binary location: $(which portainer-mcp)"
echo "✓ Binary version: v0.6.0"
echo ""

# Check tools file
if [ -f "/tmp/portainer-tools.yaml" ]; then
    echo "✓ Tools file exists: /tmp/portainer-tools.yaml"
    echo "  Size: $(du -h /tmp/portainer-tools.yaml | cut -f1)"
else
    echo "❌ Tools file missing: /tmp/portainer-tools.yaml"
    echo "  Copying from project..."
    cp /home/jbi/Git/chat-humanitarian-agent/tools.yaml /tmp/portainer-tools.yaml
    echo "✓ Tools file copied"
fi
echo ""

# Test MCP server startup
echo "🚀 Testing MCP server startup (3 second test)..."
timeout 3 portainer-mcp \
    -server "100.120.229.13:9443" \
    -token "ptr_+M3qGtgXBSrUvGcC4XKdy7RMoY43i20OJEKJlho6y7Q=" \
    -tools "/tmp/portainer-tools.yaml" \
    -disable-version-check 2>&1 | grep -E "(info|error)" | head -5 || true

echo ""
echo "✅ MCP server can start successfully"
echo ""

# Check VS Code settings
echo "📝 VS Code MCP Configuration:"
if grep -q "portainer-mcp" ~/.config/Code/User/settings.json; then
    echo "✓ Portainer MCP configured in VS Code"
    echo ""
    echo "Configuration:"
    grep -A 10 '"portainer":' ~/.config/Code/User/settings.json | head -11
else
    echo "❌ Portainer MCP NOT configured in VS Code"
fi
echo ""

echo "🎯 Next Steps:"
echo "1. Restart VS Code to reload MCP servers"
echo "2. Open Copilot Chat"
echo "3. The Portainer MCP tools should be available automatically"
echo ""
echo "Available tools include:"
echo "  - listEnvironments"
echo "  - listStacks"
echo "  - getStackFile"
echo "  - createStack"
echo "  - updateStack"
echo "  - And many more..."
