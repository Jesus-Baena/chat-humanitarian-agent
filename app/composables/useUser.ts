interface User {
  id: string
  email?: string
  user_metadata?: {
    full_name?: string
    avatar_url?: string
  }
  [key: string]: unknown
}

const useUser = () => {
  const user = useState<User | null>('user', () => null)
  const loading = useState<boolean>('user-loading', () => true)

  const fetchUser = async () => {
    loading.value = true
    const { public: publicCfg } = useRuntimeConfig()
    const base: string = (publicCfg.apiBase as string) || ''
    // Prefer relative URL to leverage same-origin cookies; prepend base if provided.
    const url: string = base ? `${base.replace(/\/$/, '')}/api/me` : '/api/me'
    try {
      const response = await fetch(url, {
        headers: { Accept: 'application/json' },
        credentials: 'include'
      })
      if (!response.ok) {
        // If CORS blocked, response.type may be 'opaque'.
        if (import.meta.dev)
          console.warn(
            '[useUser] Non-ok user response',
            response.status,
            response.type
          )
        user.value = null
      } else {
        const data = await response.json().catch(() => null)
        user.value = data && data.id ? data : null
      }
    } catch (error) {
      console.error('Error fetching user:', error)
      user.value = null
    } finally {
      loading.value = false
    }
  }

  const handleVisibilityChange = () => {
    if (document.visibilityState === 'visible') {
      fetchUser()
    }
  }

  onMounted(() => {
    fetchUser()
    window.addEventListener('visibilitychange', handleVisibilityChange)
  })

  onUnmounted(() => {
    window.removeEventListener('visibilitychange', handleVisibilityChange)
  })

  const logout = async () => {
    const { public: publicCfg } = useRuntimeConfig()
    const apiBase: string = (publicCfg.apiBase as string) || ''
    const authBase: string = (publicCfg.authBase as string) || ''
    const logoutPath: string = (publicCfg.logoutPath as string) || '/logout'
    const current = typeof window !== 'undefined' ? window.location.href : ''
    // Prefer logging out via main app to clear shared cookies and redirect back to chat
    if (authBase) {
      const qs = current ? `?redirectTo=${encodeURIComponent(current)}` : ''
      window.location.href = `${authBase.replace(/\/$/, '')}${logoutPath}${qs}`
      return
    }
    // Fallback: use this app's logout endpoint
    const localLogout: string = apiBase
      ? `${apiBase.replace(/\/$/, '')}/auth/logout`
      : '/auth/logout'
    window.location.href = localLogout
  }

  return {
    user,
    loading,
    fetchUser,
    logout
  } as const
}

export default useUser
