# Deploying New Supabase Secrets to Production

## Overview

This guide walks you through creating and deploying the new Supabase API key secrets to your Docker Swarm production environment.

## Step 1: Access Your Production Server

SSH into your Docker Swarm manager node:

```bash
ssh your-production-server
```

## Step 2: Create the New Secrets

Run the secret creation script on the Swarm manager:

```bash
# Option A: If you have the script on the server
# Make sure to set the keys as environment variables first!
export SUPABASE_PUBLISHABLE_KEY="your_actual_publishable_key_here"
export SUPABASE_SECRET_KEY="your_actual_secret_key_here"
./create-supabase-secrets.sh

# Option B: Run commands manually (REPLACE WITH YOUR ACTUAL KEYS)
echo "sb_publishable_YOUR_ACTUAL_KEY_HERE" | docker secret create supabase_publishable_key -
echo "sb_secret_YOUR_ACTUAL_KEY_HERE" | docker secret create supabase_secret_key -
```

## Step 3: Verify Secrets Were Created

```bash
docker secret ls --filter "name=supabase"
```

Expected output:
```
ID                          NAME                        CREATED          UPDATED
xxxxxxxxxxxxx               supabase_publishable_key    X seconds ago    X seconds ago
xxxxxxxxxxxxx               supabase_secret_key         X seconds ago    X seconds ago
```

## Step 4: Update Your Docker Compose Stack

Your `docker-compose.yml` should reference the new secrets:

```yaml
version: '3.8'

services:
  chat:
    image: ghcr.io/jesus-baena/chat-humanitarian-agent:latest
    secrets:
      - supabase_publishable_key
      - supabase_secret_key
      - flowise_api_key
      - nuxt_ui_pro_license
    environment:
      # Map secrets to environment variables
      NUXT_PUBLIC_SUPABASE_URL: https://qecdwuwkxgwkpopmdewl.supabase.co
      NUXT_PUBLIC_SUPABASE_KEY_FILE: /run/secrets/supabase_publishable_key
      SUPABASE_URL: https://qecdwuwkxgwkpopmdewl.supabase.co
      SUPABASE_SECRET_KEY_FILE: /run/secrets/supabase_secret_key
      # ... other environment variables

secrets:
  supabase_publishable_key:
    external: true
  supabase_secret_key:
    external: true
  flowise_api_key:
    external: true
  nuxt_ui_pro_license:
    external: true
```

## Step 5: Update Your Entrypoint Script

Your container's entrypoint should read the secrets and export them:

```bash
#!/bin/sh
# Read Docker secrets and export as environment variables
if [ -f /run/secrets/supabase_publishable_key ]; then
  export NUXT_PUBLIC_SUPABASE_KEY=$(cat /run/secrets/supabase_publishable_key)
fi

if [ -f /run/secrets/supabase_secret_key ]; then
  export SUPABASE_SECRET_KEY=$(cat /run/secrets/supabase_secret_key)
fi

# Start the application
exec node .output/server/index.mjs
```

## Step 6: Deploy the Updated Stack

```bash
# Deploy or update the stack
docker stack deploy -c docker-compose.yml web

# Or if using Portainer, redeploy via UI
```

## Step 7: Verify the Deployment

```bash
# Check service status
docker service ps web_chat

# Check logs for the new keys being loaded
docker service logs web_chat | grep -i supabase

# Test the application
curl https://chat.baena.ai
```

## Step 8: Remove Old Legacy Secrets (Optional)

Once confirmed the new secrets work:

```bash
# List old secrets
docker secret ls | grep -E "supabase.*anon|service_role"

# Remove old secrets (only if no longer used)
docker secret rm supabase_anon_key
docker secret rm supabase_service_role_key
```

## Troubleshooting

### Secret Already Exists

If you get "secret already exists" error:

```bash
# Option 1: Use versioned names
echo "sb_publishable_YOUR_ACTUAL_KEY_HERE" | docker secret create supabase_publishable_key_v2 -

# Option 2: Remove and recreate (DANGEROUS - causes downtime)
docker secret rm supabase_publishable_key
echo "sb_publishable_YOUR_ACTUAL_KEY_HERE" | docker secret create supabase_publishable_key -
```

### Service Not Picking Up New Secrets

```bash
# Force service update
docker service update --force web_chat

# Or redeploy the entire stack
docker stack rm web
docker stack deploy -c docker-compose.yml web
```

### Check What Secrets a Service Is Using

```bash
docker service inspect web_chat --format='{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' | jq
```

## Using Portainer UI

If you prefer using the Portainer web interface:

1. Go to **Portainer** → **Secrets**
2. Click **Add secret**
3. Name: `supabase_publishable_key`
4. Secret: `sb_publishable_YOUR_ACTUAL_KEY_HERE` ⚠️ Use your real key
5. Click **Create secret**
6. Repeat for `supabase_secret_key`
7. Go to **Stacks** → **web** → **Editor**
8. Update the compose file to reference new secrets
9. Click **Update the stack**

## Security Best Practices

1. ✅ Never commit secrets to git (already in `.gitignore`)
2. ✅ Use Docker secrets for production (more secure than env vars)
3. ✅ Rotate secrets periodically
4. ✅ Use versioned secret names for zero-downtime rotation
5. ✅ Monitor secret usage before removing old ones

## Verification Checklist

- [ ] New secrets created in Docker Swarm
- [ ] docker-compose.yml updated to reference new secrets
- [ ] Entrypoint script reads and exports secrets
- [ ] Stack redeployed successfully
- [ ] Application loads without errors
- [ ] Supabase authentication works
- [ ] Database queries execute properly
- [ ] Old secrets removed (if applicable)

---

**Last Updated**: October 16, 2025
**Status**: Ready for deployment
