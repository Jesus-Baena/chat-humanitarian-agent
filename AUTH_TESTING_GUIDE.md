# Authentication Implementation - Testing Guide

## Implementation Complete ✅

All authentication files have been created and configured:

### Files Created/Modified:
- ✅ `/app/pages/login.vue` - Login page with email/password and OAuth
- ✅ `/app/pages/signup.vue` - Signup page for new users
- ✅ `/app/pages/auth/callback.vue` - OAuth callback handler (fixed)
- ✅ `nuxt.config.ts` - Updated Supabase module config

---

## Testing Checklist

### 1. Start Development Server
```bash
pnpm dev
```
Visit: `http://localhost:3000`

### 2. Test Login Page
- [ ] Navigate to `http://localhost:3000/login`
- [ ] Page loads without 404
- [ ] Login form is visible
- [ ] Email and password fields are present
- [ ] "Sign in with Google" button visible
- [ ] "Sign in with GitHub" button visible
- [ ] "Sign up" link points to `/signup`

### 3. Test Signup Page
- [ ] Navigate to `http://localhost:3000/signup`
- [ ] Signup form loads
- [ ] Can enter email
- [ ] Can enter password
- [ ] Can confirm password
- [ ] Form validates password mismatch
- [ ] Form validates password length (8+ chars)

### 4. Test Email/Password Login
**Prerequisite**: Create a test account first via Supabase dashboard or use test credentials

- [ ] Enter valid email
- [ ] Enter valid password
- [ ] Click "Sign in"
- [ ] Success message appears
- [ ] Redirected to home page
- [ ] User object is available via `useSupabaseUser()`

**To verify user is logged in:**
```typescript
const user = useSupabaseUser()
console.log(user.value) // Should show user object, not null
```

### 5. Test OAuth Login (Google)
- [ ] Click "Sign in with Google" button
- [ ] Redirected to Google login page
- [ ] Select or enter Google account
- [ ] Authorize access when prompted
- [ ] Redirected back to `http://localhost:3000/auth/callback`
- [ ] Loading indicator shows "Completing sign in..."
- [ ] Redirected to home page
- [ ] User is logged in
- [ ] Check browser DevTools → Application → Cookies
  - Should see cookies starting with `sb-` (Supabase session)
  - Cookie domain should be `.localhost` (dev) or `.baena.ai` (prod)

### 6. Test OAuth Login (GitHub)
- [ ] Click "Sign in with GitHub" button
- [ ] Redirected to GitHub login page
- [ ] Enter GitHub credentials or select account
- [ ] Authorize access when prompted
- [ ] Redirected back to callback
- [ ] Same process as Google test above

### 7. Test Session Persistence
**After successfully logging in:**

- [ ] Refresh the page (`F5` or `Cmd+R`)
- [ ] Still logged in (user object persists)
- [ ] No redirect to login page
- [ ] Can access chat features

### 8. Test Logout
- [ ] User menu (top right) shows user email
- [ ] Click "Logout" (or similar)
- [ ] Session is cleared
- [ ] Redirected to home page
- [ ] User object becomes `null`
- [ ] Cookies are cleared

### 9. Test Redirect on Login
**With redirect URL:**

- [ ] Visit: `http://localhost:3000/login?redirectTo=/chat/abc123`
- [ ] Login with credentials
- [ ] After successful login, redirected to `/chat/abc123`
- [ ] Not redirected to home page

### 10. Test Cross-Domain Auth (Production Setup)
**When deployed to baena.ai and chat.baena.ai:**

- [ ] Login on `https://baena.ai/login`
- [ ] Get redirected and logged in
- [ ] Navigate to `https://chat.baena.ai`
- [ ] Still logged in automatically (via shared `.baena.ai` cookie)
- [ ] Session persists across subdomains

### 11. Test Anonymous Access Still Works
- [ ] Open incognito/private window
- [ ] Don't login
- [ ] Visit `http://localhost:3000/chat`
- [ ] Chat works with anonymous session
- [ ] Session ID cookie is created (separate from auth cookies)

### 12. Test Form Validation

#### Email Validation
- [ ] Leave email empty, try to submit → Error shown
- [ ] Enter invalid email (no @), try to submit → Error shown
- [ ] Enter valid email → No error

#### Password Validation (Login)
- [ ] Leave password empty → Error shown
- [ ] Enter password, try to login → Handled by Supabase
- [ ] Wrong password → Error message from Supabase

