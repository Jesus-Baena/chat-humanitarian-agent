# Production API Routes 404 Troubleshooting

## Issue Summary
- **Problem**: `/api/chats/[id]/messages` returns 404 in production
- **Status**: ✅ Local development works, ✅ Local production build works, ❌ Production deployment fails
- **Root Cause**: Production deployment configuration issue

## Diagnostic Steps

### 1. Check Docker Build
```bash
# SSH into your production server
ssh your-production-server

# Check if the API routes exist in production container
docker exec -it your-chat-container ls -la /app/.output/server/chunks/routes/api/chats/_id/
```

**Expected output:**
```
messages.get.mjs
messages.post.mjs
```

### 2. Check Container Startup
```bash
# Check container logs for startup errors
docker logs your-chat-container | head -20

# Check if Nitro server is starting correctly
docker logs your-chat-container | grep -i "listening\|server\|port"
```

### 3. Check Dockerfile
Your Dockerfile should:
- ✅ Copy `.output/server` directory completely
- ✅ Start with `node .output/server/index.mjs`
- ✅ Not just copy client files

**Correct Dockerfile pattern:**
```dockerfile
# Build stage
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm@10.13.1
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm run build

# Production stage
FROM node:22-alpine AS production
WORKDIR /app
COPY --from=builder /app/.output/server ./
COPY --from=builder /app/.output/public ./public
EXPOSE 3000
CMD ["node", "index.mjs"]
```

### 4. Check Reverse Proxy Configuration

If using Nginx/Traefik, ensure `/api/*` requests are proxied to the Node.js server:

**Nginx example:**
```nginx
location /api/ {
    proxy_pass http://chat-app:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

**Traefik example:**
```yaml
services:
  chat-app:
    image: your-chat-image
    labels:
      - "traefik.http.routers.chat.rule=Host(`chat.baena.ai`)"
      # Ensure API routes go to the same service
```

## Common Fixes

### Fix 1: Docker Build Missing Server Routes
If the API routes aren't in the production container:

1. **Check your Dockerfile** copies the entire `.output` directory
2. **Rebuild the Docker image** with correct paths
3. **Redeploy** with the new image

### Fix 2: Incorrect Startup Command
If the container is running but API routes don't work:

1. **Check Docker command** starts the Nitro server: `node .output/server/index.mjs`
2. **Not a client-only build** - must be full-stack Nuxt build
3. **Environment variables** are passed to production container

### Fix 3: Reverse Proxy Misconfiguration
If using a reverse proxy (Nginx, Traefik):

1. **Ensure `/api/*` routes** are proxied to the Node.js container
2. **Check proxy headers** are set correctly
3. **Verify container networking** allows communication

## Immediate Action Plan

### Step 1: Verify Production Container
```bash
# SSH to production server
ssh your-production-server

# Check if API routes exist in container
docker exec -it $(docker ps -q --filter "name=chat") ls -la /.output/server/chunks/routes/api/chats/_id/

# Check container startup logs
docker logs $(docker ps -q --filter "name=chat") | tail -50
```

### Step 2: Test Direct Container Access
```bash
# Get container IP or use localhost with port mapping
# Test API endpoint directly (bypass reverse proxy)
curl -X GET "http://container-ip:3000/api/chats"
# or if port is mapped:
curl -X GET "http://localhost:mapped-port/api/chats"
```

### Step 3: Check Build Process
If API routes are missing from container:
1. Rebuild Docker image with correct Dockerfile
2. Ensure `.output/server` is completely copied
3. Verify build process includes server routes

### Step 4: Verify Environment
```bash
# Check production environment variables
docker exec -it your-chat-container env | grep -E "(SUPABASE|FLOWISE|NODE_ENV)"
```

## Expected Behavior

**Working production should have:**
- ✅ Container with `.output/server/chunks/routes/api/chats/_id/messages.get.mjs`
- ✅ Nitro server listening on port 3000 (or configured port)
- ✅ API endpoints responding (even with errors, not 404)
- ✅ Environment variables properly set

## Next Steps

1. **Diagnose**: Run the diagnostic commands above
2. **Identify**: Determine if it's Docker build, startup, or proxy issue
3. **Fix**: Apply appropriate fix based on findings
4. **Redeploy**: Update production deployment
5. **Verify**: Test API endpoints work

The fix will be one of:
- Rebuild Docker image with correct server files
- Fix reverse proxy to route API requests
- Correct startup command to run Nitro server
- Add missing environment variables