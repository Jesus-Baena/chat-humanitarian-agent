#!/bin/bash

# Quick deployment script - Run this on your production server

set -e

echo "🚀 Deploying Rate Limit Fix to Production"
echo "=========================================="
echo ""

# Configuration
STACK_NAME="web"
IMAGE="ghcr.io/jesus-baena/chat-humanitarian-agent:latest"
SERVICE_NAME="${STACK_NAME}_chat"
ROLLOUT_VERSION=$(date +%s)

echo "📋 Deployment Info:"
echo "   Stack: ${STACK_NAME}"
echo "   Service: ${SERVICE_NAME}"
echo "   Image: ${IMAGE}"
echo "   Rollout: ${ROLLOUT_VERSION}"
echo ""

# Step 1: Pull the latest image
echo "📥 Step 1/3: Pulling latest image..."
docker pull "${IMAGE}"

echo ""
echo "✅ Image pulled successfully"
echo ""

# Step 2: Update the stack with new rollout version
echo "🔄 Step 2/3: Updating stack..."
export ROLLOUT_VERSION
docker stack deploy -c docker-compose.prod.yml "${STACK_NAME}"

echo ""
echo "✅ Stack updated"
echo ""

# Step 3: Wait and verify
echo "⏳ Step 3/3: Waiting for deployment to stabilize..."
sleep 10

echo ""
echo "🔍 Checking service status..."
docker service ps "${SERVICE_NAME}" --filter "desired-state=running" --no-trunc | head -10

echo ""
echo "📊 Service details:"
docker service inspect "${SERVICE_NAME}" --format 'Image: {{.Spec.TaskTemplate.ContainerSpec.Image}}'
docker service inspect "${SERVICE_NAME}" --format 'Replicas: {{.Spec.Mode.Replicated.Replicas}}'

echo ""
echo "📝 Recent logs (last 20 lines):"
docker service logs "${SERVICE_NAME}" --tail 20 --no-trunc 2>&1 | grep -v "incomplete log stream" || true

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "🧪 Next Steps:"
echo "   1. Visit: https://chat.baena.ai"
echo "   2. Clear cookies: F12 → Application → Cookies → Delete 'sb-*'"
echo "   3. Test authentication - should work without rate limits"
echo ""
echo "📊 Monitor with:"
echo "   docker service logs -f ${SERVICE_NAME}"
echo "   docker service ps ${SERVICE_NAME}"
echo ""
echo "🔍 Check Supabase logs:"
echo "   https://supabase.com/dashboard/project/qecdwuwkxgwkpopmdewl/logs/auth-logs"
