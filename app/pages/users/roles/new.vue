<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

definePageMeta({ middleware: 'permissions' })

const router = useRouter()
const toast = useToast()
const isOpen = ref(true)

const schema = z.object({ name: z.string().min(2, 'Nome deve ter pelo menos 2 caracteres') })
type Schema = z.output<typeof schema>
const state = reactive({ name: '' })

function onClose() {
  isOpen.value = false
  router.push('/users/roles')
}

async function onSubmit(event: FormSubmitEvent<Schema>) {
  try {
    await useApiFetch('/api/roles', { method: 'POST', body: event.data })
    toast.add({ title: 'Sucesso', description: 'Cargo criado com sucesso', color: 'success' })
    router.push('/users/roles')
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Erro ao criar cargo'
    toast.add({ title: 'Erro', description: message, color: 'error' })
  }
}
</script>

<template>
  <div>
    <UModal
      v-model:open="isOpen"
      title="Novo Cargo"
      description="Crie um novo cargo para a sua organização."
      :ui="{ content: 'sm:max-w-lg' }"
      @close="onClose"
    >
      <template #body>
        <UForm
          :schema="schema"
          :state="state"
          class="space-y-4"
          @submit="onSubmit"
        >
          <UFormField label="Nome do Cargo" name="name" required>
            <UInput
              v-model="state.name"
              placeholder="Ex: Psicólogo"
              autocomplete="off"
            />
          </UFormField>

          <div class="flex justify-end gap-2 pt-2">
            <UButton
              label="Cancelar"
              color="neutral"
              variant="subtle"
              @click="onClose"
            />
            <UButton
              type="submit"
              label="Criar Cargo"
            />
          </div>
        </UForm>
      </template>
    </UModal>
  </div>
</template>
