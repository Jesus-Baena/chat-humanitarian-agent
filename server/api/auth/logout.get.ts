import { getSupabaseServerClient } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  setHeader(event, 'Cache-Control', 'no-store')
  try {
    const supabase = getSupabaseServerClient(event)
    await supabase.auth.signOut()
  } catch {
    // ignore
  }
  return sendRedirect(event, '/', 302)
})
