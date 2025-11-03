# Authentication Implementation Guide

## Quick Start

This guide will help you implement the missing authentication pages to enable login in the chat app, integrating it with the professional portfolio's auth system.

## Step 1: Create Login Page

Create `/app/pages/login.vue`:

```vue
<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

definePageMeta({
  layout: 'default',
  middleware: 'unauthenticated' // optional: redirect if already logged in
})

useSeoMeta({
  title: 'Login to AI Chat',
  description: 'Sign in to your account'
})

const toast = useToast()
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const route = useRoute()

// Handle redirect_to parameter for cross-domain auth
// Supports: baena.ai -> chat.baena.ai
const redirectTo = computed(() => {
  const path = route.query.redirect_to?.toString() || route.query.redirectTo?.toString()
  if (path) {
    // Allow redirects to chat.baena.ai from baena.ai
    if (path.startsWith('http://localhost:3001') || 
        path.startsWith('https://chat.baena.ai') ||
        path.startsWith('http://chat.localhost:3001')) {
      return path
    }
  }
  // Default to index page
  return typeof window !== 'undefined' ? `${window.location.origin}/` : '/'
})

// Redirect if already logged in
watch(user, (newUser) => {
  if (newUser) {
    if (redirectTo.value.startsWith('http')) {
      window.location.href = redirectTo.value
    } else {
      navigateTo(redirectTo.value, { external: false })
    }
  }
}, { immediate: true })

// Form fields
const fields = [{
  name: 'email',
  type: 'text' as const,
  label: 'Email',
  placeholder: 'your@email.com',
  required: true
}, {
  name: 'password',
  label: 'Password',
  type: 'password' as const,
  placeholder: 'Enter your password',
  required: true
}]

// OAuth providers
const providers = [{
  label: 'Google',
  icon: 'i-simple-icons-google',
  onClick: async () => {
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: redirectTo.value.startsWith('http') 
            ? redirectTo.value 
            : `${window.location.origin}/auth/callback?redirectTo=${encodeURIComponent(redirectTo.value)}`
        }
      })
      if (error) throw error
    } catch (error: unknown) {
      toast.add({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to sign in with Google',
        color: 'red'
      })
    }
  }
}, {
  label: 'GitHub',
  icon: 'i-simple-icons-github',
  onClick: async () => {
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'github',
        options: {
          redirectTo: redirectTo.value.startsWith('http')
            ? redirectTo.value
            : `${window.location.origin}/auth/callback?redirectTo=${encodeURIComponent(redirectTo.value)}`
        }
      })
      if (error) throw error
    } catch (error: unknown) {
      toast.add({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to sign in with GitHub',
        color: 'red'
      })
    }
  }
}]

// Validation schema
const schema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters')
})

type Schema = z.output<typeof schema>

async function onSubmit(payload: FormSubmitEvent<Schema>) {
  try {
    const { error } = await supabase.auth.signInWithPassword({
      email: payload.data.email,
      password: payload.data.password
    })

    if (error) throw error

    toast.add({
      title: 'Success',
      description: 'Logged in successfully'
    })

    // Navigate after successful login
    if (redirectTo.value.startsWith('http')) {
      window.location.href = redirectTo.value
    } else {
      navigateTo(redirectTo.value)
    }
  } catch (error: unknown) {
    toast.add({
      title: 'Error',
      description: error instanceof Error ? error.message : 'Failed to sign in',
      color: 'red'
    })
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center px-4 py-12 bg-gradient-to-b from-background to-muted/30">
    <div class="w-full max-w-md space-y-8">
      <!-- Logo -->
      <div class="text-center">
        <ULink to="/" class="inline-block mb-4">
          <Logo class="h-8 w-auto" />
        </ULink>
        <h1 class="text-3xl font-bold tracking-tight">Sign in</h1>
        <p class="mt-2 text-sm text-muted-foreground">
          to your humanitarian AI assistant
        </p>
      </div>

      <!-- Auth Form -->
      <UForm
        :schema="schema"
        @submit="onSubmit"
        class="space-y-6"
      >
        <!-- Email Field -->
        <UFormGroup name="email" label="Email address">
          <UInput
            type="email"
            placeholder="you@example.com"
            required
          />
        </UFormGroup>

        <!-- Password Field -->
        <UFormGroup name="password" label="Password">
          <UInput
            type="password"
            placeholder="••••••••"
            required
          />
        </UFormGroup>

        <!-- Submit Button -->
        <UButton type="submit" block size="lg">
          Sign in
        </UButton>
      </UForm>

      <!-- OAuth Divider -->
      <div class="relative">
        <div class="absolute inset-0 flex items-center">
          <div class="w-full border-t border-muted" />
        </div>
        <div class="relative flex justify-center text-sm">
          <span class="px-2 bg-background text-muted-foreground">
            Or continue with
          </span>
        </div>
      </div>

      <!-- OAuth Buttons -->
      <div class="grid grid-cols-2 gap-3">
        <UButton
          v-for="provider in providers"
          :key="provider.label"
          :icon="provider.icon"
          color="white"
          variant="outline"
          block
          @click="provider.onClick"
        >
          {{ provider.label }}
        </UButton>
      </div>

      <!-- Signup Link -->
      <p class="text-center text-sm text-muted-foreground">
        Don't have an account?
        <ULink to="/signup" class="font-semibold text-primary hover:underline">
          Sign up
        </ULink>
      </p>
    </div>
  </div>
</template>
```

## Step 2: Fix Auth Callback

Update `/app/pages/auth/callback.vue`:

