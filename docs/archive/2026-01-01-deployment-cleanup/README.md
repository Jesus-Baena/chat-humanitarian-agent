# Archive - Deployment Cleanup (January 1, 2026)

This archive contains documentation and scripts from the project's early deployment phase that are now outdated or consolidated.

## What Was Archived

### Deployment Scripts
These scripts were replaced by the simplified `ssh-deploy.sh`:
- `deploy.sh` - Old on-swarm deployment
- `deploy-stack.sh` - Stack-based deployment
- `emergency-deploy.sh` - Emergency Flowise fix (no longer needed)
- `force-refresh-deploy.sh` - Browser cache workaround
- `wait-and-deploy.sh` - GitHub Actions wait script

### Deployment Documentation
These were consolidated into `DEPLOYMENT.md` and `docs/guides/production-deployment.md`:
- `deploy-production.md` - Multiple deployment options
- `DEPLOYMENT_STATUS.md` - Historical deployment status
- `DEPLOYMENT_VERIFICATION.md` - Old verification report
- `docs/guides/deployment-status.md` - Duplicate status doc
- `docs/guides/deployment-verification.md` - Duplicate verification doc

### Fix Documentation
These document resolved issues that are no longer relevant:
- `ACTION_CHECKLIST.md` - Old action items
- `AUTH_FIX_SUMMARY.md` - Auth fix summary (now in AUTH_IMPLEMENTATION_GUIDE.md)
- `AUTH_INVESTIGATION_REPORT.md` - Detailed auth investigation
- `CLEAR_COOKIES_NOW.md` - Cookie clearing instructions
- `CROSS_DOMAIN_AUTH_FIX.md` - Cross-domain auth fix
- `DEBUG_INSTRUCTIONS.md` - Old debug instructions
- `FIXES_APPLIED.md` - Historical fixes list
- `FIX_SUMMARY.md` - General fix summary
- `FLOWISE_BUILD_FIX.md` - Flowise build issue fix
- `FLOWISE_FIX_COMPLETE.md` - Flowise completion notice
- `FLOWISE_KEY_CORRECTION.md` - API key correction
- `INVESTIGATION_COMPLETE.md` - Investigation completion notice
- `ISSUE_RESOLVED.md` - Issue resolution notice
- `PERMANENT_FIX.md` - Permanent fix documentation
- `PRODUCTION_AUTH_FIX.md` - Production auth fix
- `PRODUCTION_FIX.md` - General production fix
- `PRODUCTION_READY.md` - Production readiness notice
- `QUICK_FIX_CHECKLIST.md` - Quick fix checklist
- `RATE_LIMIT_FIX_DEPLOYMENT.md` - Rate limit fix deployment
- `RATE_LIMIT_QUICK_FIX.md` - Rate limit quick fix
- `QUICK_REFERENCE.md` - Old quick reference
- `DOCS_CLEANUP_PLAN.md` - Documentation cleanup plan

## Current Deployment Process

As of January 1, 2026, the deployment process is:

### From Local Machine
```bash
./ssh-deploy.sh
```

### On Swarm Manager (100.120.229.13)
```bash
sudo docker pull ghcr.io/jesus-baena/chat-humanitarian-agent:latest
export ROLLOUT_VERSION=$(date +%s)
sudo docker stack deploy -c docker-compose.prod.yml web
```

## Current Documentation

- **[DEPLOYMENT.md](../../DEPLOYMENT.md)** - Quick deployment reference
- **[docs/guides/production-deployment.md](../../docs/guides/production-deployment.md)** - Comprehensive guide
- **[QUICK_DEPLOY.md](../../QUICK_DEPLOY.md)** - Command reference
- **[DOCUMENTATION_INDEX.md](../../DOCUMENTATION_INDEX.md)** - Complete documentation index

## Why This Cleanup?

The project had accumulated many fix documents during development and troubleshooting. Now that deployment is stable and well-documented, these historical documents were archived to:

1. Simplify the root directory
2. Reduce confusion about which process to follow
3. Preserve history for reference
4. Make current documentation easier to find

## Access to Archived Files

All files remain in this directory and are accessible via git history.
