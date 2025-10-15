import { getSupabaseServerClient } from '../utils/supabase'
import { getOrCreateSessionId } from '../utils/session'
import { getOrCreateProfileId } from '../utils/profiles'

function pickString(o: unknown, key: string): string | null {
  if (o && typeof o === 'object') {
    const v = (o as Record<string, unknown>)[key]
    return typeof v === 'string' ? v : null
  }
  return null
}

export default defineEventHandler(async (event) => {
  const supabase = getSupabaseServerClient(event)
  const raw: unknown = await readBody(event).catch(() => ({}))
  const fromParam = getRouterParam(event, 'id') as string | undefined
  const id = pickString(raw, 'id') ?? fromParam ?? ''
  if (!id) {
    setResponseStatus(event, 400)
    return { error: 'Missing chat id' }
  }

  const res = await supabase.auth.getUser().catch(() => null)
  const authUserId: string | null = res?.data?.user?.id ?? null
  const profileId = authUserId ? await getOrCreateProfileId(supabase, authUserId) : null
  const sessionId = getOrCreateSessionId(event)

  const titleCandidate = pickString(raw, 'title') || 'New chat'
  const title = titleCandidate.slice(0, 80)
  const insertChat = {
    id,
    user_id: profileId,
    session_id: profileId ? null : sessionId,
    title,
    is_deleted: false
  }
  const { error } = await supabase.schema('web').from('chats').insert(insertChat)
  if (error) {
    setResponseStatus(event, 500)
    return { error: error.message }
  }
  return { id }
})
