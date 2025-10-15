<script setup lang="ts">
const emit = defineEmits<{
  'send-message': [message: string]
}>()

const message = ref('')

function sendMessage() {
  if (message.value.trim()) {
    emit('send-message', message.value.trim())
    message.value = ''
  }
}

function handleKeydown(event: KeyboardEvent) {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault()
    sendMessage()
  }
}
</script>

<template>
  <div class="relative">
    <UTextarea
      v-model="message"
      placeholder="Type your message here..."
      aria-label="Chat message input"
      autocomplete="off"
      class="w-full pr-16 resize-none"
      size="xl"
      :rows="1"
      autoresize
      @keydown="handleKeydown"
    />
    <UButton
      variant="outline"
      size="md"
      class="absolute bottom-2.5 right-2.5"
      :disabled="!message.trim()"
      aria-label="Send message"
      title="Send message"
      @click="sendMessage"
    >
      <UIcon name="i-heroicons-paper-airplane" />
    </UButton>
  </div>
</template>
