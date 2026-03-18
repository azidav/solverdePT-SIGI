<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

definePageMeta({
  middleware: 'permissions'
})

const props = defineProps<{ onClose?: () => void }>()
const route = useRoute()
const toast = useToast()
const loading = ref(true)

const roleId = computed(() => route.params.id as string)
const subroleId = computed(() => route.params.subroleId as string)

interface Subrole {
  id: number
  role_id: number
  name: string
  date_creation: string
}

const schema = z.object({
  name: z.string().min(2, 'Nome deve ter pelo menos 2 caracteres')
})

type Schema = z.output<typeof schema>

const state = reactive({
  name: undefined as string | undefined
})

// Load subrole data
onMounted(async () => {
  try {
    const subrolesData = await useApiFetch(`/api/subroles?role_id=${roleId.value}`, { method: 'GET' })
    const subroles = subrolesData as Subrole[]
    const subrole = subroles.find(s => s.id === Number(subroleId.value))

    if (!subrole) {
      toast.add({
        title: 'Erro',
        description: 'Sub-cargo não encontrado',
        color: 'error'
      })
      // Close modal on error
      return
    }

    state.name = subrole.name
  } catch {
    toast.add({
      title: 'Erro',
      description: 'Erro ao carregar sub-cargo',
      color: 'error'
    })
  } finally {
    loading.value = false
  }
})

async function onSubmit(event: FormSubmitEvent<Schema>) {
  try {
    await useApiFetch(`/api/subroles/${subroleId.value}`, {
      method: 'PUT',
      body: event.data
    })

    toast.add({
      title: 'Sucesso',
      description: 'Sub-cargo atualizado com sucesso',
      color: 'success'
    })

    props.onClose?.()
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Erro ao atualizar sub-cargo'
    toast.add({
      title: 'Erro',
      description: message,
      color: 'error'
    })
  }
}

function handleClose() {
  props.onClose?.()
}
</script>

<template>
  <div>
    <UModal @close="handleClose">
      <UCard>
        <template #header>
          <h3 class="text-lg font-semibold">
            Editar Sub-cargo
          </h3>
        </template>

        <div v-if="loading" class="flex items-center justify-center py-10">
          <UIcon name="i-lucide-loader-2" class="w-8 h-8 animate-spin text-muted" />
        </div>

        <UForm
          v-else
          :schema="schema"
          :state="state"
          class="space-y-4"
          @submit="onSubmit"
        >
          <UFormField label="Nome do Sub-cargo" name="name" required>
            <UInput
              v-model="state.name"
              placeholder="Ex: Clínico"
              autocomplete="off"
            />
          </UFormField>

          <div class="flex justify-end gap-3 pt-2">
            <UButton
              label="Cancelar"
              color="neutral"
              variant="subtle"
              @click="handleClose"
            />
            <UButton
              type="submit"
              label="Atualizar Sub-cargo"
            />
          </div>
        </UForm>
      </UCard>
    </UModal>
  </div>
</template>
