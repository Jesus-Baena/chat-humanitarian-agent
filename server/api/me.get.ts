import { getSupabaseServerClient } from '../utils/supabase'

export default defineEventHandler(async (event) => {
  const supabase = getSupabaseServerClient(event)
  // Validate the session and fetch the user
  const { data, error } = await supabase.auth.getUser()
  if (error || !data?.user) {
    // Anonymous allowed: return null user
    return null
  }
  const { user } = data
  return {
    id: user.id,
    email: user.email ?? undefined,
    user_metadata: user.user_metadata ?? {}
  }
})
