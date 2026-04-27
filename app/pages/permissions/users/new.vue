<script setup lang="ts">
import type { IGroup } from '~/types/permissions'

definePageMeta({
  title: 'Novo Utilizador'
})

const toast = useToast()
const loading = ref(true)
const groups = ref<IGroup[]>([])

onMounted(async () => {
  try {
    const data = await useApiFetch('/api/roles')
    groups.value = data as IGroup[]
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar grupos', color: 'error' })
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <UDashboardPanel id="users-new">
    <template #header>
      <UDashboardNavbar title="Novo Utilizador">
        <template #leading>
          <UButton
            icon="i-lucide-arrow-left"
            color="neutral"
            variant="ghost"
            @click="navigateTo('/permissions/users')"
          />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div v-if="loading" class="flex items-center justify-center py-16">
        <UIcon name="i-lucide-loader-2" class="size-6 animate-spin text-primary" />
      </div>

      <div v-else>
        <UCard>
          <template #header>
            <div class="flex items-center gap-2">
              <UIcon name="i-lucide-user-plus" class="size-5 text-primary" />
              <h2 class="font-semibold">
                Informações do Utilizador
              </h2>
            </div>
          </template>
          <PermissionsUserForm
            :groups="groups"
            @saved="navigateTo('/permissions/users')"
            @cancel="navigateTo('/permissions/users')"
          />
        </UCard>
      </div>
    </template>
  </UDashboardPanel>
</template>
