#!/bin/bash

# Diagnostic script to check Supabase auth status
# This helps diagnose rate limit issues

echo "🔍 Supabase Rate Limit Diagnostic"
echo "=================================="
echo ""

# Check if logged into Supabase
echo "1️⃣  Checking Supabase CLI login status..."
if command -v supabase &> /dev/null; then
    if supabase status 2>&1 | grep -q "Not logged in"; then
        echo "   ❌ Not logged into Supabase CLI"
        echo "   ℹ️  This is OK - we'll check via curl instead"
    else
        echo "   ✅ Supabase CLI is available"
    fi
else
    echo "   ℹ️  Supabase CLI not installed (this is OK)"
fi
echo ""

# Check if the Supabase project is reachable
echo "2️⃣  Testing Supabase project health..."
SUPABASE_URL="https://qecdwuwkxgwkpopmdewl.supabase.co"
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${SUPABASE_URL}/auth/v1/health" 2>&1)

if [ "$HEALTH_RESPONSE" = "200" ]; then
    echo "   ✅ Supabase auth service is healthy (HTTP 200)"
else
    echo "   ⚠️  Got HTTP $HEALTH_RESPONSE from Supabase"
fi
echo ""

# Check current environment
echo "3️⃣  Checking environment configuration..."
if [ -f ".env" ]; then
    echo "   ✅ .env file exists"
    
    # Check for Supabase keys (without showing them)
    if grep -q "NUXT_PUBLIC_SUPABASE_URL" .env; then
        echo "   ✅ NUXT_PUBLIC_SUPABASE_URL is set"
    else
        echo "   ❌ NUXT_PUBLIC_SUPABASE_URL is missing"
    fi
    
    if grep -q "NUXT_PUBLIC_SUPABASE_KEY\|NUXT_PUBLIC_SUPABASE_ANON_KEY" .env; then
        echo "   ✅ Supabase key is set"
    else
        echo "   ❌ Supabase key is missing"
    fi
else
    echo "   ⚠️  .env file not found"
fi
echo ""

# Check if the new protection plugin exists
echo "4️⃣  Checking if rate limit protection is in place..."
if [ -f "app/plugins/02.supabase-refresh-guard.client.ts" ]; then
    echo "   ✅ Refresh guard plugin exists"
    echo "   ℹ️  This will protect against rate limiting once deployed"
else
    echo "   ❌ Refresh guard plugin not found"
    echo "   ℹ️  You may still be vulnerable to rate limit loops"
fi
echo ""

# Check if app is running
echo "5️⃣  Checking if app is running..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:3001" | grep -q "200"; then
    echo "   ✅ App is running on localhost:3001"
elif curl -s -o /dev/null -w "%{http_code}" "https://chat.baena.ai" | grep -q "200"; then
    echo "   ✅ App is accessible at https://chat.baena.ai"
else
    echo "   ⚠️  App doesn't appear to be running"
fi
echo ""

# Check for rate limit errors in recent git commits
echo "6️⃣  Checking recent changes..."
if git log --oneline -5 2>/dev/null | grep -iq "rate\|limit\|429"; then
    echo "   ✅ Found recent commits related to rate limiting"
else
    echo "   ℹ️  No recent rate limit related commits"
fi
echo ""

echo "=================================="
echo "📋 Summary & Next Steps"
echo "=================================="
echo ""
echo "If you're still getting rate limit errors:"
echo ""
echo "1️⃣  CLEAR BROWSER COOKIES"
echo "   → Open DevTools (F12)"
echo "   → Application/Storage → Cookies"
echo "   → Delete all 'sb-*' cookies"
echo ""
echo "2️⃣  WAIT 5-10 MINUTES"
echo "   → Supabase rate limits need time to reset"
echo ""
echo "3️⃣  TRY INCOGNITO MODE"
echo "   → This ensures no old cookies"
echo ""
echo "4️⃣  DEPLOY THE FIX"
echo "   → git add -A"
echo "   → git commit -m 'fix: rate limit protection'"
echo "   → git push origin main"
echo ""
echo "📚 See CLEAR_COOKIES_NOW.md for detailed instructions"
echo ""