```vue
<template>
  <div class="flex items-center justify-center min-h-screen">
    <div class="text-center">
      <UIcon name="i-lucide-loader-2" class="h-8 w-8 animate-spin mx-auto mb-4" />
      <p class="text-muted-foreground">Completing sign in...</p>
    </div>
  </div>
</template>

<script setup lang="ts">
const supabase = useSupabaseClient()
const router = useRouter()
const route = useRoute()
const { data: { session } } = await useAsyncData('session', () => supabase.auth.getSession())

onMounted(async () => {
  // Get redirect URL from query params
  const redirectTo = route.query.redirectTo?.toString() || '/'
  
  try {
    // The Supabase SSR client should have already handled the OAuth exchange
    // This page just needs to verify and redirect
    const { data, error } = await supabase.auth.getSession()
    
    if (error) {
      console.error('Auth callback error:', error)
      // Redirect to login on error
      await router.push('/login')
      return
    }

    if (!data.session) {
      console.warn('No session established after callback')
      await router.push('/login')
      return
    }

    // Successfully authenticated, redirect to intended destination
    if (redirectTo.startsWith('http')) {
      // External redirect (e.g., to another subdomain)
      window.location.href = redirectTo
    } else {
      // Internal redirect
      await router.push(redirectTo)
    }
  } catch (error) {
    console.error('Unexpected error in auth callback:', error)
    await router.push('/login')
  }
})
</script>
```

## Step 3: Update Nuxt Config

In `nuxt.config.ts`, update the Supabase module configuration:

```typescript
['@nuxtjs/supabase', {
  redirectOptions: {
    login: '/login',           // Changed from '/'
    callback: '/auth/callback',
    exclude: [
      '/', 
      '/chat/*',               // Allow unauthenticated access to chat
      '/auth/callback',
      '/login',                // Don't redirect from login
      '/signup'                // Don't redirect from signup
    ]
  }
}]
```

## Step 4: Create Signup Page (Optional)

Create `/app/pages/signup.vue`:

```vue
<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

definePageMeta({
  layout: 'default'
})

useSeoMeta({
  title: 'Create Account - AI Chat',
  description: 'Sign up for a new account'
})

const toast = useToast()
const supabase = useSupabaseClient()
const user = useSupabaseUser()

// Redirect if already logged in
watch(user, (newUser) => {
  if (newUser) {
    navigateTo('/')
  }
}, { immediate: true })

const schema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  confirmPassword: z.string()
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"],
})

type Schema = z.output<typeof schema>

async function onSubmit(payload: FormSubmitEvent<Schema>) {
  try {
    const { error } = await supabase.auth.signUp({
      email: payload.data.email,
      password: payload.data.password,
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback`
      }
    })

    if (error) throw error

    toast.add({
      title: 'Success',
      description: 'Check your email to confirm your account'
    })

    navigateTo('/login')
  } catch (error: unknown) {
    toast.add({
      title: 'Error',
      description: error instanceof Error ? error.message : 'Failed to sign up',
      color: 'red'
    })
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center px-4 py-12">
    <div class="w-full max-w-md space-y-8">
      <div class="text-center">
        <h1 class="text-3xl font-bold">Create account</h1>
        <p class="mt-2 text-sm text-muted-foreground">
          Join the humanitarian AI assistant
        </p>
      </div>

      <UForm :schema="schema" @submit="onSubmit" class="space-y-6">
        <UFormGroup name="email" label="Email address">
          <UInput type="email" placeholder="you@example.com" required />
        </UFormGroup>

        <UFormGroup name="password" label="Password">
          <UInput type="password" placeholder="••••••••" required />
        </UFormGroup>

        <UFormGroup name="confirmPassword" label="Confirm password">
          <UInput type="password" placeholder="••••••••" required />
        </UFormGroup>

        <UButton type="submit" block size="lg">
          Create account
        </UButton>
      </UForm>

      <p class="text-center text-sm text-muted-foreground">
        Already have an account?
        <ULink to="/login" class="font-semibold text-primary hover:underline">
          Sign in
        </ULink>
      </p>
    </div>
  </div>
</template>
```

## Step 5: Create Unauthenticated Middleware (Optional)

Create `/app/middleware/unauthenticated.ts` to redirect already-logged-in users:

```typescript
export default defineRouteMiddleware((to, from) => {
  const user = useSupabaseUser()
  
  if (user.value && (to.path === '/login' || to.path === '/signup')) {
    return navigateTo('/')
  }
})
```

## Step 6: Test the Auth Flow

1. **Start the app**: `pnpm dev`
2. **Visit login**: Go to `http://localhost:3000/login`
3. **Test email/password**: Create account first or use test credentials
4. **Test OAuth**: Click Google/GitHub button
5. **Verify session**: Check cookies and `useSupabaseUser()` composable
6. **Test cross-domain**: Verify auth works on subdomains

## Integration with Portfolio

The portfolio app at `/login` uses the same Supabase instance, so:

1. ✅ Cookies are shared via `.baena.ai` domain
2. ✅ Sessions persist across `baena.ai` and `chat.baena.ai`
3. ✅ User can login on portfolio and access chat
4. ✅ User can login on chat and context persists

## Environment Variables

Ensure these are set:
```bash
NUXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NUXT_PUBLIC_SUPABASE_KEY=eyJ... # anon key
SUPABASE_SECRET_KEY=eyJ...      # service role key (server-side)
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| OAuth redirect fails | Check Supabase auth settings for correct redirect URLs |
| Session doesn't persist | Verify cookie domain is `.baena.ai` in production |
| "redirectTo is undefined" | Ensure URL params are properly decoded |
| CORS errors | Check Supabase auth configuration for allowed origins |

