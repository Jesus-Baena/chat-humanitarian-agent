# Portainer Redeployment Guide

## Quick Redeployment (Image Already Built)

Since your image is already built at `ghcr.io/jesus-baena/chat-humanitarian-agent:latest`, follow these steps to redeploy via Portainer UI:

### Method 1: Stack Update (Recommended)

1. **Log into Portainer** web interface
2. Navigate to **Stacks** in the left sidebar
3. Find and click on the **web** stack
4. Click the **Editor** button
5. The current `docker-compose.prod.yml` configuration will be shown
6. Click **Update the stack** button at the bottom
7. **Enable these options:**
   - ✅ **Re-pull image** - Forces Docker to pull the latest image
   - ✅ **Prune services** (optional) - Removes old stopped containers
8. Click **Update**

**What happens:**
- Portainer will pull `ghcr.io/jesus-baena/chat-humanitarian-agent:latest`
- Rolling update of `web_chat` service (2 replicas)
- Zero downtime deployment (one replica updates at a time)
- All environment variables and secrets are preserved

### Method 2: Service Update (Quick Alternative)

1. Go to **Services** in the left sidebar
2. Click on **web_chat** service
3. Click **Update this service**
4. In the **Image** section, confirm image is `ghcr.io/jesus-baena/chat-humanitarian-agent:latest`
5. Click **Pull latest image version** toggle
6. Scroll to bottom and click **Update service**

### Method 3: Command Line (If SSH Works)

If SSH is properly configured, you can use the automated script:

```bash
./ssh-deploy.sh
```

Or manually on the Swarm manager:

```bash
# SSH into your Swarm manager
ssh sysop@100.120.229.13

# Pull latest image
sudo docker pull ghcr.io/jesus-baena/chat-humanitarian-agent:latest

# Update the service with rolling update
sudo docker service update --image ghcr.io/jesus-baena/chat-humanitarian-agent:latest --force web_chat
```

## Post-Deployment Verification

### 1. Check Service Status

In Portainer:
- Go to **Services** → **web_chat**
- Verify **Running tasks: 2/2**
- Check that both replicas are in "Running" state

Or via CLI:
```bash
docker service ps web_chat --filter "desired-state=running"
```

### 2. Check Service Logs

In Portainer:
- Go to **Services** → **web_chat** → **Service logs**
- Look for startup messages confirming Supabase and Flowise configuration

Or via CLI:
```bash
docker service logs web_chat --tail 50
```

Expected output should include:
```
🔍 Supabase Environment Check:
SUPABASE_URL: https://qecdwuwkxg...
NUXT_PUBLIC_FLOWISE_URL: https://flowise.baena.site...
```

### 3. Test the Application

1. **Visit:** https://chat.baena.ai
2. **Clear cookies** (F12 → Application → Cookies → Delete all `sb-*` cookies)
3. **Test authentication** - Try signing in
4. **Test chat** - Send a message to verify AI responses work

### 4. Monitor Supabase Logs (Optional)

Visit: https://supabase.com/dashboard/project/qecdwuwkxgwkpopmdewl/logs/auth-logs

Look for:
- ✅ Normal login requests
- ✅ Occasional token refresh (every 5-50 minutes)
- ❌ NO bursts of token refresh requests
- ❌ NO 429 rate limit errors

## Troubleshooting

### Service Won't Start

Check logs for error messages:
```bash
docker service logs web_chat --tail 100
```

Common issues:
- Missing secrets → Verify all secrets exist: `docker secret ls`
- Wrong image → Verify image name in stack configuration
- Resource limits → Check memory/CPU constraints

### "No completion backend configured" Error

This means Flowise environment variables are missing. Verify:

1. In Portainer, check **Services** → **web_chat** → **Environment variables**
2. Confirm these exist:
   - `NUXT_PUBLIC_FLOWISE_URL`
   - `NUXT_PUBLIC_FLOWISE_API_KEY`
   - `FLOWISE_API_KEY` (from secrets)

If missing, the issue is in the GitHub Actions build (secrets not configured).
See [SECRETS_SETUP.md](SECRETS_SETUP.md) for fix.

### Authentication Issues

If users can't log in:
1. Check Supabase logs for rate limit errors
2. Verify cookie domain is set correctly (`.baena.ai`)
3. Clear all browser cookies and try again
4. Check service logs for auth-related errors

## Rollback

If the new deployment has issues:

### Via Portainer UI
1. Go to **Services** → **web_chat**
2. Click **Rollback this service**
3. Confirm rollback

### Via CLI
```bash
docker service rollback web_chat
```

This will revert to the previous working version.

## Stack Configuration Reference

Current stack uses:
- **Stack name:** `web`
- **Service name:** `web_chat`
- **Image:** `ghcr.io/jesus-baena/chat-humanitarian-agent:latest`
- **Replicas:** 2
- **Network:** `public` (external)
- **Update strategy:** Rolling update (1 at a time, 10s delay)

Secrets required:
- `NUXT_PUBLIC_SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_SECRET_KEY`
- `SUPABASE_URL`
- `FLOWISE_API_KEY`

All configuration is defined in `docker-compose.prod.yml`.
