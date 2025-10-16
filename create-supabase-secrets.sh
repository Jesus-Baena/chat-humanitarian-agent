#!/bin/bash
# Create new Supabase API key secrets in Docker Swarm
# Uses the new sb_publishable_ and sb_secret_ format

set -e

echo "🔐 Creating new Supabase API key secrets in Docker Swarm..."
echo ""

# Check if running on a Swarm manager
if ! docker node ls &> /dev/null; then
  echo "❌ Error: This script must be run on a Docker Swarm manager node"
  echo "   Please run this on your production server"
  exit 1
fi

echo "✅ Running on Docker Swarm manager"
echo ""

# New Supabase keys (sb_publishable_ and sb_secret_ format)
# ⚠️ REPLACE THESE WITH YOUR ACTUAL KEYS - DO NOT COMMIT REAL KEYS!
SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY:-sb_publishable_your_key_here}"
SUPABASE_SECRET_KEY="${SUPABASE_SECRET_KEY:-sb_secret_your_key_here}"

# Check if secrets already exist
echo "🔍 Checking for existing secrets..."
if docker secret ls --format "{{.Name}}" | grep -q "^supabase_publishable_key$"; then
  echo "⚠️  Secret 'supabase_publishable_key' already exists"
  echo "   To update, you must remove the old secret first:"
  echo "   docker secret rm supabase_publishable_key"
  echo ""
else
  echo "✅ Creating secret: supabase_publishable_key"
  echo "$SUPABASE_PUBLISHABLE_KEY" | docker secret create supabase_publishable_key -
  echo "   ✓ Created"
  echo ""
fi

if docker secret ls --format "{{.Name}}" | grep -q "^supabase_secret_key$"; then
  echo "⚠️  Secret 'supabase_secret_key' already exists"
  echo "   To update, you must remove the old secret first:"
  echo "   docker secret rm supabase_secret_key"
  echo ""
else
  echo "✅ Creating secret: supabase_secret_key"
  echo "$SUPABASE_SECRET_KEY" | docker secret create supabase_secret_key -
  echo "   ✓ Created"
  echo ""
fi

# List all Supabase-related secrets
echo "📋 Current Supabase secrets:"
docker secret ls --filter "name=supabase" --format "table {{.Name}}\t{{.CreatedAt}}\t{{.UpdatedAt}}"
echo ""

echo "✅ Secret creation complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Update your docker-compose.yml to reference these new secrets"
echo "   2. Deploy/update your stack: docker stack deploy -c docker-compose.yml web"
echo "   3. Verify the service picks up the new secrets"
echo ""
echo "🔄 To rotate secrets in the future:"
echo "   1. Create new secret with versioned name (e.g., supabase_publishable_key_v2)"
echo "   2. Update stack to use new secret"
echo "   3. Remove old secret after successful deployment"
