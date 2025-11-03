# Flowise Configuration Troubleshooting Guide

## ⚠️ CRITICAL: "No completion backend configured" Error

The error **"No completion backend configured"** means the Flowise URL was not available when the app was **built**. This is the #1 issue in production deployments.

### Root Cause

`NUXT_PUBLIC_*` environment variables are **baked into the client-side JavaScript bundle at BUILD time**, not runtime. This means:

1. ❌ **Setting them in Docker Compose is NOT enough** - Docker only runs the pre-built container
2. ❌ **Docker Swarm secrets are NOT sufficient** - They only work at container runtime
3. ✅ **They MUST be set as GitHub Actions Secrets** - So they're available during the CI/CD build

### Quick Fix for Production

**Step 1: Add GitHub Actions Secrets**

Go to your repository → Settings → Secrets and variables → Actions → Repository secrets

Add these secrets:
- `NUXT_PUBLIC_FLOWISE_URL` = `https://flowise.baena.site/api/v1/prediction/40718af9-e9bd-47d9-a57b-009cb26f8fe3`
- `NUXT_PUBLIC_FLOWISE_API_KEY` = `FO5JgBFwXMPQDE_XrgDn8FSYpGbgtyeZ2h7YlJd-Skk`
- `NUXT_PUBLIC_SUPABASE_URL` = Your Supabase project URL
- `NUXT_PUBLIC_SUPABASE_KEY` = Your Supabase anon/publishable key

**Step 2: Verify GitHub Actions Workflow**

Your `.github/workflows/build.yml` (or similar) should pass these as build args:

```yaml
- name: Build Docker image
  env:
    NUXT_PUBLIC_FLOWISE_URL: ${{ secrets.NUXT_PUBLIC_FLOWISE_URL }}
    NUXT_PUBLIC_FLOWISE_API_KEY: ${{ secrets.NUXT_PUBLIC_FLOWISE_API_KEY }}
    NUXT_PUBLIC_SUPABASE_URL: ${{ secrets.NUXT_PUBLIC_SUPABASE_URL }}
    NUXT_PUBLIC_SUPABASE_KEY: ${{ secrets.NUXT_PUBLIC_SUPABASE_KEY }}
  run: |
    docker build \
      --build-arg NUXT_PUBLIC_FLOWISE_URL="${NUXT_PUBLIC_FLOWISE_URL}" \
      --build-arg NUXT_PUBLIC_FLOWISE_API_KEY="${NUXT_PUBLIC_FLOWISE_API_KEY}" \
      --build-arg NUXT_PUBLIC_SUPABASE_URL="${NUXT_PUBLIC_SUPABASE_URL}" \
      --build-arg NUXT_PUBLIC_SUPABASE_KEY="${NUXT_PUBLIC_SUPABASE_KEY}" \
      -t your-image:tag .
```

**Step 3: Rebuild and Redeploy**

After adding the secrets, trigger a new build (push to main or manually trigger the workflow).

## Understanding the Issue

### Why This Happens

Nuxt uses Vite, which performs **static code analysis** during build:

1. During `pnpm build`, Vite scans code for `import.meta.env.NUXT_PUBLIC_*`
2. It **replaces** these references with actual values (like string literals)
3. The final JavaScript bundle contains hardcoded values
4. At runtime, changing env vars has **no effect** - values are already baked in

### Evidence

If you inspect the built JavaScript (`.output/public/_nuxt/*.js`), you'll see:
```javascript
// If NUXT_PUBLIC_FLOWISE_URL was empty at build time:
const flowiseUrl = undefined  // or ""

// If it was set at build time:
const flowiseUrl = "https://flowise.baena.site/api/v1/prediction/..."
```

## Diagnostic Steps

### 1. Check Environment Variables
```bash
# In your project directory
cd /home/jbi-laptop/Git/chat-humanitarian-agent

# Verify environment variables are loaded
echo "FLOWISE_URL: $NUXT_PUBLIC_FLOWISE_URL"
echo "FLOWISE_KEY: ${NUXT_PUBLIC_FLOWISE_API_KEY:0:10}..." # Show first 10 chars only
```

### 2. Test Flowise Connection
Visit: http://localhost:3001/test-flowise
This page will show:
- Whether environment variables are loaded
- Test connection to your Flowise instance
- Detailed error messages if connection fails

### 3. Verify Flowise Instance
Your Flowise URL should look like:
```
https://your-flowise-instance.com/api/v1/prediction/your-chatflow-id
```

**Check:**
- [ ] Is your Flowise instance running?
- [ ] Is the chatflow ID correct?
- [ ] Does the endpoint accept POST requests?
- [ ] Is the API key valid (if required)?

### 4. Production vs Development
**In Development:**
```bash
# Environment variables loaded from .env file
pnpm dev
```

**In Production:**
```bash
# Environment variables must be set in Docker/deployment
# Check deployment logs for missing environment variables
```

## Common Fixes

### Fix 1: Missing Environment Variables
```bash
# Copy from example and fill in real values
cp .env.example .env
nano .env
```

### Fix 2: Flowise Instance Down
- Check if your Flowise instance is accessible
- Verify the URL in browser: GET request should return 405 Method Not Allowed
- POST with proper payload should work

### Fix 3: Incorrect Chatflow ID
- Get correct chatflow ID from Flowise dashboard
- Update NUXT_PUBLIC_FLOWISE_URL with correct ID

### Fix 4: API Key Issues
- Verify API key in Flowise dashboard
- Check if API key authentication is enabled
- Update NUXT_PUBLIC_FLOWISE_API_KEY

## Production Deployment Fix

If this works in development but not production:

```bash
# Check deployment environment variables
docker logs your-chat-container | grep -i flowise
# or
kubectl logs your-chat-pod | grep -i flowise
```

The variables must be set in your deployment environment (Docker Swarm secrets, Kubernetes ConfigMap, etc.)

## Immediate Action

1. **Test Local Development:**
   ```bash
   cd /home/jbi-laptop/Git/chat-humanitarian-agent
   pnpm dev
   # Visit http://localhost:3001/test-flowise
   ```

2. **If Development Works:**
   - Issue is in production deployment
   - Check environment variables in production container/pod

3. **If Development Fails:**
   - Check .env file has correct Flowise URL and API key
   - Test Flowise endpoint manually with curl/Postman
   - Verify Flowise instance is running and accessible