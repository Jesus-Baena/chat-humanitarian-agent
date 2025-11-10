# 🚀 Quick Deployment Reference

## Production Deployment (On Swarm Manager)

### Normal Deployment
```bash
./deploy.sh
```
This pulls the latest image and updates the service with all required environment variables.

### Emergency Fix (If Flowise Fails)
```bash
./emergency-deploy.sh
```
Quickly adds missing Flowise environment variables without rebuilding.

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
**Cause**: Missing `NUXT_PUBLIC_FLOWISE_URL` in service environment

**Fix**: Run `./emergency-deploy.sh`

### Service Won't Start
**Check logs**: `docker service logs web_chat --tail 50`

**Common fixes**:
- `docker service update --force web_chat` (restart)
- `docker service rollback web_chat` (revert to previous)

### Verify Deployment
```bash
# Check service status
docker service ps web_chat

# Check environment variables
docker service inspect web_chat --format '{{json .Spec.TaskTemplate.ContainerSpec.Env}}' | jq

# View logs
docker service logs web_chat --tail 20
```

## Manual Service Update

If you need to update manually:

```bash
docker service update \
  --image ghcr.io/jesus-baena/chat-humanitarian-agent:latest \
  --env-add NUXT_PUBLIC_FLOWISE_URL=https://flowise.baena.site/api/v1/prediction/40718af9-e9bd-47d9-a57b-009cb26f8fe3 \
  --env-add NUXT_PUBLIC_FLOWISE_API_KEY=YOUR_KEY \
  --env-add ROLLOUT_VERSION=$(date +%s) \
  --force \
  web_chat
```

## Full Documentation

See: `docs/guides/production-deployment.md`
