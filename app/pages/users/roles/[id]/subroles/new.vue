<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

definePageMeta({
  middleware: 'permissions'
})

const router = useRouter()
const route = useRoute()
const toast = useToast()
const isOpen = ref(true)

const roleId = computed(() => route.params.id as string)

const schema = z.object({
  name: z.string().min(2, 'Nome deve ter pelo menos 2 caracteres')
})

type Schema = z.output<typeof schema>

const state = reactive({
  name: undefined
})

async function onSubmit(event: FormSubmitEvent<Schema>) {
  try {
    await useApiFetch('/api/subroles', {
      method: 'POST',
      body: {
        role_id: Number(roleId.value),
        name: event.data.name
      }
    })

    toast.add({
      title: 'Sucesso',
      description: 'Sub-cargo criado com sucesso',
      color: 'success'
    })

    router.push(`/users/roles/${roleId.value}/subroles`)
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Erro ao criar sub-cargo'
    toast.add({
      title: 'Erro',
      description: message,
      color: 'error'
    })
  }
}

function onClose() {
  isOpen.value = false
  router.push(`/users/roles/${roleId.value}/subroles`)
}
</script>

<template>
  <div>
    <UModal v-model:open="isOpen" @close="onClose">
      <UCard>
        <template #header>
          <h3 class="text-lg font-semibold">Novo Sub-cargo</h3>
        </template>

        <UForm :schema="schema" :state="state" class="space-y-4" @submit="onSubmit">
          <UFormField label="Nome do Sub-cargo" name="name" required>
            <UInput
              v-model="state.name"
              placeholder="Ex: Clínico"
              autocomplete="off"
            />
          </UFormField>

          <div class="flex justify-end gap-3 pt-4">
            <UButton
              label="Cancelar"
              color="neutral"
              variant="subtle"
              @click="onClose"
            />
            <UButton
              type="submit"
              label="Criar Sub-cargo"
            />
          </div>
        </UForm>
      </UCard>
    </UModal>
  </div>
</template>
