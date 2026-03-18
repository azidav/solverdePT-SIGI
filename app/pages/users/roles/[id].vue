<script setup lang="ts">
definePageMeta({ middleware: 'permissions' })

const route = useRoute()
const router = useRouter()
const toast = useToast()
const roleId = computed(() => route.params.id as string)

interface Role {
  id: number
  name: string
}

const loading = ref(true)
const state = reactive({ name: '' })

onMounted(async () => {
  try {
    const role = await useApiFetch(`/api/roles/${roleId.value}`, { method: 'GET' }) as Role
    state.name = role.name
  } catch {
    toast.add({ title: 'Erro', description: 'Cargo não encontrado.', color: 'error' })
    return router.replace('/users/roles')
  } finally {
    loading.value = false
  }
})

async function onSubmit() {
  try {
    await useApiFetch(`/api/roles/${roleId.value}`, { method: 'PUT', body: { name: state.name } })
    toast.add({ title: 'Sucesso', description: 'Cargo atualizado.', color: 'success' })
    router.replace('/users/roles')
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Erro ao atualizar cargo'
    toast.add({ title: 'Erro', description: message, color: 'error' })
  }
}
</script>

<template>
  <div class="flex justify-center">
    <div class="w-full max-w-lg space-y-4">
      <div v-if="loading" class="flex justify-center items-center py-12">
        <UIcon name="i-lucide-loader-2" class="w-8 h-8 animate-spin" />
      </div>
      <UCard v-else>
        <template #header>
          <div class="flex items-center justify-between gap-3">
            <div>
              <p class="text-base font-semibold">Editar Cargo</p>
              <p class="text-sm text-muted">Atualize o nome do cargo.</p>
            </div>
          </div>
        </template>

        <UForm class="space-y-4" @submit.prevent="onSubmit">
          <UFormField label="Nome do Cargo" name="name" required>
            <UInput v-model="state.name" placeholder="Ex: Psicólogo" autocomplete="off" />
          </UFormField>
          <div class="flex justify-end gap-3 pt-2">
            <UButton variant="subtle" color="neutral" @click="router.replace('/users/roles')">Cancelar</UButton>
            <UButton type="submit" label="Salvar" />
          </div>
        </UForm>
      </UCard>
    </div>
  </div>
</template>
