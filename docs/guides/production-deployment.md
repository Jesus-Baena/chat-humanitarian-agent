# Production Deployment Guide

## Overview

This guide covers how to deploy the chat-humanitarian-agent application to production using Docker Swarm.

## Prerequisites

- Docker Swarm cluster configured
- Access to the swarm manager node
- GitHub Container Registry credentials
- Required secrets configured in Docker Swarm

## Required Environment Variables

The application requires the following environment variables for production:

### Client-Side (NUXT_PUBLIC_*)
These must be set at **build time** (in GitHub Actions) and **runtime** (in Docker service):

- `NUXT_PUBLIC_SUPABASE_URL` - Supabase project URL
- `NUXT_PUBLIC_SUPABASE_ANON_KEY` - Supabase publishable key
- `NUXT_PUBLIC_FLOWISE_URL` - Flowise API endpoint URL
- `NUXT_PUBLIC_FLOWISE_API_KEY` - Flowise API key
- `NUXT_PUBLIC_SITE_URL` - Application URL (e.g., https://chat.baena.ai)
- `NUXT_PUBLIC_AUTH_BASE` - Authentication base URL (e.g., https://baena.ai)
- `NUXT_PUBLIC_LOGOUT_PATH` - Logout path

### Server-Side
These are provided via Docker secrets:

- `SUPABASE_URL` - Supabase URL
- `SUPABASE_PUBLISHABLE_KEY` - Supabase publishable key
- `SUPABASE_SECRET_KEY` - Supabase service role key
- `FLOWISE_API_KEY` - Flowise API key

## Deployment Methods

### Method 1: Automated Deployment (Recommended)

Use the `deploy.sh` script on the swarm manager:

```bash
# On the swarm manager node
./deploy.sh
```

This script will:
1. Pull the latest Docker image
2. Update the service with all required environment variables
3. Perform a rolling update
4. Show deployment status

### Method 2: Manual Deployment

```bash
# Pull the latest image
docker pull ghcr.io/jesus-baena/chat-humanitarian-agent:latest

# Update the service
docker service update \
  --image ghcr.io/jesus-baena/chat-humanitarian-agent:latest \
  --env-add NUXT_PUBLIC_FLOWISE_URL=https://flowise.baena.site/api/v1/prediction/40718af9-e9bd-47d9-a57b-009cb26f8fe3 \
  --env-add NUXT_PUBLIC_FLOWISE_API_KEY=YOUR_API_KEY \
  --env-add ROLLOUT_VERSION=$(date +%s) \
  --force \
  web_chat
```

### Method 3: Emergency Deployment

If you need to quickly fix environment variables without rebuilding:

```bash
./emergency-deploy.sh
```

## GitHub Actions Setup

The GitHub Actions workflow (`.github/workflows/deploy.yml`) requires the following secrets:

### Required Secrets
1. `NUXT_UI_PRO_LICENSE` - Nuxt UI Pro license key
2. `NUXT_PUBLIC_SUPABASE_URL` - Supabase project URL
3. `NUXT_PUBLIC_SUPABASE_ANON_KEY` - Supabase publishable key
4. `NUXT_PUBLIC_FLOWISE_URL` - Flowise API endpoint
5. `NUXT_PUBLIC_FLOWISE_API_KEY` - Flowise API key

### Setting GitHub Secrets

1. Go to repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret with its value

**Important**: `NUXT_PUBLIC_*` variables must be GitHub Secrets because they're baked into the client bundle at build time.

## Docker Swarm Secrets

The following secrets should be created in Docker Swarm:

```bash
# Create secrets (run once on swarm manager)
echo "YOUR_URL" | docker secret create SUPABASE_URL -
echo "YOUR_KEY" | docker secret create SUPABASE_PUBLISHABLE_KEY -
echo "YOUR_SECRET" | docker secret create SUPABASE_SECRET_KEY -
echo "YOUR_KEY" | docker secret create FLOWISE_API_KEY -
echo "YOUR_URL" | docker secret create NUXT_PUBLIC_SUPABASE_URL -
```

## Service Configuration

The service runs with:
- **Replicas**: 2
- **Memory Limit**: 512MB per container
- **CPU Limit**: 0.5 cores per container
- **Network**: `public` overlay network
- **Update Strategy**: Rolling update (1 container at a time, 10s delay)

## Verification

After deployment, verify:

1. **Service Status**:
   ```bash
   docker service ps web_chat
   ```

2. **Logs**:
   ```bash
   docker service logs web_chat --tail 50
   ```

3. **Health Check**:
   ```bash
   curl https://chat.baena.ai
   ```

4. **Test Chat**:
   - Visit https://chat.baena.ai
   - Send a test message
   - Verify Flowise integration works

## Troubleshooting

### "No completion backend configured" Error

This means `NUXT_PUBLIC_FLOWISE_URL` is missing. Fix:

```bash
./emergency-deploy.sh
```

### Service Won't Start

Check logs:
```bash
docker service logs web_chat --tail 100
```

Common issues:
- Missing secrets
- Invalid environment variables
- Image pull failures

### Rollback

If deployment fails:
```bash
docker service rollback web_chat
```

## Monitoring

### View Service Logs
```bash
docker service logs -f web_chat
```

### Check Service Status
```bash
docker service ps web_chat --no-trunc
```

### Inspect Configuration
```bash
docker service inspect web_chat
```

## Best Practices

1. **Always test in staging first** (if available)
2. **Monitor logs during deployment**
3. **Keep secrets secure** - never commit them to git
4. **Document changes** - update this guide when changing configuration
5. **Use rollback** if issues occur
6. **Test thoroughly** after each deployment

## Common Tasks

### Update Single Environment Variable
```bash
docker service update \
  --env-add VARIABLE_NAME=new_value \
  web_chat
```

### Increase Replicas
```bash
docker service scale web_chat=3
```

### Force Restart
```bash
docker service update --force web_chat
```

### View Environment Variables
```bash
docker service inspect web_chat --format '{{json .Spec.TaskTemplate.ContainerSpec.Env}}' | jq
```
