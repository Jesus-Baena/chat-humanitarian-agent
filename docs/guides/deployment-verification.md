# Deployment Verification Report (Sanitized)

## Verification Summary

- GitHub Actions build completed and pushed `ghcr.io/jesus-baena/chat-humanitarian-agent:latest`
- Docker Swarm service updated successfully; all replicas running
- Image labels match the intended commit revision

## What Changed in Production

Before: image without Flowise config baked in → messages failed

After: image built with Flowise config (URL + API key) → messages stream

## Testing Checklist

1. Visit production URL and open a chat
2. Send a message; verify typing indicator and streamed response
3. Refresh; verify messages persisted
4. Check browser console for errors and Network tab for Flowise request

## Configuration Notes

Removed from compose (now provided at build time):
```yaml
# REMOVED (ignored previously):
- NUXT_PUBLIC_FLOWISE_URL=${FLOWISE_URL}
- NUXT_PUBLIC_FLOWISE_API_KEY=YOUR_FLOWISE_API_KEY
```

Build args passed in CI:
```yaml
build-args: |
  NUXT_UI_PRO_LICENSE=${{ secrets.NUXT_UI_PRO_LICENSE }}
  NUXT_PUBLIC_SUPABASE_URL=${{ secrets.NUXT_PUBLIC_SUPABASE_URL }}
  NUXT_PUBLIC_SUPABASE_ANON_KEY=${{ secrets.NUXT_PUBLIC_SUPABASE_ANON_KEY }}
  NUXT_PUBLIC_FLOWISE_URL=${{ secrets.NUXT_PUBLIC_FLOWISE_URL }}
  NUXT_PUBLIC_FLOWISE_API_KEY=${{ secrets.NUXT_PUBLIC_FLOWISE_API_KEY }}
```

## Troubleshooting

- Confirm bundle has public config in browser (`useRuntimeConfig().public`)
- Service logs for rollout errors
- If needed, rollback to a previously working image
