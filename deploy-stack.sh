#!/bin/bash

# 🚀 Stack-Based Deployment for chat-humanitarian-agent
# Uses docker-compose.prod.yml to ensure all env vars are preserved

set -e

echo "🚀 Deploying chat-humanitarian-agent stack to production"
echo ""

# Check if we're on the swarm manager
if ! docker node ls >/dev/null 2>&1; then
    echo "❌ Error: This script must be run on a Docker Swarm manager node"
    exit 1
fi

echo "✅ Running on Docker Swarm manager"
echo ""

# Configuration
STACK_NAME="web"
COMPOSE_FILE="docker-compose.prod.yml"
ROLLOUT_VERSION=$(date +%s)

echo "📋 Deployment Configuration:"
echo "   Stack: ${STACK_NAME}"
echo "   Compose File: ${COMPOSE_FILE}"
echo "   Rollout Version: ${ROLLOUT_VERSION}"
echo ""

# Check if compose file exists
if [ ! -f "${COMPOSE_FILE}" ]; then
    echo "❌ Error: ${COMPOSE_FILE} not found"
    echo "💡 This file should be in the repository root"
    exit 1
fi

# Pull the latest image
echo "📥 Pulling latest image..."
docker pull ghcr.io/jesus-baena/chat-humanitarian-agent:latest

echo ""
echo "🔄 Deploying stack with docker-compose..."

# Export ROLLOUT_VERSION for docker-compose
export ROLLOUT_VERSION

# Deploy the stack
docker stack deploy -c "${COMPOSE_FILE}" "${STACK_NAME}"

echo ""
echo "⏳ Waiting for deployment to stabilize..."
sleep 5

echo ""
echo "🔍 Checking deployment status..."
docker service ps ${STACK_NAME}_chat --filter "desired-state=running" --no-trunc | head -10

echo ""
echo "📊 Service details:"
docker service inspect ${STACK_NAME}_chat --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'

echo ""
echo "📝 Environment variables (verify Flowise is included):"
docker service inspect ${STACK_NAME}_chat --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' | grep -E "FLOWISE|SUPABASE" | head -5

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🧪 Test endpoints:"
echo "   Chat app: https://chat.baena.ai"
echo "   Flowise: https://flowise.baena.site"
echo ""
echo "💡 To monitor:"
echo "   docker service logs -f ${STACK_NAME}_chat"
echo "   docker service ps ${STACK_NAME}_chat"
echo ""
echo "⚠️  Note: Stack deployments preserve ALL environment variables from docker-compose.prod.yml"
echo "   This prevents the 'No completion backend configured' error!"
