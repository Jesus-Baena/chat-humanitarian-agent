# Flowise "No completion backend configured" - Cache Issue

## Problem Summary

The application intermittently showed "No completion backend configured" error even though GitHub Secrets were correctly set. This was caused by **GitHub Actions Docker build cache** serving stale layers built without the Flowise environment variables.

## Root Cause

1. **Initial bad build**: Early deployment built Docker image when `NUXT_PUBLIC_FLOWISE_URL` and `NUXT_PUBLIC_FLOWISE_API_KEY` secrets were empty
2. **Layer caching**: GitHub Actions cached those build layers with empty values baked in
3. **Cache reuse**: Subsequent builds reused cached layers instead of rebuilding with new secret values
4. **Intermittent behavior**: 
   - Hard refresh (Ctrl+Shift+R) worked → loaded fresh JS from new builds
   - Normal page load failed → browser cached old JS from bad builds
   - Sometimes worked, sometimes didn't → depended on cache state

## Evidence

Production payload showed empty Flowise config:
```javascript
flowiseUrl:"",flowiseApiKey:""
```

This confirmed the build was created without environment variables, despite secrets being set in GitHub.

## The Fix

Applied three-layer protection:

### 1. Secret Validation (Fail Fast)
```yaml
- name: Verify build arguments (diagnostic)
  run: |
    if [ -z "${{ secrets.NUXT_PUBLIC_FLOWISE_URL }}" ]; then
      echo "❌ ERROR: NUXT_PUBLIC_FLOWISE_URL is not set!"
      exit 1
    fi
```

Builds now **fail immediately** if secrets are missing, preventing bad deployments.

### 2. Cache Scoping (Invalidation)
```yaml
- name: Create cache key from build args
  id: cache-key
  run: |
    echo "hash=$(echo '${{ secrets.NUXT_PUBLIC_FLOWISE_URL }}${{ secrets.NUXT_PUBLIC_FLOWISE_API_KEY }}' | sha256sum | cut -d' ' -f1 | cut -c1-8)" >> $GITHUB_OUTPUT
```

Cache is now scoped by hash of secrets:
```yaml
cache-from: type=gha,scope=build-${{ steps.cache-key.outputs.hash }}
cache-to: type=gha,mode=max,scope=build-${{ steps.cache-key.outputs.hash }}
```

When secrets change, cache is invalidated and full rebuild occurs.

### 3. Build Date Tracking
```yaml
build-args: |
  BUILD_DATE=${{ github.event.head_commit.timestamp }}
```

Helps track which build is deployed and when it was created.

## Prevention

This issue **will NOT happen again** because:

✅ Builds fail if secrets are missing (caught before bad cache is created)  
✅ Cache is scoped to secret values (changing secrets = new cache)  
✅ Validation logs show exactly which secrets are set/missing  
✅ Build timestamp helps identify stale deployments

## Manual Recovery (if needed)

If you ever see this issue again:

1. **Check GitHub Actions logs**: https://github.com/Jesus-Baena/chat-humanitarian-agent/actions
2. **Look for validation output**: Shows which secrets are set/missing
3. **Clear browser cache**: Ctrl+Shift+R (hard refresh)
4. **Force rebuild**: `git commit --allow-empty -m "rebuild" && git push`

## Related Files

- `.github/workflows/deploy.yml` - Build workflow with cache scoping
- `app/composables/useAssistants.ts` - Reads Flowise config at runtime
- `nuxt.config.ts` - Exposes secrets as runtimeConfig.public

## Key Takeaway

**Client-side environment variables** (`NUXT_PUBLIC_*`) must be set as **GitHub Secrets** because they're baked into the JavaScript bundle at build time. Docker Swarm secrets alone won't work for these variables.
