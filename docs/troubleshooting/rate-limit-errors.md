# Rate Limit Errors on Login/Signup

## Problem

You may encounter a rate limit error when trying to log in or sign up:
- `"Too many login attempts. Please wait a few minutes and try again."`
- `"Too many signup attempts. Please wait a few minutes and try again."`
- HTTP 429 errors from Supabase Auth

## Root Causes

### 1. Refresh Token Loop (Most Common)
The application continuously tries to refresh an invalid/expired token, triggering rate limits. This happens when:
- Old or corrupted refresh tokens are stored in cookies
- The token was revoked but the cookie wasn't cleared
- Multiple tabs/windows are trying to refresh the same expired token

**Symptoms:**
- Rate limit errors appear even without manually logging in
- Errors occur immediately on page load
- Supabase logs show many `/token` requests with `refresh_token_not_found`

### 2. Actual Login Attempts
Too many manual login attempts in a short period (less common).

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

### Automatic Protection (Already Implemented)

This application now includes automatic refresh token loop detection:

**File:** `/app/plugins/02.supabase-refresh-guard.client.ts`

**What it does:**
- Monitors failed token refresh attempts
- Automatically clears invalid cookies after 3 failures in 10 seconds
- Prevents infinite refresh loops that cause rate limiting

**You'll see console warnings like:**
```
[supabase-refresh-guard] Token refresh failed (1/3)
[supabase-refresh-guard] Too many refresh failures. Clearing session to prevent rate limiting.
[supabase-refresh-guard] Invalid session cleared. Please sign in again.
```

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
