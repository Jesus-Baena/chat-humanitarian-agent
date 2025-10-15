<template>
  <UDashboardPanel grow>
    <UDashboardNavbar />

    <ChatWindow :chat-id="chatId" :initial-message="initialMessage" />
  </UDashboardPanel>
</template>

<script setup lang="ts">
// Get the chat ID from the route
const route = useRoute()
const chatId = computed(() => route.params.id as string)

// Get the initial message from query parameter
const initialMessage = computed(
  () => route.query.message as string | undefined
)

// Set page title
useHead({
  title: `Chat ${chatId.value} - Nuxt Chat`
})
</script>
