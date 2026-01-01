# 🚀 Quick Deployment Reference

## Production Deployment

### SSH Deployment (From Local Machine)
```bash
./ssh-deploy.sh
```
Connects to the Swarm manager (100.120.229.13), uploads the compose file, and deploys the stack.

### Manual Deployment (On Swarm Manager)
```bash
# Pull latest image
sudo docker pull ghcr.io/jesus-baena/chat-humanitarian-agent:latest

# Deploy stack
export ROLLOUT_VERSION=$(date +%s)
sudo docker stack deploy -c docker-compose.prod.yml web
```

## Key Environment Variables

These **MUST** be present in production for the app to work:

### Client-Side (Required at Runtime)
- `NUXT_PUBLIC_FLOWISE_URL` - Get from your Flowise instance
- `NUXT_PUBLIC_FLOWISE_API_KEY` - Get from your Flowise instance
- `NUXT_PUBLIC_SUPABASE_URL`
- `NUXT_PUBLIC_SUPABASE_ANON_KEY`

### Build-Time (GitHub Actions Secrets)
All `NUXT_PUBLIC_*` variables must also be set as GitHub Secrets for the build to include them in the client bundle.

## Troubleshooting

### Error: "No completion backend configured"
**Cause**: Missing `NUXT_PUBLIC_FLOWISE_URL` in build

**Fix**: Verify GitHub Secrets are configured and rebuild via GitHub Actions

### Service Won't Start
**Check logs**: `docker service logs web_chat --tail 50`

**Common fixes**:
- `docker service update --force web_chat` (restart)
- `docker service rollback web_chat` (revert to previous)

### Verify Deployment
```bash
# From local machine
ssh sysop@100.120.229.13 "sudo docker service ps web_chat"
ssh sysop@100.120.229.13 "sudo docker service logs web_chat --tail 20"

# Or on swarm manager directly
sudo docker service ps web_chat
sudo docker service logs web_chat --tail 20
```

## Manual Service Update

If you need to force update the service:

```bash
sudo docker service update \
  --image ghcr.io/jesus-baena/chat-humanitarian-agent:latest \
  --env-add ROLLOUT_VERSION=$(date +%s) \
  --force \
  web_chat
```

**Note:** Flowise configuration is baked into the image at build time via GitHub Actions.

## Full Documentation

See: `docs/guides/production-deployment.md`
