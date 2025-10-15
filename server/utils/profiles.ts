import type { SupabaseClient } from '@supabase/supabase-js'

export async function getOrCreateProfileId(supabase: SupabaseClient, authUserId: string): Promise<string | null> {
  if (!authUserId) return null
  const { data: found, error: findErr } = await supabase
    .schema('web')
    .from('profiles')
    .select('id')
    .eq('user_id', authUserId)
    .limit(1)
  if (!findErr && Array.isArray(found) && found[0]?.id) {
    return found[0].id as string
  }
  // Create a minimal profile row
  const { data: created, error: insErr } = await supabase
    .schema('web')
    .from('profiles')
    .insert({ user_id: authUserId })
    .select('id')
    .limit(1)
  if (insErr) return null
  return (created && created[0]?.id) || null
}
