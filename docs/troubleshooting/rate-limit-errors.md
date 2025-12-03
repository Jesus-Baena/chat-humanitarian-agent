# Rate Limit Errors on Login/Signup

## Problem

You may encounter a rate limit error when trying to log in or sign up:
- `"Too many login attempts. Please wait a few minutes and try again."`
- `"Too many signup attempts. Please wait a few minutes and try again."`
- HTTP 429 errors from Supabase Auth

## Root Causes

### 1. Automatic Token Refresh Loop (FIXED - December 2025)
**This was the primary cause of 429 errors.**

The `@nuxtjs/supabase` module was configured to automatically refresh tokens on every page load. When a token was invalid/expired, it would attempt to refresh it repeatedly, causing hundreds of requests per second.

**The Fix:**
- Disabled `autoRefreshToken` in `nuxt.config.ts`
- Implemented manual token refresh with rate limiting in `02.supabase-refresh-guard.client.ts`
- Added immediate session validation on page load (before any refresh attempts)
- Limited refresh attempts to max 1 per minute, only when user is logged in

**Old behavior:**
```
Page load → Auto refresh attempt → Failed (invalid token) → Auto retry → Failed → Auto retry → ... (100+ times) → 429 Rate Limit
```

**New behavior:**
```
Page load → Check session validity → Clear if invalid (no refresh attempt) → User can sign in fresh
OR
Page load → Valid session → Manual refresh after 5 minutes if still active
```

### 2. Expired Refresh Tokens in Cookies (Secondary Issue)
When tokens expire but cookies remain, the old system would continuously try to refresh them.

## Default Supabase Rate Limits

- **Email logins**: ~30-60 attempts per hour per IP
- **Email signups**: ~3-5 attempts per hour per IP
- **Password resets**: ~3-5 attempts per hour per IP
- **OAuth attempts**: ~10-20 attempts per hour per IP

## Immediate Solutions

### 1. Clear All Auth Cookies (Most Important)

This fixes the refresh token loop issue:

**Method A: Browser DevTools (Recommended)**
1. Open Browser DevTools (F12)
2. Go to Application → Cookies
3. Delete all cookies starting with `sb-`
4. Refresh the page

**Method B: JavaScript Console**
```javascript
// Paste this in the browser console
document.cookie.split(";").forEach(c => {
  const name = c.split("=")[0].trim();
  if (name.startsWith("sb-")) {
    document.cookie = name + "=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    // Also try parent domain
    const parts = location.hostname.split(".");
    if (parts.length >= 2) {
      const domain = "." + parts.slice(-2).join(".");
      document.cookie = name + "=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=" + domain;
    }
  }
});
location.reload();
```

**Method C: Use Incognito/Private Mode**
Test in a fresh session without any cookies.

### 2. Wait for Rate Limit Reset
Rate limits typically reset after **1 hour**. Simply wait before trying again.

### 3. Check Supabase Logs (For Diagnosis)

Navigate to your Supabase project dashboard:
```
https://supabase.com/dashboard/project/YOUR_PROJECT_ID/logs/auth-logs
```

**Look for:**
- `POST /token` with status 429
- Error: `refresh_token_not_found`
- Error: `over_request_rate_limit`

**If you see many `/token` requests:** You have a refresh token loop. Clear cookies (solution #1).

**If you see many failed `/token?grant_type=password` requests:** Someone is attempting to brute force login.

## Adjusting Rate Limits (For Admins)

### In Supabase Dashboard

1. Go to **Authentication > Rate Limits**
2. Adjust limits based on your needs:
   - **Development**: Can be more lenient
   - **Production**: Should be strict for security

### Recommended Production Settings

```
Email signups:     5 per hour per IP
Email logins:      60 per hour per IP
Password resets:   3 per hour per IP
OAuth attempts:    20 per hour per IP
```

### For High-Traffic Applications

Consider implementing:
- **CAPTCHA** on auth forms (Google reCAPTCHA, hCaptcha)
- **IP allowlisting** for known good actors
- **Custom rate limiting** in middleware (see below)

## Prevention Strategies

### Automatic Protection (NOW FULLY IMPLEMENTED)

**Core Fix: Manual Token Refresh Control**
- **File:** `/nuxt.config.ts`
- Disabled automatic token refresh that was causing the loops
- Tokens are only refreshed manually when needed (max once per minute)

**Smart Session Management**
- **File:** `/app/plugins/02.supabase-refresh-guard.client.ts`
- Validates session immediately on page load (before any refresh attempts)
- Clears invalid sessions instantly (no retry loops)
- Only refreshes tokens when user is actually logged in
- Periodic refresh every 5 minutes for active sessions (not on every page load)

**Console output you'll see:**
```
✓ [supabase-refresh-guard] User signed in successfully
✓ [supabase-refresh-guard] Token refreshed successfully
⚠ [supabase-refresh-guard] Detected invalid session, clearing cookies
ℹ [supabase-refresh-guard] Invalid auth session cleared. You can continue using anonymous chat or sign in again.
```

**Benefits:**
- ✅ Prevents refresh token loops entirely
- ✅ No more 429 rate limit errors from automatic refresh
- ✅ Invalid tokens are detected and cleared immediately
- ✅ Rate limited to 1 refresh attempt per minute max
- ✅ Anonymous chat continues to work even when auth cookies are cleared

### 1. User Education
- Clear error messages (already implemented in this app)
- Show remaining attempts if possible
- Provide alternative auth methods (OAuth)

### 2. Application-Level Rate Limiting

Add server middleware for custom rate limiting:

```typescript
// server/middleware/rate-limit.ts
import { defineEventHandler } from 'h3'

const loginAttempts = new Map<string, { count: number; resetAt: number }>()

export default defineEventHandler((event) => {
  if (!event.path.startsWith('/api/auth')) return

  const ip = getRequestIP(event) || 'unknown'
  const now = Date.now()
  const attempt = loginAttempts.get(ip)

  if (attempt && now < attempt.resetAt) {
    if (attempt.count >= 5) {
      throw createError({
        statusCode: 429,
        message: 'Too many requests. Please try again later.'
      })
    }
    attempt.count++
  } else {
    loginAttempts.set(ip, {
      count: 1,
      resetAt: now + 15 * 60 * 1000 // 15 minutes
    })
  }
})
```

### 3. Monitoring

Set up alerts for:
- Unusual spike in auth failures
- Consistent 429 errors from legitimate users
- Geographic patterns (attacks from specific regions)

## Testing After Changes

After adjusting rate limits or implementing fixes:

1. **Clear cache and cookies**
2. **Test in incognito mode**
3. **Verify error messages are user-friendly**
4. **Monitor Supabase auth logs**

## Related Files

- `/app/pages/login.vue` - Enhanced error handling for rate limits
- `/app/pages/signup.vue` - Enhanced error handling for rate limits
- `/nuxt.config.ts` - Supabase configuration
- `/server/utils/supabase.ts` - Server-side Supabase client

## Support Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase Rate Limiting](https://supabase.com/docs/guides/platform/going-into-prod#rate-limiting)
- [Security Best Practices](https://supabase.com/docs/guides/platform/going-into-prod#security)
