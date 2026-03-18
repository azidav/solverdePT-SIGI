<script setup lang="ts">
const props = withDefaults(defineProps<{
  count?: number
  userId?: string
}>(), {
  count: 0,
  userId: ''
})

const open = ref(false)
const toast = useAppToast()
const emit = defineEmits(['deleted'])

async function onSubmit() {
  try {
    const { success, message } = await useApiFetch(`/api/users?id=${props.userId}`, {
      method: 'DELETE'
    })

    if (success) {
      toast.success('Utilizador apagado com sucesso', 'Sucesso')
      emit('deleted')
      open.value = false
    }
  } catch (error: unknown) {
    let message = 'Erro ao apagar utilizador'
    if (typeof error === 'object' && error) {
      const maybe = error as Record<string, unknown>
      const fromMessage = typeof maybe.message === 'string' ? maybe.message : undefined
      const data = maybe['data'] as Record<string, unknown> | undefined
      const dataMsg = typeof data?.message === 'string' ? data.message : undefined
      message = dataMsg || fromMessage || message
    }
    toast.error(message, 'Erro')
  }
}
</script>

<template>
  <UModal
    v-model:open="open"
    :title="`Apagar ${count} utilizador${count > 1 ? 'es' : ''}`"
    :description="`Tens a certeza que desejas apagar?`"
  >
    <slot />

    <template #body>
      <div class="flex justify-end gap-2">
        <UButton
          label="Cancelar"
          color="neutral"
          variant="subtle"
          @click="open = false"
        />
        <UButton
          label="Apagar"
          color="error"
          variant="solid"
          loading-auto
          @click="onSubmit"
        />
      </div>
    </template>
  </UModal>
</template>
