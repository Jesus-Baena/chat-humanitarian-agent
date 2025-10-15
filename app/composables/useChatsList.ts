import { ref, onMounted } from 'vue'
import type { Chat } from '../types'

interface ChatRow {
  id: string
  title: string
  createdAt: string
  updatedAt: string
}

export function useChatsList() {
  const chats = ref<Chat[]>([])
  const isLoading = ref(false)
  const isError = ref<string | null>(null)

  async function refresh() {
    isLoading.value = true
    isError.value = null
    try {
      const listUnknown = await $fetch('/api/chats') as unknown
      const rows: ChatRow[] = Array.isArray(listUnknown)
        ? (listUnknown as Array<Record<string, unknown>>).map(c => ({
            id: String(c.id ?? ''),
            title: String(c.title ?? ''),
            createdAt: String(c.createdAt ?? new Date().toISOString()),
            updatedAt: String(c.updatedAt ?? new Date().toISOString())
          }))
        : []
      chats.value = rows.map(c => ({
        id: c.id,
        title: c.title,
        createdAt: new Date(c.createdAt),
        updatedAt: new Date(c.updatedAt)
      }))
    } catch (e) {
      const err = e as { message?: string }
      isError.value = err?.message || 'Failed to load chats'
    } finally {
      isLoading.value = false
    }
  }

  onMounted(() => {
    refresh()
  })

  return { chats, isLoading, isError, refresh }
}
