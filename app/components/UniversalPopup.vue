<script setup lang="ts">
import { computed, defineAsyncComponent } from 'vue'

const popupStore = usePopupStore()

const isOpen = computed({
  get: () => popupStore.isOpen,
  set: (value: boolean) => {
    if (!value) {
      popupStore.close()
    }
  }
})

const config = computed(() => popupStore.config)

// Lazy load page component if pagePath is provided
const asyncPageComponent = computed(() => {
  if (config.value?.pagePath) {
    return defineAsyncComponent(() => import(/* @vite-ignore */ config.value!.pagePath!))
  }
  return null
})

// Determine which component to render
const componentToRender = computed(() => {
  return asyncPageComponent.value || config.value?.pageComponent
})

const iconColorClass = computed(() => {
  switch (config.value?.type) {
    case 'delete':
      return 'text-error'
    case 'confirmation':
      return 'text-warning'
    default:
      return 'text-primary'
  }
})

const defaultIcon = computed(() => {
  switch (config.value?.type) {
    case 'delete':
      return 'i-lucide-trash-2'
    case 'confirmation':
      return 'i-lucide-alert-circle'
    default:
      return 'i-lucide-info'
  }
})

const displayIcon = computed(() => config.value?.icon || defaultIcon.value)

const defaultAcceptButton = computed(() => {
  if (config.value?.type === 'delete') {
    return {
      label: 'Eliminar',
      color: 'error' as const,
      icon: 'i-lucide-trash-2'
    }
  }
  if (config.value?.type === 'confirmation') {
    return {
      label: 'Confirmar',
      color: 'primary' as const
    }
  }
  return {
    label: 'OK',
    color: 'primary' as const
  }
})

const defaultDeclineButton = computed(() => ({
  label: 'Cancelar',
  color: 'neutral' as const,
  variant: 'subtle' as const
}))

const acceptButton = computed(() => ({
  ...defaultAcceptButton.value,
  ...config.value?.acceptButton
}))

const declineButton = computed(() => ({
  ...defaultDeclineButton.value,
  ...config.value?.declineButton
}))

async function handleAccept() {
  await popupStore.accept()
}

async function handleDecline() {
  await popupStore.decline()
}

async function handleClose() {
  await popupStore.close()
}
</script>

<template>
  <UModal
    v-model:open="isOpen"
    @close="handleClose"
  >
    <template #content>
      <UCard v-if="config">
        <template #header>
          <div class="flex items-center gap-2">
            <UIcon
              v-if="displayIcon"
              :name="displayIcon"
              class="w-5 h-5"
              :class="iconColorClass"
            />
            <h3 class="text-lg font-semibold">
              {{ config.title || 'Popup' }}
            </h3>
          </div>
        </template>

        <!-- eslint-disable-next-line vue/no-v-html -->
        <div v-if="config.content" class="text-muted" v-html="config.content" />

        <component
          :is="componentToRender"
          v-if="componentToRender"
          v-bind="config.pageProps || {}"
        />

        <template #footer>
          <div class="flex justify-end gap-3">
            <UButton
              v-if="declineButton"
              :label="declineButton.label"
              :color="declineButton.color"
              :variant="declineButton.variant"
              :icon="declineButton.icon"
              @click="handleDecline"
            />
            <UButton
              v-if="acceptButton"
              :label="acceptButton.label"
              :color="acceptButton.color"
              :variant="acceptButton.variant"
              :icon="acceptButton.icon"
              @click="handleAccept"
            />
          </div>
        </template>
      </UCard>
    </template>
  </UModal>
</template>
