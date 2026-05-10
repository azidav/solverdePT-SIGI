<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

definePageMeta({ layout: 'default' })

const route = useRoute()
const toast = useToast()
const loading = ref(true)
const saving = ref(false)

const schema = z.object({
  name: z.string().min(2, 'Nome deve ter pelo menos 2 caracteres'),
  description: z.string().optional(),
  image_url: z.string().optional(),
  capacity: z.number({ coerce: true }).min(1, 'Capacidade deve ser pelo menos 1'),
  location: z.string().optional(),
  amenities: z.string().optional(),
  status: z.enum(['active', 'inactive'])
})
type Schema = z.output<typeof schema>

const state = reactive<Schema>({
  name: '',
  description: '',
  image_url: '',
  capacity: 1,
  location: '',
  amenities: '',
  status: 'active'
})

const statusOptions = [
  { label: 'Ativa', value: 'active' },
  { label: 'Inativa', value: 'inactive' }
]

const roomId = computed(() => parseInt(route.params.id as string))

onMounted(async () => {
  try {
    const room = await useApiFetch(`/api/meeting-rooms/${roomId.value}`) as any
    state.name = room.name || ''
    state.description = room.description || ''
    state.image_url = room.image_url || ''
    state.capacity = room.capacity || 1
    state.location = room.location || ''
    state.amenities = room.amenities || ''
    state.status = room.status || 'active'
  } catch {
    toast.add({ title: 'Erro', description: 'Sala não encontrada', color: 'error' })
    await navigateTo('/meeting-rooms/manage')
  } finally {
    loading.value = false
  }
})

async function onSubmit(event: FormSubmitEvent<Schema>) {
  saving.value = true
  try {
    await useApiFetch(`/api/meeting-rooms/${roomId.value}`, { method: 'PUT', body: event.data })
    toast.add({ title: 'Sala atualizada', color: 'success' })
    await navigateTo('/meeting-rooms/manage')
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Erro ao atualizar sala'
    toast.add({ title: 'Erro', description: msg, color: 'error' })
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="p-6">
        <div v-if="loading" class="flex justify-center py-16">
          <UIcon name="i-lucide-loader-2" class="size-6 animate-spin text-primary" />
        </div>

        <UCard v-else class="max-w-2xl">
          <template #header>
            <div class="flex items-center gap-2">
              <UIcon name="i-lucide-building-2" class="size-5 text-primary" />
              <h2 class="font-semibold">Editar Sala</h2>
            </div>
          </template>

          <UForm :schema="schema" :state="state" class="space-y-4" @submit="onSubmit">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <UFormField label="Nome da Sala" name="name" required class="md:col-span-2">
                <UInput v-model="state.name" placeholder="Ex: Sala Alpha" class="w-full" />
              </UFormField>

              <UFormField label="Descrição" name="description" class="md:col-span-2">
                <UTextarea v-model="state.description" placeholder="Descreva a sala..." class="w-full" :rows="3" />
              </UFormField>

              <UFormField label="Capacidade (pessoas)" name="capacity" required>
                <UInput v-model="state.capacity" type="number" min="1" class="w-full" />
              </UFormField>

              <UFormField label="Equipamentos / Comodidades" name="amenities" class="md:col-span-2">
                <UInput v-model="state.amenities" placeholder="Ex: Projetor, Quadro Branco, TV" class="w-full" />
              </UFormField>

              <UFormField label="Estado" name="status">
                <USelect v-model="state.status" :items="statusOptions" class="w-full" />
              </UFormField>
            </div>

            <div class="flex justify-end gap-2 pt-2">
              <UButton label="Cancelar" color="neutral" variant="subtle" @click="navigateTo('/meeting-rooms/manage')" />
              <UButton type="submit" label="Guardar Alterações" color="primary" icon="i-lucide-save" :loading="saving" />
            </div>
          </UForm>
        </UCard>
  </div>
</template>
