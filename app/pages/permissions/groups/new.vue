<script setup lang="ts">
import type { IUser } from '~/types/permissions'

definePageMeta({
  title: 'Novo Grupo'
})

const toast = useToast()
const loading = ref(true)
const users = ref<IUser[]>([])

onMounted(async () => {
  try {
    const data = await useApiFetch('/api/users')
    users.value = (data as IUser[]).map(u => ({
      ...u,
      first_name: u.name?.split(' ')[0] || '',
      last_name: u.name?.split(' ').slice(1).join(' ') || '',
      modified_at: '',
      modified_by: '',
      roles: u.roles || []
    }))
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar utilizadores', color: 'error' })
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <UDashboardPanel id="groups-new">
    <template #header>
      <UDashboardNavbar title="Novo Grupo">
        <template #leading>
          <UButton
            icon="i-lucide-arrow-left"
            color="neutral"
            variant="ghost"
            @click="navigateTo('/permissions/groups')"
          />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div v-if="loading" class="flex items-center justify-center py-16">
        <UIcon name="i-lucide-loader-2" class="size-6 animate-spin text-primary" />
      </div>

      <div v-else class="p-6">
        <UCard>
          <template #header>
            <div class="flex items-center gap-2">
              <UIcon name="i-lucide-users" class="size-5 text-primary" />
              <h2 class="font-semibold">
                Informações do Grupo
              </h2>
            </div>
          </template>
          <PermissionsGroupForm
            :users="users"
            @saved="navigateTo('/permissions/groups')"
            @cancel="navigateTo('/permissions/groups')"
          />
        </UCard>
      </div>
    </template>
  </UDashboardPanel>
</template>
