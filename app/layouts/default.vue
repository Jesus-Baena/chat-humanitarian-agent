<script setup lang="ts">
const open = ref(false)

const { chats, isLoading, isError, refresh } = useChatsList()

defineShortcuts({
  c: () => {
    navigateTo('/')
  }
})
</script>

<template>
  <UDashboardGroup>
    <UDashboardSidebar
      id="default"
      v-model:open="open"
      :min-size="22"
      :default-size="25"
      :max-size="40"
      collapsible
      resizable
      class="bg-elevated/50"
    >
      <template #header="{ collapsed }">
        <a
          href="https://baena.ai"
          target="_blank"
          rel="noopener noreferrer"
          class="flex items-center"
        >
          <Logo class="h-8 w-auto shrink-0" />
        </a>

        <div v-if="!collapsed" class="flex items-center gap-1.5 ms-auto">
          <UDashboardSearchButton collapsed />
          <UDashboardSidebarCollapse />
        </div>
      </template>

      <template #default="{ collapsed }">
        <div class="flex flex-col gap-1.5">
          <UButton
            v-bind="
              collapsed ? { icon: 'i-lucide-plus' } : { label: 'New chat' }
            "
            variant="soft"
            block
            to="/"
            @click="open = false"
          />

          <template v-if="collapsed">
            <UDashboardSearchButton collapsed />
            <UDashboardSidebarCollapse />
          </template>

          <div v-if="!collapsed" class="mt-2 flex items-center justify-between">
            <span class="text-sm text-muted">Your chats</span>
            <UButton
              size="xs"
              variant="ghost"
              icon="i-lucide-refresh-cw"
              :loading="isLoading"
              @click="refresh"
            />
          </div>

          <div v-if="isError && !collapsed" class="text-xs text-red-500">
            {{ isError }}
          </div>

          <div v-if="chats.length === 0 && !isLoading" class="text-xs text-muted" :class="{ 'text-center': collapsed }">
            <span v-if="!collapsed">No chats yet</span>
          </div>

          <div class="flex flex-col gap-1.5 mt-1">
            <NuxtLink
              v-for="chat in chats"
              :key="chat.id"
              class="truncate rounded px-2 py-1.5 hover:bg-elevated/70 text-sm"
              :to="`/chat/${chat.id}`"
              :title="chat.title"
              @click="open = false"
            >
              <span v-if="!collapsed">{{ chat.title }}</span>
              <span v-else class="i-lucide-message-circle h-5 w-5" />
            </NuxtLink>
          </div>
        </div>
      </template>

      <template #footer>
        <UserMenu />
      </template>
    </UDashboardSidebar>

    <UDashboardSearch
      placeholder="Search chats..."
      :groups="[
        {
          id: 'links',
          items: [
            {
              label: 'New chat',
              to: '/',
              icon: 'i-lucide-square-pen'
            }
          ]
        }
      ]"
    />

    <slot />
  </UDashboardGroup>
</template>
