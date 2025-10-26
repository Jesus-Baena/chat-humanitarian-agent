# Flowise Configuration Troubleshooting Guide

## Current Issue: "No completion backend configured"

The error indicates that your chat app cannot connect to the Flowise AI backend. This prevents the AI from generating responses.

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