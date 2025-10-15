import { fileURLToPath } from 'node:url'

const siteUrl = process.env.NUXT_PUBLIC_SITE_URL || 'http://localhost:3000'
const supabaseUrl
  = process.env.NUXT_PUBLIC_SUPABASE_URL
    || process.env.SUPABASE_URL
    || ''
const supabaseAnonKey
  = process.env.NUXT_PUBLIC_SUPABASE_ANON_KEY
    || process.env.SUPABASE_ANON_KEY
    || ''
const flowiseUrl = process.env.NUXT_PUBLIC_FLOWISE_URL || ''
const flowiseApiKey = process.env.NUXT_PUBLIC_FLOWISE_API_KEY || ''

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    '@nuxt/eslint',
    '@nuxt/ui',
    '@nuxt/ui-pro',
    '@nuxtjs/mdc',
    ['@nuxtjs/supabase', {
      redirectOptions: {
        login: '/',
        callback: '/',
        exclude: ['/']
      }
    }]
  ],

  devtools: {
    enabled: true
  },

  srcDir: 'app',

  css: ['~/assets/css/main.css'],

  mdc: {
    highlight: {
      shikiEngine: 'javascript'
    },
    components: {
      prose: true
    }
  },

  runtimeConfig: {
    supabaseUrl,
    supabaseAnonKey,
    supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
    public: {
      siteUrl,
      supabaseUrl,
      supabaseAnonKey,
      flowiseUrl,
      flowiseApiKey
    }
  },

  compatibilityDate: '2024-07-11',

  supabase: {
    url: supabaseUrl,
    key: supabaseAnonKey,
    redirectOptions: {
      login: '/',
      callback: '/',
      exclude: ['/']
    }
  },

  nitro: {
    experimental: {
      openAPI: true
    }
  },

  vite: {
    resolve: {
      alias: {
        '~': fileURLToPath(new URL('./app', import.meta.url)),
        '@': fileURLToPath(new URL('./app', import.meta.url))
      }
    }
  }
})
