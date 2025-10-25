# Production Deployment Status

## Completed Steps

1) Docker build configuration updated (Flowise build args) and pushed
2) GitHub Secrets added for required NUXT_PUBLIC_* vars
3) swarm-infra compose cleaned (no hardcoded Flowise secrets)

## In Progress

- GitHub Actions building and pushing `ghcr.io/jesus-baena/chat-humanitarian-agent:latest`
- Monitor the workflow in repository Actions

## Next Steps

1) Wait for build to finish
2) Update Swarm service to latest image and monitor rollout/logs
3) Verify end-to-end: send a message; confirm AI stream and persistence

## Architecture note

- NUXT_PUBLIC_* must be provided at build time (baked into bundle)
- Server-only SUPABASE_* may be provided via Swarm secrets at runtime
