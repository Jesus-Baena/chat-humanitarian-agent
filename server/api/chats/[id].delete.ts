import { getSupabaseServerClient } from '../../utils/supabase'
import { getOrCreateSessionId } from '../../utils/session'
import { getOrCreateProfileId } from '../../utils/profiles'

export default defineEventHandler(async (event) => {
  const supabase = getSupabaseServerClient(event)
  const id = getRouterParam(event, 'id') as string
  if (!id) {
    setResponseStatus(event, 400)
    return { error: 'Missing chat id' }
  }
  const res = await supabase.auth.getUser().catch(() => null)
  const authUserId: string | null = res?.data?.user?.id ?? null
  const sessionId = getOrCreateSessionId(event)
  const profileId = authUserId ? await getOrCreateProfileId(supabase, authUserId) : null

  const { data: chats, error } = await supabase
    .schema('web')
    .from('chats')
    .select('id,user_id,session_id,is_deleted')
    .eq('id', id)
    .limit(1)
  if (error) {
    setResponseStatus(event, 500)
    return { error: error.message }
  }
  const chat = (chats || [])[0]
  if (!chat) {
    setResponseStatus(event, 404)
    return { error: 'Not found' }
  }
  const owned = profileId ? chat.user_id === profileId : chat.session_id === sessionId
  if (!owned) {
    setResponseStatus(event, 403)
    return { error: 'Forbidden' }
  }

  const { error: updErr } = await supabase
    .schema('web')
    .from('chats')
    .update({ is_deleted: true, deleted_at: new Date().toISOString() })
    .eq('id', id)
  if (updErr) {
    setResponseStatus(event, 500)
    return { error: updErr.message }
  }
  return { ok: true }
})
