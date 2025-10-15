#!/bin/bash

# 🔍 PRODUCTION DEBUGGING COMMANDS
# Run these commands on your Docker Swarm manager to diagnose the issue

echo "🔍 DIAGNOSING CHAT SERVICE ISSUES"
echo "=================================="
echo ""

echo "1️⃣ Check service status:"
echo "docker service ls | grep web"
echo ""

echo "2️⃣ Check chat service tasks:"
echo "docker service ps web_chat --no-trunc"
echo ""

echo "3️⃣ Check recent container logs:"
echo "docker service logs web_chat --tail 50 --follow"
echo ""

echo "4️⃣ Inspect service configuration:"
echo "docker service inspect web_chat | jq '.[] | {Image: .Spec.TaskTemplate.ContainerSpec.Image, Env: .Spec.TaskTemplate.ContainerSpec.Env}'"
echo ""

echo "5️⃣ Check stack status:"
echo "docker stack ps web | grep chat"
echo ""

echo "6️⃣ Check if image exists:"
echo "docker pull ghcr.io/jesus-baena/chat-humanitarian-agent:latest"
echo ""

echo "7️⃣ Check resource usage:"
echo "docker stats --no-stream"
echo ""

echo "🚨 COMMON ISSUES TO LOOK FOR:"
echo "• Container constantly restarting (restart loop)"
echo "• Image pull failures (403 Forbidden, not found)"
echo "• Environment variable errors in logs"
echo "• Out of memory/resources"
echo "• Port binding conflicts"
echo ""

echo "🛠️ EMERGENCY FIXES:"
echo ""
echo "A) If containers are failing to start:"
echo "   docker service update --force web_chat"
echo ""
echo "B) If image pull is failing:"
echo "   docker service update --image ghcr.io/jesus-baena/chat-humanitarian-agent:main web_chat"
echo ""
echo "C) If environment issues:"
echo "   ./emergency-deploy.sh"
echo ""
echo "D) Complete service recreation:"
echo "   docker service rm web_chat"
echo "   docker stack deploy -c docker-compose.yml web"
echo ""

# Auto-run commands if we're on swarm manager
if docker node ls >/dev/null 2>&1; then
    echo "🤖 RUNNING AUTOMATIC DIAGNOSTICS..."
    echo "=================================="
    
    echo ""
    echo "📊 Service Status:"
    docker service ls | grep web || echo "❌ No web services found"
    
    echo ""
    echo "🔍 Chat Service Tasks:"
    docker service ps web_chat --no-trunc 2>/dev/null || echo "❌ web_chat service not found"
    
    echo ""
    echo "📝 Recent Logs (last 20 lines):"
    docker service logs web_chat --tail 20 2>/dev/null || echo "❌ Cannot get logs for web_chat"
    
else
    echo "ℹ️  Run this script on Docker Swarm manager for automatic diagnostics"
fi