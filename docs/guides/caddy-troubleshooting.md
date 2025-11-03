# Caddy + Docker Swarm Troubleshooting

## Problem: "Site is not secure" / HTTP instead of HTTPS

This happens when Caddy can't reach the Docker service or the service isn't running.

## Quick Diagnostics

### 1. Check if the service is running
```bash
docker service ls | grep chat
docker service ps web_chat
```

### 2. Check if Caddy can resolve the service
```bash
# From inside the Caddy container:
docker exec -it $(docker ps -q -f name=caddy) nslookup web_chat
docker exec -it $(docker ps -q -f name=caddy) wget -O- http://web_chat:3000 --timeout=5
```

### 3. Check network connectivity
```bash
# Verify both are on the same network
docker network inspect public | grep -A 5 "web_chat\|caddy"
```

### 4. Check Caddy configuration
```bash
# View Caddy config
docker exec -it $(docker ps -q -f name=caddy) cat /etc/caddy/Caddyfile

# Check Caddy logs
docker logs $(docker ps -q -f name=caddy) --tail 50
```

## Expected Caddyfile Configuration

For Docker Swarm service discovery, your Caddyfile should have:

```caddyfile
chat.baena.ai {
    reverse_proxy web_chat:3000
    
    # Optional: Enable logging
    log {
        output file /var/log/caddy/chat.log
        format console
    }
}
```

**Note**: `web_chat` is the service name (`{stack}_{service}`)
- Stack name: `web`
- Service name: `chat`
- Full service DNS: `web_chat`

## Common Issues

### Issue 1: Service name mismatch
**Symptom**: Caddy can't resolve hostname
**Fix**: Make sure Caddyfile uses `web_chat` not just `chat`

### Issue 2: Network isolation
**Symptom**: Caddy and service on different networks
**Fix**: Both must be on `public` network:
```yaml
# In docker-compose.prod.yml
networks:
  - public

# Caddy also needs:
networks:
  - public
```

### Issue 3: Port mismatch
**Symptom**: Connection refused
**Fix**: Verify service listens on port 3000:
```yaml
environment:
  - NITRO_PORT=3000  # ✅ Correct
```

### Issue 4: Service not started
**Symptom**: DNS resolves but connection times out
**Fix**: Check service status:
```bash
docker service ps web_chat --no-trunc
```

## Deployment Steps After Fix

1. **Update the stack**:
   ```bash
   ./deploy-stack.sh
   ```

2. **Reload Caddy** (if config changed):
   ```bash
   docker exec $(docker ps -q -f name=caddy) caddy reload --config /etc/caddy/Caddyfile
   ```

3. **Test immediately**:
   ```bash
   curl -I https://chat.baena.ai
   # Should return: HTTP/2 200
   ```

## Still Not Working?

Check if the issue is:
1. **Build-time environment variables** (see `flowise-troubleshooting.md`)
2. **Supabase secrets** (see `deploy-supabase-secrets.md`)
3. **Service crash loop** (check logs: `docker service logs web_chat`)

## Quick Health Check Script

```bash
#!/bin/bash
echo "=== Service Status ==="
docker service ps web_chat --filter "desired-state=running"

echo -e "\n=== Network Connectivity ==="
docker exec $(docker ps -q -f name=caddy) wget -qO- http://web_chat:3000 --timeout=3 && echo "✅ Reachable" || echo "❌ Not reachable"

echo -e "\n=== Caddy Logs (last 20 lines) ==="
docker logs $(docker ps -q -f name=caddy) --tail 20 | grep chat
```

Save this as `check-caddy.sh` and run it on your production server.