#### Password Validation (Signup)
- [ ] Leave password empty → Error shown
- [ ] Enter < 8 characters → Error shown
- [ ] Passwords don't match → Error shown
- [ ] All valid → Signup proceeds

### 13. Test Error Handling

#### Invalid Credentials
- [ ] Use non-existent email
- [ ] Try to login
- [ ] Error message: "Invalid login credentials" or similar
- [ ] Not redirected

#### Network Error Simulation
- [ ] Turn off internet (dev tools → offline)
- [ ] Try to login
- [ ] Error message displayed
- [ ] Try again after internet restored → Works

### 14. Test Page Redirects

#### Already Logged In Redirects
- [ ] Login successfully
- [ ] Visit `/login` again
- [ ] Should redirect to home (optional) or allow re-auth
- [ ] Visit `/signup` → Same behavior

#### Unauthenticated Redirects
- [ ] Clear cookies/logout
- [ ] Visit `/chat` (protected route, if applicable)
- [ ] Should redirect to `/login` (if route requires auth)
- [ ] Or allow anonymous access (current setup)

---

## Debugging Tips

### Check Browser Console
```javascript
// See current user
const user = useSupabaseUser()
console.log('User:', user.value)

// Check session
const supabase = useSupabaseClient()
supabase.auth.getSession().then(({ data }) => {
  console.log('Session:', data.session)
})

// Check cookies
document.cookie // Shows all cookies
```

### Check DevTools
1. **Application → Cookies**
   - Look for cookies starting with `sb-`
   - Check domain (should be `.baena.ai` in prod)
   - Check HTTPOnly flag (should be set)

2. **Network → Fetch/XHR**
   - Look for auth requests
   - Check redirect responses

3. **Console**
   - Look for errors
   - Check for console.logs from app

### Common Issues

#### Cookies Not Persisting
- Check cookie domain setting in production
- Verify HTTPS is used (cookies need secure flag in production)
- Check browser privacy settings not blocking cookies

#### OAuth Redirect Loop
- Verify Supabase OAuth settings have correct redirect URLs
- Check app is whitelisted in Google/GitHub OAuth apps
- Clear browser cookies and try again

#### "getSession returns null"
- OAuth code exchange might have failed
- Check browser console for errors
- Check Supabase dashboard for logs
- Verify callback URL matches OAuth settings

#### "User persists but shouldn't"
- Check if route exclusion in nuxt.config is working
- Verify middleware isn't forcing redirect

---

## Performance Checklist

- [ ] Login page loads in < 2 seconds
- [ ] OAuth redirect completes in < 5 seconds
- [ ] Session persists instantly on page refresh
- [ ] No unnecessary API calls on page load
- [ ] No memory leaks (check DevTools Memory tab)

---

## Security Checklist

- [ ] Passwords sent over HTTPS only (production)
- [ ] Session cookies have HTTPOnly flag
- [ ] Session cookies have Secure flag (production)
- [ ] Session cookies have SameSite flag
- [ ] OAuth tokens not exposed in browser storage
- [ ] No sensitive data in localStorage
- [ ] CSRF protection working (Supabase handles this)

---

## Success Criteria

All tests pass when:
- ✅ Can login with email/password
- ✅ Can login with Google OAuth
- ✅ Can login with GitHub OAuth
- ✅ Can create account
- ✅ Session persists after refresh
- ✅ Cross-domain auth works (production)
- ✅ Anonymous access still works
- ✅ Logout clears session
- ✅ Form validation works
- ✅ Error messages display correctly
- ✅ Redirects work properly

---

## Next Steps

1. **Run all tests above**
2. **Fix any issues found**
3. **Deploy to staging**
4. **Run QA tests**
5. **Deploy to production**
6. **Monitor for errors**

---

## Rollback Plan

If something breaks:

```bash
# Revert changes
git checkout app/pages/auth/callback.vue
git checkout nuxt.config.ts

# Remove new files
rm app/pages/login.vue
rm app/pages/signup.vue

# Restart server
pnpm dev
```

This reverts the app to the previous state with no data loss.

---

## Support

If tests fail:
1. Check console errors
2. Verify Supabase credentials are correct
3. Check network requests in DevTools
4. Verify OAuth app configuration
5. Check Supabase dashboard for errors/logs

All implementation is complete. Ready to test! 🚀
