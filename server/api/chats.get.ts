import { getSupabaseServerClient } from '../utils/supabase'
import { getOrCreateSessionId } from '../utils/session'
import { getOrCreateProfileId } from '../utils/profiles'

export default defineEventHandler(async (event) => {
  const supabase = getSupabaseServerClient(event)
  const res = await supabase.auth.getUser().catch(() => null)
  const authUserId: string | null = res?.data?.user?.id ?? null
  const sessionId = getOrCreateSessionId(event)

  let profileId: string | null = null
  if (authUserId) {
    profileId = await getOrCreateProfileId(supabase, authUserId)
  }

  let query = supabase
    .schema('web')
    .from('chats')
    .select('id,title,created_at,updated_at,is_deleted,deleted_at,session_id,user_id')
    .eq('is_deleted', false)
    .order('updated_at', { ascending: false })
    .limit(100)

  if (profileId) {
    query = query.or(`user_id.eq.${profileId},session_id.eq.${sessionId}`)
  } else {
    query = query.eq('session_id', sessionId)
  }

  const { data, error } = await query
  if (error) {
    setResponseStatus(event, 500)
    return { error: error.message }
  }

  return (data || []).map(c => ({
    id: c.id as string,
    title: (c.title as string) || '',
    createdAt: c.created_at as string,
    updatedAt: c.updated_at as string
  }))
})
