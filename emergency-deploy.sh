#!/bin/bash

# 🚨 EMERGENCY DEPLOYMENT - Flowise URL Fix
# Use this if Docker build is still failing

echo "🚨 Emergency Deployment: Fixing Flowise URL without rebuilding Docker image"
echo ""

# Check if we're on the swarm manager
if ! docker node ls >/dev/null 2>&1; then
    echo "❌ Error: This script must be run on a Docker Swarm manager node"
    exit 1
fi

echo "✅ Running on Docker Swarm manager"

# Update the chat service with correct environment variables
echo "🔄 Updating chat service with fixed Flowise URL..."

# Default values from production
FLOWISE_URL="${NUXT_PUBLIC_FLOWISE_URL:-https://flowise.baena.site/api/v1/prediction/40718af9-e9bd-47d9-a57b-009cb26f8fe3}"
FLOWISE_KEY="${NUXT_PUBLIC_FLOWISE_API_KEY:-FO5JgBFwXMPQDE_XrgDn8FSYpGbgtyeZ2h7YlJd-Skk}"

docker service update \
  --env-add NUXT_PUBLIC_FLOWISE_URL="${FLOWISE_URL}" \
  --env-add NUXT_PUBLIC_FLOWISE_API_KEY="${FLOWISE_KEY}" \
  --env-add ROLLOUT_VERSION=$(date +%s) \
  --force \
  web_chat

echo ""
echo "🔍 Checking deployment status..."
docker service ps web_chat --no-trunc

echo ""
echo "📋 Service details:"
docker service inspect web_chat --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'

echo ""
echo "🧪 Testing endpoints:"
echo "Chat app: https://chat.baena.ai"
echo "Flowise API: https://flowise.baena.site/api/v1/prediction/40718af9-e9bd-47d9-a57b-009cb26f8fe3"

echo ""
echo "✅ Emergency deployment complete!"
echo "💡 The service will restart with the correct Flowise URL"
echo "🎯 Chat functionality should be restored immediately"