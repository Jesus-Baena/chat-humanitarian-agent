import { getSupabaseServerClient } from '../../../utils/supabase'
import { getOrCreateSessionId } from '../../../utils/session'
import { getOrCreateProfileId } from '../../../utils/profiles'

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

  const { data: chats, error: chatErr } = await supabase
    .schema('web')
    .from('chats')
    .select('id,user_id,session_id,is_deleted')
    .eq('id', id)
    .limit(1)

  if (chatErr) {
    setResponseStatus(event, 500)
    return { error: chatErr.message }
  }
  const chat = (chats || [])[0]
  if (!chat || chat.is_deleted) {
    setResponseStatus(event, 404)
    return { error: 'Chat not found' }
  }
  const owned = profileId ? chat.user_id === profileId : chat.session_id === sessionId
  if (!owned) {
    setResponseStatus(event, 403)
    return { error: 'Forbidden' }
  }

  const { data, error } = await supabase
    .schema('web')
    .from('messages')
    .select('id,role,content,created_at')
    .eq('chat_id', id)
    .order('created_at', { ascending: true })
    .limit(500)

  if (error) {
    setResponseStatus(event, 500)
    return { error: error.message }
  }

  return (data || []).map(m => ({
    id: m.id as string,
    chatId: id,
    role: m.role as 'user' | 'assistant' | 'system',
    content: m.content as string,
    createdAt: m.created_at as string
  }))
})
