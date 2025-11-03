# Authentication Setup Guide

## Overview

This app uses Supabase authentication with Google OAuth provider. Authentication sessions are shared across subdomains using cookie domain `.baena.ai`.

## Supabase Configuration

### 1. Add Redirect URLs

In your Supabase project dashboard:

1. Go to **Authentication** → **URL Configuration**
2. Add these URLs to **Redirect URLs**:
   - Development: `http://localhost:3000/auth/callback`
   - Production: `https://chat.baena.ai/auth/callback`

### 2. Configure Site URL

Set the **Site URL** to:
- Development: `http://localhost:3000`
- Production: `https://chat.baena.ai`

### 3. Enable Google OAuth Provider

1. Go to **Authentication** → **Providers**
2. Enable **Google** provider
3. Add your Google OAuth credentials:
   - Client ID (from Google Cloud Console)
   - Client Secret (from Google Cloud Console)

## Google Cloud Console Setup

### 1. Create OAuth 2.0 Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create a new one)
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**
5. Select **Web application**

### 2. Configure Authorized Origins

Add these to **Authorized JavaScript origins**:
- `http://localhost:3000` (development)
- `https://chat.baena.ai` (production)
- `https://baena.ai` (if auth shared with main app)

### 3. Configure Redirect URIs

Add these to **Authorized redirect URIs**:
- `http://localhost:3000/auth/callback`
- `https://chat.baena.ai/auth/callback`
- Your Supabase auth callback: `https://<project-id>.supabase.co/auth/v1/callback`

## Authentication Flow

### User Login Process (Production)

1. User clicks **Sign In** button on `chat.baena.ai`
2. App redirects to `baena.ai/login?redirect_to=https://chat.baena.ai` (main portfolio login page)
3. User authenticates via Google OAuth on the main portfolio
4. Main portfolio creates session with cookie domain `.baena.ai`
5. User is redirected back to `https://chat.baena.ai`
6. Chat app detects existing session via shared cookie
7. User is automatically logged in on chat app

### User Login Process (Development)

1. User clicks **Sign In** button
2. App triggers Supabase OAuth directly
3. Redirects to Google OAuth consent screen
4. Google redirects to Supabase auth endpoint
5. Supabase creates session and redirects to `/auth/callback`
6. App processes the session and redirects to home page

### Session Sharing

Because the cookie domain is set to `.baena.ai`, the authentication session is automatically shared between:
- `baena.ai` (main portfolio)
- `chat.baena.ai` (this chat app)
- Any other `*.baena.ai` subdomain

This means users only need to log in once across all subdomains.

## Integration with Main Portfolio

The chat app integrates seamlessly with the main portfolio authentication system:

- **Sign In**: Redirects to `baena.ai/login` with `redirect_to` parameter
- **Profile**: Links to `baena.ai/profile`
- **Logout**: Redirects to `baena.ai/logout` to clear shared session

The main portfolio's login page (`app/pages/login.vue`) explicitly supports redirecting to `https://chat.baena.ai` after successful authentication.

## Environment Variables

Required for authentication:

```bash
# Supabase Configuration
NUXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NUXT_PUBLIC_SUPABASE_KEY=your-publishable-key

# Server-side key (for admin operations)
SUPABASE_SECRET_KEY=your-service-role-key

# Site URL
NUXT_PUBLIC_SITE_URL=https://chat.baena.ai
```

## Troubleshooting

### "Invalid redirect URL" Error

**Cause**: The redirect URL is not configured in Supabase.

**Solution**: Add the callback URL to Supabase Authentication → URL Configuration.

### "Access Denied" Error from Google

**Cause**: The redirect URI is not authorized in Google Cloud Console.

**Solution**: Add the callback URL to Google OAuth Credentials → Authorized redirect URIs.

### Session Not Shared Across Subdomains

**Cause**: Cookie domain not set correctly.

**Solution**: Verify that `server/utils/supabase.ts` sets cookie domain to `.baena.ai` in production.

### User Shows as Logged Out After Login

**Cause**: Session not being refreshed in the client.

**Solution**: Check the `/auth/callback` page is processing the session correctly and redirecting.

## Development Testing

### Test Login Flow Locally

1. Ensure Supabase redirect URL includes `http://localhost:3000/auth/callback`
2. Run the dev server: `pnpm dev`
3. Click **Sign In** button
4. Complete Google OAuth flow
5. Verify you're redirected back and logged in

### Debug Authentication State

Check the browser console for:
- Supabase session data
- Cookie values (should include `sb-*` cookies)
- Any error messages during auth flow

You can also check `/api/me` endpoint response to see the current user state.

## Production Deployment

1. Update Supabase redirect URLs to include production domain
2. Update Google OAuth redirect URIs to include production domain
3. Set environment variables in Docker Swarm secrets
4. Deploy the application
5. Test the complete authentication flow

## Security Notes

- Never commit OAuth credentials to version control
- Use environment variables for all sensitive configuration
- Regularly rotate service role keys
- Monitor authentication logs in Supabase dashboard
- Implement rate limiting on auth endpoints if needed
