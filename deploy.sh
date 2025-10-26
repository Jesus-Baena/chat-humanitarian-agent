#!/bin/bash

# 🚀 Production Deployment Script for chat-humanitarian-agent
# This script deploys the latest Docker image with all required environment variables

set -e

echo "🚀 Deploying chat-humanitarian-agent to production"
echo ""

# Check if we're on the swarm manager
if ! docker node ls >/dev/null 2>&1; then
    echo "❌ Error: This script must be run on a Docker Swarm manager node"
    echo "💡 Run this on your swarm manager or use ssh-deploy.sh for remote deployment"
    exit 1
fi

echo "✅ Running on Docker Swarm manager"
echo ""

# Configuration
SERVICE_NAME="web_chat"
IMAGE="ghcr.io/jesus-baena/chat-humanitarian-agent:latest"
ROLLOUT_VERSION=$(date +%s)

# Environment variables with defaults (can be overridden)
FLOWISE_URL="${NUXT_PUBLIC_FLOWISE_URL:-https://flowise.baena.site/api/v1/prediction/40718af9-e9bd-47d9-a57b-009cb26f8fe3}"
FLOWISE_KEY="${NUXT_PUBLIC_FLOWISE_API_KEY:-FO5JgBFwXMPQDE_XrgDn8FSYpGbgtyeZ2h7YlJd-Skk}"

echo "📋 Deployment Configuration:"
echo "   Service: ${SERVICE_NAME}"
echo "   Image: ${IMAGE}"
echo "   Flowise URL: ${FLOWISE_URL:0:50}..."
echo "   Rollout Version: ${ROLLOUT_VERSION}"
echo ""

# Pull the latest image
echo "📥 Pulling latest image..."
docker pull "${IMAGE}"

echo ""
echo "🔄 Updating service with latest image and environment variables..."

# Update the service with all required environment variables
docker service update \
  --image "${IMAGE}" \
  --env-add NUXT_PUBLIC_FLOWISE_URL="${FLOWISE_URL}" \
  --env-add NUXT_PUBLIC_FLOWISE_API_KEY="${FLOWISE_KEY}" \
  --env-add ROLLOUT_VERSION="${ROLLOUT_VERSION}" \
  --update-parallelism 1 \
  --update-delay 10s \
  --force \
  "${SERVICE_NAME}"

echo ""
echo "⏳ Waiting for deployment to complete..."
sleep 5

echo ""
echo "🔍 Checking deployment status..."
docker service ps "${SERVICE_NAME}" --filter "desired-state=running" --no-trunc

echo ""
echo "📊 Service details:"
docker service inspect "${SERVICE_NAME}" --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'

echo ""
echo "📝 Recent logs:"
docker service logs "${SERVICE_NAME}" --tail 10 2>&1 | grep -v "incomplete log stream" || true

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🧪 Test endpoints:"
echo "   Chat app: https://chat.baena.ai"
echo "   Flowise API: ${FLOWISE_URL}"
echo ""
echo "💡 To monitor:"
echo "   docker service logs -f ${SERVICE_NAME}"
echo "   docker service ps ${SERVICE_NAME}"
