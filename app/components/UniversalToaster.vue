<script setup lang="ts">
const toastStore = useToastStore()

const toasts = computed(() => toastStore.activeToasts)

const getToastColor = (type: string) => {
  switch (type) {
    case 'success':
      return 'success'
    case 'error':
      return 'error'
    case 'warning':
      return 'warning'
    case 'info':
      return 'primary'
    default:
      return 'neutral'
  }
}

const getToastIcon = (type: string) => {
  switch (type) {
    case 'success':
      return 'i-lucide-check-circle'
    case 'error':
      return 'i-lucide-x-circle'
    case 'warning':
      return 'i-lucide-alert-triangle'
    case 'info':
      return 'i-lucide-info'
    default:
      return 'i-lucide-message-circle'
  }
}

function handleClose(id: string) {
  toastStore.remove(id)
}
</script>

<template>
  <div class="fixed top-4 right-4 z-50 flex flex-col gap-2 max-w-md">
    <TransitionGroup
      name="toast"
      tag="div"
      class="flex flex-col gap-2"
    >
      <UCard
        v-for="toast in toasts"
        :key="toast.id"
        :ui="{
          body: 'p-0'
        }"
      >
        <div class="flex items-start gap-3 p-4">
          <UIcon
            :name="getToastIcon(toast.type)"
            :class="`w-5 h-5 shrink-0 text-${getToastColor(toast.type)}`"
          />
          <div class="flex-1">
            <p v-if="toast.title" class="font-semibold text-sm mb-1">
              {{ toast.title }}
            </p>
            <p class="text-sm" :class="{ 'text-muted': toast.title }">
              {{ toast.message }}
            </p>
          </div>
          <UButton
            icon="i-lucide-x"
            size="xs"
            variant="ghost"
            color="neutral"
            @click="handleClose(toast.id)"
          />
        </div>
      </UCard>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}

.toast-enter-from {
  opacity: 0;
  transform: translateX(100%);
}

.toast-leave-to {
  opacity: 0;
  transform: translateX(100%);
}

.toast-move {
  transition: transform 0.3s ease;
}
</style>
