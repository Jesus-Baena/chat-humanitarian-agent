#!/bin/bash

# SSH Remote Deployment Script for Docker Swarm
set -e

# Load SSH configuration if available
if [ -f ".env.ssh" ]; then
    echo "📁 Loading SSH configuration from .env.ssh..."
    source .env.ssh
fi

# Configuration - Update these values for your setup
SWARM_HOST="${SWARM_HOST:-'100.119.42.25'}"
SWARM_USER="${SWARM_USER:-sysop}"

# Deployment configuration
STACK_NAME="web"
CHAT_VERSION="main-0ee48ea"  # Your latest commit with Tailwind fixes
PORTFOLIO_VERSION="latest"
NGINX_VERSION="1.25-alpine"
ROLLOUT_COUNTER=$(date +%s)

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 SSH Remote Deployment to Docker Swarm${NC}"
echo -e "${YELLOW}🖥️  Host: ${SWARM_USER}@${SWARM_HOST}:${SWARM_PORT}${NC}"
echo -e "${YELLOW}📦 Chat Version: ${CHAT_VERSION}${NC}"
echo -e "${YELLOW}📦 Portfolio Version: ${PORTFOLIO_VERSION}${NC}"
echo -e "${YELLOW}📦 Nginx Version: ${NGINX_VERSION}${NC}"
echo -e "${YELLOW}🔄 Rollout Counter: ${ROLLOUT_COUNTER}${NC}"
echo ""

# Test SSH connection
echo -e "${BLUE}🔌 Testing SSH connection...${NC}"
if ! ssh -i "${SSH_KEY}" -p "${SWARM_PORT}" -o ConnectTimeout=10 -o BatchMode=yes "${SWARM_USER}@${SWARM_HOST}" "echo 'SSH connection successful'" 2>/dev/null; then
    echo -e "${RED}❌ SSH connection failed!${NC}"
    echo -e "${BLUE}💡 Please check:${NC}"
    echo -e "  - Host: ${SWARM_HOST}"
    echo -e "  - User: ${SWARM_USER}"
    echo ""
    echo -e "${YELLOW}🔧 To configure, set environment variables:${NC}"
    echo -e "  export SWARM_HOST='100.119.42.25'"
    echo -e "  export SWARM_USER='sysop'"
    exit 1
fi

echo -e "${GREEN}✅ SSH connection successful${NC}"

# Upload docker-compose.yml to remote host
echo -e "${BLUE}📤 Uploading docker-compose.yml...${NC}"
scp -i "${SSH_KEY}" -P "${SWARM_PORT}" docker-compose.yml "${SWARM_USER}@${SWARM_HOST}:/tmp/docker-compose-${ROLLOUT_COUNTER}.yml"

# Execute remote deployment
echo -e "${BLUE}🚀 Executing remote deployment...${NC}"
ssh -i "${SSH_KEY}" -p "${SWARM_PORT}" "${SWARM_USER}@${SWARM_HOST}" << EOF
    set -e
    
    echo "🔍 Verifying Docker Swarm status..."
    if ! docker node ls >/dev/null 2>&1; then
        echo "❌ Error: Not a Docker Swarm manager node or Swarm not initialized"
        exit 1
    fi
    
    echo "📋 Setting environment variables..."
    export CHAT_VERSION="${CHAT_VERSION}"
    export PORTFOLIO_VERSION="${PORTFOLIO_VERSION}"
    export NGINX_VERSION="${NGINX_VERSION}"
    export ROLLOUT_COUNTER="${ROLLOUT_COUNTER}"
    
    echo "🚀 Deploying stack: ${STACK_NAME}"
    echo "   Chat Version: \${CHAT_VERSION}"
    echo "   Portfolio Version: \${PORTFOLIO_VERSION}"
    echo "   Nginx Version: \${NGINX_VERSION}"
    echo "   Rollout Counter: \${ROLLOUT_COUNTER}"
    
    # Deploy the stack
    if docker stack deploy -c /tmp/docker-compose-${ROLLOUT_COUNTER}.yml "${STACK_NAME}"; then
        echo "✅ Stack deployed successfully!"
        
        echo ""
        echo "📊 Current services:"
        docker service ls
        
        echo ""
        echo "🔍 Chat service status:"
        docker service ps ${STACK_NAME}_chat --no-trunc | head -10
        
        # Clean up temporary file
        rm -f /tmp/docker-compose-${ROLLOUT_COUNTER}.yml
    else
        echo "❌ Stack deployment failed!"
        rm -f /tmp/docker-compose-${ROLLOUT_COUNTER}.yml
        exit 1
    fi
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 Remote deployment completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}🔍 Useful remote commands:${NC}"
    echo -e "  📊 Check services: ${YELLOW}ssh ${SWARM_USER}@${SWARM_HOST} 'docker service ls'${NC}"
    echo -e "  📋 Check chat status: ${YELLOW}ssh ${SWARM_USER}@${SWARM_HOST} 'docker service ps ${STACK_NAME}_chat'${NC}"
    echo -e "  📝 Check chat logs: ${YELLOW}ssh ${SWARM_USER}@${SWARM_HOST} 'docker service logs ${STACK_NAME}_chat --tail 50'${NC}"
    echo ""
    echo -e "${BLUE}🌐 Test your deployment:${NC}"
    echo -e "  ${YELLOW}https://chat.baena.ai${NC} - Should now include Tailwind CSS fixes"
else
    echo -e "${RED}❌ Remote deployment failed!${NC}"
    exit 1
fi